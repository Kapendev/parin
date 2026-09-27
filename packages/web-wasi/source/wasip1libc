module wasip1libc;

extern(C) __gshared {
    WasmArena wasmArena;
    int errno;
    void* stdout = cast(void*) fdstdout;
    void* stderr = cast(void*) fdstderr;
    int _CLOCK_MONOTONIC = 1;
    int _CLOCK_REALTIME = 0;
}

// No idea why I'm adding attributes, but it is what it is.
extern(C) @trusted nothrow @nogc {
    alias QsortCompFunc = int function(const(void)* a, const(void)* b);
}

alias pthread_t           = size_t;
alias pthread_mutex_t     = void*;
alias pthread_cond_t      = void*;
alias pthread_mutexattr_t = void*;
alias pthread_condattr_t  = void*;

alias sighandler_t = void function(int);
alias sigset_t     = ulong;

enum SIG_ERR = cast(sighandler_t) -1;
enum SIG_DFL = cast(sighandler_t) 0;
enum SIG_IGN = cast(sighandler_t) 1;
enum SIGHUP  = 1;
enum SIGINT  = 2;
enum SIGQUIT = 3;
enum SIGILL  = 4;
enum SIGTRAP = 5;
enum SIGABRT = 6;
enum SIGBUS  = 7;
enum SIGFPE  = 8;
enum SIGKILL = 9;
enum SIGUSR1 = 10;
enum SIGSEGV = 11;
enum SIGUSR2 = 12;
enum SIGPIPE = 13;
enum SIGALRM = 14;
enum SIGTERM = 15;
enum SIGCHLD = 17;
enum SIGCONT = 18;
enum SIGSTOP = 19;
enum SIGTSTP = 20;

enum SIG_BLOCK   = 0;
enum SIG_UNBLOCK = 1;
enum SIG_SETMASK = 2;

enum MAP_ANON = 32;
enum ENODEV   = 43;
enum ENOMEM   = 48;
enum EINVAL   = 28;

// They are 32 bits on wasm32 and 64 bits on wasm64.
alias CLong  = ptrdiff_t;
alias CULong = size_t;

alias defaultWarenaMemcpy = memcpy;

enum defaultWarenaPageSize  = cast(size_t) (1U << 16U);
enum defaultWarenaAlignment = cast(size_t) 16U;

enum fdstdout = 1;
enum fdstderr = 2;

enum M_PI       = 3.14159265358979323846264338327950288;
enum M_PI_2     = 1.57079632679489661923132169163975144;
enum M_PI_4     = 0.78539816339744830961566084581987572;
enum TWO_PI     = 6.28318530717958647692528676655900576;
enum M_1_PI     = 0.31830988618379067153776752674502872;
enum M_2_PI     = 0.63661977236758134307553505349005744;
enum M_2_SQRTPI = 1.12837916709551257389615890312154517;
enum M_E        = 2.71828182845904523536028747135266250;
enum M_LOG2E    = 1.44269504088896340735992468100189214;
enum M_LOG10E   = 0.43429448190325182765112891891660508;
enum M_LN2      = 0.69314718055994530941723212145817657;
enum M_LN10     = 2.30258509299404568401799145468436421;
enum M_SQRT2    = 1.41421356237309504880168872420969808;
enum M_SQRT1_2  = 0.70710678118654752440084436210484904;

