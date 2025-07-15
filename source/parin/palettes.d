// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `palettes` module offers a collection of predefined colors.
module parin.palettes;

import joka.math;

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
