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
void readText(const(char)[] path, ref List!char text) {
    auto f = io.fopen(toStrz(path), "rb");
    if (f == null) {
        text.clear();
        return;
    }
    if (io.fseek(f, 0, io.SEEK_END) != 0) {
        io.fclose(f);
        text.clear();
        return;
    }

    auto fsize = io.ftell(f);
    if (fsize == -1) {
        io.fclose(f);
        text.clear();
        return;
    }
    if (io.fseek(f, 0, io.SEEK_SET) != 0) {
        io.fclose(f);
        text.clear();
        return;
    }

    text.resize(fsize);
    io.fread(text.items.ptr, fsize, 1, f);
    io.fclose(f);
}

List!char readText(const(char)[] path) {
    List!char result;
    readText(path, result);
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
                        static if (isIntegerType!(typeof(member))) {
                            auto conv = toSigned(value);
                        } else static if (isDoubleType!(typeof(member))) {
                            auto conv = toDouble(value);
                        } else {
                            static assert(0, "The 'readConfig' function does not handle the '" ~ typeof(member).toString ~ "' type.");
                        }
                        if (conv.error) {
                            println("Line ", lineNumber, ": Can not parse value.");
                        } else {
                            mixin("arg.", member.stringof, "= cast(typeof(member)) conv.value;");
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
