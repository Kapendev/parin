// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `faults` module provides a set of codes and data structures for error handling.
module popka.core.faults;

import popka.core.traits;

@safe @nogc nothrow:

enum Fault : ubyte {
    none,
    some,
    invalid,
    overflow,
    cantFind,
    cantOpen,
    cantClose,
    cantRead,
    cantWrite,
}

struct Result(T) {
    static if (isNumberType!T) {
        T value = 0;
    } else {
        T value;
    }
    Fault fault = Fault.some;

    @safe @nogc nothrow:

    this(T value) {
        this.value = value;
        fault = Fault.none;
    }

    this(Fault fault) {
        this.fault = fault;
    }

    this(T value, Fault fault) {
        if (fault) {
            this.fault = fault;
        } else {
            this.value = value;
        }
    }

    T unwrap() {
        if (fault) {
            assert(0, "");
        }
        return value;
    }

    T unwrapOr(T dflt) {
        if (fault) {
            return dflt;
        } else {
            return value;
        }
    }

    T unwrapOr() {
        return value;
    }

    bool isNone() {
        return fault != 0;
    }

    bool isSome() {
        return fault == 0;
    }
}

// Result test.
unittest {
    assert(Result!int().isNone == true);
    assert(Result!int().isSome == false);
    assert(Result!int().unwrapOr() == 0);
    assert(Result!int(0).isNone == false);
    assert(Result!int(0).isSome == true);
    assert(Result!int(0).unwrapOr() == 0);
    assert(Result!int(69).isNone == false);
    assert(Result!int(69).isSome == true);
    assert(Result!int(69).unwrapOr() == 69);
}
