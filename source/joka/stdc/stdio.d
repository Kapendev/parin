// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

module joka.stdc.stdio;

import joka.stdc.config;

extern(C) nothrow @nogc:

struct FILE;

enum SEEK_SET = 0;
enum SEEK_CUR = 1;
enum SEEK_END = 2;

enum STDIN_FILENO  = 0;
enum STDOUT_FILENO = 1;
enum STDERR_FILENO = 2;

// NOTE: Code from the D standard library.
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
CLong ftell(FILE* stream);
int fseek(FILE* stream, CLong offset, int origin);
size_t fread(void* ptr, size_t size, size_t count, FILE* stream);
int fclose(FILE* stream);
int fputs(const(char)* str, FILE* stream);
size_t fwrite(const(void)* buffer, size_t size, size_t count, FILE* stream);
int ferror(FILE* stream);

int printf(const(char)* format, ...);
int fprintf(FILE* stream, const(char)* format, ...);
int sprintf(char* buffer, const(char)* format, ...);
int snprintf(char* buffer, size_t bufsz, const(char)* format, ...);
