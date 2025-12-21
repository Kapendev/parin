// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `memory` module provides functions for dealing with memory.
module parin.joka.memory;

import parin.joka.types;

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
    import stringc = parin.joka.stdc.string;

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
    import stdlibc = parin.joka.stdc.stdlib;
    import stringc = parin.joka.stdc.string;

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
