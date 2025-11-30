// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `interpolation` module provides a way to use D's IES (https://dlang.org/spec/istring.html).
module parin.joka.interpolation;

import parin.joka.types;

static if (__traits(compiles, { import core.interpolation; })) {
    public import core.interpolation;
} else {
    pragma(msg, "Joka: Using custom interpolation functions.");

    // Functions below are copy-pasted from core.interpolation.

    public IStr __getEmptyString() @nogc pure nothrow @safe {
        return "";
    }

    struct InterpolationHeader {
        alias toString = __getEmptyString;
    }

    struct InterpolationFooter {
        alias toString = __getEmptyString;
    }

    struct InterpolatedLiteral(IStr text) {
        static IStr toString() @nogc pure nothrow @safe {
            return text;
        }
    }

    struct InterpolatedExpression(IStr text) {
        enum expression = text;
        alias toString = __getEmptyString;
    }
}

// NOTE: A BetterC fix. It's only needed when using IES.
version (D_BetterC) {
    extern(C) @nogc pure nothrow @safe
    IStr _D4core13interpolation16__getEmptyStringFNaNbNiNfZAya() {
        return "";
    }
}
