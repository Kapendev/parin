// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `memory` module provides functions for dealing with memory and various general-purpose containers.
/// `List`, `BufferList`, and `FixedList` are the "basic" containers.
/// Most other containers can accept one of these to adjust their allocation strategy.

module parin.joka.memory;

version (JokaNoTypes) {
    pragma(msg, "Joka: Defining missing `types.d` symbols for `memory.d`.");

    private alias Sz = size_t;
    private alias IStr = const(char)[];
    private alias Str = char[];

    private @safe nothrow @nogc IStr fmtSignedGroup(IStr[] fmtStrs, long[] args...) { return ""; }
    private @safe nothrow @nogc IStr fmtFloatingGroup(IStr[] fmtStrs, double[] args...) { return ""; }

    private struct StaticArray(T, Sz N) {
        alias Self = StaticArray!(T, N);
        enum length = N;
        enum capacity = N;

        align(T.alignof) ubyte[T.sizeof * N] _data;

        pragma(inline, true) @trusted nothrow @nogc:

        mixin sliceOps!(Self, T);

        this(const(T)[] items...) {
            if (items.length > N) assert(0, "Too many items.");
            auto me = this.items;
            foreach (i; 0 .. N) me[i] = cast(T) items[i];
        }

        T[] items() {
            return (cast(T*) _data.ptr)[0 .. N];
        }

        T* ptr() {
            return cast(T*) _data.ptr;
        }
    }

    private mixin template sliceOps(T, TT, IStr itemsMemberName = "items") if (__traits(hasMember, T, "items")) {
        pragma(inline, true) @trusted nothrow @nogc {
            TT[] opSlice(Sz dim)(Sz i, Sz j) {
                return mixin(itemsMemberName, "[i .. j]");
            }

            TT[] opIndex() {
                return mixin(itemsMemberName, "[]");
            }

            TT[] opIndex(TT[] slice) {
                return slice;
            }

            ref TT opIndex(Sz i) {
                return mixin(itemsMemberName, "[i]");
            }

            void opIndexAssign(const(TT) rhs, Sz i) {
                mixin(itemsMemberName, "[i] = cast(TT) rhs;");
            }

            void opIndexOpAssign(const(char)[] op)(const(TT) rhs, Sz i) {
                mixin(itemsMemberName, "[i]", op, "= cast(TT) rhs;");
            }

            Sz opDollar(Sz dim)() {
                return mixin(itemsMemberName, ".length");
            }
        }
    }

    private IStr __getEmptyString() @nogc pure nothrow @safe {
        return "";
    }
    private struct InterpolationHeader {
        alias toString = __getEmptyString;
    }
    private struct InterpolationFooter {
        alias toString = __getEmptyString;
    }

    private @safe nothrow @nogc IStr toStr(IStr value) { return value; }
    private @safe nothrow @nogc IStr toStr(long value) { return ""; }
    private enum defaultAsciiFmtArgStr = "{}";
} else {
    import parin.joka.types;
}

// --- Core

// NOTE: Memory tracking related things are here.
debug {
    version (D_BetterC) {
        enum isTrackingMemory = false;
    } else {
        enum isTrackingMemory = true;

        struct _MallocInfo {
            IStr file;
            Sz line;
            Sz size;
            bool canIgnore;
            IStr group;
        }

        struct _MallocGroupInfo {
            Sz size;
            Sz count = 1;
        }

        struct _MemoryTrackingState {
            _MallocInfo[void*] table;
            _MallocInfo[] invalidFreeTable;
            IStr[] currentGroupStack;
            Sz totalBytes;
            bool canIgnoreInvalidFree;
            Str infoBuffer;
            _MallocGroupInfo[_MallocInfo] groupBuffer;
        }

        version (JokaGlobalTracking) {
            pragma(msg, "Joka: Using global (non-TLS) tracking.");
            __gshared _MemoryTrackingState _memoryTrackingState;
        } else {
            _MemoryTrackingState _memoryTrackingState;
        }
    }
} else {
    enum isTrackingMemory = false;
}

struct MemoryState {
    void* allocatorState;
    AllocatorMallocFunc allocatorMallocFunc; // NOTE: If this is null, then we should return to the default allocator setup.
    AllocatorReallocFunc allocatorReallocFunc;
    AllocatorFreeFunc allocatorFreeFunc;
}

extern(C) nothrow {
    alias AllocatorMallocFunc = void* function(void* allocatorState, Sz alignment, Sz size, IStr file, Sz line);
    alias AllocatorReallocFunc = void* function(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, Sz newSize, IStr file, Sz line);
}

extern(C) nothrow @nogc {
    alias AllocatorFreeFunc = void function(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, IStr file, Sz line);
}

struct AllocationGroup {
    IStr _currentGroup;

    @safe nothrow:

    this(IStr group) {
        this._currentGroup = group;
        beginAllocationGroup(group);
    }

    @nogc
    ~this() {
        endAllocationGroup();
    }
}

MemoryState __memoryState;

@system nothrow:

