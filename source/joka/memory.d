// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `memory` module provides functions for dealing with memory.
module joka.memory;

import joka.ascii;
import joka.types;
import stdc = joka.stdc;

@system nothrow:

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
        }

        struct _MallocGroupInfo {
            Sz size;
            Sz count = 1;
        }

        struct _MemoryTrackingState {
            Str infoBuffer;
            _MallocGroupInfo[_MallocInfo] groupBuffer;
            _MallocInfo[void*] table;
            _MallocInfo[] invalidFreeTable;
            Sz totalBytes;
            bool canIgnoreInvalidFree;
        }

        _MemoryTrackingState _memoryTrackingState;
    }
} else {
    enum isTrackingMemory = false;
}

struct Heap(T) {
    T* ptr;

    @trusted nothrow:

    this(T value, IStr file = __FILE__, Sz line = __LINE__) {
        make(value, file, line);
    }

    bool isSome() => ptr != null;
    bool isNone() => ptr == null;
    alias isEmpty = isNone;
    alias isNull = isNone;

    void makeBlank(IStr file = __FILE__, Sz line = __LINE__) {
        free(file, line);
        ptr = jokaMakeBlank!T(file, line);
    }

    void make(IStr file = __FILE__, Sz line = __LINE__) {
        free(file, line);
        ptr = jokaMake!T(file, line);
    }

    void make(T value, IStr file = __FILE__, Sz line = __LINE__) {
        free(file, line);
        ptr = jokaMake!T(value, file, line);
    }

    @nogc
    void free(IStr file = __FILE__, Sz line = __LINE__) {
        jokaFree(ptr, file, line);
        ptr = null;
    }
}

version (JokaCustomMemory) {
    pragma(msg, "Joka: Using custom allocator.");

    extern(C) void* jokaMalloc(Sz size);
    extern(C) void* jokaRealloc(void* ptr, Sz size);
    extern(C) @nogc void jokaFree(void* ptr);
} else version (JokaGcMemory) {
    pragma(msg, "Joka: Using GC allocator.");

    extern(C)
    void* jokaMalloc(Sz size) {
        auto result = cast(void*) new ubyte[](size).ptr;
        return result;
    }

    extern(C)
    void* jokaRealloc(void* ptr, Sz size) {
        auto result = jokaMalloc(size);
        if (ptr == null || result == null) return result;
        jokaMemcpy(result, ptr, size);
        return result;
    }

    extern(C) @nogc
    void jokaFree(void* ptr) {}
} else {
    extern(C)
    void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = stdc.malloc(size);
        static if (isTrackingMemory) {
            if (result) {
                _memoryTrackingState.table[result] = _MallocInfo(file, line, size);
                _memoryTrackingState.totalBytes += size;
            }
        }
        return result;
    }

    extern(C)
    void* jokaRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        void* result;
        if (ptr) {
            static if (isTrackingMemory) {
                if (auto mallocValue = ptr in _memoryTrackingState.table) {
                    result = stdc.realloc(ptr, size);
                    if (result) {
                        _memoryTrackingState.table[result] = _MallocInfo(file, line, size, mallocValue.canIgnore);
                        _memoryTrackingState.totalBytes += size - mallocValue.size;
                        if (ptr != result) _memoryTrackingState.table.remove(ptr);
                    }
                } else {
                    if (_memoryTrackingState.canIgnoreInvalidFree) {
                        _memoryTrackingState.invalidFreeTable ~= _MallocInfo(file, line, size);
                    } else {
                        assert(0, "Invalid free: {}:{}".fmt(file, line));
                    }
                }
            } else {
                result = stdc.realloc(ptr, size);
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
                stdc.free(ptr);
                debug {
                    _memoryTrackingState.totalBytes -= mallocValue.size;
                    _memoryTrackingState.table.remove(ptr);
                }
            } else {
                debug {
                    if (_memoryTrackingState.canIgnoreInvalidFree) {
                        _memoryTrackingState.invalidFreeTable ~= _MallocInfo(file, line, 0);
                    } else {
                        assert(0, "Invalid free: {}:{}".fmt(file, line));
                    }
                }
            }
        } else {
            stdc.free(ptr);
        }
    }
}