// LLVM copy-pasta.
private {
    version (LDC) {
        import ldc = ldc.attributes;
        import ldcn = ldc.intrinsics;

        extern(C) __gshared extern ubyte __heap_base;
        alias llvmAttr = ldc.llvmAttr;
        alias llvm_wasm_memory_size = ldcn.llvm_wasm_memory_size;
        alias llvm_wasm_memory_grow = ldcn.llvm_wasm_memory_grow;
        alias llvm_memcpy = ldcn.llvm_memcpy;
        alias llvm_memmove = ldcn.llvm_memmove;
        alias llvm_memset = ldcn.llvm_memset;

        // With bulk memory, the LLVM memory intrinsics become the `memory.copy` and `memory.fill` instructions.
        // Without it, they become calls to `memcpy` and friends, so using them in there would call itself forever.
        enum hasBulkMemory = __traits(targetHasFeature, "bulk-memory");
    } else {
        enum hasBulkMemory = false;

        extern(C) __gshared ubyte __heap_base;

        struct llvmAttr {
            immutable(char)[] a, b;
        }

        @trusted nothrow @nogc {
            int llvm_wasm_memory_size(int) {
                return 0;
            }

            int llvm_wasm_memory_grow(int, int) {
                return -1;
            }
        }
    }

    enum wasi = llvmAttr("wasm-import-module", "wasi_snapshot_preview1");

    @trusted nothrow @nogc {
        llvmAttr importName(immutable(char)[] name) {
            return llvmAttr("wasm-import-name", name);
        }

        void* heapBasePtr() {
            return &__heap_base;
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
                defaultWarenaMemcpy(newPtr, oldPtr, oldSize);
            } else {
                defaultWarenaMemcpy(newPtr, oldPtr, newSize);
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

struct Ciovec {
    const(void)* ptr;
    size_t length;
}

struct timespec {
    long tv_sec, tv_nsec;
}

struct tm {
    int tm_sec, tm_min, tm_hour, tm_mday, tm_mon, tm_year, tm_wday, tm_yday, tm_isdst;
}

struct siginfo_t {
    int si_signo, si_code, si_errno;
}

struct sigaction_t {
    sighandler_t sa_handler;
    sigset_t sa_mask;
    int sa_flags;
}

struct FILE;

// @--
extern(C) @system nothrow @nogc:

void _start() {
    version (D_BetterC) {
        __main_void();
    } else {
        __main_argc_argv(0, null);
    }
}

int __main_void();
int __main_argc_argv(int argc, const(char)** argv);

void* memset(void* dest, int ch, size_t count) {
    static if (hasBulkMemory) {
        llvm_memset(dest, cast(ubyte) ch, count);
    } else {
        foreach (i; 0 .. count) (cast(ubyte*) dest)[i] = cast(ubyte) ch;
    }
    return dest;
}

void* memcpy(void* dest, const(void)* src, size_t count) {
    static if (hasBulkMemory) {
        llvm_memcpy(dest, src, count);
    } else {
        foreach (i; 0 .. count) (cast(ubyte*) dest)[i] = (cast(ubyte*) src)[i];
    }
    return dest;
}

void* memmove(void* dest, const(void)* src, size_t count) {
    static if (hasBulkMemory) {
        llvm_memmove(dest, src, count);
    } else {
        auto d = cast(ubyte*) dest;
        auto s = cast(const(ubyte)*) src;
        if (d < s) {
            foreach (i; 0 .. count) d[i] = s[i];
        } else {
            foreach_reverse (i; 0 .. count) d[i] = s[i];
        }
    }
    return dest;
}

int memcmp(const(void)* s1, const(void)* s2, size_t count) {
    auto p1 = cast(const(ubyte)*) s1;
    auto p2 = cast(const(ubyte)*) s2;
    foreach (i; 0 .. count) if (p1[i] != p2[i]) return p1[i] - p2[i];
    return 0;
}

void qsort(void* ptr, size_t count, size_t size, QsortCompFunc comp) {
    if (ptr == null || comp == null) return;
    qsortRange(cast(ubyte*) ptr, count, size, comp);
}

void qsortSwap(ubyte* a, ubyte* b, size_t size) {
    if (a == b) return;
    if (size == 4) {
        auto t = *cast(uint*) a; *cast(uint*) a = *cast(uint*) b; *cast(uint*) b = t;
    } else if (size == 8) {
        auto t = *cast(ulong*) a; *cast(ulong*) a = *cast(ulong*) b; *cast(ulong*) b = t;
    } else {
        foreach (k; 0 .. size) { auto t = a[k]; a[k] = b[k]; b[k] = t; }
    }
}

// Quicksort with a median-of-three pivot and a partition that handles equal items well.
// Recurses on the smaller side and loops on the bigger one, so the stack depth stays around log2(count).
// Small ranges use insertion sort.
void qsortRange(ubyte* ptr, size_t count, size_t size, QsortCompFunc comp) {
    enum insertionSortCount = 12;

    if (size == 0) return;
    while (count > insertionSortCount) {
        auto first = ptr;
        auto middle = ptr + (count / 2) * size;
        auto last = ptr + (count - 1) * size;
        if (comp(middle, first) < 0) qsortSwap(middle, first, size);
        if (comp(last, middle) < 0) {
            qsortSwap(last, middle, size);
            if (comp(middle, first) < 0) qsortSwap(middle, first, size);
        }
        qsortSwap(first, middle, size); // The pivot lives at the start while partitioning.

        size_t i = 1;
        size_t j = count - 1;
        while (true) {
            while (i <= j && comp(ptr + i * size, first) < 0) i += 1;
            while (i <= j && comp(ptr + j * size, first) > 0) j -= 1;
            if (i >= j) break;
            qsortSwap(ptr + i * size, ptr + j * size, size);
            i += 1;
            j -= 1;
        }
        qsortSwap(first, ptr + j * size, size);

        auto leftCount = j;
        auto rightCount = count - j - 1;
        if (leftCount < rightCount) {
            qsortRange(ptr, leftCount, size, comp);
            ptr += (j + 1) * size;
            count = rightCount;
        } else {
            qsortRange(ptr + (j + 1) * size, rightCount, size, comp);
            count = leftCount;
        }
    }

    foreach (i; 1 .. count) {
        auto j = i;
        while (j > 0 && comp(ptr + (j - 1) * size, ptr + j * size) > 0) {
            qsortSwap(ptr + (j - 1) * size, ptr + j * size, size);
            j -= 1;
        }
    }
}

int fputc(int character, FILE* stream) {
    auto c = cast(char) character;
    auto iov = Ciovec(&c, 1);
    size_t n;
    return fd_write(fdstdout, &iov, 1, &n) == 0 ? character : -1;
}

dchar fputwc(dchar wc, FILE* stream) {
    return cast(dchar) fputc(cast(int) wc, stream);
}

size_t fwrite(const(void)* ptr, size_t size, size_t nmemb, FILE* stream) {
    auto total = size * nmemb;
    if (total == 0) return 0;
    auto iov = Ciovec(ptr, total);
    size_t n;
    return fd_write(fdstdout, &iov, 1, &n) == 0 ? nmemb : 0;
}

int* __errno_location() {
    return &errno;
}

size_t strlen(const(char)* str) {
    auto result = 0U;
    while (str[result]) result += 1;
    return result;
}

size_t strnlen(const(char)* str, size_t maxlen) {
    auto result = 0U;
    while (result < maxlen && str[result]) result += 1;
    return result;
}

void* memchr(const(void)* ptr, int ch, size_t count) {
    auto p = cast(const(ubyte)*) ptr;
    auto c = cast(ubyte) ch;
    foreach (i; 0 .. count) if (p[i] == c) return cast(void*) (p + i);
    return null;
}

int strcmp(const(char)* s1, const(char)* s2) {
    auto p1 = cast(const(ubyte)*) s1;
    auto p2 = cast(const(ubyte)*) s2;
    while (*p1 && *p1 == *p2) { p1 += 1; p2 += 1; }
    return *p1 - *p2;
}

int strncmp(const(char)* s1, const(char)* s2, size_t count) {
    auto p1 = cast(const(ubyte)*) s1;
    auto p2 = cast(const(ubyte)*) s2;
    foreach (i; 0 .. count) {
        if (p1[i] != p2[i] || p1[i] == 0) return p1[i] - p2[i];
    }
    return 0;
}

char* strchr(const(char)* str, int ch) {
    auto c = cast(char) ch;
    while (true) {
        if (*str == c) return cast(char*) str;
        if (*str == 0) return null;
        str += 1;
    }
}

char* strrchr(const(char)* str, int ch) {
    auto c = cast(char) ch;
    const(char)* result = null;
    while (true) {
        if (*str == c) result = str;
        if (*str == 0) return cast(char*) result;
        str += 1;
    }
}

char* strstr(const(char)* haystack, const(char)* needle) {
    if (*needle == 0) return cast(char*) haystack;
    for (; *haystack; haystack += 1) {
        size_t i = 0;
        while (needle[i] && haystack[i] == needle[i]) i += 1;
        if (needle[i] == 0) return cast(char*) haystack;
    }
    return null;
}

char* strcpy(char* dest, const(char)* src) {
    size_t i = 0;
    while (src[i]) { dest[i] = src[i]; i += 1; }
    dest[i] = 0;
    return dest;
}

char* strncpy(char* dest, const(char)* src, size_t count) {
    size_t i = 0;
    while (i < count && src[i]) { dest[i] = src[i]; i += 1; }
    while (i < count) { dest[i] = 0; i += 1; } // Yes, it pads with zeros. That's C.
    return dest;
}

char* strcat(char* dest, const(char)* src) {
    strcpy(dest + strlen(dest), src);
    return dest;
}

char* strncat(char* dest, const(char)* src, size_t count) {
    auto end = dest + strlen(dest);
    size_t i = 0;
    while (i < count && src[i]) { end[i] = src[i]; i += 1; }
    end[i] = 0;
    return dest;
}

int strerror_r(int errnum, char* buf, size_t buflen) {
    enum message = "error";

    if (buflen == 0) return -1;
    auto len = message.length < buflen - 1 ? message.length : buflen - 1;
    foreach (i; 0 .. len) buf[i] = message[i];
    buf[len] = '\0';
    return 0;
}

char* strerror(int errnum) {
    return cast(char*) "error".ptr;
}

void* malloc(size_t size) {
    auto result = wasmArena.malloc(0, defaultWarenaAlignment + size);
    if (result == null) return null;
    *(cast(size_t*) result) = size;
    return (cast(ubyte*) result) + defaultWarenaAlignment;
}

void* calloc(size_t nmemb, size_t size) {
    if (size != 0 && nmemb > size_t.max / size) return null;
    auto p = malloc(nmemb * size);
    if (p) memset(p, 0, nmemb * size);
    return p;
}

void* realloc(void* ptr, size_t size) {
    if (ptr == null) return malloc(size);
    auto raw = (cast(ubyte*) ptr) - defaultWarenaAlignment;
    auto oldSize = *(cast(size_t*) raw);
    auto result = wasmArena.realloc(0, raw, defaultWarenaAlignment + oldSize, defaultWarenaAlignment + size);
    if (result is null) return null;
    *cast(size_t*) result = size;
    return (cast(ubyte*) result) + defaultWarenaAlignment;
}

void free(void* ptr) {}

void* mmap(void* addr, size_t length, int prot, int flags, int fd, long offset) {
    if (length == 0) { errno = EINVAL; return cast(void*) -1; }
    if (fd != -1 || (flags & MAP_ANON) == 0) { errno = ENODEV; return cast(void*) -1; }

    auto result = wasmArena.malloc(defaultWarenaPageSize, length);
    if (result == null) { errno = ENOMEM; return cast(void*) -1; }
    memset(result, 0, length);
    return result;
}

int munmap(void* addr, size_t length) {
    return 0;
}

int fclose(void* stream) {
    return 0;
}

int fwide(void* stream, int mode) {
    return 0;
}

int fflush(void* stream) {
    return 0;
}

int putchar(int c) {
    return fputc(c, null);
}

int putc(int character, FILE* stream) {
    return fputc(character, stream);
}

int fputs(const(char)* str, FILE* stream) {
    auto iov = Ciovec(str, strlen(str));
    size_t n;
    return fd_write(fdstdout, &iov, 1, &n) == 0 ? 0 : -1;
}

int puts(const(char)* str) {
    char newline = '\n';
    Ciovec[2] iovs = [Ciovec(str, strlen(str)), Ciovec(&newline, 1)];
    size_t n;
    return fd_write(fdstdout, iovs.ptr, 2, &n) == 0 ? 0 : -1;
}

int printf(const(char)* fmt, ...) {
    auto iov = Ciovec(fmt, strlen(fmt));
    size_t n;
    return fd_write(fdstdout, &iov, 1, &n) == 0 ? cast(int) n : -1;
}

int fprintf(void* stream, const(char)* fmt, ...) {
    return printf(fmt);
}

int snprintf(char* s, size_t n, const(char)* fmt, ...) {
    if (n == 0) return 0;
    auto len = strlen(fmt);
    if (len >= n) len = n - 1;
    memcpy(s, fmt, len);
    s[len] = '\0';
    return cast(int) len;
}

int sscanf(const(char)* s, const(char)* fmt, ...) {
    return 0;
}

ptrdiff_t write(int fd, const(void)* buf, size_t count) {
    auto iov = Ciovec(buf, count);
    size_t n;
    return fd_write(fd, &iov, 1, &n) == 0 ? cast(ptrdiff_t) n : -1;
}

void abort() {
    proc_exit(134);
}

void exit(int status) {
    proc_exit(status);
}

int isspace(int c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\v' || c == '\f';
}

int isblank(int c) {
    return c == ' ' || c == '\t';
}

int isdigit(int c) {
    return c >= '0' && c <= '9';
}

int isxdigit(int c) {
    return isdigit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

int isupper(int c) {
    return c >= 'A' && c <= 'Z';
}

int islower(int c) {
    return c >= 'a' && c <= 'z';
}

int isalpha(int c) {
    return isupper(c) || islower(c);
}

int isalnum(int c) {
    return isalpha(c) || isdigit(c);
}

int iscntrl(int c) {
    return (c >= 0 && c < 32) || c == 127;
}

int isprint(int c) {
    return c >= 32 && c < 127;
}

int isgraph(int c) {
    return c > 32 && c < 127;
}

int ispunct(int c) {
    return isgraph(c) && !isalnum(c);
}

int toupper(int c) {
    return islower(c) ? c - 32 : c;
}

int tolower(int c) {
    return isupper(c) ? c + 32 : c;
}

char* getenv(const(char)* name) {
    return null;
}

// The clock id is a pointer (`&_CLOCK_MONOTONIC`), like in wasi-libc.
int clock_gettime(const(int)* clk, timespec* tp) {
    ulong nanos = void;
    if (clock_time_get(*clk, 1, &nanos) != 0) return -1;
    tp.tv_sec  = cast(long) (nanos / 1_000_000_000UL);
    tp.tv_nsec = cast(long) (nanos % 1_000_000_000UL);
    return 0;
}

int clock_getres(const(int)* clk, timespec* res) {
    ulong resNanos = void;
    if (clock_res_get(*clk, &resNanos) != 0) return -1;
    res.tv_sec  = cast(long) (resNanos / 1_000_000_000UL);
    res.tv_nsec = cast(long) (resNanos % 1_000_000_000UL);
    return 0;
}

tm* localtime_r(const(timespec)* timep, tm* result) {
    *result = tm();
    return result;
}

int sysconf(int name) {
    enum _SC_PAGESIZE = 30;
    if (name == _SC_PAGESIZE) return defaultWarenaPageSize;
    return -1;
}

// Number parsing is out of scope. These all say that nothing was parsed and return 0.
int atoi(const(char)* str) {
    return 0;
}

CLong atol(const(char)* str) {
    return 0;
}

long atoll(const(char)* str) {
    return 0;
}

double atof(const(char)* str) {
    return 0;
}

CLong strtol(const(char)* nptr, char** endptr, int base) {
    if (endptr) *endptr = cast(char*) nptr;
    return 0;
}

CULong strtoul(const(char)* nptr, char** endptr, int base) {
    if (endptr) *endptr = cast(char*) nptr;
    return 0;
}

long strtoll(const(char)* nptr, char** endptr, int base) {
    if (endptr) *endptr = cast(char*) nptr;
    return 0;
}

ulong strtoull(const(char)* nptr, char** endptr, int base) {
    if (endptr) *endptr = cast(char*) nptr;
    return 0;
}

float strtof(const(char)* nptr, char** endptr) {
    if (endptr) *endptr = cast(char*) nptr;
    return 0;
}

double strtod(const(char)* nptr, char** endptr) {
    if (endptr) *endptr = cast(char*) nptr;
    return 0;
}

real strtold(const(char)* nptr, char** endptr) {
    if (endptr) *endptr = cast(char*) nptr;
    return 0;
}

int pthread_mutexattr_init(pthread_mutexattr_t* a) {
    return 0;
}

int pthread_mutexattr_settype(pthread_mutexattr_t* a, int t) {
    return 0;
}

int pthread_mutexattr_destroy(pthread_mutexattr_t* a) {
    return 0;
}

int pthread_mutex_init(pthread_mutex_t* m, const(pthread_mutexattr_t)* a) {
    return 0;
}

int pthread_mutex_destroy(pthread_mutex_t* m) {
    return 0;
}

int pthread_mutex_lock(pthread_mutex_t* m) {
    return 0;
}

int pthread_mutex_unlock(pthread_mutex_t* m) {
    return 0;
}

int pthread_mutex_trylock(pthread_mutex_t* m) {
    return 0;
}

int pthread_condattr_init(pthread_condattr_t* a) {
    return 0;
}

int pthread_condattr_setclock(pthread_condattr_t* a, int c) {
    return 0;
}

int pthread_condattr_destroy(pthread_condattr_t* a) {
    return 0;
}

int pthread_cond_init(pthread_cond_t* c, const(pthread_condattr_t)* a) {
    return 0;
}

int pthread_cond_destroy(pthread_cond_t* c) {
    return 0;
}

int pthread_cond_wait(pthread_cond_t* c, pthread_mutex_t* m) {
    return 0;
}

int pthread_cond_timedwait(pthread_cond_t* c, pthread_mutex_t* m, const(timespec)* t) {
    return 0;
}

int pthread_cond_signal(pthread_cond_t* c) {
    return 0;
}

int pthread_cond_broadcast(pthread_cond_t* c) {
    return 0;
}

int pthread_detach(pthread_t t) {
    return 0;
}

int pthread_join(pthread_t t, void** r) {
    return 0;
}

pthread_t pthread_self() {
    return 1;
}

int pthread_sigmask(int how, const(sigset_t)* set, sigset_t* oldset) {
    return 0;
}

int pthread_kill(pthread_t thread, int sig) {
    return 0;
}

int sched_yield() {
    return 0;
}

sighandler_t signal(int sig, sighandler_t handler) {
    return SIG_DFL;
}

int raise(int sig) {
    return 0;
}

int kill(int pid, int sig) {
    return 0;
}

int sigaction(int sig, const(sigaction_t)* act, sigaction_t* oldact) {
    return 0;
}

int sigemptyset(sigset_t* set) {
    if (set) *set = 0;
    return 0;
}

int sigfillset(sigset_t* set) {
    if (set) *set = ~cast(sigset_t) 0;
    return 0;
}

int sigaddset(sigset_t* set, int sig) {
    return 0;
}

int sigdelset(sigset_t* set, int sig) {
    return 0;
}

int sigismember(const(sigset_t)* set, int sig) {
    return 0;
}

int sigprocmask(int how, const(sigset_t)* set, sigset_t* oldset) {
    return 0;
}

private bool mathSignBit(double x) {
    return ((*cast(ulong*) &x) >> 63) != 0;
}

private bool mathIsInf(double x) {
    return x == double.infinity || x == -double.infinity;
}

float fabsf(float x) {
    uint bits = (*cast(uint*) &x) & 0x7FFF_FFFFU;
    return *cast(float*) &bits;
}

double fabs(double x) {
    ulong bits = (*cast(ulong*) &x) & 0x7FFF_FFFF_FFFF_FFFFUL;
    return *cast(double*) &bits;
}

float floorf(float x) {
    if (!(fabsf(x) < 8388608.0f)) return x; // 2^23. Also NaN and infinity.
    auto truncated = cast(float) cast(int) x;
    if (truncated > x) truncated -= 1.0f;
    if (truncated == 0 && mathSignBit(x)) return -0.0f;
    return truncated;
}

double floor(double x) {
    if (!(fabs(x) < 0x1p52)) return x; // Also NaN and infinity.
    auto truncated = cast(double) cast(long) x;
    if (truncated > x) truncated -= 1.0;
    if (truncated == 0 && mathSignBit(x)) return -0.0;
    return truncated;
}

float ceilf(float x) {
    return -floorf(-x);
}

double ceil(double x) {
    return -floor(-x);
}

// Rounds half away from zero, like C.
float roundf(float x) {
    if (!(fabsf(x) < 8388608.0f)) return x;
    auto truncated = cast(float) cast(int) x;
    if (fabsf(x - truncated) >= 0.5f) truncated += x < 0 ? -1.0f : 1.0f;
    if (truncated == 0 && mathSignBit(x)) return -0.0f;
    return truncated;
}

double round(double x) {
    if (!(fabs(x) < 0x1p52)) return x;
    auto truncated = cast(double) cast(long) x;
    if (fabs(x - truncated) >= 0.5) truncated += x < 0 ? -1.0 : 1.0;
    if (truncated == 0 && mathSignBit(x)) return -0.0;
    return truncated;
}

// Splits x into n * (pi / 2) + r, with |r| <= pi / 4, and returns r. The quadrant (n mod 4) goes into q.
// Accurate for |x| up to about 1e9. Bigger values give imprecise (but valid) results.
private double mathTrigSplit(double x, int* q) {
    enum pio2A = 1.57079632673412561417e+00; // pi / 2 split in three, so x - n * (pi / 2) stays exact.
    enum pio2B = 6.07710050630396597660e-11;
    enum pio2C = 2.02226624879595063154e-21;
    if (fabs(x) > 0x1p30) x = remainder(x, TWO_PI);
    auto n = floor(x * M_2_PI + 0.5);
    *q = cast(int) n & 3;
    return ((x - n * pio2A) - n * pio2B) - n * pio2C;
}

// sin(r) and cos(r) for |r| <= pi / 4, double precision.
private double mathSinPoly(double r) {
    auto z = r * r;
    return r + r * z * (-0.16666666666666666 + z * (0.008333333333330948 + z * (-0.00019841269836758574
        + z * (2.755731610255244e-06 + z * (-2.5051131845003624e-08 + z * 1.5918129294866608e-10)))));
}

private double mathCosPoly(double r) {
    auto z = r * r;
    return 1.0 - 0.5 * z + z * z * (0.041666666666666664 + z * (-0.0013888888888887398 + z * (2.480158729876569e-05
        + z * (-2.7557317271729793e-07 + z * (2.08761462684032e-09 + z * -1.1382632425521717e-11)))));
}

// sin(r) and cos(r) for |r| <= pi / 4, float precision.
private double mathSinPolyF(double r) {
    auto z = r * r;
    return r + r * z * (-0.1666666466231438 + z * (0.008332748270629749 + z * -0.00019587890880412386));
}

private double mathCosPolyF(double r) {
    auto z = r * r;
    return 1.0 - 0.5 * z + z * z * (0.04166666465950221 + z * (-0.0013888303035894866 + z * 2.4547942085071572e-05));
}

double sin(double x) {
    if (x != x || mathIsInf(x)) return double.nan;
    if (fabs(x) < 0x1p-26) return x; // sin(x) == x here. Also keeps -0.
    int q = void;
    auto r = mathTrigSplit(x, &q);
    switch (q) {
        case 0:  return mathSinPoly(r);
        case 1:  return mathCosPoly(r);
        case 2:  return -mathSinPoly(r);
        default: return -mathCosPoly(r);
    }
}

float sinf(float x) {
    if (x != x || mathIsInf(x)) return float.nan;
    if (fabsf(x) < 0x1p-12f) return x;
    int q = void;
    auto r = mathTrigSplit(x, &q);
    switch (q) {
        case 0:  return cast(float) mathSinPolyF(r);
        case 1:  return cast(float) mathCosPolyF(r);
        case 2:  return cast(float) -mathSinPolyF(r);
        default: return cast(float) -mathCosPolyF(r);
    }
}

double cos(double x) {
    if (x != x || mathIsInf(x)) return double.nan;
    int q = void;
    auto r = mathTrigSplit(x, &q);
    switch (q) {
        case 0:  return mathCosPoly(r);
        case 1:  return -mathSinPoly(r);
        case 2:  return -mathCosPoly(r);
        default: return mathSinPoly(r);
    }
}

float cosf(float x) {
    if (x != x || mathIsInf(x)) return float.nan;
    int q = void;
    auto r = mathTrigSplit(x, &q);
    switch (q) {
        case 0:  return cast(float) mathCosPolyF(r);
        case 1:  return cast(float) -mathSinPolyF(r);
        case 2:  return cast(float) -mathCosPolyF(r);
        default: return cast(float) mathSinPolyF(r);
    }
}

double tan(double x) {
    if (x != x || mathIsInf(x)) return double.nan;
    if (fabs(x) < 0x1p-26) return x;
    int q = void;
    auto r = mathTrigSplit(x, &q);
    auto s = mathSinPoly(r);
    auto c = mathCosPoly(r);
    return (q & 1) ? -c / s : s / c;
}

float tanf(float x) {
    if (x != x || mathIsInf(x)) return float.nan;
    if (fabsf(x) < 0x1p-12f) return x;
    int q = void;
    auto r = mathTrigSplit(x, &q);
    auto s = mathSinPolyF(r);
    auto c = mathCosPolyF(r);
    return cast(float) ((q & 1) ? -c / s : s / c);
}

// Returns x * 2^n.
private double mathScale(double x, int n) {
    while (n > 1023)  { x *= 0x1p1023;  n -= 1023; }
    while (n < -1022) { x *= 0x1p-1022; n += 1022; }
    ulong bits = cast(ulong) (n + 1023) << 52;
    return x * *cast(double*) &bits;
}

// Splits x (positive, finite) into m * 2^e with m in [sqrt(0.5), sqrt(2)].
// Returns s = (m - 1) / (m + 1), where ln(m) = 2 * (s + s^3/3 + s^5/5 + ...) and |s| <= 0.172.
private double mathLogSplit(double x, int* e) {
    *e = 0;
    if (x < 0x1p-1022) { x *= 0x1p54; *e = -54; } // Subnormals.
    ulong bits = *cast(ulong*) &x;
    *e += cast(int) ((bits >> 52) & 0x7FF) - 1023;
    bits = (bits & 0xF_FFFF_FFFF_FFFF) | (1023UL << 52);
    auto m = *cast(double*) &bits;
    if (m > M_SQRT2) { m *= 0.5; *e += 1; }
    return (m - 1.0) / (m + 1.0);
}

// ln(m) from s, double precision.
private double mathLogPoly(double s) {
    auto s2 = s * s;
    auto p = s2 * (1.0 / 3 + s2 * (1.0 / 5 + s2 * (1.0 / 7 + s2 * (1.0 / 9 + s2 * (1.0 / 11
        + s2 * (1.0 / 13 + s2 * (1.0 / 15 + s2 * (1.0 / 17 + s2 * (1.0 / 19 + s2 * (1.0 / 21))))))))));
    return 2.0 * (s + s * p);
}

// ln(m) from s, float precision.
private double mathLogPolyF(double s) {
    auto s2 = s * s;
    auto p = s2 * (1.0 / 3 + s2 * (1.0 / 5 + s2 * (1.0 / 7 + s2 * (1.0 / 9 + s2 * (1.0 / 11)))));
    return 2.0 * (s + s * p);
}

// e^r for |r| <= ln(2) / 2, double precision.
private double mathExpPoly(double r) {
    return 1.0 + r * (1.0 + r * (1.0 / 2 + r * (1.0 / 6 + r * (1.0 / 24 + r * (1.0 / 120
        + r * (1.0 / 720 + r * (1.0 / 5040 + r * (1.0 / 40320 + r * (1.0 / 362880
        + r * (1.0 / 3628800 + r * (1.0 / 39916800 + r * (1.0 / 479001600 + r * (1.0 / 6227020800)))))))))))));
}

// e^r for |r| <= ln(2) / 2, float precision.
private double mathExpPolyF(double r) {
    return 1.0 + r * (1.0 + r * (1.0 / 2 + r * (1.0 / 6 + r * (1.0 / 24 + r * (1.0 / 120
        + r * (1.0 / 720 + r * (1.0 / 5040)))))));
}

// Splits x into n * ln(2) + r, with |r| <= ln(2) / 2. Assumes x is in exp range.
private double mathExpSplit(double x, int* n) {
    enum ln2Hi = 6.93147180369123816490e-01; // ln(2) split in two, so x - n * ln(2) stays exact.
    enum ln2Lo = 1.90821492927058770002e-10;
    *n = cast(int) (x * M_LOG2E + (x < 0 ? -0.5 : 0.5));
    return (x - *n * ln2Hi) - *n * ln2Lo;
}

// atan(k / 8) for k = 0 .. 8.
private immutable double[9] mathAtanTable = [
    0.0, 0.12435499454676144, 0.24497866312686414, 0.35877067027057225, 0.4636476090008061,
    0.5585993153435624, 0.6435011087932844, 0.7188299996216245, 0.7853981633974483,
];

// atan(x) for x in [0, 1]. Uses atan(x) = atan(c) + atan((x - c) / (1 + x * c)) with c = k / 8, so |t| <= 1/16.
private double mathAtanKernel(double x, bool isFloat) {
    auto k = cast(int) (x * 8.0 + 0.5);
    auto c = k * 0.125;
    auto t = (x - c) / (1.0 + x * c);
    auto t2 = t * t;
    double p = void;
    if (isFloat) {
        p = t2 * (1.0 / 3 - t2 * (1.0 / 5 - t2 * (1.0 / 7)));
    } else {
        p = t2 * (1.0 / 3 - t2 * (1.0 / 5 - t2 * (1.0 / 7 - t2 * (1.0 / 9 - t2 * (1.0 / 11
            - t2 * (1.0 / 13 - t2 * (1.0 / 15)))))));
    }
    return mathAtanTable[k] + (t - t * p);
}

double sqrt(double x) {
    if (x != x || x < 0) return double.nan;
    if (x == 0 || x == double.infinity) return x;
    if (x < 0x1p-1000) return sqrt(x * 0x1p600) * 0x1p-300;

    // Guess 1 / sqrt(x) with the bit trick, refine without division, then one Newton step for sqrt(x).
    ulong bits = 0x5FE6_EB50_C7B5_37A9UL - ((*cast(ulong*) &x) >> 1);
    auto y = *cast(double*) &bits;
    auto h = 0.5 * x;
    foreach (i; 0 .. 3) y = y * (1.5 - h * y * y);
    auto s = x * y;
    return 0.5 * (s + x / s);
}

float sqrtf(float x) {
    if (x != x || x < 0) return float.nan;
    if (x == 0 || x == float.infinity) return x;
    double dx = x;
    if (dx < 0x1p-1000) return cast(float) sqrt(dx); // Never for floats, but keeps the trick below valid.

    ulong bits = 0x5FE6_EB50_C7B5_37A9UL - ((*cast(ulong*) &dx) >> 1);
    auto y = *cast(double*) &bits;
    auto h = 0.5 * dx;
    foreach (i; 0 .. 2) y = y * (1.5 - h * y * y);
    auto s = dx * y;
    return cast(float) (0.5 * (s + dx / s));
}

double log(double x) {
    if (x != x || x < 0) return double.nan;
    if (x == 0) return -double.infinity;
    if (x == double.infinity) return x;
    int e = void;
    auto lnm = mathLogPoly(mathLogSplit(x, &e));
    return lnm + e * M_LN2;
}

float logf(float x) {
    if (x != x || x < 0) return float.nan;
    if (x == 0) return -float.infinity;
    if (x == float.infinity) return x;
    int e = void;
    auto lnm = mathLogPolyF(mathLogSplit(x, &e));
    return cast(float) (lnm + e * M_LN2);
}

double log2(double x) {
    if (x != x || x < 0) return double.nan;
    if (x == 0) return -double.infinity;
    if (x == double.infinity) return x;
    int e = void;
    auto lnm = mathLogPoly(mathLogSplit(x, &e));
    return lnm * M_LOG2E + e;
}

float log2f(float x) {
    if (x != x || x < 0) return float.nan;
    if (x == 0) return -float.infinity;
    if (x == float.infinity) return x;
    int e = void;
    auto lnm = mathLogPolyF(mathLogSplit(x, &e));
    return cast(float) (lnm * M_LOG2E + e);
}

double log10(double x) {
    enum log10Of2 = 0.30102999566398119521373889472449302;
    if (x != x || x < 0) return double.nan;
    if (x == 0) return -double.infinity;
    if (x == double.infinity) return x;
    int e = void;
    auto lnm = mathLogPoly(mathLogSplit(x, &e));
    return lnm * M_LOG10E + e * log10Of2;
}

float log10f(float x) {
    enum log10Of2 = 0.30102999566398119521373889472449302;
    if (x != x || x < 0) return float.nan;
    if (x == 0) return -float.infinity;
    if (x == float.infinity) return x;
    int e = void;
    auto lnm = mathLogPolyF(mathLogSplit(x, &e));
    return cast(float) (lnm * M_LOG10E + e * log10Of2);
}

double exp(double x) {
    if (x != x) return x;
    if (x > 709.782712893384) return double.infinity;
    if (x < -745.1332191019412) return 0.0;
    int n = void;
    auto r = mathExpSplit(x, &n);
    return mathScale(mathExpPoly(r), n);
}

float expf(float x) {
    if (x != x) return x;
    if (x > 88.72284f) return float.infinity;
    if (x < -103.97208f) return 0.0f;
    int n = void;
    auto r = mathExpSplit(x, &n);
    return cast(float) mathScale(mathExpPolyF(r), n);
}

double exp2(double x) {
    if (x != x) return x;
    if (x >= 1024.0) return double.infinity;
    if (x < -1075.0) return 0.0;
    auto n = cast(int) (x + (x < 0 ? -0.5 : 0.5));
    auto f = x - n; // Exact.
    return mathScale(mathExpPoly(f * M_LN2), n);
}

float exp2f(float x) {
    if (x != x) return x;
    if (x >= 128.0f) return float.infinity;
    if (x < -150.0f) return 0.0f;
    auto n = cast(int) (x + (x < 0 ? -0.5f : 0.5f));
    auto f = cast(double) x - n; // Exact.
    return cast(float) mathScale(mathExpPolyF(f * M_LN2), n);
}

// The exact rounding error of a * b, given product = a * b rounded (Dekker).
// Needs |a| and |b| below 2^995, and the product far from underflow.
private double mathMulError(double a, double b, double product) {
    enum splitter = 134217729.0; // 2^27 + 1.
    auto t = a * splitter;
    auto aHi = t - (t - a);
    auto aLo = a - aHi;
    t = b * splitter;
    auto bHi = t - (t - b);
    auto bLo = b - bHi;
    return ((aHi * bHi - product) + aHi * bLo + aLo * bHi) + aLo * bLo;
}

// Multiplies the double-double number (hi + lo) by (bHi + bLo), keeping about 100 bits.
private void mathMulDouble(double* hi, double* lo, double bHi, double bLo) {
    auto product = *hi * bHi;
    auto error = mathMulError(*hi, bHi, product) + (*hi * bLo + *lo * bHi);
    auto sum = product + error;
    *lo = error - (sum - product);
    *hi = sum;
}

// log(x) as hi + lo with about 100 bits, for positive finite x. Used by pow.
private double mathLogDouble(double x, double* lo) {
    enum ln2Hi = 6.93147180369123816490e-01; // ln(2) split in two, so e * ln2Hi is exact.
    enum ln2Lo = 1.90821492927058770002e-10;

    // x = m * 2^e with m in [sqrt(0.5), sqrt(2)].
    auto e = 0;
    if (x < 0x1p-1022) { x *= 0x1p54; e = -54; } // Subnormals.
    ulong bits = *cast(ulong*) &x;
    e += cast(int) ((bits >> 52) & 0x7FF) - 1023;
    bits = (bits & 0xF_FFFF_FFFF_FFFF) | (1023UL << 52);
    auto m = *cast(double*) &bits;
    if (m > M_SQRT2) { m *= 0.5; e += 1; }

    // s = f / (2 + f) with f = m - 1, as s + sLo. Then ln(m) = 2 * (s + s^3/3 + s^5/5 + ...).
    auto f = m - 1.0; // Exact.
    auto dHi = 2.0 + f;
    auto dLo = f - (dHi - 2.0); // 2 + f == dHi + dLo exactly.
    auto s = f / dHi;
    auto p = s * dHi;
    auto sLo = (((f - p) - mathMulError(s, dHi, p)) - s * dLo) / dHi;
    // The s^3/3 term is still big enough to matter, so it gets extra precision too.
    enum twoThirdsHi = 0.6666666666666666;
    enum twoThirdsLo = 3.700743415417188e-17;
    auto z = s * s;
    auto zError = mathMulError(s, s, z);
    auto cube = s * z;
    auto cubeError = mathMulError(s, z, cube) + s * zError;
    auto third = cube * twoThirdsHi; // 2s^3 / 3.
    auto thirdError = mathMulError(cube, twoThirdsHi, third) + (cubeError * twoThirdsHi + cube * twoThirdsLo);
    auto rest = 2.0 * s * z * z * (1.0 / 5 + z * (1.0 / 7 + z * (1.0 / 9 + z * (1.0 / 11 + z * (1.0 / 13
        + z * (1.0 / 15 + z * (1.0 / 17 + z * (1.0 / 19 + z * (1.0 / 21 + z * (1.0 / 23 + z * (1.0 / 25)))))))))));

    // e * ln2Hi + 2s + 2s^3/3 is added exactly (Knuth), everything small goes into the low part.
    auto a = e * ln2Hi;
    auto b = 2.0 * s;
    auto hi = a + b;
    auto v = hi - a;
    auto low = (a - (hi - v)) + (b - v);
    auto hi2 = hi + third;
    v = hi2 - hi;
    low += (hi - (hi2 - v)) + (third - v);
    low += thirdError + 2.0 * sLo * (1.0 + z) + rest + e * ln2Lo; // The (1 + z) is sLo's effect on the s^3 term.
    auto result = hi2 + low;
    *lo = low - (result - hi2);
    return result;
}

// x^n for integers, with double-double squaring so the error doesn't grow with n.
// Returns false when the numbers could get too big or small for that, and pow falls back to exp and log.
private bool mathPowInt(double x, long n, double* result) {
    int e = void;
    frexp(x, &e);
    auto k = cast(ulong) (n < 0 ? -n : n);
    if (k * (cast(ulong) (e < 0 ? -e : e) + 1) > 900) return false;

    auto hi = 1.0;
    auto lo = 0.0;
    auto baseHi = x;
    auto baseLo = 0.0;
    while (true) {
        if (k & 1) mathMulDouble(&hi, &lo, baseHi, baseLo);
        k >>= 1;
        if (k == 0) break;
        auto copyHi = baseHi;
        auto copyLo = baseLo;
        mathMulDouble(&baseHi, &baseLo, copyHi, copyLo);
    }
    if (n < 0) {
        // 1 / (hi + lo), with one correction step.
        auto q = 1.0 / hi;
        auto p = q * hi;
        auto residual = ((1.0 - p) - mathMulError(q, hi, p)) - q * lo;
        *result = q + residual * q;
    } else {
        *result = hi + lo;
    }
    return true;
}

double pow(double x, double y) {
    if (y == 0 || x == 1) return 1.0;
    if (x != x || y != y) return double.nan;
    auto ax = fabs(x);
    if (mathIsInf(y)) {
        if (ax == 1) return 1.0;
        return (ax > 1) == (y > 0) ? double.infinity : 0.0;
    }

    auto isInt = fabs(y) < 0x1p53 && y == cast(double) cast(long) y;
    auto isOdd = isInt && (cast(long) y & 1);
    auto sign = (mathSignBit(x) && isOdd) ? -1.0 : 1.0;
    if (ax == 0) return sign * (y > 0 ? 0.0 : double.infinity);
    if (ax == double.infinity) return sign * (y > 0 ? double.infinity : 0.0);
    if (x < 0 && !isInt && fabs(y) < 0x1p53) return double.nan; // Beyond 2^53 every double is an even integer.

    if (isInt && fabs(y) < 0x1p31) {
        auto n = cast(long) y;
        if (n == 1) return x;
        if (n == -1) return 1.0 / x;
        if (n == 2) return x * x;
        if (n == 3) return x * x * x; // Small powers stay plain for speed, within 2 ulp.
        if (n == 4) { auto x2 = x * x; return x2 * x2; }
        if (n == -2) return 1.0 / (x * x);
        double result = void;
        if (mathPowInt(x, n, &result)) return result;
    }

    // x^y = e^(y * log(x)), with log(x) and the product kept in extra precision.
    double logLo = void;
    auto logHi = mathLogDouble(ax, &logLo);
    auto z = y * logHi;
    if (!(fabs(z) < 1000)) return sign * exp(z); // Overflow or underflow anyway.
    auto zLo = mathMulError(y, logHi, z) + y * logLo;
    auto r = exp(z);
    return sign * (r + r * zLo);
}

float powf(float x, float y) {
    return cast(float) pow(x, y);
}

double fmod(double x, double y) {
    if (x != x || y != y || mathIsInf(x) || y == 0) return double.nan;
    auto ax = fabs(x);
    auto ay = fabs(y);
    if (ax < ay) return x;

    // Long division in binary. Every subtraction is exact.
    auto r = ax;
    auto d = ay;
    while (d <= r * 0.5) d *= 2.0;
    while (d >= ay) {
        if (r >= d) r -= d;
        d *= 0.5;
    }
    return x < 0 ? -r : r;
}

float fmodf(float x, float y) {
    return cast(float) fmod(x, y);
}

double remainder(double x, double y) {
    if (x != x || y != y || mathIsInf(x) || y == 0) return double.nan;
    auto ay = fabs(y);
    auto r = fabs(x);
    if (ay <= double.max * 0.5) r = fmod(r, 2.0 * ay); // Now r is in [0, 2 * ay).

    // Round to nearest, ties to even.
    if (r > 0.5 * ay) {
        r -= ay;
        if (r >= 0.5 * ay) r -= ay;
    }
    return mathSignBit(x) ? -r : r;
}

float remainderf(float x, float y) {
    return cast(float) remainder(x, y);
}

double atan(double x) {
    if (x != x || x == 0) return x;
    auto ax = fabs(x);
    auto r = ax > 1 ? M_PI_2 - mathAtanKernel(1.0 / ax, false) : mathAtanKernel(ax, false);
    return x < 0 ? -r : r;
}

float atanf(float x) {
    if (x != x || x == 0) return x;
    double ax = fabs(x);
    auto r = ax > 1 ? M_PI_2 - mathAtanKernel(1.0 / ax, true) : mathAtanKernel(ax, true);
    return cast(float) (x < 0 ? -r : r);
}

double atan2(double y, double x) {
    if (x != x || y != y) return double.nan;
    auto negY = mathSignBit(y);
    if (mathIsInf(x) && mathIsInf(y)) {
        auto r = x > 0 ? M_PI_4 : 3.0 * M_PI_4;
        return negY ? -r : r;
    }
    if (x == 0) {
        if (y == 0) {
            auto r = mathSignBit(x) ? M_PI : 0.0;
            return negY ? -r : r;
        }
        return negY ? -M_PI_2 : M_PI_2;
    }
    auto r = atan(y / x);
    if (x < 0) r += negY ? -M_PI : M_PI;
    return r;
}

float atan2f(float y, float x) {
    return cast(float) atan2(y, x);
}

// asin(x) for |x| <= 0.5.
private double mathAsinPoly(double x) {
    auto z = x * x;
    return x + x * z * (0.1666666666666665 + z * (0.07500000000020764 + z * (0.044642857103423646
        + z * (0.03038194736709848 + z * (0.02237204763174451 + z * (0.017355259955786323
        + z * (0.013929652902326633 + z * (0.011875494382636922 + z * (0.0078029494773533175
        + z * (0.01603551434914882 + z * (-0.010749050339697808 + z * 0.028169218060881414)))))))))));
}

private double mathAsinPolyF(double x) {
    auto z = x * x;
    return x + x * z * (0.16666672414795305 + z * (0.07498855072600821 + z * (0.04500138006991017
        + z * (0.026554542206161328 + z * 0.038085023561092654))));
}

enum mathPio2Hi = 1.57079632679489655800e+00; // pi / 2 and pi split in two, for the subtractions below.
enum mathPio2Lo = 6.12323399573676603587e-17;
enum mathPiHi = 3.14159265358979311600e+00;
enum mathPiLo = 1.22464679914735317720e-16;

// Uses asin(x) = pi/2 - 2 * asin(sqrt((1 - x) / 2)) above 0.5, so the polynomial only sees [0, 0.5].
double asin(double x) {
    if (x != x || x > 1 || x < -1) return double.nan;
    auto ax = fabs(x);
    if (ax <= 0.5) return mathAsinPoly(x);
    auto s = sqrt((1.0 - ax) * 0.5);
    auto r = mathPio2Hi - (2.0 * mathAsinPoly(s) - mathPio2Lo);
    return x < 0 ? -r : r;
}

float asinf(float x) {
    if (x != x || x > 1 || x < -1) return float.nan;
    double ax = fabs(x);
    if (ax <= 0.5) return cast(float) mathAsinPolyF(x);
    auto s = sqrt((1.0 - ax) * 0.5);
    auto r = M_PI_2 - 2.0 * mathAsinPolyF(s);
    return cast(float) (x < 0 ? -r : r);
}

double acos(double x) {
    if (x != x || x > 1 || x < -1) return double.nan;
    if (fabs(x) <= 0.5) return mathPio2Hi - (mathAsinPoly(x) - mathPio2Lo);
    if (x > 0) return 2.0 * mathAsinPoly(sqrt((1.0 - x) * 0.5));
    return mathPiHi - (2.0 * mathAsinPoly(sqrt((1.0 + x) * 0.5)) - mathPiLo);
}

float acosf(float x) {
    if (x != x || x > 1 || x < -1) return float.nan;
    double dx = x;
    if (fabs(dx) <= 0.5) return cast(float) (M_PI_2 - mathAsinPolyF(dx));
    if (dx > 0) return cast(float) (2.0 * mathAsinPolyF(sqrt((1.0 - dx) * 0.5)));
    return cast(float) (M_PI - 2.0 * mathAsinPolyF(sqrt((1.0 + dx) * 0.5)));
}

double trunc(double x) {
    if (!(fabs(x) < 0x1p52)) return x;
    auto truncated = cast(double) cast(long) x;
    if (truncated == 0 && mathSignBit(x)) return -0.0;
    return truncated;
}

float truncf(float x) {
    if (!(fabsf(x) < 8388608.0f)) return x;
    auto truncated = cast(float) cast(int) x;
    if (truncated == 0 && mathSignBit(x)) return -0.0f;
    return truncated;
}

// Rounds to nearest, ties to even.
double rint(double x) {
    if (!(fabs(x) < 0x1p52)) return x;
    auto big = mathSignBit(x) ? -0x1p52 : 0x1p52;
    auto result = (x + big) - big; // Adding 2^52 pushes the fraction out, and the addition rounds it for us.
    if (result == 0 && mathSignBit(x)) return -0.0;
    return result;
}

float rintf(float x) {
    if (!(fabsf(x) < 8388608.0f)) return x;
    auto big = mathSignBit(x) ? -8388608.0f : 8388608.0f;
    auto result = (x + big) - big;
    if (result == 0 && mathSignBit(x)) return -0.0f;
    return result;
}

// Out of range values and NaN return the minimum value, like most C libraries.
private CLong mathToCLong(double x) {
    enum limit = cast(double) (1UL << (CLong.sizeof * 8 - 1));
    if (!(x >= -limit && x < limit)) return CLong.min;
    return cast(CLong) x;
}

private long mathToLong(double x) {
    if (!(x >= -0x1p63 && x < 0x1p63)) return long.min;
    return cast(long) x;
}

CLong lround(double x) {
    return mathToCLong(round(x));
}

CLong lroundf(float x) {
    return mathToCLong(roundf(x));
}

long llround(double x) {
    return mathToLong(round(x));
}

long llroundf(float x) {
    return mathToLong(roundf(x));
}

CLong lrint(double x) {
    return mathToCLong(rint(x));
}

CLong lrintf(float x) {
    return mathToCLong(rintf(x));
}

long llrint(double x) {
    return mathToLong(rint(x));
}

long llrintf(float x) {
    return mathToLong(rintf(x));
}

// NaN loses against numbers, and -0 counts as smaller than +0.
double fmin(double x, double y) {
    if (x != x) return y;
    if (y != y) return x;
    if (x == y) return mathSignBit(x) ? x : y;
    return x < y ? x : y;
}

float fminf(float x, float y) {
    if (x != x) return y;
    if (y != y) return x;
    if (x == y) return mathSignBit(x) ? x : y;
    return x < y ? x : y;
}

double fmax(double x, double y) {
    if (x != x) return y;
    if (y != y) return x;
    if (x == y) return mathSignBit(x) ? y : x;
    return x > y ? x : y;
}

float fmaxf(float x, float y) {
    if (x != x) return y;
    if (y != y) return x;
    if (x == y) return mathSignBit(x) ? y : x;
    return x > y ? x : y;
}

double copysign(double x, double y) {
    ulong bits = ((*cast(ulong*) &x) & 0x7FFF_FFFF_FFFF_FFFFUL) | ((*cast(ulong*) &y) & 0x8000_0000_0000_0000UL);
    return *cast(double*) &bits;
}

float copysignf(float x, float y) {
    uint bits = ((*cast(uint*) &x) & 0x7FFF_FFFFU) | ((*cast(uint*) &y) & 0x8000_0000U);
    return *cast(float*) &bits;
}

double hypot(double x, double y) {
    if (mathIsInf(x) || mathIsInf(y)) return double.infinity; // Even when the other one is NaN.
    if (x != x || y != y) return double.nan;
    auto ax = fabs(x);
    auto ay = fabs(y);
    auto big = ax > ay ? ax : ay;

    // Scale by a power of 2 (exact) so the squares can't overflow or underflow.
    auto scale = 1.0;
    if (big > 0x1p500) {
        ax *= 0x1p-600;
        ay *= 0x1p-600;
        scale = 0x1p600;
    } else if (big < 0x1p-500) {
        ax *= 0x1p600;
        ay *= 0x1p600;
        scale = 0x1p-600;
    }
    return scale * sqrt(ax * ax + ay * ay);
}

float hypotf(float x, float y) {
    if (mathIsInf(x) || mathIsInf(y)) return float.infinity;
    double dx = x;
    double dy = y;
    return cast(float) sqrt(dx * dx + dy * dy); // Float squares always fit in a double.
}

double ldexp(double x, int exp) {
    if (exp > 2200) exp = 2200; // Anything past this is already infinity or zero.
    if (exp < -2200) exp = -2200;
    return mathScale(x, exp);
}

float ldexpf(float x, int exp) {
    return cast(float) ldexp(x, exp);
}

double scalbn(double x, int exp) {
    return ldexp(x, exp);
}

float scalbnf(float x, int exp) {
    return cast(float) ldexp(x, exp);
}

// Splits x into m * 2^exp, with |m| in [0.5, 1).
double frexp(double x, int* exp) {
    if (x == 0 || x != x || mathIsInf(x)) {
        *exp = 0;
        return x;
    }
    auto e = 0;
    if (fabs(x) < 0x1p-1022) { x *= 0x1p54; e = -54; } // Subnormals.
    ulong bits = *cast(ulong*) &x;
    e += cast(int) ((bits >> 52) & 0x7FF) - 1022;
    bits = (bits & 0x800F_FFFF_FFFF_FFFFUL) | (1022UL << 52);
    *exp = e;
    return *cast(double*) &bits;
}

float frexpf(float x, int* exp) {
    return cast(float) frexp(x, exp);
}

// Splits x into integer and fraction parts. Both keep the sign of x.
double modf(double x, double* iptr) {
    auto integer = trunc(x);
    *iptr = integer;
    if (mathIsInf(x)) return copysign(0.0, x);
    return copysign(x - integer, x);
}

float modff(float x, float* iptr) {
    auto integer = truncf(x);
    *iptr = integer;
    if (mathIsInf(x)) return copysignf(0.0f, x);
    return copysignf(x - integer, x);
}

// x * y + z computed exactly in two parts (Dekker for the product, Knuth for the sum), then rounded.
// Needs |x| and |y| in [2^-400, 2^400], so the splitting can't overflow or underflow.
private double mathFmaCore(double x, double y, double z) {
    enum splitter = 134217729.0; // 2^27 + 1.
    auto product = x * y;
    auto t = x * splitter;
    auto xHi = t - (t - x);
    auto xLo = x - xHi;
    t = y * splitter;
    auto yHi = t - (t - y);
    auto yLo = y - yHi;
    auto productError = ((xHi * yHi - product) + xHi * yLo + xLo * yHi) + xLo * yLo;

    auto sum = product + z;
    if (mathIsInf(sum)) return sum;
    auto v = sum - product;
    auto sumError = (product - (sum - v)) + (z - v);
    return sum + (sumError + productError);
}

// There is no fma instruction in core wasm, so this is done in software.
double fma(double x, double y, double z) {
    if (mathIsInf(z) && !mathIsInf(x) && !mathIsInf(y) && x == x && y == y) return z;
    if (x != x || y != y || z != z || mathIsInf(x) || mathIsInf(y) || mathIsInf(z)) return x * y + z;
    if (x == 0 || y == 0) return x * y + z;
    if (z == 0) return x * y;
    auto ax = fabs(x);
    auto ay = fabs(y);
    if (ax > 0x1p-400 && ax < 0x1p400 && ay > 0x1p-400 && ay < 0x1p400) return mathFmaCore(x, y, z);

    // Far from 1: work with the mantissas and scale back at the end.
    int ex = void;
    int ey = void;
    int ez = void;
    auto mx = frexp(x, &ex);
    auto my = frexp(y, &ey);
    frexp(z, &ez);
    auto e = ex + ey;
    if (ez - e > 110) return z; // x * y is too small to change z.
    return ldexp(mathFmaCore(mx, my, ldexp(z, -e)), e);
}

float fmaf(float x, float y, float z) {
    return cast(float) (cast(double) x * y + z); // The product of two floats is exact in a double.
}

double cbrt(double x) {
    if (x != x || x == 0 || mathIsInf(x)) return x;
    auto ax = fabs(x);
    auto scale = 1.0;
    if (ax < 0x1p-1022) { ax *= 0x1p54; scale = 0x1p-18; } // Subnormals.

    // Guess by dividing the exponent by 3, then Newton.
    ulong bits = (*cast(ulong*) &ax) / 3 + 0x2A9F_7893_782D_A1CEUL;
    auto y = *cast(double*) &bits;
    foreach (i; 0 .. 4) y = (2.0 * y + ax / (y * y)) * (1.0 / 3);
    y *= scale;
    return x < 0 ? -y : y;
}

float cbrtf(float x) {
    return cast(float) cbrt(x);
}

double sinh(double x) {
    if (x != x || mathIsInf(x)) return x;
    auto ax = fabs(x);
    if (ax < 0.5) {
        auto z = x * x;
        return x + x * z * (1.0 / 6 + z * (1.0 / 120 + z * (1.0 / 5040 + z * (1.0 / 362880
            + z * (1.0 / 39916800 + z * (1.0 / 6227020800 + z * (1.0 / 1307674368000)))))));
    }
    double result = void;
    if (ax < 22) {
        auto e = exp(ax);
        result = 0.5 * (e - 1.0 / e);
    } else {
        auto h = exp(0.5 * ax); // e^x / 2 as (e^(x/2) / 2) * e^(x/2), so it doesn't overflow too early.
        result = (0.5 * h) * h;
    }
    return x < 0 ? -result : result;
}

float sinhf(float x) {
    return cast(float) sinh(x);
}

double cosh(double x) {
    if (x != x) return x;
    auto ax = fabs(x);
    if (ax < 22) {
        auto e = exp(ax);
        return 0.5 * (e + 1.0 / e);
    }
    auto h = exp(0.5 * ax);
    return (0.5 * h) * h;
}

float coshf(float x) {
    return cast(float) cosh(x);
}

double tanh(double x) {
    if (x != x) return x;
    auto ax = fabs(x);
    double result = void;
    if (ax > 22) {
        result = 1.0;
    } else if (ax < 0.5) {
        result = sinh(ax) / cosh(ax);
    } else {
        auto e = exp(2.0 * ax);
        result = 1.0 - 2.0 / (e + 1.0);
    }
    return mathSignBit(x) ? -result : result;
}

float tanhf(float x) {
    return cast(float) tanh(x);
}

// log(1 + u) without losing precision for small u (Kahan's trick).
private double log1pPrecise(double u) {
    double w = 1 + u;
    if (w == 1) return u;
    return log(w) * (u / (w - 1));
}

// Inverse hyperbolic functions. Invalid inputs return -NaN, like glibc.
double asinh(double x) {
    double a = fabs(x);
    if (a != a || a == double.infinity) return x;
    double r = a > 0x1p28
        ? log(a) + 0.6931471805599453 // sqrt(a*a + 1) == a here, and a*a could overflow
        : log1pPrecise(a + a * a / (1 + sqrt(1 + a * a)));
    return copysign(r, x);
}

float asinhf(float x) {
    return cast(float) asinh(x);
}

double acosh(double x) {
    if (x != x) return x;
    if (x < 1) return -double.nan;
    if (x == double.infinity) return x;
    if (x > 0x1p28) return log(x) + 0.6931471805599453;
    double t = x - 1;
    return log1pPrecise(t + sqrt(t * (t + 2)));
}

float acoshf(float x) {
    return cast(float) acosh(x);
}

double atanh(double x) {
    double a = fabs(x);
    if (a != a) return x;
    if (a > 1) return -double.nan;
    if (a == 1) return copysign(double.infinity, x);
    return copysign(0.5 * log1pPrecise(2 * a / (1 - a)), x);
}

float atanhf(float x) {
    return cast(float) atanh(x);
}

void roundl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(round(f128ToDouble(aLo, aHi)));
}

void floorl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(floor(f128ToDouble(aLo, aHi)));
}

void ceill(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(ceil(f128ToDouble(aLo, aHi)));
}

void sinl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(sin(f128ToDouble(aLo, aHi)));
}

void cosl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(cos(f128ToDouble(aLo, aHi)));
}

