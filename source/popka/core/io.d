// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `io` module provides input and output functions such as file reading.

module popka.core.io;

import popka.core.containers;
import popka.core.stdc;
import popka.core.ascii;
import popka.core.traits;
import popka.core.types;

@safe @nogc nothrow:

@trusted
void printf(A...)(IStr text, A args) {
    .fputs(format("{}\0", format(text, args)).ptr, .stdout);
}

@trusted
void printfln(A...)(IStr text, A args) {
    .fputs(format("{}\n\0", format(text, args)).ptr, .stdout);
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
// TODO: Check the error values and let the user know what went wrong.
void readText(IStr path, ref List!char text) {
    auto f = .fopen(toCStr(path).unwrapOr(), "rb");
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

List!char readText(IStr path) {
    List!char result;
    readText(path, result);
    return result;
}

@trusted
// TODO: Check the error values and let the user know what went wrong.
void writeText(IStr path, IStr text) {
    auto f = .fopen(toCStr(path).unwrapOr(), "w");
    if (f == null) {
        return;
    }
    .fwrite(text.ptr, char.sizeof, text.length, f);
    .fclose(f);
}
