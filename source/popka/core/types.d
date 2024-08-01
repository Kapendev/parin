// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `types` module provides a collection of type definitions.
module popka.core.types;

// Popka utilizes two groups of attributes:
// 1. @safe @nogc nothrow
// 2. @trusted @nogc nothrow
@safe @nogc nothrow:

alias Sz     = size_t;

alias Str    = char[];
alias Str16  = wchar[];
alias Str32  = dchar[];

alias IStr   = const(char)[];
alias IStr16 = const(wchar)[];
alias IStr32 = const(dchar)[];

alias CStr   = char*;
alias CStr16 = wchar*;
alias CStr32 = dchar*;

alias ICStr   = const(char)*;
alias ICStr16 = const(wchar)*;
alias ICStr32 = const(dchar)*;
