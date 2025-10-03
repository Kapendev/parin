// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

module joka.stdc.stdlib;

extern(C) nothrow @nogc:

alias STDLIB_QSORT_FUNC = int function(const(void)* a, const(void)* b);

void* malloc(size_t size);
void* realloc(void* ptr, size_t size);
void free(void* ptr);
void abort();
void exit(int code);
char* getenv(const(char)* name);
int system(const(char)* command);

void qsort(void* ptr, size_t count, size_t size, STDLIB_QSORT_FUNC comp);

float strtof(const(char)* str, char** str_end);
double strtod(const(char)* str, char** str_end);
