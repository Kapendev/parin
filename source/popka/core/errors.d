// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `errors` module provides a set of error codes and data structures for error handling.

module popka.core.errors;

import popka.core.traits;

@safe @nogc nothrow:

enum BasicError : ubyte {
    none,
    some,
    invalid,
    overflow,
    notFound,
    cantRead,
    cantWrite,
}

struct BasicResult(T) {
    static if (isNumberType!T) {
        T value = 0;
    } else {
        T value;
    }
    BasicError error = BasicError.some;

    @safe @nogc nothrow:

    this(T value) {
        this.value = value;
        error = BasicError.none;
    }

    this(BasicError error) {
        this.error = error;
    }

    T unwrap() {
        if (error) {
            assert(0, "");
        }
        return value;
    }

    T unwrapOr(T dflt) {
        if (error) {
            return dflt;
        } else {
            return value;
        }
    }

    T unwrapOr() {
        return value;
    }

    bool isNone() {
        return error != 0;
    }

    bool isSome() {
        return error == 0;
    }
}

// BasicResult test.
unittest {
    assert(BasicResult!int().isNone == true);
    assert(BasicResult!int().isSome == false);
    assert(BasicResult!int().unwrapOr() == 0);
    assert(BasicResult!int(0).isNone == false);
    assert(BasicResult!int(0).isSome == true);
    assert(BasicResult!int(0).unwrapOr() == 0);
    assert(BasicResult!int(69).isNone == false);
    assert(BasicResult!int(69).isSome == true);
    assert(BasicResult!int(69).unwrapOr() == 69);
}
