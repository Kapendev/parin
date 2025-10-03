// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

module joka.stdc.config;

extern(C) nothrow @nogc:

version (WebAssembly) {
    static if ((void*).sizeof > int.sizeof) {
        alias CLong = long;
        alias CULong = ulong;
    } else {
        alias CLong = int;
        alias CULong = uint;
    }
} else version (Windows) {
    alias CLong = int;
    alias CULong = uint;
} else {
    alias CLong = long;
    alias CULong = ulong;
}
