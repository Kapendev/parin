// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `errors` module provides a set of error codes and data structures for error handling.

module popka.core.errors;

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
    T value;
    BasicError error;
}
