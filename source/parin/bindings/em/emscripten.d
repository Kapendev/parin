// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `emscripten` module provides access to the emscripten.h functions.
module parin.bindings.em.emscripten;

import parin.joka.types;

nothrow @nogc extern(C):

enum EM_TIMING_SETTIMEOUT = 0;
enum EM_TIMING_RAF = 1;
enum EM_TIMING_SETIMMEDIATE = 2;

void emscripten_set_main_loop(void* ptr, int fps, bool loop);
void emscripten_cancel_main_loop();
double emscripten_get_device_pixel_ratio();
void emscripten_set_window_title(const(char)* title);
void emscripten_hide_mouse();
int emscripten_set_main_loop_timing(int mode, int value);