// NOTE: This part has the main allocation functions.
// NOTE: Some `JokaCustomMemory` functions are defined also in `types.d`.
version (JokaCustomMemory) {
    extern(C) nothrow       void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__);
    extern(C) nothrow       void* jokaRealloc(void* ptr, Sz size, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__);
    extern(C) nothrow @nogc void  jokaFree(void* ptr, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__);

    extern(C) nothrow @nogc
    void jokaRestoreDefaultAllocatorSetup(MemoryState* state) {
        state = MemoryState();
    }

    extern(C) nothrow
    void* jokaSystemMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        return jokaMalloc(size, file, line);
    }

    extern(C) nothrow
    void* jokaSystemRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        return jokaRealloc(ptr, size, 0, file, line);
    }

    extern(C) nothrow @nogc
    void jokaSystemFree(void* ptr, IStr file = __FILE__, Sz line = __LINE__) {
        jokaFree(ptr, 0, file, line);
    }

    version (JokaNoTypes) {
        private extern(C) nothrow @nogc pure void* jokaMemset(void* ptr, int value, Sz size);
        private extern(C) nothrow @nogc pure void* jokaMemcpy(void* ptr, const(void)* source, Sz size);
    }
} else version (JokaGcMemory) {
    import memoryd = core.memory;
    import stringc = core.stdc.string;

    extern(C) nothrow @nogc
    void jokaRestoreDefaultAllocatorSetup(MemoryState* state) {
        state.allocatorState = null;
        state.allocatorMallocFunc = &jokaAllocatorMalloc;
        state.allocatorReallocFunc = &jokaAllocatorRealloc;
        state.allocatorFreeFunc = &jokaAllocatorFree;
    }

    extern(C) nothrow
    void* jokaSystemMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        return memoryd.GC.malloc(size);
    }

    extern(C) nothrow
    void* jokaAllocatorMalloc(void* allocatorState, Sz alignment, Sz size, IStr file, Sz line) {
        return jokaSystemMalloc(size, file, line);
    }

    extern(C) nothrow
    void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryState.allocatorMallocFunc == null) jokaRestoreDefaultAllocatorSetup(&__memoryState);
        return __memoryState.allocatorMallocFunc(&__memoryState.allocatorState, 0, size, file, line);
    }

    extern(C) nothrow
    void* jokaSystemRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        return memoryd.GC.realloc(ptr, size);
    }

    extern(C) nothrow
    void* jokaAllocatorRealloc(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, Sz newSize, IStr file, Sz line) {
        return jokaSystemRealloc(oldPtr, newSize, file, line);
    }

    extern(C) nothrow
    void* jokaRealloc(void* ptr, Sz size, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryState.allocatorMallocFunc == null) jokaRestoreDefaultAllocatorSetup(&__memoryState);
        return __memoryState.allocatorReallocFunc(&__memoryState.allocatorState, 0, ptr, oldSize, size, file, line);
    }

    extern(C) nothrow @nogc
    void jokaSystemFree(void* ptr, IStr file = __FILE__, Sz line = __LINE__) {}

    extern(C) nothrow @nogc
    void jokaAllocatorFree(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, IStr file, Sz line) {
        return jokaSystemFree(oldPtr, file, line);
    }

    extern(C) nothrow @nogc
    void jokaFree(void* ptr, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryState.allocatorMallocFunc == null) jokaRestoreDefaultAllocatorSetup(&__memoryState);
        __memoryState.allocatorFreeFunc(&__memoryState.allocatorState, 0, ptr, oldSize, file, line);
    }

    version (JokaNoTypes) {
        extern(C) nothrow @nogc pure
        void* jokaMemset(void* ptr, int value, Sz size) {
            return stringc.memset(ptr, value, size);
        }
        extern(C) nothrow @nogc pure
        void* jokaMemcpy(void* ptr, const(void)* source, Sz size) {
            return stringc.memcpy(ptr, source, size);
        }
    }
} else {
    version(JokaPhobosStdc) {
        import stdlibc = core.stdc.stdlib;
        import stringc = core.stdc.string; // NOTE: Used for `JokaNoTypes`.
    } else {
        import stdlibc = parin.joka.stdc;
        import stringc = parin.joka.stdc; // NOTE: Used for `JokaNoTypes`.
    }

    extern(C) nothrow @nogc
    void jokaRestoreDefaultAllocatorSetup(MemoryState* state) {
        state.allocatorState = null;
        state.allocatorMallocFunc = &jokaAllocatorMalloc;
        state.allocatorReallocFunc = &jokaAllocatorRealloc;
        state.allocatorFreeFunc = &jokaAllocatorFree;
    }

    extern(C) nothrow
    void* jokaSystemMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        if (size == 0) {
            return null;
        }

        auto result = stdlibc.malloc(size);
        static if (isTrackingMemory) {
            if (result) {
                _memoryTrackingState.table[result] = _MallocInfo(file, line, size, false, _memoryTrackingState.currentGroupStack.length ? _memoryTrackingState.currentGroupStack[$ - 1] : "");
                _memoryTrackingState.totalBytes += size;
            }
        }
        return result;
    }

    extern(C) nothrow
    void* jokaAllocatorMalloc(void* allocatorState, Sz alignment, Sz size, IStr file, Sz line) {
        return jokaSystemMalloc(size, file, line);
    }

    extern(C) nothrow
    void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryState.allocatorMallocFunc == null) jokaRestoreDefaultAllocatorSetup(&__memoryState);
        return __memoryState.allocatorMallocFunc(&__memoryState.allocatorState, 0, size, file, line);
    }

    extern(C) nothrow
    void* jokaSystemRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        if (size == 0) {
            jokaFree(ptr);
            return null;
        }

        void* result;
        if (ptr) {
            static if (isTrackingMemory) {
                if (auto mallocValue = ptr in _memoryTrackingState.table) {
                    result = stdlibc.realloc(ptr, size);
                    if (result) {
                        _memoryTrackingState.table[result] = _MallocInfo(file, line, size, mallocValue.canIgnore, _memoryTrackingState.currentGroupStack.length ? _memoryTrackingState.currentGroupStack[$ - 1] : "");
                        _memoryTrackingState.totalBytes += size;
                        _memoryTrackingState.totalBytes -= mallocValue.size;
                        if (ptr != result) _memoryTrackingState.table.remove(ptr);
                    }
                } else {
                    if (_memoryTrackingState.canIgnoreInvalidFree) {
                        _memoryTrackingState.invalidFreeTable ~= _MallocInfo(file, line, size, false, _memoryTrackingState.currentGroupStack.length ? _memoryTrackingState.currentGroupStack[$ - 1] : "");
                    } else {
                        assert(0, "Invalid free.");
                    }
                }
            } else {
                result = stdlibc.realloc(ptr, size);
            }
        } else {
            result = jokaMalloc(size, file, line);
        }
        return result;
    }

    extern(C) nothrow
    void* jokaAllocatorRealloc(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, Sz newSize, IStr file, Sz line) {
        return jokaSystemRealloc(oldPtr, newSize, file, line);
    }

    extern(C) nothrow
    void* jokaRealloc(void* ptr, Sz size, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryState.allocatorMallocFunc == null) jokaRestoreDefaultAllocatorSetup(&__memoryState);
        return __memoryState.allocatorReallocFunc(&__memoryState.allocatorState, 0, ptr, oldSize, size, file, line);
    }

    extern(C) nothrow @nogc
    void jokaSystemFree(void* ptr, IStr file = __FILE__, Sz line = __LINE__) {
        static if (isTrackingMemory) {
            if (ptr == null) return;
            if (auto mallocValue = ptr in _memoryTrackingState.table) {
                stdlibc.free(ptr);
                debug {
                    _memoryTrackingState.totalBytes -= mallocValue.size;
                    _memoryTrackingState.table.remove(ptr);
                }
            } else {
                debug {
                    if (_memoryTrackingState.canIgnoreInvalidFree) {
                        _memoryTrackingState.invalidFreeTable ~= _MallocInfo(file, line, 0, false, _memoryTrackingState.currentGroupStack.length ? _memoryTrackingState.currentGroupStack[$ - 1] : "");
                    } else {
                        assert(0, "Invalid free.");
                    }
                }
            }
        } else {
            stdlibc.free(ptr);
        }
    }

    extern(C) nothrow @nogc
    void jokaAllocatorFree(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, IStr file, Sz line) {
        return jokaSystemFree(oldPtr, file, line);
    }

    extern(C) nothrow @nogc
    void jokaFree(void* ptr, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryState.allocatorMallocFunc == null) jokaRestoreDefaultAllocatorSetup(&__memoryState);
        __memoryState.allocatorFreeFunc(&__memoryState.allocatorState, 0, ptr, oldSize, file, line);
    }

    version (JokaNoTypes) {
        extern(C) nothrow @nogc pure
        void* jokaMemset(void* ptr, int value, Sz size) {
            return stringc.memset(ptr, value, size);
        }
        extern(C) nothrow @nogc pure
        void* jokaMemcpy(void* ptr, const(void)* source, Sz size) {
            return stringc.memcpy(ptr, source, size);
        }
    }
}

pragma(inline, true) @trusted @nogc
void jokaEnsureCapture(MemoryState* capture) {
    if (capture.allocatorMallocFunc != null) return;
    if (__memoryState.allocatorMallocFunc == null) jokaRestoreDefaultAllocatorSetup(&__memoryState);
    *capture = __memoryState;
}

@trusted @nogc
auto ignoreLeak(T)(T ptr) {
    static if (is(T : const(A)[], A)) {
        static if (isTrackingMemory) {
            if (auto mallocValue = ptr.ptr in _memoryTrackingState.table) {
                mallocValue.canIgnore = true;
            }
        }
        return ptr;
    } else static if (is(T : const(void)*)) {
        static if (isTrackingMemory) {
            if (auto mallocValue = ptr in _memoryTrackingState.table) {
                mallocValue.canIgnore = true;
            }
        }
        return ptr;
    } else static if (__traits(hasMember, T, "ignoreLeak")) {
        return ptr.ignoreLeak();
    } else {
        static assert(0, "Type doesn't implement the `ignoreLeak` function.");
    }
}

@trusted
void beginAllocationGroup(IStr group) {
    static if (isTrackingMemory) {
        _memoryTrackingState.currentGroupStack ~= group.idup;
    }
}

@trusted @nogc
void endAllocationGroup() {
    static if (isTrackingMemory) {
        if (_memoryTrackingState.currentGroupStack.length) _memoryTrackingState.currentGroupStack = _memoryTrackingState.currentGroupStack[0 .. $ - 1];
    }
}

@trusted
T* jokaMakeBlank(T)(IStr file = __FILE__, Sz line = __LINE__) {
    return cast(T*) jokaMalloc(T.sizeof, file, line);
}

@trusted
T* jokaMake(T)(IStr file = __FILE__, Sz line = __LINE__) {
    auto result = jokaMakeBlank!T(file, line);
    if (result) *result = T.init;
    return result;
}

@trusted
T* jokaMake(T)(const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = jokaMakeBlank!T(file, line);
    if (result) *result = cast(T) value;
    return result;
}

@trusted
T[] jokaMakeSliceBlank(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = (cast(T*) jokaMalloc(T.sizeof * length, file, line))[0 .. length];
    if (result.ptr) return result;
    return [];
}

@trusted
T[] jokaMakeSlice(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = jokaMakeSliceBlank!T(length, file, line);
    foreach (ref item; result) item = T.init;
    return result;
}

@trusted
T[] jokaMakeSlice(T)(Sz length, const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = jokaMakeSliceBlank!T(length, file, line);
    foreach (ref item; result) item = value;
    return result;
}

@trusted
T[] jokaMakeSlice(T)(const(T)[] values, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = jokaMakeSliceBlank!T(values.length, file, line);
    if (result.ptr) jokaMemcpy(result.ptr, values.ptr, T.sizeof * values.length);
    return result;
}

@trusted
T[] jokaResizeSlice(T)(T* values, Sz length, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = (cast(T*) jokaRealloc(values, T.sizeof * length, file, line))[0 .. length];
    if (result.ptr) return result;
    return [];
}

T jokaMakeJoint(T)(Sz[] lengths...) if (is(T == struct)) {
    enum commonAlignment = typeof(T.tupleof[0][0]).alignof;

    if (lengths.length != T.tupleof.length) assert(0, "Lengths count doesn't match member count.");
    auto result = T();

    auto totalBytes = cast(Sz) 0;
    static foreach (i, member; T.tupleof) {
        static assert(
            is(typeof(member) : const(M)[], M) || isBufferContainerType!(typeof(member)),
            "Member `" ~ member.stringof ~ "` must be a slice or a buffer list.",
        );
        totalBytes = (totalBytes + (typeof(member[0]).alignof - 1)) & ~(typeof(member[0]).alignof - 1);
        totalBytes += typeof(member[0]).sizeof * lengths[i];
    }

    auto memory = cast(ubyte*) jokaMalloc(totalBytes);
    if (memory == null) return result;
    jokaMemset(memory, 0, totalBytes);

    auto offset = cast(Sz) 0;
    static foreach (i, member; T.tupleof) {
        offset = (offset + (typeof(member[0]).alignof - 1)) & ~(typeof(member[0]).alignof - 1);
        static if (isBufferContainerType!(typeof(member))) {
            mixin("result.", member.stringof, "= BufferList!(member.Item)(  (cast(typeof(member[0])*) (memory + offset))[0 .. lengths[i]]  );");
        } else {
            mixin("result.", member.stringof, "= (cast(typeof(member[0])*) (memory + offset))[0 .. lengths[i]];");
        }
        offset += typeof(member[0]).sizeof * lengths[i];
    }
    return result;
}