void tanl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(tan(f128ToDouble(aLo, aHi)));
}

void atanl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(atan(f128ToDouble(aLo, aHi)));
}

void logl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(log(f128ToDouble(aLo, aHi)));
}

void expl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(exp(f128ToDouble(aLo, aHi)));
}

void fabsl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(fabs(f128ToDouble(aLo, aHi)));
}

void sqrtl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(sqrt(f128ToDouble(aLo, aHi)));
}

void truncl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(trunc(f128ToDouble(aLo, aHi)));
}

void rintl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(rint(f128ToDouble(aLo, aHi)));
}

void asinl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(asin(f128ToDouble(aLo, aHi)));
}

void acosl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(acos(f128ToDouble(aLo, aHi)));
}

void log2l(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(log2(f128ToDouble(aLo, aHi)));
}

void log10l(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(log10(f128ToDouble(aLo, aHi)));
}

void exp2l(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(exp2(f128ToDouble(aLo, aHi)));
}

void cbrtl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(cbrt(f128ToDouble(aLo, aHi)));
}

void sinhl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(sinh(f128ToDouble(aLo, aHi)));
}

void coshl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(cosh(f128ToDouble(aLo, aHi)));
}

void tanhl(F128* result, ulong aLo, ulong aHi) {
    *result = doubleToF128(tanh(f128ToDouble(aLo, aHi)));
}

