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

bool isFloatingType(T)() {
    return is(T == float) ||
        is(T == const(float)) ||
        is(T == immutable(float)) ||
        is(T == double) ||
        is(T == const(double)) ||
        is(T == immutable(double));
}

bool isNumberType(T)() {
    return isIntegerType!T || isFloatingType!T;
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

bool hasMember(T, IStr name)() {
    return __traits(hasMember, T, name);
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

IStr funcImplementationErrorMessage(T, IStr func)() {
    return "Type `" ~ T.stringof ~ "` does not implement the `" ~ func ~ "` function.";
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

mixin template addXyzwOps(T, Sz N) {
    static assert(N >= 1 && N <= 4, "Vector `" ~ T.stringof ~ "`  must have a dimension between 1 and 4.");

    pragma(inline, true)
    T opUnary(IStr op)() {
        static if (N == 1) {
            return T(
                mixin(op, "x"),
            );
        } else static if (N == 2) {
            return T(
                mixin(op, "x"),
                mixin(op, "y"),
            );
        } else static if (N == 3) {
            return T(
                mixin(op, "x"),
                mixin(op, "y"),
                mixin(op, "z"),
            );
        } else static if (N == 4) {
            return T(
                mixin(op, "x"),
                mixin(op, "y"),
                mixin(op, "z"),
                mixin(op, "w"),
            );
        }
    }

    pragma(inline, true)
    T opBinary(IStr op)(T rhs) {
        static if (N == 1) {
            return T(
                mixin("x", op, "rhs.x"),
            );
        } else static if (N == 2) {
            return T(
                mixin("x", op, "rhs.x"),
                mixin("y", op, "rhs.y"),
            );
        } else static if (N == 3) {
            return T(
                mixin("x", op, "rhs.x"),
                mixin("y", op, "rhs.y"),
                mixin("z", op, "rhs.z"),
            );
        } else static if (N == 4) {
            return T(
                mixin("x", op, "rhs.x"),
                mixin("y", op, "rhs.y"),
                mixin("z", op, "rhs.z"),
                mixin("w", op, "rhs.w"),
            );
        }
    }

    pragma(inline, true)
    void opOpAssign(IStr op)(T rhs) {
        static if (N == 1) {
            mixin("x", op, "=rhs.x;");
        } else static if (N == 2) {
            mixin("x", op, "=rhs.x;");
            mixin("y", op, "=rhs.y;");
        } else static if (N == 3) {
            mixin("x", op, "=rhs.x;");
            mixin("y", op, "=rhs.y;");
            mixin("z", op, "=rhs.z;");
        } else static if (N == 4) {
            mixin("x", op, "=rhs.x;");
            mixin("y", op, "=rhs.y;");
            mixin("z", op, "=rhs.z;");
            mixin("w", op, "=rhs.w;");
        }
    }
}

mixin template addRgbaOps(T, Sz N) {
    static assert(N >= 1 && N <= 4, "Color `" ~ T.stringof ~ "`  must have a dimension between 1 and 4.");

    pragma(inline, true)
    T opUnary(IStr op)() {
        static if (N == 1) {
            return T(
                mixin(op, "r"),
            );
        } else static if (N == 2) {
            return T(
                mixin(op, "r"),
                mixin(op, "g"),
            );
        } else static if (N == 3) {
            return T(
                mixin(op, "r"),
                mixin(op, "g"),
                mixin(op, "b"),
            );
        } else static if (N == 4) {
            return T(
                mixin(op, "r"),
                mixin(op, "g"),
                mixin(op, "b"),
                mixin(op, "a"),
            );
        }
    }

    pragma(inline, true)
    T opBinary(IStr op)(T rhs) {
        static if (N == 1) {
            return T(
                mixin("r", op, "rhs.r"),
            );
        } else static if (N == 2) {
            return T(
                mixin("r", op, "rhs.r"),
                mixin("g", op, "rhs.g"),
            );
        } else static if (N == 3) {
            return T(
                mixin("r", op, "rhs.r"),
                mixin("g", op, "rhs.g"),
                mixin("b", op, "rhs.b"),
            );
        } else static if (N == 4) {
            return T(
                mixin("r", op, "rhs.r"),
                mixin("g", op, "rhs.g"),
                mixin("b", op, "rhs.b"),
                mixin("a", op, "rhs.a"),
            );
        }
    }

    pragma(inline, true)
    void opOpAssign(IStr op)(T rhs) {
        static if (N == 1) {
            mixin("r", op, "=rhs.r;");
        } else static if (N == 2) {
            mixin("r", op, "=rhs.r;");
            mixin("g", op, "=rhs.g;");
        } else static if (N == 3) {
            mixin("r", op, "=rhs.r;");
            mixin("g", op, "=rhs.g;");
            mixin("b", op, "=rhs.b;");
        } else static if (N == 4) {
            mixin("r", op, "=rhs.r;");
            mixin("g", op, "=rhs.g;");
            mixin("b", op, "=rhs.b;");
            mixin("a", op, "=rhs.a;");
        }
    }
}

// Function test.
unittest {
    assert(isInAliasArgs!(int, AliasArgs!(float)) == false);
    assert(isInAliasArgs!(int, AliasArgs!(float, int)) == true);
}
