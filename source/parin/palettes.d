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

alias Palette(Sz N) = Array!(Rgba, N); /// A generic color palette of RGBA colors.
alias HexPalette(Sz N) = uint[N];      /// A generic color palette of hexadecimal numbers.

/// A 2-color palette inspired by the Playdate.
/// Link: https://kapendev.itch.io/will-of-the-hair-wisp
enum Wisp2 : Rgba {
    black = toRgb(wisp2[0]),
    white = toRgb(wisp2[1]),
}

/// A 4-color palette inspired by the Game Boy.
/// Link: https://lospec.com/palette-list/2-bit-matrix
enum Gb4 : Rgba {
    black     = toRgb(gb4[0]),
    darkGray  = toRgb(gb4[1]),
    lightGray = toRgb(gb4[2]),
    white     = toRgb(gb4[3]),
}

/// An 8-color palette inspired by the NES.
/// Link: https://lospec.com/palette-list/mf-8
enum Nes8 : Rgba {
    black  = toRgb(nes8[0]),
    brown  = toRgb(nes8[1]),
    purple = toRgb(nes8[2]),
    red    = toRgb(nes8[3]),
    green  = toRgb(nes8[4]),
    blue   = toRgb(nes8[5]),
    yellow = toRgb(nes8[6]),
    white  = toRgb(nes8[7]),
}

/// A 16-color palette used by the PICO-8.
/// Link: https://lospec.com/palette-list/pico-8
enum Pico8 : Rgba {
    black      = toRgb(pico8[0]),
    navy       = toRgb(pico8[1]),
    maroon     = toRgb(pico8[2]),
    darkGreen  = toRgb(pico8[3]),
    brown      = toRgb(pico8[4]),
    darkGray   = toRgb(pico8[5]),
    lightGray  = toRgb(pico8[6]),
    white      = toRgb(pico8[7]),
    red        = toRgb(pico8[8]),
    orange     = toRgb(pico8[9]),
    yellow     = toRgb(pico8[10]),
    lightGreen = toRgb(pico8[11]),
    blue       = toRgb(pico8[12]),
    purple     = toRgb(pico8[13]),
    pink       = toRgb(pico8[14]),
    peach      = toRgb(pico8[15]),
}

/// Link: https://kapendev.itch.io/will-of-the-hair-wisp
immutable HexPalette!2 wisp2 = [
    0x322F29,
    0xDAD6D0,
];

/// Link: https://lospec.com/palette-list/2-bit-matrix
immutable HexPalette!4 gb4 = [
    0x343434,
    0x5b8c7c,
    0xadd9bc,
    0xf2fff2,
];

/// Link: https://lospec.com/palette-list/mf-8
immutable HexPalette!8 nes8 = [
    0x292320,
    0xa7763e,
    0x7f339a,
    0xe04113,
    0x32a75c,
    0x1ac1fe,
    0xfdd156,
    0xfcf8ea,
];

/// Link: https://lospec.com/palette-list/pico-8
immutable HexPalette!16 pico8 = [
    0x000000,
    0x1D2B53,
    0x7E2553,
    0x008751,
    0xAB5236,
    0x5F574F,
    0xC2C3C7,
    0xFFF1E8,
    0xFF004D,
    0xFFA300,
    0xFFEC27,
    0x00E436,
    0x29ADFF,
    0x83769C,
    0xFF77A8,
    0xFFCCAA,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://github.com/morhetz/gruvbox
immutable HexPalette!16 gruvboxDark = [
    0x282828,
    0x3c3836,
    0x504945,
    0x665c54,
    0xbdae93,
    0xd5c4a1,
    0xebdbb2,
    0xfbf1c7,
    0xfb4934,
    0xfe8019,
    0xfabd2f,
    0xb8bb26,
    0x8ec07c,
    0x83a598,
    0xd3869b,
    0xd65d0e,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://github.com/morhetz/gruvbox
immutable HexPalette!16 gruvboxLight = [
    0xfbf1c7,
    0xebdbb2,
    0xd5c4a1,
    0xbdae93,
    0x665c54,
    0x504945,
    0x3c3836,
    0x282828,
    0x9d0006,
    0xaf3a03,
    0xb57614,
    0x79740e,
    0x427b58,
    0x076678,
    0x8f3f71,
    0xd65d0e,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://github.com/pulsar-edit/pulsar
immutable HexPalette!16 oneDark = [
    0x282c34,
    0x353b45,
    0x3e4451,
    0x545862,
    0x565c64,
    0xabb2bf,
    0xb6bdca,
    0xc8ccd4,
    0xe06c75,
    0xd19a66,
    0xe5c07b,
    0x98c379,
    0x56b6c2,
    0x61afef,
    0xc678dd,
    0xbe5046,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://github.com/pulsar-edit/pulsar
immutable HexPalette!16 oneLight = [
    0xfafafa,
    0xf0f0f1,
    0xe5e5e6,
    0xa0a1a7,
    0x696c77,
    0x383a42,
    0x202227,
    0x090a0b,
    0xca1243,
    0xd75f00,
    0xc18401,
    0x50a14f,
    0x0184bc,
    0x4078f2,
    0xa626a4,
    0x986801,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://ethanschoonover.com/solarized/
immutable HexPalette!16 solarizedDark = [
    0x002b36,
    0x073642,
    0x586e75,
    0x657b83,
    0x839496,
    0x93a1a1,
    0xeee8d5,
    0xfdf6e3,
    0xdc322f,
    0xcb4b16,
    0xb58900,
    0x859900,
    0x2aa198,
    0x268bd2,
    0x6c71c4,
    0xd33682,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://ethanschoonover.com/solarized/
immutable HexPalette!16 solarizedLight = [
    0xfdf6e3,
    0xeee8d5,
    0x93a1a1,
    0x839496,
    0x657b83,
    0x586e75,
    0x073642,
    0x002b36,
    0xdc322f,
    0xcb4b16,
    0xb58900,
    0x859900,
    0x2aa198,
    0x268bd2,
    0x6c71c4,
    0xd33682,
];

/// Converts a CSV row to a color palette.
/// If the row can't be parsed, then the first value of the palette will be blank.
Palette!N csvRowToPalette(Sz N)(IStr csv, Sz row = 0, Sz startCol = 0) {
    Palette!N result = void;

    auto line = csv.skipLine();
    if (row > 0) { row -= 1; line = csv.skipLine(); }
    auto fields = line.split(',');
    if (startCol >= fields.length) { result[0] = blank; return result; }
    fields = fields[startCol .. $];
    if (fields.length != N) { result[0] = blank; return result; }

    foreach (i, field; fields) {
        auto value = field.toRgba();
        if (value == blank) { result[0] = blank; return result; }
        result[i] = value;
    }
    return result;
}