void powl(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(pow(f128ToDouble(aLo, aHi), f128ToDouble(bLo, bHi)));
}

void atan2l(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(atan2(f128ToDouble(aLo, aHi), f128ToDouble(bLo, bHi)));
}

void fmodl(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(fmod(f128ToDouble(aLo, aHi), f128ToDouble(bLo, bHi)));
}

void remainderl(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(remainder(f128ToDouble(aLo, aHi), f128ToDouble(bLo, bHi)));
}

void hypotl(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(hypot(f128ToDouble(aLo, aHi), f128ToDouble(bLo, bHi)));
}

void copysignl(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(copysign(f128ToDouble(aLo, aHi), f128ToDouble(bLo, bHi)));
}

void fminl(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(fmin(f128ToDouble(aLo, aHi), f128ToDouble(bLo, bHi)));
}

void fmaxl(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(fmax(f128ToDouble(aLo, aHi), f128ToDouble(bLo, bHi)));
}

void fmal(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi, ulong cLo, ulong cHi) {
    *result = doubleToF128(fma(f128ToDouble(aLo, aHi), f128ToDouble(bLo, bHi), f128ToDouble(cLo, cHi)));
}

void ldexpl(F128* result, ulong aLo, ulong aHi, int n) {
    *result = doubleToF128(ldexp(f128ToDouble(aLo, aHi), n));
}

