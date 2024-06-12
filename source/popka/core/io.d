// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The io module facilitates input and output operations,
/// offering functionalities such as file reading and writing.

module popka.core.io;

import popka.core.container;
import popka.core.stdc;
import popka.core.strutils;
import popka.core.traits;

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
// Does not do any error checking for now and works only with booleans, integers and floats.
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
