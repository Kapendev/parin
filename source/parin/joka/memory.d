// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `memory` module provides functions for dealing with memory and various general-purpose containers.
/// `List`, `BufferList`, and `FixedList` are the "basic" containers.
/// Most other containers can accept one of those to adjust their allocation strategy.

module parin.joka.memory;

import parin.joka.types;

// --- Core

MemoryContext __memoryContext;
enum defaultJokaMemoryAlignment = 16;

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

        _MemoryTrackingState _memoryTrackingState;
    }
} else {
    enum isTrackingMemory = false;
}

struct AllocationGroup {
    IStr _currentAllocationGroup;

    @safe nothrow:
    @disable this();

    this(IStr group) {
        this._currentAllocationGroup = group;
        beginAllocationGroup(group);
    }

    @nogc
    ~this() {
        endAllocationGroup();
    }
}

struct MemoryContext {
    void* allocatorState;
    AllocatorReallocFunc reallocFunc; // NOTE: If this is null, then the default allocator setup should be used.
    AllocatorFreeFunc freeFunc;       // NOTE: This can be null for things like arenas.

    // NOTE: The functions here are just helpers that pass the allocator state.
    //  They avoid `void*` mistakes.
    //  Could have more helpers, but it's better to keep things simple.
    //  The `nullAllocatorReallocWrapper` and `nullAllocatorFreeWrapper` can be used to ignore allocations.

    pragma(inline, true) @system nothrow:

    void* malloc(Sz alignment, Sz size, IStr file, Sz line) {
        return reallocFunc(allocatorState, alignment, null, 0, size, file, line);
    }

    void* realloc(Sz alignment, void* oldPtr, Sz oldSize, Sz newSize, IStr file, Sz line) {
        return reallocFunc(allocatorState, alignment, oldPtr, oldSize, newSize, file, line);
    }

    @nogc
    void free(Sz alignment, void* oldPtr, Sz oldSize, IStr file, Sz line) {
        freeFunc(allocatorState, alignment, oldPtr, oldSize, file, line);
    }
}

nothrow {
    alias AllocatorMallocFunc  = void* function(void* allocatorState, Sz alignment, Sz size, IStr file, Sz line);
    alias AllocatorReallocFunc = void* function(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, Sz newSize, IStr file, Sz line);
}

nothrow @nogc {
    alias AllocatorFreeFunc = void function(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, IStr file, Sz line);
}

struct ScopedMemoryContext {
    MemoryContext _previousMemoryContext;

    pragma(inline, true) @safe nothrow @nogc:
    @disable this();

    this(MemoryContext newContext) {
        this._previousMemoryContext = __memoryContext;
        __memoryContext = newContext;
    }

    this(ref Arena arena) {
        this(arena.toMemoryContext());
    }

    this(ref GrowingArena arena) {
        this(arena.toMemoryContext());
    }

    ~this() {
        __memoryContext = _previousMemoryContext;
    }
}

@safe nothrow @nogc
ScopedMemoryContext ScopedDefaultMemoryContext() {
    auto context = MemoryContext();
    jokaRestoreDefaultAllocatorSetup(context);
    return ScopedMemoryContext(context);
}