/// Joint allocation test.
unittest {
    // First Jai example.
    static struct Vector2 { float x, y; }
    static struct Vector3 { float x, y, z; }
    static struct Mesh {
        char[] name;
        Vector3[] positions;
        int[] indices;
        Vector2[] uvs;

        nothrow:

        void* ptr() {
            return this.tupleof[0].ptr;
        }

        void free() {
            jokaFree(ptr);
            this = Mesh();
        }
    }

    auto mesh = jokaMakeJoint!Mesh(64, 24, 36, 24);

    assert(mesh.name.length == 64);
    assert(mesh.positions.length == 24);
    assert(mesh.indices.length == 36);
    assert(mesh.uvs.length == 24);

    assert(mesh.name[0] == '\0');
    assert(mesh.indices[0] == 0);
    mesh.free();

    // Second Jai example.
    static struct PartyMemberInfo {
        BStr className;
        BStr characterName;

        nothrow:

        void* ptr() {
            return this.tupleof[0].ptr;
        }

        void free() {
            jokaFree(ptr);
            this = PartyMemberInfo();
        }
    }
    static struct PartyMember {
        PartyMemberInfo info;
        int healthMax = 100;
        int currentLevel = 1;

        nothrow:

        void free() {
            info.free();
            this = PartyMember();
        }
    }

    auto partyMember = PartyMember(jokaMakeJoint!PartyMemberInfo(32, 64));

    assert(partyMember.info.characterName.length == 0);
    assert(partyMember.info.characterName.capacity == 64);
    assert(partyMember.info.characterName.append("Harold") == false);
    assert(partyMember.info.characterName[] == "Harold");

    assert(partyMember.info.className.length == 0);
    assert(partyMember.info.className.capacity == 32);
    assert(partyMember.info.className.append("Hero") == false);
    assert(partyMember.info.className[] == "Hero");
    partyMember.free();
}

// --- Containers

@safe nothrow:

enum defaultListCapacity = 16; /// The default list capacity. It is also the smallest list capacity.

alias LStr         = List!char;            /// A dynamic string of chars.
alias LStr16       = List!wchar;           /// A dynamic string of wchars.
alias LStr32       = List!dchar;           /// A dynamic string of dchars.
alias BStr         = BufferList!char;      /// A dynamic string of chars backed by external memory.
alias BStr16       = BufferList!wchar;     /// A dynamic string of wchars backed by external memory.
alias BStr32       = BufferList!dchar;     /// A dynamic string of dchars backed by external memory.
alias FStr(Sz N)   = FixedList!(char, N);  /// A dynamic string of chars allocated on the stack.
alias FStr16(Sz N) = FixedList!(wchar, N); /// A dynamic string of wchars allocated on the stack.
alias FStr32(Sz N) = FixedList!(dchar, N); /// A dynamic string of dchars allocated on the stack.

/// A dynamic array.
struct List(T) {
    alias Self = List!T;
    alias Item = T;
    alias Data = T[];

    // NOTE: I know this is slop code, but I don't care MONKEYYY! STOP MAKING ME FEEL BAD :(
    enum isBasicContainer = true;
    enum isBufferContainer = false;
    enum hasFixedCapacity = false;

    Data items;
    Sz capacity;
    bool canIgnoreLeak;
    MemoryState capture;

    @safe nothrow:

    mixin sliceOps!(Self, Item);

    pragma(inline, true) @trusted {
        this(ref MemoryState capture, const(T)[] args...) {
            this.capture = capture;
            append(args);
        }

        this(const(T)[] args...) {
            this(__memoryState, args);
        }

        @nogc
        Sz length() {
            return items.length;
        }

        @nogc
        T* ptr() {
            return items.ptr;
        }

        @nogc
        bool isEmpty() {
            return length == 0;
        }
    }

    @trusted
    bool appendBlank(IStr file = __FILE__, Sz line = __LINE__) {
        Sz newLength = length + 1;
        if (newLength > capacity) {
            jokaEnsureCapture(&capture);
            auto targetCapacity = findListCapacityFastAndAssumeOneAddedItemInLength(newLength, capacity);
            // NOTE/TODO: This part coult maybe be better with a helper function???
            auto rawPtr = capture.allocatorReallocFunc(capture.allocatorState, 0, items.ptr, capacity * T.sizeof, targetCapacity * T.sizeof, file, line);
            if (rawPtr == null) return true;
            static if (isTrackingMemory) {
                if (canIgnoreLeak) rawPtr.ignoreLeak();
            }
            capacity = targetCapacity;
            items = (cast(T*) rawPtr)[0 .. newLength];
        } else {
            items = items.ptr[0 .. newLength];
        }
        return false;
    }

    @trusted
    bool append(const(T)[] args...) {
        auto oldLength = length;
        if (resizeBlank(length + args.length)) return true;
        if (length != oldLength) jokaMemcpy(items.ptr + oldLength, args.ptr, args.length * T.sizeof);
        return false;
    }

    // NOTE: There is no good reason here for args having a default value, but I keep it for reference.
    @trusted
    bool appendSource(IStr file = __FILE__, Sz line = __LINE__, const(T)[] args = []...) {
        auto oldLength = length;
        if (resizeBlank(length + args.length, file, line)) return true;
        if (length != oldLength) jokaMemcpy(items.ptr + oldLength, args.ptr, args.length * T.sizeof);
        return false;
    }

    pragma(inline, true) @trusted
    bool push(const(T) arg, IStr file = __FILE__, Sz line = __LINE__) {
        if (appendBlank(file, line)) return true;
        items.ptr[items.length - 1] = cast(T) arg;
        return false;
    }

    pragma(inline, true) @trusted @nogc
    void remove(Sz i) {
        items[i] = items.ptr[items.length - 1];
        items = items.ptr[0 .. items.length - 1];
    }

    @nogc
    void removeShift(Sz i) {
        foreach (j; i .. length - 1) items[j] = items[j + 1];
        items = items[0 .. $ - 1];
    }

    @trusted @nogc
    void pop() {
        if (length) items = items.ptr[0 .. items.length - 1];
    }

    @nogc
    void popFront() {
        if (length) removeShift(0);
    }

    @trusted
    bool reserve(Sz newCapacity, IStr file = __FILE__, Sz line = __LINE__) {
        auto targetCapacity = findListCapacity(newCapacity, capacity);
        if (targetCapacity > capacity) {
            jokaEnsureCapture(&capture);
            auto rawPtr = capture.allocatorReallocFunc(capture.allocatorState, 0, items.ptr, capacity * T.sizeof, targetCapacity * T.sizeof, file, line);
            if (rawPtr == null) return true;
            static if (isTrackingMemory) {
                if (canIgnoreLeak) rawPtr.ignoreLeak();
            }
            capacity = targetCapacity;
            items = (cast(T*) rawPtr)[0 .. length];
        }
        return false;
    }

    @trusted
    bool resizeBlank(Sz newLength, IStr file = __FILE__, Sz line = __LINE__) {
        if (newLength <= length) {
            items = items[0 .. newLength];
        } else {
            if (reserve(newLength, file, line)) return true;
            items = items.ptr[0 .. newLength];
        }
        return false;
    }

    bool resize(Sz newLength, IStr file = __FILE__, Sz line = __LINE__) {
        auto oldLength = length;
        if (resizeBlank(newLength, file, line)) return true;
        if (length > oldLength) {
            foreach (i; 0 .. length - oldLength) items[$ - i - 1] = T.init;
        }
        return false;
    }

    @trusted @nogc
    void fill(const(T) value) {
        foreach (ref item; items) item = cast(T) value;
    }

    @nogc
    void clear() {
        items = items[0 .. 0];
    }

    @trusted @nogc
    void free(IStr file = __FILE__, Sz line = __LINE__) {
        capture.allocatorFreeFunc(capture.allocatorState, 0, items.ptr, capacity * T.sizeof, file, line);
        items = null;
        capacity = 0;
        canIgnoreLeak = false;
    }

    @nogc
    void ignoreLeak() {
        canIgnoreLeak = true;
        items.ignoreLeak();
    }

    @nogc
    IStr toStr() {
        static if (is(T == char)) { // isCharType
            return items;
        } else {
            assert(0, "Cannot call `toStr` on `List!T` when `T` is not a `char`.");
        }
    }
}

/// A dynamic array that uses external memory provided at runtime.
// The API is almost 1-1 with `List` to make meta programming easier.
struct BufferList(T) {
    alias Self = BufferList!T;
    alias Item = T;
    alias Data = T[];

    enum isBasicContainer = true;
    enum isBufferContainer = true;
    enum hasFixedCapacity = true;

    Data data;
    Sz length;

    bool growCapacity(C)(ref C arena) {
        return resizeCapacity(arena, findListCapacityFastAndAssumeOneAddedItemInLength(data.length + 1, data.length));
    }

    @trusted
    bool resizeCapacity(C)(ref C arena, Sz newCapacity) {
        auto newData = arena.resizeSlice(data.ptr, data.length, newCapacity);
        if (newData.ptr) {
            data = newData;
            if (length > newData.length) length = newData.length;
            return false;
        }
        return true;
    }

