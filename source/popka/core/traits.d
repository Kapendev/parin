// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `traits` module provides compile-time functions such as type checking.
module popka.core.traits;

import popka.core.types;

@safe @nogc nothrow:

alias AliasArgs(A...) = A;

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

bool isIntegerType(T)() {
    return isUnsignedType!T || isSignedType!T;
}

bool isDoubleType(T)() {
    return is(T == float) ||
    is(T == const(float)) ||
    is(T == immutable(float)) ||
    is(T == double) ||
    is(T == const(double)) ||
    is(T == immutable(double));
}

bool isNumberType(T)() {
    return isIntegerType!T || isDoubleType!T;
}

bool isCharType(T)() {
    return is(T == char) ||
        is(T == const(char)) ||
        is(T == immutable(char));
}

bool isPrimaryType(T)() {
    return isBoolType!T ||
        isUnsignedType!T ||
        isSignedType!T ||
        isDoubleType!T ||
        isCharType!T;
}

bool isArrayType(T)() {
    return is(T : const(A)[N], A, N);
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

bool isStrType(T)() {
    return is(T : IStr);
}

bool isCStrType(T)() {
    return is(T : ICStr);
}

int findInAliasArgs(T, A...)() {
    int result = -1;
    static foreach (i, TT; A) {
        static if (is(T == TT)) {
            result = i;
        }
    }
    return result;
}

bool isInAliasArgs(T, A...)() {
    return findInAliasArgs!(T, A) != -1;
}

IStr toCleanNumber(alias i)() {
    enum str = i.stringof;
    static if (str.length >= 3 && (((str[$ - 1] == 'L' || str[$ - 1] == 'l') && (str[$ - 2] == 'U' || str[$ - 2] == 'u')) || ((str[$ - 1] == 'U' || str[$ - 1] == 'u') && (str[$ - 2] == 'L' || str[$ - 2] == 'l')))) {
        return str[0 .. $ - 2];
    } else static if (str.length >= 2 && (str[$ - 1] == 'U' || str[$ - 1] == 'u')) {
        return str[0 .. $ - 1];
    } else static if (str.length >= 2 && (str[$ - 1] == 'L' || str[$ - 1] == 'l')) {
        return str[0 .. $ - 1];
    } else {
        return str;
    }
}

// Function test.
unittest {
    assert(isInAliasArgs!(int, AliasArgs!(float)) == false);
    assert(isInAliasArgs!(int, AliasArgs!(float, int)) == true);
}
