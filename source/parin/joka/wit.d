// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `wit` module provides types used in WIT files.
/// Since they are often similar to equivalent Rust types, they may also be useful when interacting with Rust code.
module parin.joka.wit;

import parin.joka.types;

alias WitBool   = bool;   /// The WIT `bool` type.
alias WitU8     = ubyte;  /// The WIT `u8` type.
alias WitU16    = ushort; /// The WIT `u16` type.
alias WitU32    = uint;   /// The WIT `u32` type.
alias WitU64    = ulong;  /// The WIT `u64` type.
alias WitS8     = byte;   /// The WIT `s8` type.
alias WitS16    = short;  /// The WIT `s16` type.
alias WitS32    = int;    /// The WIT `s32` type.
alias WitS64    = long;   /// The WIT `s64` type.
alias WitF32    = float;  /// The WIT `f32` type.
alias WitF64    = double; /// The WIT `f64` type.
alias WitChar   = dchar;  /// The WIT `char` type.
alias WitCharU8 = char;   /// A helper to avoid using `WitU8` for strings.
alias WitSize   = Sz;     /// A helper to change the type used for sizes.
alias WitNoData = NoData; /// Can be used with `WitResult`.

alias WitList   = ForeignSlice; /// The WIT `list` type.
alias WitOption = Option;       /// The WIT `option` type.
alias toWit = toForeign;        /// Converts a value to its WIT representation.

alias WitString = WitList!(const(WitCharU8)); /// The WIT `string` type.

// NOTE: There are some weird cases that might need special checks.
alias WitResult = Result; /// The WIT `result` type.

// NOTE: The layout of a Joka union is the same as a WIT variant: type first and then data.
alias WitVariant  = Union;  /// The WIT `variant` type.
alias WitResource = WitU32; /// The WIT `resource` type.

// A `WitEnum` is just an enum.
// A `WitFlag` is just a number (bit set).
// A `WitInterface` is just an empty struct with types and static functions.