// NOTE: Memory allocation related things are here.
@system nothrow { // BEGIN: MEMORY(@systen nothrow)
version (JokaCustomMemory) {
    extern(C) nothrow       void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__);
    extern(C) nothrow       void* jokaRealloc(void* ptr, Sz size, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__);
    extern(C) nothrow @nogc void  jokaFree(void* ptr, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__);

    void* jokaSystemMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        // NOTE: You should not call `jokaMalloc` from `system*`, but it's fine because there is no global memory context.
        return jokaMalloc(size, file, line);
    }

    void* jokaAllocatorMalloc(void* allocatorState, Sz alignment, Sz size, IStr file, Sz line) {
        return jokaSystemMalloc(size, file, line);
    }

    void* jokaSystemRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        return jokaRealloc(ptr, size, 0, file, line);
    }

    void* jokaAllocatorRealloc(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, Sz newSize, IStr file, Sz line) {
        return jokaSystemRealloc(oldPtr, newSize, file, line);
    }

    @nogc
    void jokaSystemFree(void* ptr, IStr file = __FILE__, Sz line = __LINE__) {
        jokaFree(ptr, 0, file, line);
    }

    @nogc
    void jokaAllocatorFree(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, IStr file, Sz line) {
        return jokaSystemFree(oldPtr, file, line);
    }
} else version (JokaGcMemory) {
    import memoryd = core.memory;
    import stringc = core.stdc.string;

    void* jokaSystemMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        return memoryd.GC.malloc(size);
    }

    void* jokaAllocatorMalloc(void* allocatorState, Sz alignment, Sz size, IStr file, Sz line) {
        return jokaSystemMalloc(size, file, line);
    }

    void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryContext.reallocFunc == null) jokaRestoreDefaultAllocatorSetup(__memoryContext);
        return __memoryContext.malloc(0, size, file, line);
    }

    void* jokaSystemRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        if (size == 0) return null;
        return memoryd.GC.realloc(ptr, size);
    }

    void* jokaAllocatorRealloc(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, Sz newSize, IStr file, Sz line) {
        return jokaSystemRealloc(oldPtr, newSize, file, line);
    }

    void* jokaRealloc(void* ptr, Sz size, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryContext.reallocFunc == null) jokaRestoreDefaultAllocatorSetup(__memoryContext);
        return __memoryContext.realloc(0, ptr, oldSize, size, file, line);
    }

    @nogc
    void jokaSystemFree(void* ptr, IStr file = __FILE__, Sz line = __LINE__) {}

    @nogc
    void jokaAllocatorFree(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, IStr file, Sz line) {
        return jokaSystemFree(oldPtr, file, line);
    }

    @nogc
    void jokaFree(void* ptr, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryContext.reallocFunc == null) jokaRestoreDefaultAllocatorSetup(__memoryContext);
        __memoryContext.free(0, ptr, oldSize, file, line);
    }
} else {
    version(JokaPhobosStdc) {
        import stdlibc = core.stdc.stdlib;
    } else {
        import stdlibc = parin.joka.stdc;
    }

    void* jokaSystemMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        if (size == 0) return null;
        auto result = stdlibc.malloc(size);
        static if (isTrackingMemory) {
            if (result) {
                _memoryTrackingState.table[result] = _MallocInfo(
                    file,
                    line,
                    size,
                    false,
                    _memoryTrackingState.currentGroupStack.length ? _memoryTrackingState.currentGroupStack[$ - 1] : "",
                );
                _memoryTrackingState.totalBytes += size;
            }
        }
        return result;
    }

    void* jokaAllocatorMalloc(void* allocatorState, Sz alignment, Sz size, IStr file, Sz line) {
        return jokaSystemMalloc(size, file, line);
    }

    void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryContext.reallocFunc == null) jokaRestoreDefaultAllocatorSetup(__memoryContext);
        return __memoryContext.malloc(0, size, file, line);
    }

    void* jokaSystemRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        if (size == 0) {
            jokaSystemFree(ptr);
            return null;
        }

        void* result;
        if (ptr) {
            static if (isTrackingMemory) {
                if (auto mallocValue = ptr in _memoryTrackingState.table) {
                    result = stdlibc.realloc(ptr, size);
                    if (result) {
                        _memoryTrackingState.table[result] = _MallocInfo(
                            file,
                            line,
                            size,
                            mallocValue.canIgnore,
                            _memoryTrackingState.currentGroupStack.length ? _memoryTrackingState.currentGroupStack[$ - 1] : "",
                        );
                        _memoryTrackingState.totalBytes += size;
                        _memoryTrackingState.totalBytes -= mallocValue.size;
                        if (ptr != result) _memoryTrackingState.table.remove(ptr);
                    }
                } else {
                    if (_memoryTrackingState.canIgnoreInvalidFree) {
                        _memoryTrackingState.invalidFreeTable ~= _MallocInfo(
                            file,
                            line,
                            size,
                            false,
                            _memoryTrackingState.currentGroupStack.length ? _memoryTrackingState.currentGroupStack[$ - 1] : "",
                        );
                    } else {
                        assert(0, "Invalid free.");
                    }
                }
            } else {
                result = stdlibc.realloc(ptr, size);
            }
        } else {
            result = jokaSystemMalloc(size, file, line);
        }
        return result;
    }

    void* jokaAllocatorRealloc(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, Sz newSize, IStr file, Sz line) {
        return jokaSystemRealloc(oldPtr, newSize, file, line);
    }

    void* jokaRealloc(void* ptr, Sz size, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryContext.reallocFunc == null) jokaRestoreDefaultAllocatorSetup(__memoryContext);
        return __memoryContext.realloc(0, ptr, oldSize, size, file, line);
    }

    @nogc
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
                        _memoryTrackingState.invalidFreeTable ~= _MallocInfo(
                            file,
                            line,
                            0,
                            false,
                            _memoryTrackingState.currentGroupStack.length ? _memoryTrackingState.currentGroupStack[$ - 1] : "",
                        );
                    } else {
                        assert(0, "Invalid free.");
                    }
                }
            }
        } else {
            stdlibc.free(ptr);
        }
    }

    @nogc
    void jokaAllocatorFree(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, IStr file, Sz line) {
        return jokaSystemFree(oldPtr, file, line);
    }

    @nogc
    void jokaFree(void* ptr, Sz oldSize = 0, IStr file = __FILE__, Sz line = __LINE__) {
        if (__memoryContext.reallocFunc == null) jokaRestoreDefaultAllocatorSetup(__memoryContext);
        __memoryContext.free(0, ptr, oldSize, file, line);
    }
}

