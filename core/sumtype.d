// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The sumtype module defines a data structure that can hold one of several possible types.
/// It provides functionalities to construct, access, and manipulate these values.

module popka.core.sumtype;

@safe @nogc nothrow:

struct None {}

union SumTypeData(A...) {
    static foreach (i, T; A) {
        mixin("T " ~ sumTypeDataMemberName!T ~ ";");
    }
}

alias SumTypeKind = ushort;

/// A data structure that can hold one of several possible types.
/// Note that generic types are not supported.
struct SumType(A...) {
    SumTypeData!A data;
    SumTypeKind kind;
    alias data this;

    @safe @nogc nothrow:

    static foreach (i, T; A) {
        mixin("enum " ~ sumTypeKindMemberName!T ~ " = i;");
    }

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

    auto call(string f, AA...)(AA args) {
        final switch (kind) {
            static foreach (i, T; A) {
                mixin("case " ~ i.stringof ~ ": return " ~ sumTypeDataMemberName!T ~ "." ~ f ~ "(args);");
            }
        }
    }
}

alias Optional(T) = SumType!(None, T);

bool isNone(A...)(SumType!A optional) {
    return optional.kind == 0;
}

bool isSome(A...)(SumType!A optional) {
    return optional.kind != 0;
}

bool hasCommonBase(T)() {
    static assert(is(T : SumType!A, A...), "Type '" ~ T.stringof  ~ "' must be a sum type.");
    alias Base = typeof(T.init.data.tupleof[0]);
    static foreach (member; T.init.data.tupleof[1 .. $]) {
        static if (member.tupleof.length == 0) {
            return false;
        } else static if (!is(Base == typeof(member.tupleof[0]))) {
            return false;
        }
    }
    return true;
}

template sumTypeMemberName(T) {
    mixin("enum sumTypeMemberName = \"" ~ ((T.stringof[0] >= 'A' && T.stringof[0] <= 'Z') ? cast(char) (T.stringof[0] + 32) : T.stringof[0]) ~ T.stringof[1 .. $] ~ "\";");
}

template sumTypeDataMemberName(T) {
    mixin("enum sumTypeDataMemberName = \"" ~ sumTypeMemberName!T ~ "Data\";");
}

template sumTypeKindMemberName(T) {
    mixin("enum sumTypeKindMemberName = \"" ~ sumTypeMemberName!T ~ "Kind\";");
}

mixin template AddBase(T) {
    T base;
    alias base this;
}

unittest {
    auto optional = Optional!int();
    assert(optional.isNone);
    optional = 69;
    assert(optional.isSome);
    optional = None();
    assert(optional.isNone);
}
