// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The io module facilitates input and output operations,
/// offering functionalities such as file reading and writing.

module popka.core.io;

import io = core.stdc.stdio;
import popka.core.container;
import popka.core.strutils;
import popka.core.traits;

@safe @nogc nothrow:

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

@trusted
List!char readText(const(char)[] path) {
    auto f = io.fopen(toStrz(path), "rb");
    if (f == null) {
        return List!char();
    }
    if (io.fseek(f, 0, io.SEEK_END) != 0) {
        io.fclose(f);
        return List!char();
    }

    auto fsize = io.ftell(f);
    if (fsize == -1) {
        io.fclose(f);
        return List!char();
    }
    if (io.fseek(f, 0, io.SEEK_SET) != 0) {
        io.fclose(f);
        return List!char();
    }

    auto result = List!char(fsize);
    io.fread(result.items.ptr, fsize, 1, f);
    io.fclose(f);
    return result;
}

@trusted
void writeText(const(char)[] path, List!char content) {
    auto f = io.fopen(toStrz(path), "w");
    if (f == null) {
        return;
    }
    content.append('\0');
    io.fputs(content.items.ptr, f);
    io.fclose(f);
    content.pop();
}

// TODO: Testing stuff to see how to make it easy to use.
T readConfig(T)(const(char)[] path) {
    auto result = T.init;
    auto file = readText(path);

    const(char)[] group = "";

    auto view = file.items;
    auto lineNumber = 0;
    while (view.length != 0) {
        auto line = skipLine(view).trim();
        lineNumber += 1;
        if (line.length == 0) {
            continue;
        }

        if (line[0] == '[' && line[$ - 1] == ']') {
            group = line[1 .. $ - 1];
            continue;
        }

        if (group == T.stringof) {
            auto separatorIndex = line.findStart('=');
            auto key = line[0 .. separatorIndex].trimEnd();
            auto value = line[separatorIndex + 1 .. $].trimStart();
            static foreach (member; T.tupleof) {
                if (key == member.stringof) {
                    static if (isIntegerType!(typeof(member))) {
                        auto conv = cast(typeof(member)) toSigned(value).value;
                        mixin("result.", member.stringof, "= conv", ";");
                        println(key, " -> ", conv);
                    }
                }
            }
        }
    }
    file.free();
    return result;
}