@trusted {
    T* jokaMakeBlank(T)(IStr file = __FILE__, Sz line = __LINE__) {
        return cast(T*) jokaMalloc(T.sizeof, file, line);
    }

    T* jokaMakeBlank(T)(MemoryContext context, IStr file = __FILE__, Sz line = __LINE__) {
        // NOTE: In `JokaCustomMemory`, this does nothing and will use the default allocator.
        //   Do we care? Ehh. I think it's fine for now.
        with (ScopedMemoryContext(context)) {
            return jokaMakeBlank!T(file, line);
        }
    }

    T* jokaMake(T)(IStr file = __FILE__, Sz line = __LINE__) {
        auto result = jokaMakeBlank!T(file, line);
        if (result) *result = T.init;
        return result;
    }

    T* jokaMake(T)(MemoryContext context, IStr file = __FILE__, Sz line = __LINE__) {
        with (ScopedMemoryContext(context)) {
            return jokaMake!T(file, line);
        }
    }

    T* jokaMake(T)(const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = jokaMakeBlank!T(file, line);
        if (result) *result = cast(T) value;
        return result;
    }

    T* jokaMake(T)(MemoryContext context, const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
        with (ScopedMemoryContext(context)) {
            return jokaMake!T(value, file, line);
        }
    }

    T[] jokaMakeSliceBlank(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = (cast(T*) jokaMalloc(T.sizeof * length, file, line))[0 .. length];
        if (result.ptr) return result;
        return [];
    }

    T[] jokaMakeSliceBlank(T)(MemoryContext context, Sz length, IStr file = __FILE__, Sz line = __LINE__) {
        with (ScopedMemoryContext(context)) {
            return jokaMakeSliceBlank!T(length, file, line);
        }
    }

    T[] jokaMakeSlice(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = jokaMakeSliceBlank!T(length, file, line);
        foreach (ref item; result) item = T.init;
        return result;
    }

    T[] jokaMakeSlice(T)(MemoryContext context, Sz length, IStr file = __FILE__, Sz line = __LINE__) {
        with (ScopedMemoryContext(context)) {
            return jokaMakeSlice!T(length, file, line);
        }
    }

    T[] jokaMakeSlice(T)(Sz length, const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = jokaMakeSliceBlank!T(length, file, line);
        foreach (ref item; result) item = value;
        return result;
    }

    T[] jokaMakeSlice(T)(MemoryContext context, Sz length, const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
        with (ScopedMemoryContext(context)) {
            return jokaMakeSlice!T(length, value, file, line);
        }
    }

    T[] jokaMakeSlice(T)(const(T)[] values, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = jokaMakeSliceBlank!T(values.length, file, line);
        if (result.ptr) jokaMemcpy(result.ptr, values.ptr, T.sizeof * values.length);
        return result;
    }

    T[] jokaMakeSlice(T)(MemoryContext context, const(T)[] values, IStr file = __FILE__, Sz line = __LINE__) {
        with (ScopedMemoryContext(context)) {
            return jokaMakeSlice!T(values, file, line);
        }
    }

    // NOTE: The resize and joint functions below are kinda part of the "blank" functions.
    //   The first one will not initialize new memory, and the second one will zero new memory instead of default initializing it.
    //   Joint allocations work like that because it's harder to initialize them manually.
    //
    //   In theory, you would want maybe three versions,
    //   so `jokaResizeSlice`, `jokaResizeSliceBlank`, and `jokaResizeZero` for example,
    //   but that is starting to look ugly.
    //   I don't want to repeat the mistake that some libraries make where you have 20+ functions for basic stuff that you can do manually anyway.

    T[] jokaResizeSlice(T)(T* values, Sz length, Sz oldLength = 0, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = (cast(T*) jokaRealloc(values, T.sizeof * length, T.sizeof * oldLength, file, line))[0 .. length];
        if (result.ptr) return result;
        return [];
    }

    T[] jokaResizeSlice(T)(MemoryContext context, T* values, Sz length, Sz oldLength = 0, IStr file = __FILE__, Sz line = __LINE__) {
        with (ScopedMemoryContext(context)) {
            return jokaResizeSlice!T(values, length, oldLength, file, line);
        }
    }

    T jokaMakeJointBlank(T)(Sz* outTotalBytes, Sz[] lengths...) if (is(T == struct)) {
        enum commonAlignment = typeof(T.tupleof[0][0]).alignof;
        if (lengths.length != T.tupleof.length) assert(0, "Lengths count doesn't match member count.");

        Sz totalBytes;
        static foreach (i, member; T.tupleof) {
            static assert(
                is(typeof(member) : const(M)[], M) || isBufferContainerType!(typeof(member)),
                "Member `" ~ member.stringof ~ "` must be a slice or a buffer list.",
            );
            totalBytes = (totalBytes + (typeof(member[0]).alignof - 1)) & ~(typeof(member[0]).alignof - 1);
            totalBytes += typeof(member[0]).sizeof * lengths[i];
        }

        auto memory = cast(ubyte*) jokaMalloc(totalBytes);
        if (memory) {
            if (outTotalBytes) *outTotalBytes = totalBytes;
        } else {
            if (outTotalBytes) *outTotalBytes = 0;
            return T();
        }

        auto result = T();
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

    T jokaMakeJointBlank(T)(MemoryContext context, Sz* outTotalBytes, Sz[] lengths...) if (is(T == struct)) {
        with (ScopedMemoryContext(context)) {
            return jokaMakeJointBlank!T(outTotalBytes, lengths);
        }
    }

    T jokaMakeJoint(T)(Sz[] lengths...) if (is(T == struct)) {
        Sz totalBytes;
        auto result = jokaMakeJointBlank!T(&totalBytes, lengths);
        if (totalBytes) jokaMemset(result.tupleof[0].ptr, 0, totalBytes);
        return result;
    }

    T jokaMakeJoint(T)(MemoryContext context, Sz[] lengths...) if (is(T == struct)) {
        with (ScopedMemoryContext(context)) {
            return jokaMakeJoint!T(lengths);
        }
    }
}

@trusted @nogc {
    void* nullAllocatorMallocWrapper(void* allocatorState, Sz alignment, Sz size, IStr file, Sz line) {
        return null;
    }

    void* nullAllocatorReallocWrapper(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, Sz newSize, IStr file, Sz line) {
        return null;
    }

    void nullAllocatorFreeWrapper(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, IStr file, Sz line) {}

    void jokaRestoreNullAllocatorSetup(ref MemoryContext context) {
        context.allocatorState = null;
        context.reallocFunc = &nullAllocatorReallocWrapper;
        context.freeFunc = &nullAllocatorFreeWrapper;
    }

    void jokaRestoreDefaultAllocatorSetup(ref MemoryContext context) {
        context.allocatorState = null;
        context.reallocFunc = &jokaAllocatorRealloc;
        context.freeFunc = &jokaAllocatorFree;
    }

    void jokaEnsureCapture(ref MemoryContext capture) {
        if (capture.reallocFunc != null) return;
        if (__memoryContext.reallocFunc == null) jokaRestoreDefaultAllocatorSetup(__memoryContext);
        capture = __memoryContext;
    }

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
}

@trusted
void beginAllocationGroup(IStr group) {
    static if (isTrackingMemory) {
        // NOTE: It doesn't make a copy of the string.
        //   A group string is treated just like a file string.
        _memoryTrackingState.currentGroupStack ~= group;
    }
}

@trusted @nogc
void endAllocationGroup() {
    static if (isTrackingMemory) {
        if (_memoryTrackingState.currentGroupStack.length) {
            _memoryTrackingState.currentGroupStack = _memoryTrackingState.currentGroupStack[0 .. $ - 1];
        }
    }
}
} // END: MEMORY(@systen nothrow)