    @trusted nothrow @nogc
    bool resizeCapacity(T[] newRawPureData) {
        if (newRawPureData.ptr) {
            if (data.length <= newRawPureData.length) {
                jokaMemcpy(newRawPureData.ptr, data.ptr, T.sizeof * data.length);
            } else {
                jokaMemcpy(newRawPureData.ptr, data.ptr, T.sizeof * newRawPureData.length);
            }
            data = newRawPureData;
            if (length > newRawPureData.length) length = newRawPureData.length;
            return false;
        }
        return true;
    }

    @safe nothrow @nogc:

    mixin sliceOps!(Self, Item);

    pragma(inline, true) @trusted {
        this(T[] data, const(T)[] args...) {
            this.data = data;
            append(args);
        }

        T[] items() {
            return data.ptr[0 .. length];
        }

        T* ptr() {
            return data.ptr;
        }

        bool isEmpty() {
            return length == 0;
        }

        Sz capacity() {
            return data.length;
        }
    }

    @trusted
    bool appendBlank(IStr file = __FILE__, Sz line = __LINE__) {
        if (length >= capacity) return true;
        length += 1;
        return false;
    }

    @trusted
    bool append(const(T)[] args...) {
        auto oldLength = length;
        resizeBlank(length + args.length);
        if (length == oldLength) return true;
        jokaMemcpy(ptr + oldLength, args.ptr, args.length * T.sizeof);
        return false;
    }

    @trusted
    bool appendSource(IStr file = __FILE__, Sz line = __LINE__, const(T)[] args = []...) {
        return append(args);
    }

    pragma(inline, true) @trusted
    bool push(const(T) arg, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = appendBlank(file, line);
        if (!result) data.ptr[length - 1] = cast(T) arg;
        return result;
    }

    pragma(inline, true) @trusted
    void remove(Sz i) {
        items[i] = items.ptr[items.length - 1];
        length -= 1;
    }

    void removeShift(Sz i) {
        foreach (j; i .. items.length - 1) items[j] = items[j + 1];
        length -= 1;
    }

    void pop() {
        if (length) length -= 1;
    }

    void popFront() {
        if (length) removeShift(0);
    }

    void reserve(Sz newCapacity, IStr file = __FILE__, Sz line = __LINE__) {}

    void resizeBlank(Sz newLength, IStr file = __FILE__, Sz line = __LINE__) {
        length = newLength > capacity ? capacity : newLength;
    }

    void resize(Sz newLength, IStr file = __FILE__, Sz line = __LINE__) {
        auto oldLength = length;
        resizeBlank(newLength);
        if (length > oldLength) {
            foreach (i; 0 .. length - oldLength) items[$ - i - 1] = T.init;
        }
    }

    @trusted
    void fill(const(T) value) {
        foreach (ref item; items) item = cast(T) value;
    }

    void clear() {
        length = 0;
    }

    void free(IStr file = __FILE__, Sz line = __LINE__) {}
    void ignoreLeak() {}

    IStr toStr() {
        static if (is(T == char)) { // isCharType
            return items;
        } else {
            assert(0, "Cannot call `toStr` on `List!T` when `T` is not a `char`.");
        }
    }
}

/// A dynamic array allocated on the stack.
// This is just a copy-paste of `BufferList`, but with a static array.
//   Could make both use one type, but I think it's OK to repeat code here.
//   Keeps things simple and easy to read.
struct FixedList(T, Sz N) {
    alias Self = FixedList!(T, N);
    alias Item = T;
    alias Data = StaticArray!(T, N);

    enum isBasicContainer = true;
    enum isBufferContainer = false;
    enum hasFixedCapacity = true;

    Data data = void;
    Sz length;

    @safe nothrow @nogc:

    mixin sliceOps!(Self, Item);

    pragma(inline, true) @trusted {
        this(const(T)[] args...) {
            append(args);
        }

        T[] items() {
            return data.ptr[0 .. length];
        }

        T* ptr() {
            return data.ptr;
        }

        bool isEmpty() {
            return length == 0;
        }

        enum capacity = N;
    }

    @trusted
    bool appendBlank(IStr file = __FILE__, Sz line = __LINE__) {
        if (length >= capacity) return true;
        length += 1;
        return false;
    }

    @trusted
    bool append(const(T)[] args...) {
        auto oldLength = length;
        resizeBlank(length + args.length);
        if (length == oldLength) return true;
        jokaMemcpy(ptr + oldLength, args.ptr, args.length * T.sizeof);
        return false;
    }

    @trusted
    bool appendSource(IStr file = __FILE__, Sz line = __LINE__, const(T)[] args = []...) {
        return append(args);
    }

    pragma(inline, true) @trusted
    bool push(const(T) arg, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = appendBlank(file, line);
        if (!result) data.ptr[length - 1] = cast(T) arg;
        return result;
    }

    pragma(inline, true) @trusted
    void remove(Sz i) {
        items[i] = items.ptr[items.length - 1];
        length -= 1;
    }

    void removeShift(Sz i) {
        foreach (j; i .. items.length - 1) items[j] = items[j + 1];
        length -= 1;
    }

    void pop() {
        if (length) length -= 1;
    }

    void popFront() {
        if (length) removeShift(0);
    }

    void reserve(Sz newCapacity, IStr file = __FILE__, Sz line = __LINE__) {}

    void resizeBlank(Sz newLength, IStr file = __FILE__, Sz line = __LINE__) {
        length = newLength > capacity ? capacity : newLength;
    }

    void resize(Sz newLength, IStr file = __FILE__, Sz line = __LINE__) {
        auto oldLength = length;
        resizeBlank(newLength);
        if (length > oldLength) {
            foreach (i; 0 .. length - oldLength) items[$ - i - 1] = T.init;
        }
    }

    @trusted
    void fill(const(T) value) {
        foreach (ref item; items) item = cast(T) value;
    }

    void clear() {
        length = 0;
    }

    void free(IStr file = __FILE__, Sz line = __LINE__) {}
    void ignoreLeak() {}

    IStr toStr() {
        static if (is(T == char)) { // isCharType
            return items;
        } else {
            assert(0, "Cannot call `toStr` on `List!T` when `T` is not a `char`.");
        }
    }
}

/// An item of a sparse array.
struct SparseListItem(T) {
    alias Item = T;

    Item value;
    bool flag;
}

/// A dynamic sparse array.
struct SparseList(T, D = List!(SparseListItem!T)) if (isSparseContainerPartsValid!(T, D)) {
    alias Self = SparseList!(T, D);
    alias Item = D.Item;
    alias Data = D;

    enum isBasicContainer = false;
    enum isBufferContainer = false;
    enum hasFixedCapacity = D.hasFixedCapacity;
    enum isSparseContainer = true;

    Data data;
    Sz hotIndex;
    Sz openIndex;
    Sz length;

    @safe nothrow:

    this(const(T)[] args...) {
        append(args);
    }

    @trusted @nogc
    ref T opIndex(Sz i) {
        if (!has(i)) assert(0, indexErrorMessage(i));
        return data[i].value;
    }

    @trusted @nogc
    void opIndexAssign(const(T) rhs, Sz i) {
        if (!has(i)) assert(0, indexErrorMessage(i));
        data[i].value = cast(T) rhs;
    }

    @trusted @nogc
    void opIndexOpAssign(IStr op)(const(T) rhs, Sz i) {
        if (!has(i)) assert(0, indexErrorMessage(i));
        mixin("data[i].value", op, "= cast(T) rhs;");
    }

    @nogc
    Sz capacity() {
        return data.capacity;
    }

    @trusted @nogc
    Item* ptr() {
        return data.ptr;
    }

    @nogc
    bool isEmpty() {
        return length == 0;
    }

    @nogc
    bool has(Sz i) {
        return i < data.length && data[i].flag;
    }

    @nogc
    ref T hotItem() {
        return opIndex(hotIndex);
    }

    @trusted
    bool append(const(T)[] args...) {
        foreach (arg; args) {
            if (openIndex == data.length) {
                auto result = data.push(Item(cast(T) arg, true));
                if (result) return true;
                hotIndex = openIndex;
                openIndex = data.length;
                length += 1;
            } else {
                auto isFull = true;
                foreach (i; openIndex .. data.length) {
                    if (!data[i].flag) {
                        data[i] = Item(cast(T) arg, true);
                        hotIndex = i;
                        openIndex = i;
                        isFull = false;
                        break;
                    }
                }
                if (isFull) {
                    auto result = data.push(Item(cast(T) arg, true));
                    if (result) return true;
                    hotIndex = data.length - 1;
                    openIndex = data.length;
                }
                length += 1;
            }
        }
        return false;
    }

    @trusted
    bool appendSource(IStr file = __FILE__, Sz line = __LINE__, const(T)[] args = []...) {
        foreach (arg; args) {
            if (openIndex == data.length) {
                auto result = data.push(Item(cast(T) arg, true), file, line);
                if (result) return true;
                hotIndex = openIndex;
                openIndex = data.length;
                length += 1;
            } else {
                auto isFull = true;
                foreach (i; openIndex .. data.length) {
                    if (!data[i].flag) {
                        data[i] = Item(cast(T) arg, true);
                        hotIndex = i;
                        openIndex = i;
                        isFull = false;
                        break;
                    }
                }
                if (isFull) {
                    auto result = data.push(Item(cast(T) arg, true), file, line);
                    if (result) return true;
                    hotIndex = data.length - 1;
                    openIndex = data.length;
                }
                length += 1;
            }
        }
        return false;
    }

