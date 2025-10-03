// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

module joka.stdc.string;

extern(C) nothrow @nogc:

int memcmp(const(void)* lhs, const(void)* rhs, size_t count);
void* memset(void* dest, int ch, size_t count);
void* memcpy(void* dest, const(void)* src, size_t count);
size_t strlen(const(char)* str);
