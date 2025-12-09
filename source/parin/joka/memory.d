// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `memory` module provides functions for dealing with memory.
module parin.joka.memory;

import parin.joka.ascii;
import parin.joka.types;
import stdlibc = parin.joka.stdc.stdlib;
import stringc = parin.joka.stdc.string;

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
            Str infoBuffer;
            _MallocGroupInfo[_MallocInfo] groupBuffer;
            _MallocInfo[void*] table;
            _MallocInfo[] invalidFreeTable;
            Sz totalBytes;
            bool canIgnoreInvalidFree;
            IStr[] currentGroupStack;
        }

        _MemoryTrackingState _memoryTrackingState;
    }
} else {
    enum isTrackingMemory = false;
}

@safe nothrow {
    alias BeginAllocationGroupFunc = void function(IStr group);
}
@safe nothrow @nogc {
    alias EndAllocationGroupFunc = void function();
}

struct AllocationGroup {
    BeginAllocationGroupFunc _beginAllocationGroupFunc;
    EndAllocationGroupFunc _endAllocationGroupFunc;

    @safe nothrow:

    this(IStr group, BeginAllocationGroupFunc beginFunc = null, EndAllocationGroupFunc endFunc = null) {
        this._beginAllocationGroupFunc = beginFunc;
        this._endAllocationGroupFunc = endFunc;
        if (_beginAllocationGroupFunc) {
            _beginAllocationGroupFunc(group);
        } else {
            beginAllocationGroup(group);
        }
    }

    @nogc
    ~this() {
        if (_endAllocationGroupFunc) {
            _endAllocationGroupFunc();
        } else {
            endAllocationGroup();
        }
    }
}

@system nothrow:

version (JokaCustomMemory) {
    pragma(msg, "Joka: Using custom allocator.");

    extern(C) void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__);
    extern(C) void* jokaRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__);
    extern(C) @nogc void jokaFree(void* ptr, IStr file = __FILE__, Sz line = __LINE__);
} else version (JokaGcMemory) {
    pragma(msg, "Joka: Using GC allocator.");

    extern(C)
    void* jokaMalloc(Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = cast(void*) new ubyte[](size).ptr;
        return result;
    }

    extern(C)
    void* jokaRealloc(void* ptr, Sz size, IStr file = __FILE__, Sz line = __LINE__) {
        auto result = jokaMalloc(size);
        if (ptr == null || result == null) return result;
        jokaMemcpy(result, ptr, size);
        return result;
    }

    extern(C) @nogc
    void jokaFree(void* ptr, IStr file = __FILE__, Sz line = __LINE__) {}
} else {
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
        void* result;
        if (ptr) {
            static if (isTrackingMemory) {
                if (auto mallocValue = ptr in _memoryTrackingState.table) {
                    result = stdlibc.realloc(ptr, size);
                    if (result) {
                        _memoryTrackingState.table[result] = _MallocInfo(file, line, size, mallocValue.canIgnore, _memoryTrackingState.currentGroupStack.length ? _memoryTrackingState.currentGroupStack[$ - 1] : "");
                        _memoryTrackingState.totalBytes += size - mallocValue.size;
                        if (ptr != result) _memoryTrackingState.table.remove(ptr);
                    }
                } else {
                    if (_memoryTrackingState.canIgnoreInvalidFree) {
                        _memoryTrackingState.invalidFreeTable ~= _MallocInfo(file, line, size, false, _memoryTrackingState.currentGroupStack.length ? _memoryTrackingState.currentGroupStack[$ - 1] : "");
                    } else {
                        assert(0, "Invalid free: {}:{}".fmt(file, line));
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
                        assert(0, "Invalid free: {}:{}".fmt(file, line));
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
    static if (is(T : const(A)[], A)) { // isSliceType
        static if (isTrackingMemory) {
            if (auto mallocValue = ptr.ptr in _memoryTrackingState.table) {
                mallocValue.canIgnore = true;
            }
        }
        return ptr;
    } else static if (is(T : const(void)*)) { // isPtrType
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
        debug {
            _memoryTrackingState.currentGroupStack ~= group.dup;
        }
    }
}

@trusted @nogc
void endAllocationGroup() {
    static if (isTrackingMemory) {
        if (_memoryTrackingState.currentGroupStack.length) _memoryTrackingState.currentGroupStack = _memoryTrackingState.currentGroupStack[0 .. $ - 1];
    }
}

@nogc
void* jokaMemset(void* ptr, int value, Sz size) {
    return stringc.memset(ptr, value, size);
}

@nogc
void* jokaMemcpy(void* ptr, const(void)* source, Sz size) {
    return stringc.memcpy(ptr, source, size);
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
            auto filterText = filter.length ? fmt("Filter: \"{}\"\n", filter) : "";

            if (canShowEmpty ? true : finalLength != 0) {
                _memoryTrackingState.infoBuffer ~= fmt("Memory Leaks: {} (total {} bytes{})\n{}", finalLength, _memoryTrackingState.totalBytes, ignoreText, filterText);
            }
            _updateGroupBuffer(_memoryTrackingState.table);
            foreach (key, value; _memoryTrackingState.groupBuffer) {
                if (filter.length && key.file.findEnd(filter) == -1) continue;
                _memoryTrackingState.infoBuffer ~= fmt("  {} leak, {} bytes, {}:{}{}\n", value.count, value.size, key.file, key.line, key.group.length ? " [group: \"{}\"]".fmt(key.group) : "");
            }
            if (canShowEmpty ? true : _memoryTrackingState.invalidFreeTable.length != 0) {
                _memoryTrackingState.infoBuffer ~= fmt("Invalid Frees: {}\n{}", _memoryTrackingState.invalidFreeTable.length, filterText);
            }
            _updateGroupBuffer(_memoryTrackingState.invalidFreeTable);
            foreach (key, value; _memoryTrackingState.groupBuffer) {
                if (filter.length && key.file.findEnd(filter) == -1) continue;
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
