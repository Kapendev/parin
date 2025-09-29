// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

module parin.backend;

version (ParinSdlBackend) {
    static assert("Not done!");
} else {
    public import parin.backend.rl;
}