    @trusted
    bool push(const(T) arg, IStr file = __FILE__, Sz line = __LINE__) {
        return appendSource(file, line, arg);
    }

    @nogc
    void remove(Sz i) {
        if (!has(i)) assert(0, indexErrorMessage(i));
        data[i].flag = false;
        hotIndex = i;
        if (i < openIndex) openIndex = i;
        length -= 1;
    }

    void reserve(Sz capacity, IStr file = __FILE__, Sz line = __LINE__) {
        data.reserve(capacity, file, line);
    }

    @nogc
    void clear() {
        data.clear();
        hotIndex = 0;
        openIndex = 0;
        length = 0;
    }

    @nogc
    void free(IStr file = __FILE__, Sz line = __LINE__) {
        data.free(file, line);
        hotIndex = 0;
        openIndex = 0;
        length = 0;
    }

    @nogc
    void ignoreLeak() {
        data.ignoreLeak();
    }

    @nogc
    auto ids() {
        static struct Range {
            Item[] items;
            Sz id;

            bool empty() {
                return id == items.length;
            }

            Sz front() {
                return id;
            }

            void popFront() {
                id += 1;
                while (id != items.length && !items[id].flag) id += 1;
            }
        }

        Sz id = 0;
        while (id < data.length && !data[id].flag) id += 1;
        return Range(data.items, id);
    }

    @nogc
    auto items() {
        static struct Range {
            Item[] items;
            Sz id;

            bool empty() {
                return id == items.length;
            }

            ref T front() {
                return items[id].value;
            }

            void popFront() {
                id += 1;
                while (id != items.length && !items[id].flag) id += 1;
            }
        }

        Sz id = 0;
        while (id < data.length && !data[id].flag) id += 1;
        return Range(data.items, id);
    }
}

alias Gen = int;

struct GenIndex {
    Gen value;
    Gen generation;

    pragma(inline, true) @safe nothrow @nogc pure:

    bool isNone() {
        return value < 0;
    }

    bool isSome() {
        return value >= 0;
    }
}

struct GenList(T, D = SparseList!T, G = List!Gen) if (isSparseContainerComboValid!(T, D) && isBasicContainerType!G) {
    alias Self = GenList!(T, D);
    alias Item = D.Item;
    alias Data = D;
    alias DataGen = G;

    enum isBasicContainer = false;
    enum isBufferContainer = false;
    enum hasFixedCapacity = D.hasFixedCapacity && G.hasFixedCapacity;

    Data data;
    DataGen generations;

    @safe nothrow:

    @trusted @nogc
    ref T opIndex(GenIndex i) {
        if (!has(i)) assert(0, genIndexErrorMessage(i.value, i.generation));
        return data[i.value];
    }

    @trusted @nogc
    void opIndexAssign(const(T) rhs, GenIndex i) {
        if (!has(i)) assert(0, genIndexErrorMessage(i.value, i.generation));
        data[i.value] = cast(T) rhs;
    }

    @trusted @nogc
    void opIndexOpAssign(IStr op)(const(T) rhs, GenIndex i) {
        if (!has(i)) assert(0, genIndexErrorMessage(i.value, i.generation));
        mixin("data[i.value]", op, "= cast(T) rhs;");
    }

    @nogc
    Sz length() {
        return data.length;
    }

    @nogc
    Sz capacity() {
        return data.capacity;
    }

    @trusted @nogc
    Item* ptr() {
        return data.ptr;
    }

    @nogc
    bool isEmpty() {
        return length == 0;
    }

    @nogc
    bool has(GenIndex i) {
        return data.has(i.value) && generations[i.value] == i.generation;
    }

    GenIndex append(const(T) arg, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = data.push(arg, file, line);
        if (result) return GenIndex(-1, -1);
        generations.resize(data.data.length, file, line);
        return GenIndex(cast(Gen) data.hotIndex, generations[data.hotIndex]);
    }

    GenIndex push(const(T) arg, IStr file = __FILE__, Sz line = __LINE__) {
        return append(arg, file, line);
    }

    @nogc
    void remove(GenIndex i) {
        if (!has(i)) assert(0, genIndexErrorMessage(i.value, i.generation));
        data.remove(i.value);
        generations[data.hotIndex] += 1;
    }

    void reserve(Sz capacity, IStr file = __FILE__, Sz line = __LINE__) {
        data.reserve(capacity, file, line);
        generations.reserve(capacity, file, line);
    }

    @nogc
    void clear() {
        foreach (id; ids) remove(id);
    }

    @nogc
    void free(IStr file = __FILE__, Sz line = __LINE__) {
        data.free(file, line);
        generations.free(file, line);
    }

    @nogc
    void ignoreLeak() {
        data.ignoreLeak();
        generations.ignoreLeak();
    }

    @nogc
    auto ids() {
        static struct Range {
            Gen[] generations;
            Item[] items;
            Gen id;

            bool empty() {
                return id == items.length;
            }

            GenIndex front() {
                return GenIndex(id, generations[id]);
            }

            void popFront() {
                id += 1;
                while (id != items.length && !items[id].flag) id += 1;
            }
        }

        Gen id = 0;
        while (id < data.data.length && !data.data[id].flag) id += 1;
        return Range(generations.items, data.data.items, id);
    }

    @nogc
    auto items() {
        static struct Range {
            Gen[] generations;
            Item[] items;
            Gen id;

            bool empty() {
                return id == items.length;
            }

            ref T front() {
                return items[id].value;
            }

            void popFront() {
                id += 1;
                while (id != items.length && !items[id].flag) id += 1;
            }
        }

        Gen id = 0;
        while (id < data.data.length && !data.data[id].flag) id += 1;
        return Range(generations.items, data.data.items, id);
    }
}

struct Grid(T, D = List!T) if (isBasicContainerType!D) {
    alias Self = Grid!(T, D);
    alias Item = D.Item;
    alias Data = D;

    enum isBasicContainer = false;
    enum isBufferContainer = false;
    enum hasFixedCapacity = D.hasFixedCapacity;

    Data tiles;
    Sz rowCount;
    Sz colCount;

    @safe nothrow:

    this(Sz rowCount, Sz colCount, T value = T.init, IStr file = __FILE__, Sz line = __LINE__) {
        resizeBlank(rowCount, colCount, file, line);
        fill(value);
    }

    pragma(inline, true) @trusted nothrow @nogc {
        T[] opIndex() {
            return tiles[0 .. length];
        }

        ref T opIndex(Sz row, Sz col) {
            if (!has(row, col)) assert(0, gridIndexErrorMessage(row, col));
            return tiles[findGridIndex(row, col, colCount)];
        }

        void opIndexAssign(T rhs, Sz row, Sz col) {
            if (!has(row, col)) assert(0, gridIndexErrorMessage(row, col));
            tiles[findGridIndex(row, col, colCount)] = rhs;
        }

        void opIndexOpAssign(IStr op)(T rhs, Sz row, Sz col) {
            if (!has(row, col)) assert(0, gridIndexErrorMessage(row, col));
            mixin("tiles[findGridIndex(row, col, colCount)]", op, "= rhs;");
        }

        Sz opDollar(Sz dim)() {
            static if (dim == 0) {
                return rowCount;
            } else static if (dim == 1) {
                return colCount;
            } else {
                static assert(0, "WTF!");
            }
        }

        Sz length() {
            return tiles.length;
        }

        T* ptr() {
            return tiles.ptr;
        }

        Sz capacity() {
            return tiles.capacity;
        }

        bool has(Sz row, Sz col) {
            return row < rowCount && col < colCount;
        }

        bool isEmpty() {
            return tiles.isEmpty;
        }
    }

    void reserve(Sz newCapacity, IStr file = __FILE__, Sz line = __LINE__) {
        tiles.reserve(newCapacity, file, line);
    }

    void resizeBlank(Sz newRowCount, Sz newColCount, IStr file = __FILE__, Sz line = __LINE__) {
        tiles.resizeBlank(newRowCount * newColCount, file, line);
        rowCount = newRowCount;
        colCount = newColCount;
    }

    void resize(Sz newRowCount, Sz newColCount, IStr file = __FILE__, Sz line = __LINE__) {
        tiles.resizeBlank(newRowCount * newColCount, file, line);
        tiles.fill(T.init);
        rowCount = newRowCount;
        colCount = newColCount;
    }

    @trusted @nogc
    void fill(T value) {
        tiles.fill(value);
    }

    @nogc
    void clear() {
        tiles.clear();
        rowCount = 0;
        colCount = 0;
    }

    @trusted @nogc
    void free(IStr file = __FILE__, Sz line = __LINE__) {
        tiles.free(file, line);
        rowCount = 0;
        colCount = 0;
    }

    @nogc
    void ignoreLeak() {
        tiles.ignoreLeak();
    }
}

struct Arena {
    ubyte* data;
    Sz capacity;
    Sz offset;
    Sz checkpointOffset;
    // Extra data for users of this type.
    Arena* next;

    @trusted nothrow @nogc:

    this(ubyte* data, Sz capacity) {
        ready(data, capacity);
    }

    this(ubyte[] data) {
        ready(data);
    }

    void ready(ubyte* newData, Sz newCapacity) {
        data = newData;
        capacity = newCapacity;
        offset = 0;
        checkpointOffset = 0;
        next = null;
    }

