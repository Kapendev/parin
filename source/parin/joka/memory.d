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

import parin.joka.types;

// --- Core

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

@system nothrow:

version (JokaCustomMemory) {
    pragma(msg, "Joka: Using custom memory.");

    extern(C) @nogc void* jokaMemset(void* ptr, int value, Sz size);
    extern(C) @nogc void* jokaMemcpy(void* ptr, const(void)* source, Sz size);
    extern(C)       void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__);
    extern(C)       void* jokaRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__);
    extern(C) @nogc void  jokaFree(void* ptr, IStr file = __FILE__, Sz line = __LINE__);
} else version (JokaGcMemory) {
    pragma(msg, "Joka: Using GC memory.");

    import memoryd = core.memory;
    import stringc = core.stdc.string;

    extern(C) @nogc
    void* jokaMemset(void* ptr, int value, Sz size) {
        return stringc.memset(ptr, value, size);
    }

    extern(C) @nogc
    void* jokaMemcpy(void* ptr, const(void)* source, Sz size) {
        return stringc.memcpy(ptr, source, size);
    }

    extern(C)
    void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        return memoryd.GC.malloc(size);
    }

    extern(C)
    void* jokaRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        return memoryd.GC.realloc(ptr, size);
    }

    extern(C) @nogc
    void jokaFree(void* ptr, IStr file = __FILE__, Sz line = __LINE__) {}
} else {
    version(JokaPhobosStdc) {
        pragma(msg, "Joka: Using Phobos `stdc` modules.");
        import stringc = core.stdc.string;
        import stdlibc = core.stdc.stdlib;
    } else {
        import stringc = parin.joka.stdc;
        import stdlibc = parin.joka.stdc;
    }

    extern(C) @nogc
    void* jokaMemset(void* ptr, int value, Sz size) {
        return stringc.memset(ptr, value, size);
    }

    extern(C) @nogc
    void* jokaMemcpy(void* ptr, const(void)* source, Sz size) {
        return stringc.memcpy(ptr, source, size);
    }

    extern(C)
    void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = stdlibc.malloc(size);
        static if (isTrackingMemory) {
            if (result) {
                _memoryTrackingState.table[result] = _MallocInfo(file, line, size, false, _memoryTrackingState.currentGroupStack.length ? _memoryTrackingState.currentGroupStack[$ - 1] : "");
                _memoryTrackingState.totalBytes += size;
            }
        }
        return result;
    }

    extern(C)
    void* jokaRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__) {
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

    extern(C) @nogc
    void jokaFree(void* ptr, IStr file = __FILE__, Sz line = __LINE__) {
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
    enum isBasicContainer = true;
    enum hasFixedCapacity = false;

    Data items;
    Sz capacity;
    bool canIgnoreLeak;

    @safe nothrow:

    mixin sliceOps!(Self, Item);

    pragma(inline, true) @trusted {
        this(const(T)[] args...) {
            append(args);
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
            capacity = findListCapacityFastAndAssumeOneAddedItemInLength(newLength, capacity);
            auto rawPtr = jokaRealloc(items.ptr, capacity * T.sizeof, file, line);
            static if (isTrackingMemory) {
                if (canIgnoreLeak) rawPtr.ignoreLeak();
            }
            items = (cast(T*) rawPtr)[0 .. newLength];
        } else {
            items = items.ptr[0 .. newLength];
        }
        return false;
    }

    @trusted
    bool append(const(T)[] args...) {
        auto oldLength = length;
        resizeBlank(length + args.length);
        if (length != oldLength) jokaMemcpy(items.ptr + oldLength, args.ptr, args.length * T.sizeof);
        return false;
    }

    // NOTE: There is no good reason here for args having a default value, but I keep it for reference.
    @trusted
    bool appendSource(IStr file = __FILE__, Sz line = __LINE__, const(T)[] args = []...) {
        auto oldLength = length;
        resizeBlank(length + args.length, file, line);
        if (length != oldLength) jokaMemcpy(items.ptr + oldLength, args.ptr, args.length * T.sizeof);
        return false;
    }

    pragma(inline, true) @trusted
    bool push(const(T) arg, IStr file = __FILE__, Sz line = __LINE__) {
        appendBlank(file, line);
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

    pragma(inline, true) @trusted @nogc
    void drop() {
        if (length) items = items.ptr[0 .. items.length - 1];
    }

    @nogc
    void dropFront() {
        if (length) removeShift(0);
    }

    @nogc
    T pop() {
        if (length > 0) {
            T temp = items[$ - 1];
            items = items[0 .. $ - 1];
            return temp;
        } else {
            return T.init;
        }
    }

    @nogc
    T popFront() {
        if (length > 0) {
            T temp = items[0];
            removeShift(0);
            return temp;
        } else {
            return T.init;
        }
    }

    @trusted
    void reserve(Sz newCapacity, IStr file = __FILE__, Sz line = __LINE__) {
        auto targetCapacity = findListCapacity(newCapacity, capacity);
        if (targetCapacity > capacity) {
            capacity = targetCapacity;
            auto rawPtr = jokaRealloc(items.ptr, capacity * T.sizeof, file, line);
            static if (isTrackingMemory) {
                if (canIgnoreLeak) rawPtr.ignoreLeak();
            }
            items = (cast(T*) rawPtr)[0 .. length];
        }
    }

    @trusted
    void resizeBlank(Sz newLength, IStr file = __FILE__, Sz line = __LINE__) {
        if (newLength <= length) {
            items = items[0 .. newLength];
        } else {
            reserve(newLength, file, line);
            items = items.ptr[0 .. newLength];
        }
    }

    void resize(Sz newLength, IStr file = __FILE__, Sz line = __LINE__) {
        auto oldLength = length;
        resizeBlank(newLength, file, line);
        if (length > oldLength) {
            foreach (i; 0 .. length - oldLength) items[$ - i - 1] = T.init;
        }
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
        jokaFree(items.ptr, file, line);
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

    pragma(inline, true)
    void drop() {
        if (length) length -= 1;
    }

    void dropFront() {
        if (length) removeShift(0);
    }

    T pop() {
        if (length > 0) {
            T temp = items[$ - 1];
            length -= 1;
            return temp;
        } else {
            return T.init;
        }
    }

    T popFront() {
        if (length > 0) {
            T temp = items[0];
            removeShift(0);
            return temp;
        } else {
            return T.init;
        }
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

    pragma(inline, true)
    void drop() {
        if (length) length -= 1;
    }

    void dropFront() {
        if (length) removeShift(0);
    }

    T pop() {
        if (length > 0) {
            T temp = items[$ - 1];
            length -= 1;
            return temp;
        } else {
            return T.init;
        }
    }

    T popFront() {
        if (length > 0) {
            T temp = items[0];
            removeShift(0);
            return temp;
        } else {
            return T.init;
        }
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
    enum isSparseContainer = true;
    enum hasFixedCapacity = D.hasFixedCapacity;

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
    enum hasFixedCapacity = D.hasFixedCapacity;

    Data tiles;
    Sz rowCount;
    Sz colCount;

    @safe nothrow:

    this(Sz rowCount, Sz colCount, T value = T.init, IStr file = __FILE__, Sz line = __LINE__) {
        resizeBlank(rowCount, colCount, file, line);
        fill(value);
    }

    @trusted @nogc
    T[] opIndex() {
        return tiles[0 .. length];
    }

    @trusted @nogc
    ref T opIndex(Sz row, Sz col) {
        if (!has(row, col)) assert(0, gridIndexErrorMessage(row, col));
        return tiles[findGridIndex(row, col, colCount)];
    }

    @trusted @nogc
    void opIndexAssign(T rhs, Sz row, Sz col) {
        if (!has(row, col)) assert(0, gridIndexErrorMessage(row, col));
        tiles[findGridIndex(row, col, colCount)] = rhs;
    }

    @trusted @nogc
    void opIndexOpAssign(IStr op)(T rhs, Sz row, Sz col) {
        if (!has(row, col)) assert(0, gridIndexErrorMessage(row, col));
        mixin("tiles[colCount * row + col]", op, "= rhs;");
    }

    @nogc
    Sz opDollar(Sz dim)() {
        static if (dim == 0) {
            return rowCount;
        } else static if (dim == 1) {
            return colCount;
        } else {
            static assert(0, "WTF!");
        }
    }

    @nogc
    Sz length() {
        return tiles.length;
    }

    @trusted @nogc
    T* ptr() {
        return tiles.ptr;
    }

    @nogc
    Sz capacity() {
        return tiles.capacity;
    }

    @nogc
    bool isEmpty() {
        return tiles.isEmpty;
    }

    @nogc
    bool has(Sz row, Sz col) {
        return row < rowCount && col < colCount;
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
    bool isOwning;
    bool canIgnoreLeak;
    // Extra data for users of this type.
    Arena* next;

    @trusted nothrow:

    this(Sz capacity, IStr file = __FILE__, Sz line = __LINE__) {
        ready(capacity, file, line);
    }

    @nogc
    this(ubyte* data, Sz capacity) {
        ready(data, capacity);
    }

    @nogc
    this(ubyte[] data) {
        ready(data);
    }

    void ready(Sz newCapacity, IStr file = __FILE__, Sz line = __LINE__) {
        free();
        auto rawPtr = jokaMalloc(newCapacity, file, line);
        static if (isTrackingMemory) {
            if (canIgnoreLeak) rawPtr.ignoreLeak();
        }
        data = cast(ubyte*) rawPtr;
        capacity = newCapacity;
        isOwning = true;
    }

    @trusted nothrow @nogc:

    void ready(ubyte* newData, Sz newCapacity) {
        free();
        data = newData;
        capacity = newCapacity;
    }

    void ready(ubyte[] newData) {
        ready(newData.ptr, newData.length);
    }

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

    void free(IStr file = __FILE__, Sz line = __LINE__) {
        if (isOwning) jokaFree(data, file, line);
        data = null;
        capacity = 0;
        clear();
        isOwning = false;
        canIgnoreLeak = false;
    }

    Arena ignoreLeak() {
        canIgnoreLeak = true;
        data.ignoreLeak();
        return this;
    }
}

struct GrowingArena {
    Arena* head;
    Arena* current;
    Sz chunkCapacity;
    bool canIgnoreLeak;

    @trusted nothrow:

    this(Sz chunkCapacity, Sz chunkCount = 1, IStr file = __FILE__, Sz line = __LINE__) {
        ready(chunkCapacity, chunkCount, file, line);
    }

    void ready(Sz newChunkCapacity, Sz newChunkCount = 1, IStr file = __FILE__, Sz line = __LINE__) {
        free();
        head = jokaMake(Arena(newChunkCapacity, file, line), file, line);
        static if (isTrackingMemory) {
            // To be, or not to be, that is the question.
            if (canIgnoreLeak) {
                .ignoreLeak(head);
                head.ignoreLeak();
            }
        }
        current = head;
        chunkCapacity = newChunkCapacity;
        auto chunk = head;
        foreach (i; 1 .. newChunkCount) {
            chunk.next = jokaMake(Arena(newChunkCapacity, file, line), file, line);
            static if (isTrackingMemory) {
                if (canIgnoreLeak) {
                    .ignoreLeak(chunk.next);
                    chunk.next.ignoreLeak();
                }
            }
            chunk = chunk.next;
        }
    }

    void* malloc(Sz size, Sz alignment, IStr file = __FILE__, Sz line = __LINE__) {
        void* p = current.malloc(size, alignment);
        if (p == null) {
            auto chunk = current.next ? current.next : jokaMake(Arena(size > chunkCapacity ? size : chunkCapacity, file, line), file, line);
            static if (isTrackingMemory) {
                if (current.next == null && canIgnoreLeak) {
                    .ignoreLeak(chunk);
                    chunk.ignoreLeak();
                }
            }
            p = chunk.malloc(size, alignment);
            current.next = chunk;
            current = chunk;
        }
        return p;
    }

    void* realloc(void* ptr, Sz oldSize, Sz newSize, Sz alignment, IStr file = __FILE__, Sz line = __LINE__) {
        void* p = current.realloc(ptr, oldSize, newSize, alignment);
        if (p == null) {
            auto chunk = current.next ? current.next : jokaMake(Arena(newSize > chunkCapacity ? newSize : chunkCapacity, file, line), file, line);
            static if (isTrackingMemory) {
                if (current.next == null && canIgnoreLeak) {
                    .ignoreLeak(chunk);
                    chunk.ignoreLeak();
                }
            }
            p = chunk.realloc(ptr, oldSize, newSize, alignment);
            current.next = chunk;
            current = chunk;
        }
        return p;
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
            chunk.clear();
            chunk = chunk.next;
        }
        current = head;
    }

    void free(IStr file = __FILE__, Sz line = __LINE__) {
        auto chunk = head;
        while (chunk) {
            chunk.free(file, line);
            jokaFree(chunk, file, line);
            chunk = chunk.next;
        }
        head = null;
        current = null;
        chunkCapacity = 0;
        canIgnoreLeak = false;
    }

    GrowingArena ignoreLeak() {
        canIgnoreLeak = true;
        auto chunk = head;
        while (chunk) {
            .ignoreLeak(chunk);
            chunk.ignoreLeak();
        }
        return this;
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

bool isSparseContainerType(T)() {
    static if (__traits(hasMember, T, "isBasicContainer")) {
        return !T.isBasicContainer && __traits(hasMember, T, "isSparseContainer");
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
    assert(text.pop() == '!');
    assert(text.pop() == '!');
    assert(text[] == "hello world!");
    text.resize(0);
    assert(text[] == "");
    assert(text.length == 0);
    assert(text.capacity == defaultListCapacity);
    assert(text.pop() == char.init);
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
    assert(text.fmtIntoList("Hello {}!", "world") == "Hello world!");
    assert(text.fmtIntoList("({}, {})", -69, -420) == "(-69, -420)");
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
    assert(text.pop() == '!');
    assert(text.pop() == '!');
    assert(text[] == "hello world!");
    text.resize(0);
    assert(text[] == "");
    assert(text.length == 0);
    assert(text.pop() == char.init);
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
    assert(text.pop() == '!');
    assert(text.pop() == '!');
    assert(text[] == "hello world!");
    text.resize(0);
    assert(text[] == "");
    assert(text.length == 0);
    assert(text.pop() == char.init);
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

    arena = Arena(512);
    assert(arena.isOwning == true);
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
    arena.free();
    assert(arena.capacity == 0);
    assert(arena.offset == 0);
    assert(arena.data == null);
    assert(arena.isOwning == false);

    arena = Arena(buffer);
    assert(arena.isOwning == false);
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
    arena.free();
    assert(arena.capacity == 0);
    assert(arena.offset == 0);
    assert(arena.data == null);
    assert(arena.isOwning == false);

    arena = Arena(512);
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
    arena.free();

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
