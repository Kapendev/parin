// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.44
// ---

/// The `rl` module provides access to the raylib library.
module parin.rl;

public import parin.rl.raylib;
public import parin.rl.rlgl;

version (WebAssembly) {
    @nogc nothrow extern(C):

    void emscripten_set_main_loop(void* ptr, int fps, bool loop);
    void emscripten_cancel_main_loop();
}
