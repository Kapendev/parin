// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The traits module provides compile-time procedures
/// and enables features like type checking.

module popka.core.traits;

@safe @nogc nothrow:

bool isBool(T)() {
    return is(T == bool) ||
        is(T == const(bool)) ||
        is(T == immutable(bool));
}

bool isUnsigned(T)() {
    return is(T == ubyte) ||
        is(T == const(ubyte)) ||
        is(T == immutable(ubyte)) ||
        is(T == ushort) ||
        is(T == const(ushort)) ||
        is(T == immutable(ushort)) ||
        is(T == uint) ||
        is(T == const(uint)) ||
        is(T == immutable(uint)) ||
        is(T == ulong) ||
        is(T == const(ulong)) ||
        is(T == immutable(ulong));
}

bool isSigned(T)() {
    return is(T == byte) ||
        is(T == const(byte)) ||
        is(T == immutable(byte)) ||
        is(T == short) ||
        is(T == const(short)) ||
        is(T == immutable(short)) ||
        is(T == int) ||
        is(T == const(int)) ||
        is(T == immutable(int)) ||
        is(T == long) ||
        is(T == const(long)) ||
        is(T == immutable(long));
}

bool isDouble(T)() {
    return is(T == float) ||
    is(T == const(float)) ||
    is(T == immutable(float)) ||
    is(T == double) ||
    is(T == const(double)) ||
    is(T == immutable(double));
}

bool isChar(T)() {
    return is(T == char) ||
        is(T == const(char)) ||
        is(T == immutable(char));
}

bool isStr(T)() {
    return is(T : const(char)[]);
}

bool isStrz(T)() {
    return is(T : const(char)*);
}

bool isPtr(T)() {
    return is(T : const(void)*);
}

bool isSlice(T)() {
    return is(T : const(A)[], A);
}

bool isEnum(T)() {
    return is(T == enum);
}

bool isStruct(T)() {
    return is(T == struct);
}
