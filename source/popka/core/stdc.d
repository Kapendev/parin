// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The stdc module provides access to C standard library functions and types.

module popka.core.stdc;

@nogc nothrow extern(C):

// types

// NOTE: Might be a bad idea. We care about Windows, MacOS, Linux and Web for now.
version (WebAssembly) {
    alias c_long = int;
} else {
    alias c_long = long;
}

// math.h

float sqrtf(float x);
float sinf(float x);
float cosf(float x);

// stdlib.h

void* malloc(void* ptr, size_t size);
void* realloc(void* ptr, size_t size);
void free(void* ptr);

// stdio.h

enum SEEK_SET = 0;
enum SEEK_CUR = 1;
enum SEEK_END = 2;

enum STDIN_FILENO  = 0;
enum STDOUT_FILENO = 1;
enum STDERR_FILENO = 2;

alias FILE = void;

// NOTE: Code from D std.
version (CRuntime_Microsoft) {
    FILE* __acrt_iob_func(int hnd);     // VS2015+, reimplemented in msvc.d for VS2013-
    FILE* stdin()() { return __acrt_iob_func(0); }
    FILE* stdout()() { return __acrt_iob_func(1); }
    FILE* stderr()() { return __acrt_iob_func(2); }
} else version (CRuntime_Glibc) {
    extern __gshared FILE* stdin;
    extern __gshared FILE* stdout;
    extern __gshared FILE* stderr;
} else version (Darwin) {
    extern __gshared FILE* __stdinp;
    extern __gshared FILE* __stdoutp;
    extern __gshared FILE* __stderrp;

    alias __stdinp  stdin;
    alias __stdoutp stdout;
    alias __stderrp stderr;
} else version (FreeBSD) {
    extern __gshared FILE* __stdinp;
    extern __gshared FILE* __stdoutp;
    extern __gshared FILE* __stderrp;

    alias __stdinp  stdin;
    alias __stdoutp stdout;
    alias __stderrp stderr;
} else version (NetBSD) {
    extern __gshared FILE[3] __sF;

    auto __stdin()() { return &__sF[0]; }
    auto __stdout()() { return &__sF[1]; }
    auto __stderr()() { return &__sF[2]; }

    alias __stdin stdin;
    alias __stdout stdout;
    alias __stderr stderr;
} else version (OpenBSD) {
    extern __gshared FILE[3] __sF;

    auto __stdin()() { return &__sF[0]; }
    auto __stdout()() { return &__sF[1]; }
    auto __stderr()() { return &__sF[2]; }

    alias __stdin stdin;
    alias __stdout stdout;
    alias __stderr stderr;
} else version (DragonFlyBSD) {
    extern __gshared FILE* __stdinp;
    extern __gshared FILE* __stdoutp;
    extern __gshared FILE* __stderrp;

    alias __stdinp  stdin;
    alias __stdoutp stdout;
    alias __stderrp stderr;
} else version (Solaris) {
    extern __gshared FILE[_NFILE] __iob;

    auto stdin()() { return &__iob[0]; }
    auto stdout()() { return &__iob[1]; }
    auto stderr()() { return &__iob[2]; }
} else version (CRuntime_Bionic) {
    extern __gshared FILE[3] __sF;

    auto stdin()() { return &__sF[0]; }
    auto stdout()() { return &__sF[1]; }
    auto stderr()() { return &__sF[2]; }
} else version (CRuntime_Musl) {
    extern __gshared FILE* stdin;
    extern __gshared FILE* stdout;
    extern __gshared FILE* stderr;
} else version (CRuntime_Newlib) {
    __gshared struct _reent {
        int _errno;
        __sFILE* _stdin;
        __sFILE* _stdout;
        __sFILE* _stderr;
    }

    _reent* __getreent();

    pragma(inline, true) {
        auto stdin()() { return __getreent()._stdin; }
        auto stdout()() { return __getreent()._stdout; }
        auto stderr()() { return __getreent()._stderr; }
    }
} else version (CRuntime_UClibc) {
    extern __gshared FILE* stdin;
    extern __gshared FILE* stdout;
    extern __gshared FILE* stderr;
} else version (WASI) {
    extern __gshared FILE* stdin;
    extern __gshared FILE* stdout;
    extern __gshared FILE* stderr;
} else {
    extern __gshared FILE* stdin;
    extern __gshared FILE* stdout;
    extern __gshared FILE* stderr;
}

FILE* fopen(const(char)* filename, const(char)* mode);
c_long ftell(FILE* stream);
int fseek(FILE* stream, c_long offset, int origin);
size_t fread(void* ptr, size_t size, size_t count, FILE* stream);
int fclose(FILE* stream);
int fputs(const(char)* str, FILE* stream);