    void ready(ubyte[] newData) {
        ready(newData.ptr, newData.length);
    }

    // NOTE: The file and line arguments are here for metraprogramming reasons. It keeps the API of arena types the same.

    void* malloc(Sz size, Sz alignment, IStr file = __FILE__, Sz line = __LINE__) {
        Sz alignedOffset = void;
        if (offset == 0) {
            auto ptr = cast(Sz) data;
            alignedOffset = ((ptr + (alignment - 1)) & ~(alignment - 1)) - ptr;
        } else {
            alignedOffset = (offset + (alignment - 1)) & ~(alignment - 1);
        }
        if (alignedOffset + size > capacity) return null;
        offset = alignedOffset + size;
        return cast(void*) (data + alignedOffset);
    }

    void* realloc(void* ptr, Sz oldSize, Sz newSize, Sz alignment, IStr file = __FILE__, Sz line = __LINE__) {
        if (ptr == null) return malloc(newSize, alignment);
        auto newPtr = malloc(newSize, alignment);
        if (newPtr == null) return null;
        if (oldSize <= newSize) {
            jokaMemcpy(newPtr, ptr, oldSize);
        } else {
            jokaMemcpy(newPtr, ptr, newSize);
        }
        return newPtr;
    }

    T* makeBlank(T)(IStr file = __FILE__, Sz line = __LINE__) {
        return cast(T*) malloc(T.sizeof, T.alignof);
    }

    T* make(T)(IStr file = __FILE__, Sz line = __LINE__) {
        auto result = makeBlank!T();
        if (result) *result = T.init;
        return result;
    }

    T* make(T)(const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = makeBlank!T();
        if (result) *result = cast(T) value;
        return result;
    }

    T[] makeSliceBlank(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = (cast(T*) malloc(T.sizeof * length, T.alignof))[0 .. length];
        if (result.ptr) return result;
        return [];
    }

    T[] makeSlice(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = makeSliceBlank!T(length);
        foreach (ref item; result) item = T.init;
        return result;
    }

    T[] makeSlice(T)(Sz length, const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = makeSliceBlank!T(length);
        foreach (ref item; result) item = value;
        return result;
    }

    T[] makeSlice(T)(const(T)[] values, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = makeSliceBlank!T(values.length);
        if (result.ptr) result.ptr.jokaMemcpy(values.ptr, T.sizeof * values.length);
        return result;
    }

    T[] resizeSlice(T)(T* values, Sz oldLength, Sz newLength, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = (cast(T*) realloc(values, T.sizeof * oldLength, T.sizeof * newLength, T.alignof))[0 .. newLength];
        if (result.ptr) return result;
        return [];
    }

    void checkpoint() {
        checkpointOffset = offset;
    }

    void rollback() {
        offset = checkpointOffset;
    }

    void rollback(Sz value) {
        offset = value;
    }

    void dropCheckpoint() {
        checkpointOffset = 0;
    }

    void clear() {
        offset = 0;
        checkpointOffset = 0;
    }

    void reset(IStr file = __FILE__, Sz line = __LINE__) {
        data = null;
        capacity = 0;
        offset = 0;
        checkpointOffset = 0;
    }
}

struct GrowingArena {
    Arena* head;
    Arena* current;
    Sz chunkCapacity;

    @trusted nothrow:

    this(Sz chunkCapacity, IStr file = __FILE__, Sz line = __LINE__) {
        ready(chunkCapacity, file, line);
    }

    void ready(Sz newChunkCapacity, IStr file = __FILE__, Sz line = __LINE__) {
        free();
        head = cast(Arena*) jokaSystemMalloc(Arena.sizeof, file, line);
        head.ready(cast(ubyte*) jokaSystemMalloc(newChunkCapacity, file, line), newChunkCapacity);
        current = head;
        chunkCapacity = newChunkCapacity;
    }

    void* malloc(Sz size, Sz alignment, IStr file = __FILE__, Sz line = __LINE__) {
        auto pp = current.malloc(size, alignment);
        if (pp == null) {
            auto chunk = cast(Arena*) null;
            if (current.next) {
                chunk = current.next;
            } else {
                chunk = cast(Arena*) jokaSystemMalloc(Arena.sizeof, file, line);
                chunk.ready(cast(ubyte*) jokaSystemMalloc(chunkCapacity, file, line), chunkCapacity);
                current.next = chunk;
                current = chunk;
            }
            pp = chunk.malloc(size, alignment);
        }
        return pp;
    }

    void* realloc(void* ptr, Sz oldSize, Sz newSize, Sz alignment, IStr file = __FILE__, Sz line = __LINE__) {
        auto pp = current.realloc(ptr, oldSize, newSize, alignment);
        if (pp == null) {
            auto chunk = cast(Arena*) null;
            if (current.next) {
                chunk = current.next;
            } else {
                chunk = cast(Arena*) jokaSystemMalloc(Arena.sizeof, file, line);
                chunk.ready(cast(ubyte*) jokaSystemMalloc(chunkCapacity, file, line), chunkCapacity);
                current.next = chunk;
                current = chunk;
            }
            pp = chunk.realloc(ptr, oldSize, newSize, alignment);
        }
        return pp;
    }

    T* makeBlank(T)(IStr file = __FILE__, Sz line = __LINE__) {
        return cast(T*) malloc(T.sizeof, T.alignof, file, line);
    }

    T* make(T)(IStr file = __FILE__, Sz line = __LINE__) {
        auto result = makeBlank!T(file, line);
        if (result) *result = T.init;
        return result;
    }

    T* make(T)(const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = makeBlank!T(file, line);
        if (result) *result = cast(T) value;
        return result;
    }

    T[] makeSliceBlank(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = (cast(T*) malloc(T.sizeof * length, T.alignof, file, line))[0 .. length];
        if (result.ptr) return result;
        return [];
    }

    T[] makeSlice(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = makeSliceBlank!T(length, file, line);
        foreach (ref item; result) item = T.init;
        return result;
    }

    T[] makeSlice(T)(Sz length, const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = makeSliceBlank!T(length, file, line);
        foreach (ref item; result) item = value;
        return result;
    }

    T[] makeSlice(T)(const(T)[] values, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = makeSliceBlank!T(values.length, file, line);
        if (result.ptr) result.ptr.jokaMemcpy(values.ptr, T.sizeof * values.length);
        return result;
    }

    T[] resizeSlice(T)(T* values, Sz oldLength, Sz newLength, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = (cast(T*) realloc(values, T.sizeof * oldLength, T.sizeof * newLength, T.alignof))[0 .. newLength];
        if (result.ptr) return result;
        return [];
    }

    @trusted nothrow @nogc:

    void clear() {
        auto chunk = head;
        while (chunk) {
            auto next = chunk.next;
            chunk.clear();
            chunk = next;
        }
        current = head;
    }

    void free(IStr file = __FILE__, Sz line = __LINE__) {
        auto chunk = head;
        while (chunk) {
            auto next = chunk.next;
            jokaSystemFree(chunk.data, file, line);
            jokaSystemFree(chunk, file, line);
            chunk = next;
        }
        head = null;
        current = null;
        chunkCapacity = 0;
    }
}

struct _ScopedArena(T) {
    T* _currentArena;
    Sz _currentArenaCheckpointOffset;

    @trusted nothrow:

    @nogc
    this(ref T data) {
        this._currentArena = &data;
        static if (is(T == Arena)) {
            this._currentArenaCheckpointOffset = data.offset;
        }
    }

    @nogc
    ~this() {
        static if (is(T == Arena)) {
            _currentArena.rollback(_currentArenaCheckpointOffset);
        } else {
            _currentArena.clear();
        }
    }

    void* malloc(Sz size, Sz alignment, IStr file = __FILE__, Sz line = __LINE__) {
        return _currentArena.malloc(size, alignment, file, line);
    }

    void* realloc(void* ptr, Sz oldSize, Sz newSize, Sz alignment, IStr file = __FILE__, Sz line = __LINE__) {
        return _currentArena.realloc(ptr, oldSize, newSize, alignment, file, line);
    }

    T* makeBlank(T)(IStr file = __FILE__, Sz line = __LINE__) {
        return _currentArena.makeBlank!T(file, line);
    }

    T* make(T)(IStr file = __FILE__, Sz line = __LINE__) {
        return _currentArena.make!T(file, line);
    }

    T* make(T)(const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
        return _currentArena.make!T(value, file, line);
    }

    T[] makeSliceBlank(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
        return _currentArena.makeSliceBlank!T(length, file, line);
    }

    T[] makeSlice(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
        return _currentArena.makeSlice!T(length, file, line);
    }

    T[] makeSlice(T)(Sz length, const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
        return _currentArena.makeSlice!T(length, value, file, line);
    }

    T[] resizeSlice(T)(T* values, Sz oldLength, Sz newLength, IStr file = __FILE__, Sz line = __LINE__) {
        return _currentArena.resizeSlice!T(values, oldLength, newLength, file, line);
    }
}

@trusted
_ScopedArena!T ScopedArena(T)(ref T arena) {
    return _ScopedArena!T(arena);
}

