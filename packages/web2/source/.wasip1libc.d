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
// They do nothing here. Think about it. Think.
extern(C) @trusted nothrow @nogc {
    alias QsortCompFunc = int function(const(void)* a, const(void)* b);
}

alias pthread_t           = size_t;
alias pthread_mutex_t     = void*;
alias pthread_cond_t      = void*;
alias pthread_mutexattr_t = void*;
alias pthread_condattr_t  = void*;

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
    } else {
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
    foreach (i; 0 .. count) (cast(ubyte*) dest)[i] = cast(ubyte) ch;
    return dest;
}

void* memcpy(void* dest, const(void)* src, size_t count) {
    foreach (i; 0 .. count) (cast(ubyte*) dest)[i] = (cast(ubyte*) src)[i];
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

void qsortRange(ubyte* ptr, size_t count, size_t size, QsortCompFunc comp) {
    if (count < 2 || size == 0) return;

    auto pivot = ptr + (count / 2) * size;
    foreach (k; 0 .. size) { auto t = ptr[k]; ptr[k] = pivot[k]; pivot[k] = t; }
    pivot = ptr;

    size_t i = 1;
    foreach (j; 1 .. count) {
        auto elem = ptr + j * size;
        if (comp(elem, pivot) < 0) {
            auto dest = ptr + i * size;
            foreach (k; 0 .. size) { auto t = dest[k]; dest[k] = elem[k]; elem[k] = t; }
            i += 1;
        }
    }
    auto last = ptr + (i - 1) * size;
    foreach (k; 0 .. size) { auto t = pivot[k]; pivot[k] = last[k]; last[k] = t; }

    qsortRange(ptr, i - 1, size, comp);
    qsortRange(ptr + i * size, count - i, size, comp);
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
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

int toupper(int c) {
    return (c >= 'a' && c <= 'z') ? c - 32 : c;
}

char* getenv(const(char)* name) {
    return null;
}

int clock_gettime(int clk, timespec* tp) {
    ulong nanos = void;
    if (clock_time_get(clk, 1, &nanos) != 0) return -1;
    tp.tv_sec  = cast(long) (nanos / 1_000_000_000UL);
    tp.tv_nsec = cast(long) (nanos % 1_000_000_000UL);
    return 0;
}

int clock_getres(int clk, timespec* res) {
    ulong resNanos = void;
    if (clock_res_get(clk, &resNanos) != 0) return -1;
    res.tv_sec  = cast(long) (resNanos / 1_000_000_000UL);
    res.tv_nsec = cast(long) (resNanos % 1_000_000_000UL);
    return 0;
}

tm* localtime_r(const(timespec)* timep, tm* result) {
    *result = tm();
    return result;
}

int sysconf(int name) {
    return -1;
}

real strtold(const(char)* nptr, char** endptr) {
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

int sched_yield() {
    return 0;
}

float floorf(float x) {
    if (x != x) return x;
    if (x == 0.0f || x == float.infinity || x == -float.infinity) return x;
    if (x >= 8388608.0f || x <= -8388608.0f) return x; // 2^23
    auto i = cast(int) x;
    auto truncated = cast(float) i;
    if (truncated > x) truncated -= 1.0f;
    return truncated;
}

double floor(double x) {
    if (x != x) return x;
    if (x == 0.0 || x == double.infinity || x == -double.infinity) return x;
    if (x >= 9007199254740992.0 || x <= -9007199254740992.0) return x;
    auto i = cast(long) x;
    auto truncated = cast(double) i;
    if (truncated > x) truncated -= 1.0;
    return truncated;
}

float sinf(float x) {
    auto turns = cast(int) (x / TWO_PI);
    x -= turns * TWO_PI;

    if (x > M_PI)  x -= TWO_PI;
    if (x < -M_PI) x += TWO_PI;

    auto x2 = x * x;
    auto term = x;
    auto sinX = x;

    term *= -x2 / (2.0f * 3.0f);
    sinX += term;
    term *= -x2 / (4.0f * 5.0f);
    sinX += term;
    term *= -x2 / (6.0f * 7.0f);
    sinX += term;

    return sinX;
}

double sin(double x) {
    auto turns = cast(int) (x / TWO_PI);
    x -= turns * TWO_PI;

    if (x > M_PI)  x -= TWO_PI;
    if (x < -M_PI) x += TWO_PI;

    auto x2 = x * x;
    auto term = x;
    auto sinX = x;

    term *= -x2 / (2.0 * 3.0);
    sinX += term;
    term *= -x2 / (4.0 * 5.0);
    sinX += term;
    term *= -x2 / (6.0 * 7.0);
    sinX += term;
    term *= -x2 / (8.0 * 9.0);
    sinX += term;
    term *= -x2 / (10.0 * 11.0);
    sinX += term;

    return sinX;
}

float cosf(float x) {
    auto turns = cast(int) (x / TWO_PI);
    x -= turns * TWO_PI;

    if (x > M_PI)  x -= TWO_PI;
    if (x < -M_PI) x += TWO_PI;

    auto x2 = x * x;
    auto term = 1.0f;
    auto cosX = 1.0f;

    term *= -x2 / (1.0f * 2.0f);
    cosX += term;
    term *= -x2 / (3.0f * 4.0f);
    cosX += term;
    term *= -x2 / (5.0f * 6.0f);
    cosX += term;
    term *= -x2 / (7.0f * 8.0f);
    cosX += term;
    term *= -x2 / (9.0f * 10.0f);
    cosX += term;

    return cosX;
}

double cos(double x) {
    auto turns = cast(int) (x / TWO_PI);
    x -= turns * TWO_PI;

    if (x > M_PI)  x -= TWO_PI;
    if (x < -M_PI) x += TWO_PI;

    auto x2 = x * x;
    auto term = 1.0;
    auto cosX = 1.0;

    term *= -x2 / (1.0 * 2.0);
    cosX += term;
    term *= -x2 / (3.0 * 4.0);
    cosX += term;
    term *= -x2 / (5.0 * 6.0);
    cosX += term;
    term *= -x2 / (7.0 * 8.0);
    cosX += term;
    term *= -x2 / (9.0 * 10.0);
    cosX += term;

    return cosX;
}

float tanf(float x)  {
    return sinf(x) / cosf(x);
}

double tan(double x) {
    return sin(x) / cos(x);
}

float fabsf(float x) {
    return x < 0 ? -x : x;
}

double fabs(double x) {
    return x < 0 ? -x : x;
}

float ceilf(float x) {
    auto f = floorf(x);
    return f == x ? f : f + 1.0f;
}

double ceil(double x) {
    auto f = floor(x);
    return f == x ? f : f + 1;
}

float roundf(float x) {
    return floorf(x + 0.5f);
}

double round(double x) {
    return floor(x + 0.5);
}

float atanf(float x) {
    if (x > 1.0f)  return M_PI_2 - atanf(1.0f / x);
    if (x < -1.0f) return -M_PI_2 - atanf(1.0f / x);
    auto x2 = x * x;
    auto term = x;
    auto res = x;
    term *= -x2 * 1.0f / 3.0f; res += term;
    term *= -x2 * 3.0f / 5.0f; res += term;
    term *= -x2 * 5.0f / 7.0f; res += term;
    return res;
}

double atan(double x) {
    if (x > 1.0)  return M_PI_2 - atan(1.0 / x);
    if (x < -1.0) return -M_PI_2 - atan(1.0 / x);
    auto x2 = x * x;
    auto term = x;
    auto res = x;
    term *= -x2 * 1.0 / 3.0; res += term;
    term *= -x2 * 3.0 / 5.0; res += term;
    term *= -x2 * 5.0 / 7.0; res += term;
    return res;
}

float logf(float x) {
    if (x <= 0) return float.nan;
    auto exp = 0;
    while (x >= 2.0f) { x *= 0.5f; exp++; }
    while (x < 1.0f)  { x *= 2.0f; exp--; }
    auto y = x - 1.0f;
    auto y2 = y * y;
    auto res = y - y2 * 0.5f;
    auto term = y2 * y;
    res += term / 3.0f;
    term *= y; res -= term / 4.0f;
    term *= y; res += term / 5.0f;
    return res + exp * M_LN2;
}

double log(double x) {
    if (x <= 0) return double.nan;
    auto exp = 0;
    while (x >= 2.0) { x *= 0.5; exp++; }
    while (x < 1.0)  { x *= 2.0; exp--; }
    auto y = x - 1.0;
    auto y2 = y * y;
    auto res = y - y2 * 0.5;
    auto term = y2 * y;
    res += term / 3.0;
    term *= y; res -= term / 4.0;
    term *= y; res += term / 5.0;
    return res + exp * M_LN2;
}

float expf(float x) {
    auto n = cast(int) (x * M_LOG2E);
    auto f = x - n * M_LN2;
    auto res = 1.0f + f;
    auto term = f;
    term *= f / 2.0f; res += term;
    term *= f / 3.0f; res += term;
    term *= f / 4.0f; res += term;
    term *= f / 5.0f; res += term;
    if (n > 0) foreach (i; 0 .. n) res *= 2.0f;
    else       foreach (i; 0 .. -n) res *= 0.5f;
    return res;
}

double exp(double x) {
    auto n = cast(int) (x * M_LOG2E);
    auto f = x - n * M_LN2;
    auto res = 1.0 + f;
    auto term = f;
    term *= f / 2.0; res += term;
    term *= f / 3.0; res += term;
    term *= f / 4.0; res += term;
    term *= f / 5.0; res += term;
    if (n > 0) foreach (i; 0 .. n) res *= 2.0;
    else       foreach (i; 0 .. -n) res *= 0.5;
    return res;
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
