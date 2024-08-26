// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/popka
// Version: v0.0.17
// ---

/// The `rl` module provides access to the raylib library.
module popka.rl;

public import popka.rl.raylib;
public import popka.rl.rlgl;

version (WebAssembly) {
    @nogc nothrow extern(C):

    void emscripten_set_main_loop(void* ptr, int fps, int loop);
    void emscripten_cancel_main_loop();
}