@trusted @nogc
auto ignoreLeak(T)(T ptr) {
    static if (isSliceType!T) {
        static if (isTrackingMemory) {
            if (auto mallocValue = ptr.ptr in _memoryTrackingState.table) {
                mallocValue.canIgnore = true;
            }
        }
        return ptr;
    } else static if (isPtrType!T) {
        static if (isTrackingMemory) {
            if (auto mallocValue = ptr in _memoryTrackingState.table) {
                mallocValue.canIgnore = true;
            }
        }
        return ptr;
    } else static if (__traits(hasMember, T, "ignoreLeak")) {
        return ptr.ignoreLeak();
    } else {
        static assert(0, funcImplementationErrorMessage!(T, "ignoreLeak"));
    }
}

extern(C) @nogc
void* jokaMemset(void* ptr, int value, Sz size) {
    return stdc.memset(ptr, value, size);
}

extern(C) @nogc
void* jokaMemcpy(void* ptr, const(void)* source, Sz size) {
    return stdc.memcpy(ptr, source, size);
}

@trusted
T* jokaMakeBlank(T)(IStr file = __FILE__, Sz line = __LINE__) {
    return cast(T*) jokaMalloc(T.sizeof, file, line);
}

@trusted
T* jokaMake(T)(IStr file = __FILE__, Sz line = __LINE__) {
    auto result = jokaMakeBlank!T(file, line);
    *result = T.init;
    return result;
}

@trusted
T* jokaMake(T)(const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = jokaMakeBlank!T(file, line);
    *result = cast(T) value;
    return result;
}

@trusted
T[] jokaMakeSliceBlank(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
    return (cast(T*) jokaMalloc(T.sizeof * length, file, line))[0 .. length];
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
IStr memoryTrackingInfo(IStr filter = "", bool canShowEmpty = false) {
    static void _updateGroupBuffer(T)(ref T table) {
        _memoryTrackingState.groupBuffer.clear();
        foreach (key, value; table) {
            if (value.canIgnore) continue;
            auto groupKey = _MallocInfo(value.file, value.line);
            if (auto groupValue = groupKey in _memoryTrackingState.groupBuffer) {
                groupValue.size += value.size;
                groupValue.count += 1;
            } else {
                _memoryTrackingState.groupBuffer[groupKey] = _MallocGroupInfo(value.size);
            }
        }
    }

    static if (isTrackingMemory) {
        try {
            _memoryTrackingState.infoBuffer.length = 0;
            auto finalLength = _memoryTrackingState.table.length;
            foreach (key, value; _memoryTrackingState.table) if (value.canIgnore) finalLength -= 1;
            auto ignoreCount = _memoryTrackingState.table.length - finalLength;
            auto ignoreText = ignoreCount ? ", {} ignored".fmt(ignoreCount) : "";
            auto filterText = filter.length ? fmt("Filter: \"{}\"\n", filter) : "";

            if (canShowEmpty ? true : finalLength != 0) {
                _memoryTrackingState.infoBuffer ~= fmt("Memory Leaks: {} (total {} bytes{})\n{}", finalLength, _memoryTrackingState.totalBytes, ignoreText, filterText);
            }
            _updateGroupBuffer(_memoryTrackingState.table);
            foreach (key, value; _memoryTrackingState.groupBuffer) {
                if (filter.length && key.file.findEnd(filter) == -1) continue;
                _memoryTrackingState.infoBuffer ~= fmt("  {} leak, {} bytes, {}:{}\n", value.count, value.size, key.file, key.line);
            }
            if (canShowEmpty ? true : _memoryTrackingState.invalidFreeTable.length != 0) {
                _memoryTrackingState.infoBuffer ~= fmt("Invalid Frees: {}\n{}", _memoryTrackingState.invalidFreeTable.length, filterText);
            }
            _updateGroupBuffer(_memoryTrackingState.invalidFreeTable);
            foreach (key, value; _memoryTrackingState.groupBuffer) {
                if (filter.length && key.file.findEnd(filter) == -1) continue;
                _memoryTrackingState.infoBuffer ~= fmt("  {} free, {}:{}\n", value.count, key.file, key.line);
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