pragma(inline, true) @trusted @nogc {
    IStr indexErrorMessage(Sz i) {
        IStr[1] fmtStrs = [
            "Index {} does not exist.",
        ];
        return fmtSignedGroup(fmtStrs, i);
    }

    IStr gridIndexErrorMessage(Sz row, Sz col) {
        IStr[2] fmtStrs = [
            "Index {}",
            ", {} does not exist.",
        ];
        return fmtSignedGroup(fmtStrs, row, col);
    }

    IStr genIndexErrorMessage(Sz value, Sz generation) {
        IStr[2] fmtStrs = [
            "Index {} ",
            "with generation {} does not exist.",
        ];
        return fmtSignedGroup(fmtStrs, value, generation);
    }

    Sz findListCapacity(Sz length, Sz currentCapacity = 0) {
        Sz result = currentCapacity ? currentCapacity : defaultListCapacity;
        if (result + 1 == length) return result + result;
        while (result < length) result += result;
        return result;
    }

    Sz findListCapacityFastAndAssumeOneAddedItemInLength(Sz length, Sz currentCapacity = 0) {
        Sz result = currentCapacity ? currentCapacity : defaultListCapacity;
        return (result + 1 == length) ? result + result : result;
    }

    Sz findGridIndex(Sz row, Sz col, Sz colCount) {
        return colCount * row + col;
    }

    Sz findGridRow(Sz gridIndex, Sz colCount) {
        return gridIndex % colCount;
    }

    Sz findGridCol(Sz gridIndex, Sz colCount) {
        return gridIndex / colCount;
    }
}

/// Formats a string using a list and returns the resulting formatted string.
/// The list is cleared before writing.
/// For details on formatting behavior, see the `fmtIntoBufferWithStrs` function in the `ascii` module.
IStr fmtIntoList(bool canAppend = false, S = LStr, A...)(ref S list, IStr fmtStr, A args) {
    if (!canAppend) list.clear();
    IStr tempSlice;
    auto fmtStrIndex = 0;
    auto argIndex = 0;
    while (fmtStrIndex < fmtStr.length) {
        auto c1 = fmtStr[fmtStrIndex];
        auto c2 = fmtStrIndex + 1 >= fmtStr.length ? '+' : fmtStr[fmtStrIndex + 1];
        if (c1 == defaultAsciiFmtArgStr[0] && c2 == defaultAsciiFmtArgStr[1]) {
            if (argIndex == args.length) assert(0, "A placeholder doesn't have an argument.");
            foreach (i, arg; args) {
                if (i == argIndex) {
                    tempSlice = arg.toStr();
                    static if (S.hasFixedCapacity) {
                        if (list.capacity < list.length + tempSlice.length) return "";
                    }
                    list.append(tempSlice);
                    fmtStrIndex += 2;
                    argIndex += 1;
                    goto loopExit;
                }
            }
            loopExit:
        } else {
            list.append(c1);
            fmtStrIndex += 1;
        }
    }
    if (argIndex != args.length) assert(0, "An argument doesn't have a placeholder.");
    return list[];
}

IStr fmtIntoList(bool canAppend = false, S = LStr, A...)(ref S list, InterpolationHeader header, A args, InterpolationFooter footer) {
    // NOTE: Both `fmtStr` and `fmtArgs` can be copy-pasted when working with IES. Main copy is in the `fmt` function.
    enum fmtStr = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T) { result ~= args[i].toString(); }
            else static if (isInterExpType!T) { result ~= defaultAsciiFmtArgStr; }
        } return result;
    }();
    enum fmtArgs = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T || isInterExpType!T) {}
            else { result ~= "args[" ~ i.stringof ~ "],"; }
        } return result;
    }();
    return mixin("fmtIntoList!(canAppend, S)(list, fmtStr,", fmtArgs, ")");
}

void freeOnlyItems(T)(ref T container, IStr file = __FILE__, Sz line = __LINE__) {
    foreach (ref item; container.items) {
        static if (__traits(compiles, item.free(file, line))) {
            item.free(file, line);
        } else {
            item.free();
        }
    }
}

void freeWithItems(T)(ref T container, IStr file = __FILE__, Sz line = __LINE__) {
    container.freeOnlyItems(file, line);
    container.free(file, line);
}

bool isContainerType(T)() {
    return __traits(hasMember, T, "isBasicContainer");
}

bool isBasicContainerType(T)() {
    static if (__traits(hasMember, T, "isBasicContainer")) {
        return T.isBasicContainer;
    } else {
        return false;
    }
}

bool isBufferContainerType(T)() {
    static if (__traits(hasMember, T, "isBufferContainer")) {
        return T.isBufferContainer;
    } else {
        return false;
    }
}

bool isSparseContainerType(T)() {
    static if (__traits(hasMember, T, "isSparseContainer")) {
        return T.isSparseContainer;
    } else {
        return false;
    }
}

bool isSparseContainerItemType(T)() {
    return __traits(hasMember, T, "Item") && __traits(hasMember, T, "flag");
}

bool isSparseContainerPartsValid(T, D)() {
    static if (isBasicContainerType!D) {
        static if (isSparseContainerItemType!(D.Item)) {
            return is(T == D.Item.Item);
        } else {
            return false;
        }
    } else {
        return false;
    }
}

bool isSparseContainerComboValid(T, D)() {
    static if (isSparseContainerType!D) {
        static if (is(T == D.Item.Item)) {
            return true;
        } else {
            return false;
        }
    } else {
        return false;
    }
}

bool isLStrType(T)() {
    return is(T == List!char);
}

bool isBStrType(T)() {
    return is(T == BufferList!char);
}

bool isFStrType(T)() {
    return is(T == FixedList!(char, N), Sz N);
}

bool isStrContainerType(T)() {
    return isLStrType!T || isBStrType!T || isFStrType!T;
}

// Function test.
unittest {
    assert(findListCapacity(0) == defaultListCapacity);
    assert(findListCapacity(defaultListCapacity) == defaultListCapacity);
    assert(findListCapacity(defaultListCapacity + 1) == defaultListCapacity * 2);
    assert(findListCapacity(defaultListCapacity + 1) == defaultListCapacity * 2);

    assert(findListCapacityFastAndAssumeOneAddedItemInLength(0, 0) == 16);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(16, 0) == 16);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(17, 0) == 32);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(18, 0) == 16);

    assert(findListCapacityFastAndAssumeOneAddedItemInLength(0, 32) == 32);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(16, 32) == 32);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(17, 32) == 32);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(18, 32) == 32);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(32, 32) == 32);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(33, 32) == 64);
}

// TODO: Write better tests.
// List test.
unittest {
    LStr text;

    text = LStr();
    assert(text.length == 0);
    assert(text.capacity == 0);
    assert(text.ptr == null);

    text = LStr("abc");
    assert(text.length == 3);
    assert(text.capacity == defaultListCapacity);
    assert(text.ptr != null);
    text.free();
    assert(text.length == 0);
    assert(text.capacity == 0);
    assert(text.ptr == null);

    text = LStr("Hello world!");
    assert(text.length == "Hello world!".length);
    assert(text.capacity == defaultListCapacity);
    assert(text.ptr != null);
    assert(text[] == text.items);
    assert(text[0] == text.items[0]);
    assert(text[0 .. $] == text.items[0 .. $]);
    assert(text[0] == 'H');
    text[0] = 'h';
    text[0] += 1;
    text[0] -= 1;
    assert(text[0] == 'h');
    text.append("!!");
    assert(text[] == "hello world!!!");
    text.resize(0);
    assert(text[] == "");
    assert(text.length == 0);
    assert(text.capacity == defaultListCapacity);
    text.resize(1);
    assert(text[0] == char.init);
    assert(text.length == 1);
    assert(text.capacity == defaultListCapacity);
    text.clear();
    text.reserve(5);
    assert(text.length == 0);
    assert(text.capacity == defaultListCapacity);
    text.reserve(defaultListCapacity + 1);
    assert(text.length == 0);
    assert(text.capacity == defaultListCapacity * 2);

    version (JokaNoTypes) {
        // NOTE: YOU SHOULD NOT USE `fmtIntoList` WITH THIS VERSION!!!
    } else {
        assert(text.fmtIntoList("Hello {}!", "world") == "Hello world!");
        assert(text.fmtIntoList("({}, {})", -69, -420) == "(-69, -420)");
    }

    text.free();
}

// TODO: Write better tests.
// FixedList test.
unittest {
    FStr!64 text;

    text = FStr!64();
    assert(text.length == 0);
    text.resize(63);
    assert(text.length == 63);
    text.appendBlank();
    assert(text.length == 64);

    text = FStr!64("abc");
    assert(text.length == 3);
    text.clear();
    assert(text.length == 0);

    text = FStr!64("Hello world!");
    assert(text.length == "Hello world!".length);
    assert(text[] == text.items);
    assert(text[0] == text.items[0]);
    assert(text[0 .. $] == text.items[0 .. $]);
    assert(text[0] == 'H');
    text[0] = 'h';
    text[0] += 1;
    text[0] -= 1;
    assert(text[0] == 'h');
    text.append("!!");
    assert(text[] == "hello world!!!");
    text.resize(0);
    assert(text[] == "");
    assert(text.length == 0);
    text.resize(1);
    assert(text[0] == char.init);
    assert(text.length == 1);
    text.clear();

    auto text2 = FStr!4();
    text2.push('a');
    text2.push('b');
    text2.push('c');
    text2.push('d');
    assert(text2[] == "abcd");
    text2.append("AAA");
    assert(text2[] == "abcd");
}

