// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `glfw3` module provides access to the glfw3.h functions.
module parin.bindings.gf.glfw3;

nothrow @nogc extern(C):

/// Sets the swap interval for the current context.
void glfwSwapInterval(int interval);
/// Makes the OpenGL or OpenGL ES context of the specified window current on the calling thread.
void glfwMakeContextCurrent(GLFWwindow* window);

struct GLFWwindow;