void scalbnl(F128* result, ulong aLo, ulong aHi, int n) {
    *result = doubleToF128(scalbn(f128ToDouble(aLo, aHi), n));
}

void frexpl(F128* result, ulong aLo, ulong aHi, int* exp) {
    *result = doubleToF128(frexp(f128ToDouble(aLo, aHi), exp));
}

void modfl(F128* result, ulong aLo, ulong aHi, F128* iptr) {
    double ip = void;
    *result = doubleToF128(modf(f128ToDouble(aLo, aHi), &ip));
    *iptr = doubleToF128(ip);
}

long llroundl(ulong aLo, ulong aHi) {
    return llround(f128ToDouble(aLo, aHi));
}

long llrintl(ulong aLo, ulong aHi) {
    return llrint(f128ToDouble(aLo, aHi));
}

@wasi @importName("fd_write")
int fd_write(int fd, const(Ciovec)* iovs, size_t iovs_len, size_t* nwritten);

@wasi @importName("proc_exit")
noreturn proc_exit(int code);

@wasi @importName("clock_res_get")
int clock_res_get(int clockId, ulong* resolution);

@wasi @importName("clock_time_get")
int clock_time_get(int clockId, ulong precision, ulong* time);

// ---------------------------------------------------------------------
// !!! AI SLOP !!!
// Fake IEEE754 binary128 ("real"/quad) support, backed by real doubles.
//
// We do NOT implement true 128-bit precision — every value that flows
// through these functions carries no more precision than a double
// already has. We only need a correctly-shaped 128-bit container so
// that compile-time `real` constants (which LLVM computes with true
// full precision and bakes into the binary as genuine IEEE754 binary128
// bit patterns) still get read correctly when your code touches them.
//
// LIMITATIONS (deliberate, see message this came with):
//  - subnormal doubles are flushed to zero on conversion
//  - truncation rounds toward zero, not round-to-nearest-even
// Both are irrelevant for values that started life as ordinary doubles
// (the normal case for this program) — only matters for high-precision
// `1.234567890123456789L`-style literals, which this program doesn't use.
// ---------------------------------------------------------------------

