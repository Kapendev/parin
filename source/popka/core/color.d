// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The color module specializes in handling color-related operations.

module popka.core.color;

@safe @nogc nothrow:

enum black = Color();
enum gray = Color(30);
enum gray1 = Color(30);
enum gray2 = Color(225);
enum white = Color(255);

enum red = Color(255, 0, 0);
enum green = Color(0, 255, 0);
enum blue = Color(0, 0, 255);
enum yellow = Color(255, 255, 0);
enum magenta = Color(255, 0, 255);
enum cyan = Color(0, 255, 255);

enum blank = Color(0, 0, 0, 0);

struct Color {
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a = 255;

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

    pragma(inline, true)
    this(ubyte[4] rgba) {
        this(rgba[0], rgba[1], rgba[2], rgba[3]);
    }

    pragma(inline, true)
    this(ubyte[3] rgb) {
        this(rgb[0], rgb[1], rgb[2], 255);
    }

    Color alpha(ubyte value) {
        return Color(r, g, b, value);
    }
}

Color toRGB(uint rgb) {
    return Color(
        (rgb & 0xFF0000) >> 16,
        (rgb & 0xFF00) >> 8,
        (rgb & 0xFF),
    );
}

Color toRGBA(uint rgba) {
    return Color(
        (rgba & 0xFF000000) >> 24,
        (rgba & 0xFF0000) >> 16,
        (rgba & 0xFF00) >> 8,
        (rgba & 0xFF),
    );
}
