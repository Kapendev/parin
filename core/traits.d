// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The traits module provides compile-time procedures
/// and enables features like type checking.

module popka.core.traits;

@safe @nogc nothrow:

bool isBoolType(T)() {
    return is(T == bool) ||
        is(T == const(bool)) ||
        is(T == immutable(bool));
}

bool isUnsignedType(T)() {
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

bool isSignedType(T)() {
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

bool isDoubleType(T)() {
    return is(T == float) ||
    is(T == const(float)) ||
    is(T == immutable(float)) ||
    is(T == double) ||
    is(T == const(double)) ||
    is(T == immutable(double));
}

bool isCharType(T)() {
    return is(T == char) ||
        is(T == const(char)) ||
        is(T == immutable(char));
}

bool isStrType(T)() {
    return is(T : const(char)[]);
}

bool isStrzType(T)() {
    return is(T : const(char)*);
}

bool isPtrType(T)() {
    return is(T : const(void)*);
}

bool isSliceType(T)() {
    return is(T : const(A)[], A);
}

bool isEnumType(T)() {
    return is(T == enum);
}

bool isStructType(T)() {
    return is(T == struct);
}
