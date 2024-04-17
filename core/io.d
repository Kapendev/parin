// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The io module facilitates input and output operations,
/// offering functionalities such as file reading and writing.

module popka.core.io;

import io = core.stdc.stdio;
import popka.core.container;
import popka.core.strutils;

@safe @nogc nothrow:

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
