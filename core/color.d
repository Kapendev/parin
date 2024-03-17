// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The color module specializes in handling color-related operations,
/// offering a suite of procedures tailored for manipulating and managing color properties within a program.

module popka.core.color;

@safe @nogc nothrow:

enum {
    blank = Color(),
    black = Color(0),
    darkGray = Color(40),
    lightGray = Color(220),
    white = Color(255),
    red = Color(255, 0, 0),
    green = Color(0, 255, 0),
    blue = Color(0, 0, 255),
    yellow = Color(255, 255, 0),
    magenta = Color(255, 0, 255),
    cyan = Color(0, 255, 255),
}

struct Color {
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a;

    @safe @nogc nothrow:

    this(ubyte r, ubyte g, ubyte b, ubyte a) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    this(ubyte r, ubyte g, ubyte b) {
        this(r, g, b, 255);
    }

    this(ubyte r) {
        this(r, r, r, 255);
    }

    this(ubyte[4] rgba) {
        this(rgba[0], rgba[1], rgba[2], rgba[3]);
    }
}

unittest {}