struct F128 { ulong lo; ulong hi; }

private double f128ToDouble(ulong lo, ulong hi) {
    ulong sign = (hi >> 63) & 1;
    ulong exp = (hi >> 48) & 0x7FFF;
    ulong mantHi = hi & 0xFFFF_FFFF_FFFF; // top 48 bits of the 112-bit mantissa

    ulong dBits;
    if (exp == 0 && mantHi == 0 && lo == 0) {
        dBits = sign << 63; // signed zero
    } else if (exp == 0x7FFF) {
        bool isNan = mantHi != 0 || lo != 0;
        dBits = (sign << 63) | (0x7FFUL << 52) | (isNan ? ((mantHi << 4) | 1) : 0);
    } else {
        long unbiased = cast(long) exp - 16383;
        long dExpBiased = unbiased + 1023;
        if (dExpBiased >= 0x7FF) {
            dBits = (sign << 63) | (0x7FFUL << 52); // overflow -> infinity
        } else if (dExpBiased <= 0) {
            dBits = sign << 63; // underflow -> flush to zero (see limitation above)
        } else {
            ulong dMant = (mantHi << 4) & 0xF_FFFF_FFFF_FFFF;
            dBits = (sign << 63) | (cast(ulong) dExpBiased << 52) | dMant;
        }
    }
    return *cast(double*) &dBits;
}

