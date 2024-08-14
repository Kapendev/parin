// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/popka
// Version: v0.0.16
// ---

/// The `ray` module provides access to the raylib library.
module popka.ray;

public import popka.ray.raylib;
public import popka.ray.rlgl;

@nogc nothrow extern(C):

void glfwSwapInterval(int interval);

version (WebAssembly) {
    @nogc nothrow extern(C):

    void emscripten_set_main_loop(void* ptr, int fps, int loop);
    void emscripten_cancel_main_loop();
}
