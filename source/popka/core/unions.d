// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `unions` module provides functions and data structures for working with unions.
module popka.core.unions;

import popka.core.types;
import popka.core.traits;

@safe @nogc nothrow:

alias VariantKind = int;

struct None {}

union VariantValue(A...) {
    static assert(A.length != 0, "Arguments must contain at least one element.");

    static foreach (i, T; A) {
        static if (i == 0 && isNumberType!T) {
            mixin("T ", "member", toCleanNumber!i, "= 0;");
        }  else {
            mixin("T ", "member", toCleanNumber!i, ";");
        }
    }

    enum length = A.length;
    alias Types = A;
}

struct Variant(A...) {
    VariantValue!A value;
    VariantKind kind;
    alias value this;

    @safe @nogc nothrow:

    static foreach (i, T; A) {
        @trusted
        this(T value) {
            this.value = *(cast(VariantValue!A*) &value);
            this.kind = i;
        }
    }

    static foreach (i, T; A) {
        @trusted
        void opAssign(T rhs) {
            value = *(cast(VariantValue!A*) &rhs);
            kind = i;
        }
    }

    IStr kindName() {
        static foreach (i, T; A) {
            if (kind == i) {
                return T.stringof;
            }
        }
        assert(0, "WTF!");
    }

    bool isKind(T)() {
        static assert(isInAliasArgs!(T, A), "Type `" ~ T.stringof ~ "` is not part of the variant.");
        return kind == findInAliasArgs!(T, A);
    }

    @trusted
    ref A[0] base() {
        return member0;
    }

    @trusted
    ref T get(T)() {
        if (isKind!T) {
            mixin("return ", "value.member", findInAliasArgs!(T, A), ";"); 
        } else {
            static foreach (i, TT; A) {
                if (i == kind) {
                    assert(0, "Value is `" ~ A[i].stringof ~ "` and not `" ~ T.stringof ~ "`.");
                }
            }
            assert(0, "WTF!");
        }
    }

    @trusted
    auto call(IStr func, AA...)(AA args) {
        switch (kind) {
            static foreach (i, T; A) {
                static assert(hasMember!(T, func), funcImplementationErrorMessage!(T, func));
                mixin("case ", i, ": return value.member", toCleanNumber!i, ".", func, "(args);");
            }
            default: assert(0, "WTF!");
        }
    }

    template kindOf(T) {
        static assert(isInAliasArgs!(T, A), "Type `" ~ T.stringof ~ "` is not part of the variant.");
        enum kindOf = findInAliasArgs!(T, A);
    }

    template kindNameOf(T) {
        static assert(isInAliasArgs!(T, A), "Type `" ~ T.stringof ~ "` is not part of the variant.");
        enum kindNameOf = T.stringof;
    }
}

T toVariant(T)(VariantKind kind) {
    static assert(isVariantType!T, "Type `" ~ T.stringof  ~ "` is not a variant.");

    T result;
    static foreach (i, Type; T.Types) {
        if (i == kind) {
            static if (isNumberType!Type) {
                result = cast(Type) 0;
            } else {
                result = Type.init;
            }
            goto loopExit;
        }
    }
    loopExit:
    return result;
}

T toVariant(T)(IStr kindName) {
    static assert(isVariantType!T, "Type `" ~ T.stringof  ~ "` is not a variant.");

    T result;
    static foreach (i, Type; T.Types) {
        if (Type.stringof == kindName) {
            static if (isNumberType!Type) {
                result = cast(Type) 0;
            } else {
                result = Type.init;
            }
            goto loopExit;
        }
    }
    loopExit:
    return result;
}

bool isVariantType(T)() {
    return is(T : Variant!A, A...);
}

mixin template addBase(T) {
    T base;
    alias base this;
}

// Variant test.
unittest {
    alias Number = Variant!(float, double);

    assert(Number().kindName == "float");
    assert(Number().isKind!float == true);
    assert(Number().isKind!double == false);
    assert(Number().get!float() == 0);
    assert(Number(0.0f).kindName == "float");
    assert(Number(0.0f).isKind!float == true);
    assert(Number(0.0f).isKind!double == false);
    assert(Number(0.0f).get!float() == 0);
    assert(Number(0.0).isKind!float == false);
    assert(Number(0.0).isKind!double == true);
    assert(Number(0.0).kindName == "double");
    assert(Number(0.0).get!double() == 0);
    assert(Number.kindOf!float == 0);
    assert(Number.kindOf!double == 1);
    assert(Number.kindNameOf!float == "float");
    assert(Number.kindNameOf!double == "double");

    auto number = Number();
    number = 0.0;
    assert(number.get!double() == 0);
    number = 0.0f;
    assert(number.get!float() == 0);
    number.get!float() += 69.0f;
    assert(number.get!float() == 69);
    
    auto numberPtr = &number.get!float();
    *numberPtr *= 10;
    assert(number.get!float() == 690);
}

// Function test.
unittest {
    alias Number = Variant!(float, double);

    assert(toVariant!Number(Number.kindOf!float).get!float() == 0);
    assert(toVariant!Number(Number.kindOf!double).get!double() == 0);
    assert(toVariant!Number(Number.kindNameOf!float).get!float() == 0);
    assert(toVariant!Number(Number.kindNameOf!double).get!double() == 0);
}
