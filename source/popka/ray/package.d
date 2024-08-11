// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

module popka.ray;

public import popka.ray.raylib;
public import popka.ray.rlgl;

version (WebAssembly) {
    @nogc nothrow extern(C)
    void emscripten_set_main_loop(void* ptr, int fps, int loop);
    @nogc nothrow extern(C)
    void emscripten_cancel_main_loop();
}
