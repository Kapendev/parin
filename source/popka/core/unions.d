// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `unions` module defines a data structure that can hold one of several possible types.

module popka.core.unions;

import popka.core.types;
import popka.core.traits;

@safe @nogc nothrow:

union SumTypeData(A...) {
    static foreach (i, T; A) {
        mixin("T ", "m", toCleanNumber!i, ";");
    }

    enum kindCount = A.length;

    alias BaseType = A[0];
    alias Types = A;
}

alias SumTypeKind = int;

struct SumType(A...) {
    SumTypeData!A data;
    SumTypeKind kind;

    @safe @nogc nothrow:

    enum kindCount = A.length;

    alias BaseType = A[0];
    alias Types = A;

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

    IStr kindName() {
        static foreach (i, T; A) {
            if (kind == i) {
                return T.stringof;
            }
        }
        assert(0, "Kind is invalid.");
    }

    SumTypeKind kindValue() {
        return kind;
    }

    bool isValue(T)() {
        static assert(isInAliasArgs!(T, A), "Type `" ~ T.stringof ~ "` is not part of the sum type.");
        return kind == findInAliasArgs!(T, A);
    }

    @trusted
    ref T value(T)() {
        if (isValue!T) {
            mixin("return ", "data.m", findInAliasArgs!(T, A), ";"); 
        } else {
            static foreach (i, TT; A) {
                if (kind == i) {
                    assert(0, "Value is `" ~ A[i].stringof ~ "` and not `" ~ T.stringof ~ "`.");
                }
            }
            assert(0, "Kind is invalid.");
        }
    }

    @trusted
    T* valuePtr(T)() {
        return &value!T();
    }

    @trusted
    ref BaseType base() {
        return data.m0;
    }

    @trusted
    BaseType* basePtr() {
        return &data.m0;
    }

    @trusted
    auto call(IStr func, AA...)(AA args) {
        switch (kind) {
            static foreach (i, T; A) {
                static assert(__traits(hasMember, T, func), "Type `" ~ T.stringof ~ "` does not implement the `" ~ func ~ "` function.");
                mixin("case ", i, ": return data.m", toCleanNumber!i, ".", func, "(args);");
            }
            default: assert(0, "Kind is invalid.");
        }
    }

    template kindNameOf(T) {
        static assert(isInAliasArgs!(T, A), "Type `" ~ T.stringof ~ "` is not part of the sum type.");
        enum kindNameOf = T.stringof;
    }

    template kindValueOf(T) {
        static assert(isInAliasArgs!(T, A), "Type `" ~ T.stringof ~ "` is not part of the sum type.");
        enum kindValueOf = findInAliasArgs!(T, A);
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

T toSumType(T)(SumTypeKind kind) {
    static assert(isSumType!T, "Type `" ~ T.stringof  ~ "` is not a sum type.");

    T result;
    static foreach (i, Type; T.Types) {
        if (i == kind) {
            result = Type.init;
            goto loopExit;
        }
    }
    loopExit:
    return result;
}

T toSumType(T)(IStr kindName) {
    static assert(isSumType!T, "Type `" ~ T.stringof  ~ "` is not a sum type.");

    T result;
    static foreach (i, Type; T.Types) {
        if (Type.stringof == kindName) {
            result = Type.init;
            goto loopExit;
        }
    }
    import popka.core.io;
    loopExit:
    return result;
}

bool isSumType(T)() {
    return is(T : SumType!A, A...);
}

// TODO: WTF?
int checkCommonBase(T)() {
    static assert(isSumType!T, "Type `" ~ T.stringof  ~ "` is not a sum type.");

    static foreach (i, member; T.init.data.tupleof[1 .. $]) {
        static if (isPrimaryType!(typeof(member)) || member.tupleof.length == 0) {
            static if (!is(T.BaseType == typeof(member))) {
                return i + 1;
            }
        } else static if (!is(T.BaseType == typeof(member.tupleof[0]))) {
            return i + 1;
        }
    }
    return -1;
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
    assert(number.kindName == "int");
    number = 0.0;
    assert(number.isValue!int == false);
    assert(number.isValue!float == true);
    assert(number.kindName == "float");

    number = 0;
    number.value!int += 2;
    assert(number.value!int == 2);

    struct MyType {
        mixin addBase!int;
    }
    // alias Entity1 = SumType!(int, MyType);
    // assert(hasCommonBase!Entity1 == true);
    // alias Entity2 = SumType!(MyType, int);
    // assert(hasCommonBase!Entity2 == false);

    Maybe!int result;
    result = Maybe!int();
    assert(result.isNone == true);
    assert(result.isSome == false);
    result = 69;
    assert(result.isNone == false);
    assert(result.isSome == true);
}
