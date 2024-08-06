// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `colors` module provides color-related types and functions.
module popka.core.colors;

import popka.core.ascii;
import popka.core.traits;
import popka.core.types;

@safe @nogc nothrow:

enum blank   = Color();
enum black   = Color(0);
enum white   = Color(255);

enum red     = Color(255, 0, 0);
enum green   = Color(0, 255, 0);
enum blue    = Color(0, 0, 255);
enum yellow  = Color(255, 255, 0);
enum magenta = Color(255, 0, 255);
enum cyan    = Color(0, 255, 255);

enum gray1   = toRgb(0x202020);
enum gray2   = toRgb(0x606060);
enum gray3   = toRgb(0x9f9f9f);
enum gray4   = toRgb(0xdfdfdf);

alias gray = gray1;

struct Color {
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a;

    enum length = 4;
    enum zero = Color(0, 0, 0, 0);
    enum one = Color(1, 1, 1, 1);

    @safe @nogc nothrow:

    pragma(inline, true)
    this(ubyte r, ubyte g, ubyte b, ubyte a = 255) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    pragma(inline, true)
    this(ubyte r) {
        this(r, r, r, 255);
    }

    mixin addRgbaOps!(Color, length);

    Color alpha(ubyte a) {
        return Color(r, g, b, a);
    }

    IStr toStr() {
        return "({} {} {} {})".format(r, g, b, a);
    }
}

Color toRgb(uint rgb) {
    return Color(
        (rgb & 0xFF0000) >> 16,
        (rgb & 0xFF00) >> 8,
        (rgb & 0xFF),
    );
}

Color toRgba(uint rgba) {
    return Color(
        (rgba & 0xFF000000) >> 24,
        (rgba & 0xFF0000) >> 16,
        (rgba & 0xFF00) >> 8,
        (rgba & 0xFF),
    );
}

unittest {
    assert(toRgb(0xff0000) == red);
    assert(toRgb(0x00ff00) == green);
    assert(toRgb(0x0000ff) == blue);

    assert(toRgba(0xff0000ff) == red);
    assert(toRgba(0x00ff00ff) == green);
    assert(toRgba(0x0000ffff) == blue);

    assert(black.toStr() == "(0 0 0 255)");
    assert(black.alpha(69).toStr() == "(0 0 0 69)");
}
