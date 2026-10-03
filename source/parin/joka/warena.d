module parin.joka.warena;

enum defaultWarenaPageSize  = cast(size_t) (1U << 16U);
enum defaultWarenaAlignment = cast(size_t) 16U;

// LLVM copy-pasta.
private {
    version (WebAssembly) {
        import ldcn = ldc.intrinsics;

        extern(C) __gshared extern ubyte __heap_base;
        alias llvm_wasm_memory_size = ldcn.llvm_wasm_memory_size;
        alias llvm_wasm_memory_grow = ldcn.llvm_wasm_memory_grow;
        alias llvm_memcpy = ldcn.llvm_memcpy;

        // With bulk memory, the LLVM memory intrinsics become the `memory.copy` and `memory.fill` instructions.
        // Without it, they become calls to `memcpy` and friends, so using them in there would call itself forever.
        enum hasBulkMemory = __traits(targetHasFeature, "bulk-memory");
    } else {
        enum hasBulkMemory = false;

        extern(C) __gshared ubyte __heap_base;

        @trusted nothrow @nogc {
            int llvm_wasm_memory_size(int) {
                return 0;
            }

            int llvm_wasm_memory_grow(int, int) {
                return -1;
            }
        }
    }

    @trusted nothrow @nogc {
        void* heapBasePtr() {
            return &__heap_base;
        }

        void* warenaMemcpy(void* dest, const(void)* src, size_t count) {
            static if (hasBulkMemory) {
                llvm_memcpy(dest, src, count);
            } else {
                foreach (i; 0 .. count) (cast(ubyte*) dest)[i] = (cast(ubyte*) src)[i];
            }
            return dest;
        }
    }
}

struct WasmArena {
    size_t initialTotalPageCount;
    size_t offset;
    size_t checkpointOffset;
    size_t previousOffset;
    void* lastPtr;

    @trusted nothrow @nogc:

    size_t totalPageCount() {
        if (initialTotalPageCount == 0) initialTotalPageCount = llvm_wasm_memory_size(0);
        return llvm_wasm_memory_size(0) - initialTotalPageCount;
    }

    size_t totalPageSize() {
        return cast(size_t) (totalPageCount << 16U);
    }

    void* malloc(size_t alignment, size_t size) {
        if (alignment == 0) alignment = defaultWarenaAlignment;

        size_t alignedOffset = void;
        if (offset == 0) {
            auto ptr = cast(size_t) heapBasePtr;
            alignedOffset = ((ptr + (alignment - 1)) & ~(alignment - 1)) - ptr;
        } else {
            alignedOffset = (offset + (alignment - 1)) & ~(alignment - 1);
        }

        if (alignedOffset + size > totalPageSize) {
            auto neededByteCount = alignedOffset + size - totalPageSize;
            auto pageGrowCount = (neededByteCount + (defaultWarenaPageSize - 1)) >> 16U;
            if (llvm_wasm_memory_grow(0, cast(int) pageGrowCount) == -1) return null;
        }
        previousOffset = offset;
        offset = alignedOffset + size;
        lastPtr = cast(void*) (heapBasePtr + alignedOffset);
        return lastPtr;
    }

    void* realloc(size_t alignment, void* oldPtr, size_t oldSize, size_t newSize) {
        if (alignment == 0) alignment = defaultWarenaAlignment;

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
                warenaMemcpy(newPtr, oldPtr, oldSize);
            } else {
                warenaMemcpy(newPtr, oldPtr, newSize);
            }
        }
        return newPtr;
    }

    void checkpoint() {
        checkpointOffset = offset;
    }

    void rollback(size_t value) {
        offset = value;
        previousOffset = value;
        lastPtr = null;
    }

    void rollback() {
        rollback(checkpointOffset);
    }

    void dropCheckpoint() {
        checkpointOffset = 0;
    }

    void clear() {
        checkpointOffset = 0;
        rollback(0);
    }
}