@trusted nothrow
IStr memoryTrackingInfo(IStr pathFilter = "", bool canShowEmpty = false) {
    static if (isTrackingMemory) {
        // TODO: This needs to be simpler because it was so hard to remember how it works.
        static void _updateGroupBuffer(T)(ref T table) {
            _memoryTrackingState.groupBuffer.clear();
            foreach (key, value; table) {
                if (value.canIgnore) continue;
                auto groupKey = _MallocInfo(value.file, value.line, 0, false, value.group);
                if (auto groupValue = groupKey in _memoryTrackingState.groupBuffer) {
                    groupValue.size += value.size;
                    groupValue.count += 1;
                } else {
                    _memoryTrackingState.groupBuffer[groupKey] = _MallocGroupInfo(value.size, 1);
                }
            }
        }

        try {
            _memoryTrackingState.infoBuffer.length = 0;
            auto finalLength = _memoryTrackingState.table.length;
            foreach (key, value; _memoryTrackingState.table) if (value.canIgnore) finalLength -= 1;
            auto ignoreCount = _memoryTrackingState.table.length - finalLength;
            auto ignoreText = ignoreCount ? ", {} ignored".fmt(ignoreCount) : "";
            auto filterText = pathFilter.length ? fmt("Filter: \"{}\"\n", pathFilter) : "";

            if (canShowEmpty ? true : finalLength != 0) {
                _memoryTrackingState.infoBuffer ~= fmt("Memory Leaks: {} (total {} bytes{})\n{}", finalLength, _memoryTrackingState.totalBytes, ignoreText, filterText);
            }
            _updateGroupBuffer(_memoryTrackingState.table);
            foreach (key, value; _memoryTrackingState.groupBuffer) {
                if (pathFilter.length && key.file.findEnd(pathFilter) == -1) continue;
                _memoryTrackingState.infoBuffer ~= fmt("  {} leak, {} bytes, {}:{}{}\n", value.count, value.size, key.file, key.line, key.group.length ? " [group: \"{}\"]".fmt(key.group) : "");
            }
            if (canShowEmpty ? true : _memoryTrackingState.invalidFreeTable.length != 0) {
                _memoryTrackingState.infoBuffer ~= fmt("Invalid Frees: {}\n{}", _memoryTrackingState.invalidFreeTable.length, filterText);
            }
            _updateGroupBuffer(_memoryTrackingState.invalidFreeTable);
            foreach (key, value; _memoryTrackingState.groupBuffer) {
                if (pathFilter.length && key.file.findEnd(pathFilter) == -1) continue;
                _memoryTrackingState.infoBuffer ~= fmt("  {} free, {}:{}{}\n", value.count, key.file, key.line, key.group.length ? " [group: \"{}\"]".fmt(key.group) : "");
            }
        } catch (Exception e) {
            return "No memory tracking data available.\n";
        }
        return _memoryTrackingState.infoBuffer;
    } else {
        debug {
            version (D_BetterC) {
                return "No memory tracking data available in BetterC builds.\n";
            }
        } else {
            return "No memory tracking data available in release builds.\n";
        }
    }
}

