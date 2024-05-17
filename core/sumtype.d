// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The sumtype module defines a data structure that can hold one of several possible types.

module popka.core.sumtype;

import popka.core.traits;

@safe @nogc nothrow:

union SumTypeData(A...) {
    // The slice removes the 'LU' part of the number.
    static foreach (i, T; A) {
        mixin("T ", "m", i.stringof[0 .. $ - 2], ";");
    }
}

alias SumTypeKind = ubyte;

struct SumType(A...) {
    SumTypeData!A data;
    SumTypeKind kind;

    @safe @nogc nothrow:

    alias BaseType = A[0];

    static foreach (i, T; A) {
        @trusted
        this(T data) {
            this.data = *(cast(SumTypeData!A*) &data);
            this.kind = i;
        }
    }

    static foreach (i, T; A) {
        @trusted
        void opAssign(T rhs) {
            data = *(cast(SumTypeData!A*) &rhs);
            kind = i;
        }
    }

    const(char)[] typeName() {
        static foreach (i, T; A) {
            if (kind == i) {
                return T.stringof;
            }
        }
        assert(0, "Kind is invalid.");
    }

    bool isValue(T)() {
        enum target = findInAliasArgs!(T, A);
        static assert(target != -1, "Type '" ~ T.stringof ~ "' is not part of the union.");
        return kind == target;
    }

    ref T value(T)() {
        if (isValue!T) {
            mixin("return ", "data.m", findInAliasArgs!(T, A), ";"); 
        } else {
            static foreach (i, TT; A) {
                if (kind == i) {
                    assert(0, "Value is '" ~ A[i].stringof ~ "' and not '" ~ T.stringof ~ "'.");
                }
            }
            assert(0, "Kind is invalid.");
        }
    }

    T* valuePtr(T)() {
        return &value!T();
    }

    ref BaseType base() {
        return data.m0;
    }

    BaseType* basePtr() {
        return &data.m0;
    }

    auto call(const(char)[] func, AA...)(AA args) {
        // The slice removes the 'LU' part of the number.
        switch (kind) {
            static foreach (i, T; A) {
                static if (__traits(hasMember, T, func)) {
                    mixin("case ", i, ": return data.m", i.stringof[0 .. $ - 2], ".", func, "(args);");
                } else {
                    mixin("case ", i, ": return;");
                }
            }
            default: assert(0, "Kind is invalid.");
        }
    }
}

struct NoneType {}

alias Maybe(T) = SumType!(NoneType, T);

bool isNone(A...)(SumType!A maybe) {
    return maybe.kind == 0;
}

bool isSome(A...)(SumType!A maybe)  {
    return maybe.kind != 0;
}

bool isSumType(T)() {
    return is(T : SumType!A, A...);
}

bool hasCommonBase(T)() {
    static assert(isSumType!T, "Type '" ~ T.stringof  ~ "' must be a sum type.");

    static foreach (member; T.init.data.tupleof[1 .. $]) {
        static if (isPrimaryType!(typeof(member)) || member.tupleof.length == 0) {
            static if (!is(typeof(member) == T.BaseType)) {
                return false;
            }
        } else static if (!is(T.BaseType == typeof(member.tupleof[0]))) {
            return false;
        }
    }
    return true;
}

mixin template addBase(T) {
    T base;
    alias base this;
}

unittest {
    SumType!(int, float) number;
    number = 0;
    assert(number.isValue!int == true);
    assert(number.isValue!float == false);
    assert(number.typeName == "int");
    number = 0.0;
    assert(number.isValue!int == false);
    assert(number.isValue!float == true);
    assert(number.typeName == "float");

    number = 0;
    number.value!int += 2;
    assert(number.value!int == 2);

    struct MyType {
        mixin addBase!int;
    }
    alias Entity1 = SumType!(int, MyType);
    assert(hasCommonBase!Entity1 == true);
    alias Entity2 = SumType!(MyType, int);
    assert(hasCommonBase!Entity2 == false);

    Maybe!int result;
    result = Maybe!int();
    assert(result.isNone == true);
    assert(result.isSome == false);
    result = 69;
    assert(result.isNone == false);
    assert(result.isSome == true);
}
