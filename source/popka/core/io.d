// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The io module facilitates input and output operations,
/// offering functionalities such as file reading and writing.

module popka.core.io;

import popka.core.container;
import popka.core.strutils;
import popka.core.traits;

// NOTE: Maybe all of this could go inside a module.
private {
    enum SEEK_SET = 0;
    enum SEEK_CUR = 1;
    enum SEEK_END = 2;

    enum STDIN_FILENO  = 0;
    enum STDOUT_FILENO = 1;
    enum STDERR_FILENO = 2;

    alias FILE = void;

    // NOTE: Might be a bad idea.
    version (WebAssembly) {
        alias c_long = int;
    } else {
        alias c_long = long;
    }

    @system @nogc nothrow extern(C):

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
        pragma(msg, "popka.core.io: Unsupported platform.");
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
}

@safe @nogc nothrow:

@trusted
void printf(A...)(const(char)[] str, A args) {
    .fputs(fmt("{}\0", fmt(str, args)).ptr, .stdout);
}

@trusted
void printfln(A...)(const(char)[] str, A args) {
    .fputs(fmt("{}\n\0", fmt(str, args)).ptr, .stdout);
}

void print(A...)(A args) {
    static foreach (arg; args) {
        printf("{}", arg);
    }
}

void println(A...)(A args) {
    static foreach (arg; args) {
        printf("{}", arg);
    }
    printf("\n");
}

@trusted
void readText(const(char)[] path, ref List!char text) {
    auto f = .fopen(toStrz(path), "rb");
    if (f == null) {
        text.clear();
        return;
    }
    if (.fseek(f, 0, .SEEK_END) != 0) {
        .fclose(f);
        text.clear();
        return;
    }

    auto fsize = .ftell(f);
    if (fsize == -1) {
        .fclose(f);
        text.clear();
        return;
    }
    if (.fseek(f, 0, .SEEK_SET) != 0) {
        .fclose(f);
        text.clear();
        return;
    }

    text.resize(cast(size_t) fsize);
    .fread(text.items.ptr, cast(size_t) fsize, 1, f);
    .fclose(f);
}

List!char readText(const(char)[] path) {
    List!char result;
    readText(path, result);
    return result;
}

@trusted
void writeText(const(char)[] path, List!char content) {
    auto f = .fopen(toStrz(path), "w");
    if (f == null) {
        return;
    }
    content.append('\0');
    .fputs(content.items.ptr, f);
    .fclose(f);
    content.pop();
}

// TODO: See what works.
// NOTE: Testing stuff to see how to make it easy to use.
// NOTE: Does not do any error checking for now.
void readConfig(A...)(const(char)[] path, ref A args) {
    auto file = readText(path);
    auto group = cast(const(char)[]) "";
    auto lineNumber = 0;
    auto view = file.items;
    while (view.length != 0) {
        auto line = skipLine(view).trim();
        lineNumber += 1;
        if (line.length == 0) {
            continue;
        }
        if (line[0] == '[' && line[$ - 1] == ']') {
            group = line[1 .. $ - 1];
            continue;
        } else if (line[0] == '#' || line[0] == ';') {
            continue;
        }

        static foreach (arg; args) {
            if (group == typeof(arg).stringof) {
                auto separatorIndex = line.findStart('=');
                auto key = line[0 .. separatorIndex].trimEnd();
                auto value = line[separatorIndex + 1 .. $].trimStart();
                static foreach (member; arg.tupleof) {
                    if (key == member.stringof) {
                        auto target = typeof(member).init;
                        static if (isIntegerType!(typeof(member))) {
                            auto conv = toSigned(value);
                            if (conv.error) {
                                println("Line ", lineNumber, ": Can not parse value.");
                            } else {
                                target = cast(typeof(member)) conv.value;
                            }
                            mixin("arg.", member.stringof, "= target;");
                        } else static if (isDoubleType!(typeof(member))) {
                            auto conv = toDouble(value);
                            if (conv.error) {
                                println("Line ", lineNumber, ": Can not parse value.");
                            } else {
                                target = cast(typeof(member)) conv.value;
                            }
                            mixin("arg.", member.stringof, "= target;");
                        } else static if (isBoolType!(typeof(member))) {
                            auto conv = toBool(value);
                            if (conv.error) {
                                println("Line ", lineNumber, ": Can not parse value.");
                            } else {
                                target = cast(typeof(member)) conv.value;
                            }
                            mixin("arg.", member.stringof, "= target;");
                        }
                    }
                }
                goto loopExit;
            }
        } 
        loopExit:
    }
    file.free();
}
