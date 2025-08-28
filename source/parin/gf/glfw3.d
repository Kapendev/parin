// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `glfw3` module provides access to the glfw3.h functions.
module parin.gf.glfw3;

nothrow @nogc extern(C):

void glfwSwapInterval(int interval);
