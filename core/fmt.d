// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The fmt module simplifies value formatting,
/// enabling conversion of data to strings and providing control over output appearance.

module popka.core.fmt;

import io = core.stdc.stdio;
import popka.core.strconv;

@safe @nogc nothrow:

const(char)[] fmt(A...)(const(char)[] str, A args) {
    static char[1024][4] bufs = void;
    static auto bufi = 0;

    bufi = (bufi + 1) % bufs.length;
    auto result = bufs[bufi][];
    auto resi = 0;
    auto stri = 0;
    auto argi = 0;

    while (stri < str.length) {
        auto c1 = str[stri];
        auto c2 = stri + 1 >= str.length ? '+' : str[stri + 1];
        if (c1 == '{' && c2 == '}' && argi < args.length) {
            static foreach (i, arg; args) {
                if (i == argi) {
                    auto temp = toStr(arg);
                    foreach (i, c; temp) {
                        result[resi + i] = c;
                    }
                    resi += temp.length;
                    stri += 2;
                    argi += 1;
                    goto exitLoopEarly;
                }
            }
            exitLoopEarly:
        } else {
            result[resi] = c1;
            resi += 1;
            stri += 1;
        }
    }
    result = result[0 .. resi];
    return result;
}

@trusted
void printf(A...)(const(char)[] str, A args) {
    io.fputs(fmt("{}\0", fmt(str, args)).ptr, io.stdout);
}

@trusted
void printfln(A...)(const(char)[] str, A args) {
    io.fputs(fmt("{}\n\0", fmt(str, args)).ptr, io.stdout);
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

unittest {
    assert(fmt("") == "");
    assert(fmt("{}") == "{}");
    assert(fmt("{}", "1") == "1");
    assert(fmt("{} {}", "1", "2") == "1 2");
    assert(fmt("{} {} {}", "1", "2", "3") == "1 2 3");
    assert(fmt("{} {} {}", 1, -2, 3.69) == "1 -2 3.69");
    assert(fmt("{}", 420, 320, 220, 120, 20) == "420");
    assert(fmt("", 1, -2, 3.69) == "");
    assert(fmt("({})", fmt("({}, {})", false, true)) == "((false, true))");
}