private F128 doubleToF128(double d) {
    ulong bits = *cast(ulong*) &d;
    ulong sign = (bits >> 63) & 1;
    ulong exp = (bits >> 52) & 0x7FF;
    ulong mant = bits & 0xF_FFFF_FFFF_FFFF;

    F128 r;
    if (exp == 0) {
        // zero AND subnormal doubles both flushed to zero (see limitation above)
        r.hi = sign << 63;
        r.lo = 0;
    } else if (exp == 0x7FF) {
        r.hi = (sign << 63) | (0x7FFFUL << 48) | (mant >> 4);
        r.lo = mant << 60;
    } else {
        long unbiased = cast(long) exp - 1023;
        ulong newExp = cast(ulong) (unbiased + 16383);
        r.hi = (sign << 63) | (newExp << 48) | (mant >> 4);
        r.lo = mant << 60;
    }
    return r;
}

private int f128Cmp3(ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    double da = f128ToDouble(aLo, aHi), db = f128ToDouble(bLo, bHi);
    if (da != da || db != db) return 2; // unordered (NaN involved)
    if (da < db) return -1;
    if (da > db) return 1;
    return 0;
}

void __extenddftf2(F128* result, double a) {
    *result = doubleToF128(a);
}

double __trunctfdf2(ulong aLo, ulong aHi) {
    return f128ToDouble(aLo, aHi);
}