// Joint allocation test.
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
    assert(mesh.name[$ - 1] == '\0');
    assert(mesh.positions[0] == Vector3(0, 0, 0));
    assert(mesh.positions[$ - 1] == Vector3(0, 0, 0));
    assert(mesh.indices[0] == 0);
    assert(mesh.indices[$ - 1] == 0);
    assert(mesh.uvs[0] == Vector2(0, 0));
    assert(mesh.uvs[$ - 1] == Vector2(0, 0));
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

enum defaultListCapacity = 8; /// The default list capacity. It is also the smallest list capacity.

alias LStr         = List!char;            /// A dynamic string of chars.
alias BStr         = BufferList!char;      /// A dynamic string of chars backed by external memory.
alias FStr(Sz N)   = FixedList!(char, N);  /// A dynamic string of chars allocated on the stack.

// Some types are removed for compile-time reasons.
/*
alias LStr16       = List!wchar;           /// A dynamic string of wchars.
alias LStr32       = List!dchar;           /// A dynamic string of dchars.
alias BStr16       = BufferList!wchar;     /// A dynamic string of wchars backed by external memory.
alias BStr32       = BufferList!dchar;     /// A dynamic string of dchars backed by external memory.
alias FStr16(Sz N) = FixedList!(wchar, N); /// A dynamic string of wchars allocated on the stack.
alias FStr32(Sz N) = FixedList!(dchar, N); /// A dynamic string of dchars allocated on the stack.
*/

/// A dynamic array.
struct List(T) {
    enum isBasicContainer  = true;
    enum isBufferContainer = false;
    enum hasFixedCapacity  = false;
    alias Item = T;
    alias Data = T[];

    T[] items;
    Sz capacity;
    MemoryContext capture;
    bool canIgnoreLeak;

    @safe nothrow:

    this(MemoryContext capture, const(T)[] args...) {
        this.capture = capture;
        append(args);
    }

    this(ref Arena arena, const(T)[] args...) {
        this(arena.toMemoryContext(), args);
    }

    this(ref GrowingArena arena, const(T)[] args...) {
        this(arena.toMemoryContext(), args);
    }

    this(const(T)[] args...) {
        this(__memoryContext, args);
    }

    pragma(inline, true) @trusted @nogc {
        Sz length() {
            return items.length;
        }

        T* ptr() {
            return items.ptr;
        }

        bool isEmpty() {
            return length == 0;
        }
    }

