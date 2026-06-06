module parin.joka.warena;

import parin.joka.types;

private @trusted nothrow @nogc {
    version (WebAssembly) {
        import ldc = ldc.intrinsics;
        extern(C) extern __gshared ubyte __heap_base;
        alias llvm_wasm_memory_size = ldc.llvm_wasm_memory_size;
        alias llvm_wasm_memory_grow = ldc.llvm_wasm_memory_grow;
    } else {
        __gshared ubyte __heap_base;
        int llvm_wasm_memory_size(int mem) => 0;
        int llvm_wasm_memory_grow(int mem, int delta) => -1;
    }
}

struct WasmArena {
    Sz initialTotalPageCount;
    Sz offset;
    Sz previousOffset;
    void* lastPtr;

    enum pageSize        = cast(Sz) (1U << 16U);
    enum defaulAlignment = cast(Sz) 16U;

    @system nothrow @nogc:

    static void* heapBasePtr() {
        return &__heap_base;
    }

    @trusted
    Sz totalPageCount() {
        if (initialTotalPageCount == 0) initialTotalPageCount = llvm_wasm_memory_size(0);
        return llvm_wasm_memory_size(0) - initialTotalPageCount;
    }

    @trusted
    Sz totalPageSize() {
        return cast(Sz) (totalPageCount << 16U);
    }

    void* malloc(Sz alignment, Sz size) {
        if (alignment == 0) alignment = defaulAlignment;

        Sz alignedOffset = void;
        if (offset == 0) {
            auto ptr = cast(Sz) heapBasePtr;
            alignedOffset = ((ptr + (alignment - 1)) & ~(alignment - 1)) - ptr;
        } else {
            alignedOffset = (offset + (alignment - 1)) & ~(alignment - 1);
        }

        if (alignedOffset + size > totalPageSize) {
            auto neededByteCount = alignedOffset + size - totalPageSize;
            auto pageGrowCount = (neededByteCount + (pageSize - 1)) >> 16U;
            if (llvm_wasm_memory_grow(0, cast(int) pageGrowCount) == -1) return null;
        }
        previousOffset = offset;
        offset = alignedOffset + size;
        lastPtr = cast(void*) (heapBasePtr + alignedOffset);
        return lastPtr;
    }

    void* realloc(Sz alignment, void* oldPtr, Sz oldSize, Sz newSize) {
        if (alignment == 0) alignment = defaulAlignment;

        auto shouldMemcpy = true;
        if (oldPtr == null) return malloc(alignment, newSize);
        if (oldPtr == lastPtr) {
            offset = previousOffset;
            shouldMemcpy = false;
        }
        auto newPtr = malloc(alignment, newSize);
        if (newPtr == null) return null;
        if (shouldMemcpy) {
            if (oldSize <= newSize) {
                jokaMemcpy(newPtr, oldPtr, oldSize);
            } else {
                jokaMemcpy(newPtr, oldPtr, newSize);
            }
        }
        return newPtr;
    }

    @safe
    void clear() {
        offset = 0;
        previousOffset = 0;
        lastPtr = null;
    }
}

@trusted nothrow @nogc
Sz testWasmArena() {
    WasmArena arena;
    ubyte* ptr;
    ubyte* otherPtr;

    if (arena.totalPageCount != 0) return __LINE__;

    ptr = cast(ubyte*) arena.malloc(8, 64);
    if (ptr == null) return __LINE__;
    if ((cast(Sz) ptr) % 8 != 0) return __LINE__;
    if (arena.totalPageCount != 1) return __LINE__;
    ptr[0] = 0xAB;
    if (ptr[0] != 0xAB) return __LINE__;

    otherPtr = cast(ubyte*) arena.malloc(8, 64);
    otherPtr[0] = 0xFE;
    if ((cast(Sz) otherPtr) <= (cast(Sz) ptr)) return __LINE__;
    if (arena.realloc(8, otherPtr, 64, 128) == ptr) return __LINE__;
    if (otherPtr[0] != 0xFE) return __LINE__;

    ptr = cast(ubyte*) arena.malloc(8, arena.pageSize + 1);
    if (ptr == null) return __LINE__;
    ptr[arena.pageSize] = 0xCD;
    if (ptr[arena.pageSize] != 0xCD) return __LINE__;
    if (arena.totalPageCount != 2) return __LINE__;

    arena.clear();
    if (arena.offset != 0) return __LINE__;
    if (arena.previousOffset != 0) return __LINE__;
    if (arena.lastPtr != null) return __LINE__;
    ptr = cast(ubyte*) arena.malloc(8, 64);
    if (ptr == null) return __LINE__;

    return 0;
}
