// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `palettes` module offers a collection of predefined colors.
module parin.palettes;

import joka.ascii;
import joka.math;
import joka.types;

@safe nothrow @nogc:

// TODO: Say something nice. Add docs to the other stuff too.
alias Palette(Sz N) = Array!(Color, N);

/// This palette includes a 2-color set inspired by the Playdate handheld console.
/// Link: https://kapendev.itch.io/will-of-the-hair-wisp
enum Wisp2 : Rgba {
    black = toRgb(0x322F29),
    white = toRgb(0xDAD6D0),
}

/// This palette includes the 16-color set used by the PICO-8 fantasy console.
/// Link: https://lospec.com/palette-list/pico-8
enum Pico8 : Rgba {
    black      = toRgb(0x000000),
    navy       = toRgb(0x1D2B53),
    maroon     = toRgb(0x7E2553),
    darkGreen  = toRgb(0x008751),
    brown      = toRgb(0xAB5236),
    darkGray   = toRgb(0x5F574F),
    lightGray  = toRgb(0xC2C3C7),
    white      = toRgb(0xFFF1E8),
    red        = toRgb(0xFF004D),
    orange     = toRgb(0xFFA300),
    yellow     = toRgb(0xFFEC27),
    lightGreen = toRgb(0x00E436),
    blue       = toRgb(0x29ADFF),
    purple     = toRgb(0x83769C),
    pink       = toRgb(0xFF77A8),
    peach      = toRgb(0xFFCCAA),
}

// NOTE: Error value: blank
// TODO: Should maybe be in Joka.
Rgba hexToRgba(IStr str) {
    auto hasSymbol = str.startsWith("#");
    auto isRgb = str.length == 6 + hasSymbol;
    auto isRgba = str.length == 8 + hasSymbol;
    if (!isRgb && !isRgba) return blank;
    uint hex = 0;
    foreach (c; str[hasSymbol .. $]) {
        uint digit = 0;
        if (c >= '0' && c <= '9') {
            digit = cast(uint) (c - '0');
        } else if (c >= 'a' && c <= 'f') {
            digit = cast(uint) (10 + (c - 'a'));
        } else if (c >= 'A' && c <= 'F') {
            digit = cast(uint) (10 + (c - 'A'));
        } else {
            return blank;
        }
        hex = (hex << 4) | digit;
    }
    if (isRgb) return hex.toRgb();
    return hex.toRgba();
}

// NOTE: Error value: [blank, ...]
Palette!N csvRowToPalette(Sz N)(IStr csv, Sz row = 0, Sz startCol = 0) {
    Palette!N result = void;

    auto line = csv.skipLine();
    if (row > 0) { row -= 1; line = csv.skipLine(); }
    auto fields = line.split(',');
    if (startCol >= fields.length) { result[0] = blank; return result; }
    fields = fields[startCol .. $];
    if (fields.length != N) { result[0] = blank; return result; }

    foreach (i, field; fields) {
        auto value = field.hexToRgba();
        if (value == blank) { result[0] = blank; return result; }
        result[i] = value;
    }
    return result;
}