    @trusted
    bool appendBlank(IStr file = __FILE__, Sz line = __LINE__) {
        Sz newLength = length + 1;
        if (newLength > capacity) {
            jokaEnsureCapture(capture);
            auto targetCapacity = findListCapacityFastAndAssumeOneAddedItemInLength(newLength, capacity);
            auto rawPtr = capture.realloc(0, items.ptr, capacity * T.sizeof, targetCapacity * T.sizeof, file, line);
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

    @trusted
    bool push(const(T) arg, IStr file = __FILE__, Sz line = __LINE__) {
        if (appendBlank(file, line)) return true;
        items.ptr[items.length - 1] = cast(T) arg;
        return false;
    }

    @trusted @nogc
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
            jokaEnsureCapture(capture);
            auto rawPtr = capture.realloc(0, items.ptr, capacity * T.sizeof, targetCapacity * T.sizeof, file, line);
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
        jokaEnsureCapture(capture);
        capture.free(0, items.ptr, capacity * T.sizeof, file, line);
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

    // NOTE: This is the `sliceOps` mixin. It was replaced with this to make compile-times faster.
    //   Original: mixin sliceOps!(List!T, T);
    pragma(inline, true) @trusted nothrow @nogc {
        T[] opSlice(Sz dim)(Sz i, Sz j) {
            return items[i .. j];
        }

        T[] opIndex() {
            return items[];
        }

        T[] opIndex(T[] slice) {
            return slice;
        }

        ref T opIndex(Sz i) {
            return items[i];
        }

        void opIndexAssign(const(T) rhs, Sz i) {
            items[i] = cast(T) rhs;
        }

        void opIndexOpAssign(const(char)[] op)(const(T) rhs, Sz i) {
            mixin("items[i]", op, "= cast(T) rhs;");
        }

        Sz opDollar(Sz dim)() {
            return items.length;
        }
    }
}

/// A dynamic array that uses external memory provided at runtime.
// The API is almost 1-1 with `List` to make meta programming easier.
struct BufferList(T) {
    enum isBasicContainer  = true;
    enum isBufferContainer = true;
    enum hasFixedCapacity  = true;
    alias Item = T;
    alias Data = T[];

    T[] data;
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

    this(T[] data, const(T)[] args...) {
        this.data = data;
        append(args);
    }

    pragma(inline, true) @trusted {
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

    @trusted
    bool push(const(T) arg, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = appendBlank(file, line);
        if (!result) data.ptr[length - 1] = cast(T) arg;
        return result;
    }

    @trusted
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

    IStr toStr() {
        static if (is(T == char)) { // isCharType
            return items;
        } else {
            assert(0, "Cannot call `toStr` on `List!T` when `T` is not a `char`.");
        }
    }

    void free(IStr file = __FILE__, Sz line = __LINE__) {}
    void ignoreLeak() {}
    MemoryContext capture() { return MemoryContext(); }
    void capture(MemoryContext value) {}

    // NOTE: This is the `sliceOps` mixin. It was replaced with this to make compile-times faster.
    //   Original: mixin sliceOps!(BufferList!T, T);
    pragma(inline, true) @trusted nothrow @nogc {
        T[] opSlice(Sz dim)(Sz i, Sz j) {
            return items[i .. j];
        }

        T[] opIndex() {
            return items[];
        }

        T[] opIndex(T[] slice) {
            return slice;
        }

        ref T opIndex(Sz i) {
            return items[i];
        }

        void opIndexAssign(const(T) rhs, Sz i) {
            items[i] = cast(T) rhs;
        }

        void opIndexOpAssign(const(char)[] op)(const(T) rhs, Sz i) {
            mixin("items[i]", op, "= cast(T) rhs;");
        }

        Sz opDollar(Sz dim)() {
            return items.length;
        }
    }
}

/// A dynamic array allocated on the stack.
// This is just a copy-paste of `BufferList`, but with a static array.
//   Could make both use one type, but I think it's OK to repeat code here.
//   Keeps things simple and easy to read.
struct FixedList(T, Sz N) {
    enum isBasicContainer  = true;
    enum isBufferContainer = false;
    enum hasFixedCapacity  = true;
    alias Item = T;
    alias Data = StaticArray!(T, N);

    StaticArray!(T, N) data = void;
    Sz length;

    @safe nothrow @nogc:

    this(const(T)[] args...) {
        append(args);
    }

    pragma(inline, true) @trusted {
        T[] items() {
            return data.ptr[0 .. length];
        }

        T* ptr() {
            return data.ptr;
        }

        bool isEmpty() {
            return length == 0;
        }
    }

    enum capacity = N;

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

    @trusted
    bool push(const(T) arg, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = appendBlank(file, line);
        if (!result) data.ptr[length - 1] = cast(T) arg;
        return result;
    }

    @trusted
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

    IStr toStr() {
        static if (is(T == char)) { // isCharType
            return items;
        } else {
            assert(0, "Cannot call `toStr` on `List!T` when `T` is not a `char`.");
        }
    }

    void free(IStr file = __FILE__, Sz line = __LINE__) {}
    void ignoreLeak() {}
    MemoryContext capture() { return MemoryContext(); }
    void capture(MemoryContext value) {}

    // NOTE: This is the `sliceOps` mixin. It was replaced with this to make compile-times faster.
    //   Original: mixin sliceOps!(FixedList!(T, N), T);
    pragma(inline, true) @trusted nothrow @nogc {
        T[] opSlice(Sz dim)(Sz i, Sz j) {
            return items[i .. j];
        }

        T[] opIndex() {
            return items[];
        }

        T[] opIndex(T[] slice) {
            return slice;
        }

        ref T opIndex(Sz i) {
            return items[i];
        }

        void opIndexAssign(const(T) rhs, Sz i) {
            items[i] = cast(T) rhs;
        }

        void opIndexOpAssign(const(char)[] op)(const(T) rhs, Sz i) {
            mixin("items[i]", op, "= cast(T) rhs;");
        }

        Sz opDollar(Sz dim)() {
            return items.length;
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
    enum isBasicContainer  = false;
    enum isBufferContainer = false;
    enum hasFixedCapacity  = D.hasFixedCapacity;
    alias Item = D.Item;
    alias Data = D;

    D data;
    Sz hotIndex;
    Sz openIndex;
    Sz length;

    @safe nothrow:

    this(MemoryContext capture, const(T)[] args...) {
        data.capture = capture;
        append(args);
    }

    this(ref Arena arena, const(T)[] args...) {
        this(arena.toMemoryContext(), args);
    }

    this(ref GrowingArena arena, const(T)[] args...) {
        this(arena.toMemoryContext(), args);
    }

    this(const(T)[] args...) {
        this(__memoryContext, args);
    }

    @nogc
    Sz capacity() {
        return data.capacity;
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

    @trusted @nogc {
        ref T opIndex(Sz i) {
            if (!has(i)) assert(0, indexErrorMessage(i));
            return data[i].value;
        }

        void opIndexAssign(const(T) rhs, Sz i) {
            if (!has(i)) assert(0, indexErrorMessage(i));
            data[i].value = cast(T) rhs;
        }

        void opIndexOpAssign(IStr op)(const(T) rhs, Sz i) {
            if (!has(i)) assert(0, indexErrorMessage(i));
            mixin("data[i].value", op, "= cast(T) rhs;");
        }
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

/// A dynamic generational array.
struct GenList(T, D = SparseList!T, G = List!Gen) if (isGenContainerPartsValid!(T, D, G)) {
    enum isBasicContainer  = false;
    enum isBufferContainer = false;
    enum hasFixedCapacity  = D.hasFixedCapacity;
    alias Item = D.Item;
    alias Data = D;

    D data;
    G generations;

    @safe nothrow:

    this(MemoryContext capture) {
        data.data.capture = capture;
        generations.capture = capture;
    }

    this(ref Arena arena) {
        this(arena.toMemoryContext());
    }

    this(ref GrowingArena arena) {
        this(arena.toMemoryContext());
    }

    @nogc
    Sz length() {
        return data.length;
    }

    @nogc
    Sz capacity() {
        return data.capacity;
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

    alias push = append;

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

    @trusted @nogc {
        ref T opIndex(GenIndex i) {
            if (!has(i)) assert(0, genIndexErrorMessage(i.value, i.generation));
            return data[i.value];
        }

        void opIndexAssign(const(T) rhs, GenIndex i) {
            if (!has(i)) assert(0, genIndexErrorMessage(i.value, i.generation));
            data[i.value] = cast(T) rhs;
        }

        void opIndexOpAssign(IStr op)(const(T) rhs, GenIndex i) {
            if (!has(i)) assert(0, genIndexErrorMessage(i.value, i.generation));
            mixin("data[i.value]", op, "= cast(T) rhs;");
        }
    }
}

struct Grid(T, D = List!T) if (isBasicContainerType!D) {
    enum isBasicContainer  = false;
    enum isBufferContainer = false;
    enum hasFixedCapacity  = D.hasFixedCapacity;
    alias Item = D.Item;
    alias Data = D;

    D tiles;
    Sz rowCount;
    Sz colCount;

    @safe nothrow:

    this(MemoryContext capture) {
        tiles.capture = capture;
    }

    this(ref Arena arena) {
        this(arena.toMemoryContext());
    }

    this(ref GrowingArena arena) {
        this(arena.toMemoryContext());
    }

    this(Sz rowCount, Sz colCount, T value = T.init, IStr file = __FILE__, Sz line = __LINE__) {
        resizeBlank(rowCount, colCount, file, line);
        fill(value);
    }

    this(MemoryContext capture, Sz rowCount, Sz colCount, T value = T.init, IStr file = __FILE__, Sz line = __LINE__) {
        tiles.capture = capture;
        resizeBlank(rowCount, colCount, file, line);
        fill(value);
    }

    pragma(inline, true) @trusted nothrow @nogc {
        T[] opIndex() {
            return tiles[0 .. length];
        }

        // NOTE: A normal assert is used here because it might make things faster in release builds.
        //   A grid is just a basic 1D array, so the cost of a bug is not that high in my opinion.
        ref T opIndex(Sz row, Sz col) {
            assert(has(row, col), gridIndexErrorMessage(row, col));
            return tiles[findGridIndex(row, col, colCount)];
        }

        void opIndexAssign(T rhs, Sz row, Sz col) {
            assert(has(row, col), gridIndexErrorMessage(row, col));
            tiles[findGridIndex(row, col, colCount)] = rhs;
        }

        void opIndexOpAssign(IStr op)(T rhs, Sz row, Sz col) {
            assert(has(row, col), gridIndexErrorMessage(row, col));
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

    @nogc
    void fill(T value) {
        tiles.fill(value);
    }

    @nogc
    void clear() {
        tiles.clear();
        rowCount = 0;
        colCount = 0;
    }

    @nogc
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
        if (alignment == 0) alignment = defaultJokaMemoryAlignment;

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
        if (alignment == 0) alignment = defaultJokaMemoryAlignment;

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

    MemoryContext toMemoryContext() {
        auto result = MemoryContext();
        result.allocatorState = &this;
        result.reallocFunc = &arenaAllocatorReallocWrapper;
        result.freeFunc = &arenaAllocatorFreeWrapper;
        return result;
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
        if (alignment == 0) alignment = defaultJokaMemoryAlignment;

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
        if (alignment == 0) alignment = defaultJokaMemoryAlignment;

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

    MemoryContext toMemoryContext() {
        auto result = MemoryContext();
        result.allocatorState = &this;
        result.reallocFunc = &growingArenaAllocatorReallocWrapper;
        result.freeFunc = &growingArenaAllocatorFreeWrapper;
        return result;
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

@trusted @nogc
void* arenaAllocatorMallocWrapper(void* allocatorState, Sz alignment, Sz size, IStr file, Sz line) {
    return (cast(Arena*) allocatorState).malloc(size, alignment, file, line);
}

@trusted @nogc
void* arenaAllocatorReallocWrapper(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, Sz newSize, IStr file, Sz line) {
    return (cast(Arena*) allocatorState).realloc(oldPtr, oldSize, newSize, alignment, file, line);
}

alias arenaAllocatorFreeWrapper = nullAllocatorFreeWrapper;

@trusted
void* growingArenaAllocatorMallocWrapper(void* allocatorState, Sz alignment, Sz size, IStr file, Sz line) {
    return (cast(GrowingArena*) allocatorState).malloc(size, alignment, file, line);
}

@trusted
void* growingArenaAllocatorReallocWrapper(void* allocatorState, Sz alignment, void* oldPtr, Sz oldSize, Sz newSize, IStr file, Sz line) {
    return (cast(GrowingArena*) allocatorState).realloc(oldPtr, oldSize, newSize, alignment, file, line);
}

alias growingArenaAllocatorFreeWrapper = nullAllocatorFreeWrapper;

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

bool isFixedContainerType(T)() {
    static if (__traits(hasMember, T, "hasFixedCapacity")) {
        return T.hasFixedCapacity;
    } else {
        return false;
    }
}

// NOTE:
//   D=List,BufferList,FixedList
//   D.Item=SparseListItem
bool isSparseContainerPartsValid(T, D)() {
    static if (__traits(hasMember, D, "isBasicContainer")) {
        static if (D.isBasicContainer && __traits(hasMember, D.Item, "value") && __traits(hasMember, D.Item, "flag")) {
            return is(D.Item.Item == T);
        } else {
            return false;
        }
    } else {
        return false;
    }
}

// NOTE:
//   D=SparseList
//   G=List,BufferList,FixedList
bool isGenContainerPartsValid(T, D, G)() {
    static if (__traits(hasMember, D, "isBasicContainer")) {
        static if (isSparseContainerPartsValid!(T, D.Data)) {
            static if (__traits(hasMember, G, "isBasicContainer")) {
                return G.isBasicContainer && G.hasFixedCapacity == D.hasFixedCapacity;
            } else {
                return false;
            }
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
    return is(T == List!char) || is(T == BufferList!char) || is(T == FixedList!(char, N), Sz N);
}

// Function test.
unittest {
    assert(findListCapacity(0) == defaultListCapacity);
    assert(findListCapacity(defaultListCapacity) == defaultListCapacity);
    assert(findListCapacity(defaultListCapacity + 1) == defaultListCapacity * 2);
    assert(findListCapacity(defaultListCapacity + 2) == defaultListCapacity * 2);

    assert(findListCapacityFastAndAssumeOneAddedItemInLength(0, 0) == defaultListCapacity);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(defaultListCapacity, 0) == defaultListCapacity);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(defaultListCapacity + 1, 0) == defaultListCapacity * 2);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(defaultListCapacity + 2, 0) == defaultListCapacity);

    enum x2 = defaultListCapacity * 2;
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(0, x2) == x2);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(x2 - 1, x2) == x2);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(x2 - 2, x2) == x2);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(x2, x2) == x2);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(x2 + 1, x2) == x2 * 2);
    assert(findListCapacityFastAndAssumeOneAddedItemInLength(x2 + 2, x2) == x2);
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
    text.resize(1);
    assert(text[0] == char.init);
    assert(text.length == 1);
    text.clear();
    text.reserve(5);
    assert(text.length == 0);
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
    assert(numbers.hotIndex == 0);
    assert(numbers.openIndex == 0);

    numbers = SparseList!int(1, 2, 3);
    assert(numbers.length == 3);
    assert(numbers.capacity == defaultListCapacity);
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

    index = numbers.append(1);
    assert(numbers.length == 1);
    assert(numbers.capacity == defaultListCapacity);
    assert(index.value == 0);
    assert(index.generation == 0);
    assert(numbers[index] == 1);

    index = numbers.append(2);
    assert(numbers.length == 2);
    assert(numbers.capacity == defaultListCapacity);
    assert(index.value == 1);
    assert(index.generation == 0);
    assert(numbers[index] == 2);

    index = numbers.append(3);
    assert(numbers.length == 3);
    assert(numbers.capacity == defaultListCapacity);
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
