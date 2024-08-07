// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `io` module provides input and output functions such as file reading.
module popka.core.io;

import popka.core.ascii;
import popka.core.stdc;
import popka.core.traits;
import popka.core.types;

public import popka.core.containers;
public import popka.core.faults;

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
Fault readTextIntoBuffer(IStr path, ref LStr text) {
    auto file = fopen(toCStr(path).unwrapOr(), "rb");
    if (file == null) {
        return Fault.cantOpen;
    }
    if (fseek(file, 0, SEEK_END) != 0) {
        fclose(file);
        return Fault.cantRead;
    }

    auto fileSize = ftell(file);
    if (fileSize == -1) {
        fclose(file);
        return Fault.cantRead;
    }
    if (fseek(file, 0, SEEK_SET) != 0) {
        fclose(file);
        return Fault.cantRead;
    }

    text.resize(fileSize);
    fread(text.items.ptr, fileSize, 1, file);
    if (fclose(file) != 0) {
        return Fault.cantClose;
    }
    return Fault.none;
}

Result!LStr readText(IStr path) {
    LStr value;
    return Result!LStr(value, readTextIntoBuffer(path, value));
}

@trusted
Fault writeText(IStr path, IStr text) {
    auto file = fopen(toCStr(path).unwrapOr(), "w");
    if (file == null) {
        return Fault.cantOpen;
    }
    fwrite(text.ptr, char.sizeof, text.length, file);
    if (fclose(file) != 0) {
        return Fault.cantClose;
    }
    return Fault.none;
}

// Function test.
unittest {
    assert(readText("").isSome == false);
    assert(writeText("", "") != Fault.none);
}