// TODO: Write better tests.
// BufferList test.
@trusted
unittest {
    BStr text;
    char[64] buffer;

    text = BStr(buffer);
    assert(text.length == 0);
    text.resize(63);
    assert(text.length == 63);
    text.appendBlank();
    assert(text.length == 64);

    text = BStr(buffer, "abc");
    assert(text.length == 3);
    text.clear();
    assert(text.length == 0);

    text = BStr(buffer, "Hello world!");
    assert(text.length == "Hello world!".length);
    assert(text[] == text.items);
    assert(text[0] == text.items[0]);
    assert(text[0 .. $] == text.items[0 .. $]);
    assert(text[0] == 'H');
    text[0] = 'h';
    text[0] += 1;
    text[0] -= 1;
    assert(text[0] == 'h');
    text.append("!!");
    assert(text[] == "hello world!!!");
    text.resize(0);
    assert(text[] == "");
    assert(text.length == 0);
    text.resize(1);
    assert(text[0] == char.init);
    assert(text.length == 1);
    text.clear();

    auto text2 = BStr(buffer[0 .. 4]);
    text2.push('a');
    text2.push('b');
    text2.push('c');
    text2.push('d');
    assert(text2[] == "abcd");
    text2.append("AAA");
    assert(text2[] == "abcd");
}

// SparseList test.
unittest {
    SparseList!int numbers;

    numbers = SparseList!int();
    assert(numbers.length == 0);
    assert(numbers.capacity == 0);
    assert(numbers.ptr == null);
    assert(numbers.hotIndex == 0);
    assert(numbers.openIndex == 0);

    numbers = SparseList!int(1, 2, 3);
    assert(numbers.length == 3);
    assert(numbers.capacity == defaultListCapacity);
    assert(numbers.ptr != null);
    assert(numbers.hotIndex == 2);
    assert(numbers.openIndex == 3);
    assert(numbers[0] == 1);
    assert(numbers[1] == 2);
    assert(numbers[2] == 3);
    numbers[0] = 1;
    numbers[0] += 1;
    numbers[0] -= 1;
    assert(numbers.has(0) == true);
    assert(numbers.has(1) == true);
    assert(numbers.has(2) == true);
    assert(numbers.has(3) == false);
    numbers.remove(1);
    assert(numbers.has(0) == true);
    assert(numbers.has(1) == false);
    assert(numbers.has(2) == true);
    assert(numbers.has(3) == false);
    assert(numbers.hotIndex == 1);
    assert(numbers.openIndex == 1);
    numbers.append(1);
    assert(numbers.has(0) == true);
    assert(numbers.has(1) == true);
    assert(numbers.has(2) == true);
    assert(numbers.has(3) == false);
    assert(numbers.hotIndex == 1);
    assert(numbers.openIndex == 1);
    numbers.append(4);
    assert(numbers.has(0) == true);
    assert(numbers.has(1) == true);
    assert(numbers.has(2) == true);
    assert(numbers.has(3) == true);
    assert(numbers.hotIndex == 3);
    assert(numbers.openIndex == 4);
    numbers.clear();
    numbers.append(1);
    assert(numbers.has(0) == true);
    assert(numbers.has(1) == false);
    assert(numbers.has(2) == false);
    assert(numbers.has(3) == false);
    assert(numbers.hotIndex == 0);
    assert(numbers.openIndex == 1);
    numbers.free();
    assert(numbers.length == 0);
    assert(numbers.capacity == 0);
    assert(numbers.ptr == null);
    assert(numbers.hotIndex == 0);
    assert(numbers.openIndex == 0);

    numbers = SparseList!int(4, 5, 6, 7);
    numbers.remove(0);
    numbers.remove(2);
    auto ids = numbers.ids;
    assert(ids.empty == false);
    assert(ids.front == 1);
    ids.popFront();
    assert(ids.empty == false);
    assert(ids.front == 3);
    ids.popFront();
    assert(ids.empty == true);
    numbers.free();
}

// GenList test
unittest {
    GenList!int numbers;
    GenIndex index;

    numbers = GenList!int();
    assert(numbers.length == 0);
    assert(numbers.capacity == 0);
    assert(numbers.ptr == null);

    index = numbers.append(1);
    assert(numbers.length == 1);
    assert(numbers.capacity == defaultListCapacity);
    assert(numbers.ptr != null);
    assert(index.value == 0);
    assert(index.generation == 0);
    assert(numbers[index] == 1);

    index = numbers.append(2);
    assert(numbers.length == 2);
    assert(numbers.capacity == defaultListCapacity);
    assert(numbers.ptr != null);
    assert(index.value == 1);
    assert(index.generation == 0);
    assert(numbers[index] == 2);

    index = numbers.append(3);
    assert(numbers.length == 3);
    assert(numbers.capacity == defaultListCapacity);
    assert(numbers.ptr != null);
    assert(index.value == 2);
    assert(index.generation == 0);
    assert(numbers[index] == 3);

    numbers[GenIndex(0, 0)] = 1;
    numbers[GenIndex(0, 0)] += 1;
    numbers[GenIndex(0, 0)] -= 1;
    assert(numbers.has(GenIndex(1, 0)) == true);
    assert(numbers.has(GenIndex(2, 0)) == true);
    assert(numbers.has(GenIndex(3, 0)) == false);
    numbers.remove(GenIndex(1, 0));
    assert(numbers.has(GenIndex(0, 0)) == true);
    assert(numbers.has(GenIndex(1, 0)) == false);
    assert(numbers.has(GenIndex(2, 0)) == true);
    assert(numbers.has(GenIndex(3, 0)) == false);
    numbers.append(1);
    assert(numbers.has(GenIndex(0, 0)) == true);
    assert(numbers.has(GenIndex(1, 1)) == true);
    assert(numbers.has(GenIndex(2, 0)) == true);
    assert(numbers.has(GenIndex(3, 0)) == false);
    numbers.append(4);
    assert(numbers.has(GenIndex(0, 0)) == true);
    assert(numbers.has(GenIndex(1, 1)) == true);
    assert(numbers.has(GenIndex(2, 0)) == true);
    assert(numbers.has(GenIndex(3, 0)) == true);
    numbers.clear();
    numbers.append(1);
    assert(numbers.has(GenIndex(0, 1)) == true);
    assert(numbers.has(GenIndex(1, 0)) == false);
    assert(numbers.has(GenIndex(1, 1)) == false);
    assert(numbers.has(GenIndex(2, 0)) == false);
    assert(numbers.has(GenIndex(3, 0)) == false);
    numbers.free();
    assert(numbers.length == 0);
    assert(numbers.capacity == 0);
    assert(numbers.ptr == null);
}

// Grid test
unittest {
    Grid!int numbers;
    auto rowCount = 64;
    auto colCount = 64;
    auto capacity = rowCount * colCount;

    assert(numbers.length == 0);
    assert(numbers.capacity == 0);
    assert(numbers.ptr == null);
    assert(numbers.rowCount == 0);
    assert(numbers.colCount == 0);

    numbers = Grid!int(rowCount, colCount, -1);
    assert(numbers.length == capacity);
    assert(numbers.capacity == capacity);
    assert(numbers.ptr != null);
    assert(numbers.rowCount == rowCount);
    assert(numbers.colCount == colCount);
    assert(numbers[0, 0] == -1);
    assert(numbers[rowCount - 1, colCount - 1] == -1);
    numbers[0, 0] = 0;
    numbers[0, 0] += 1;
    numbers[0, 0] -= 1;
    assert(numbers.has(7, colCount) == false);
    assert(numbers.has(rowCount, 7) == false);
    assert(numbers.has(rowCount, colCount) == false);
    numbers.free();
    assert(numbers.length == 0);
    assert(numbers.capacity == 0);
    assert(numbers.ptr == null);
    assert(numbers.rowCount == 0);
    assert(numbers.colCount == 0);
}

// Arena test
@trusted
unittest {
    Arena arena;
    int* number;
    ubyte[512] buffer;

    arena = Arena(buffer);
    assert(arena.capacity == 512);
    assert(arena.offset == 0);
    assert(arena.data != null);
    number = arena.make(69);
    assert(*number == 69);
    number = arena.make(420);
    assert(*number == 420);
    arena.clear();
    assert(arena.offset == 0);
    assert(arena.data != null);
    assert(arena.malloc(512, 1) != null);
    assert(arena.malloc(512, 1) == null);
    arena.reset();
    assert(arena.capacity == 0);
    assert(arena.offset == 0);
    assert(arena.data == null);

    arena = Arena(buffer);
    with (ScopedArena(arena)) {
        make!char('C');
        with (ScopedArena(arena)) {
            make!short(2);
            make!char('D');
            assert(arena.offset == 5);
        }
        assert(arena.offset == 1);
    }
    assert(arena.offset == 0);
    arena.reset();

    arena = Arena(buffer);
    auto dynamicArray = BStr(arena.makeSlice!char(2));
    assert(dynamicArray.push('D') == false);
    assert(dynamicArray.push('D') == false);
    assert(dynamicArray.push('D') == true);
    if (dynamicArray.push('D')) {
        dynamicArray.growCapacity(arena);
    }
    assert(dynamicArray.push('D') == false);
    assert(dynamicArray.length == 3);
    assert(dynamicArray.capacity == 4);
    foreach (item; dynamicArray) assert(item == 'D');
}