void __addtf3(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(f128ToDouble(aLo, aHi) + f128ToDouble(bLo, bHi));
}

void __subtf3(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(f128ToDouble(aLo, aHi) - f128ToDouble(bLo, bHi));
}

void __multf3(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(f128ToDouble(aLo, aHi) * f128ToDouble(bLo, bHi));
}

void __divtf3(F128* result, ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    *result = doubleToF128(f128ToDouble(aLo, aHi) / f128ToDouble(bLo, bHi));
}

int __eqtf2(ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    return f128Cmp3(aLo, aHi, bLo, bHi) == 0 ? 0 : 1;
}

int __netf2(ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    return f128Cmp3(aLo, aHi, bLo, bHi) == 0 ? 0 : 1;
}

int __unordtf2(ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    return f128Cmp3(aLo, aHi, bLo, bHi) == 2 ? 1 : 0;
}

int __lttf2(ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    auto c = f128Cmp3(aLo, aHi, bLo, bHi);
    return c == -1 ? -1 : 1;
}

int __letf2(ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    auto c = f128Cmp3(aLo, aHi, bLo, bHi);
    return (c == -1 || c == 0) ? c : 1;
}

int __gttf2(ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    auto c = f128Cmp3(aLo, aHi, bLo, bHi);
    return c == 1 ? 1 : -1;
}

int __getf2(ulong aLo, ulong aHi, ulong bLo, ulong bHi) {
    auto c = f128Cmp3(aLo, aHi, bLo, bHi);
    return (c == 1 || c == 0) ? c : -1;
}

void __floatsitf(F128* result, int a) {
    *result = doubleToF128(cast(double) a);
}

void __floatditf(F128* result, long a) {
    *result = doubleToF128(cast(double) a);
}

void __floatunsitf(F128* result, uint a) {
    *result = doubleToF128(cast(double) a);
}

void __floatunditf(F128* result, ulong a) {
    *result = doubleToF128(cast(double) a);
}

int __fixtfsi(ulong aLo, ulong aHi) {
    return cast(int) f128ToDouble(aLo, aHi);
}

long __fixtfdi(ulong aLo, ulong aHi) {
    return cast(long) f128ToDouble(aLo, aHi);
}

long __fixunstfdi(ulong aLo, ulong aHi) {
    return cast(long) cast(ulong) f128ToDouble(aLo, aHi);
}

void __extendsftf2(F128* result, float a) {
    *result = doubleToF128(cast(double) a);
}

float __trunctfsf2(ulong aLo, ulong aHi) {
    return cast(float) f128ToDouble(aLo, aHi);
}

uint __fixunstfsi(ulong aLo, ulong aHi) {
    return cast(uint) f128ToDouble(aLo, aHi);
}
