/// The `wit` module provides types used in WIT files.
/// Since they are often similar to equivalent Rust types, they may also be useful when interacting with Rust code.
module parin.joka.wit;

import parin.joka.types;

@trusted nothrow @nogc:

// --- Built-in Types

alias WitBool   = bool;
alias WitU8     = ubyte;
alias WitU16    = ushort;
alias WitU32    = uint;
alias WitU64    = ulong;
alias WitS8     = byte;
alias WitS16    = short;
alias WitS32    = int;
alias WitS64    = long;
alias WitF32    = float;
alias WitF64    = double;
alias WitChar   = dchar;
alias WitCharU8 = char;   // A helper to avoid using `WitU8` for strings.
alias WitSz     = size_t; // A helper to change the type used for sizes.
alias WitString = WitList!(const(WitCharU8));
alias WitNoData = NoData; // Can be used with `WitResult`.

alias WitList   = ForeignSlice;
alias WitOption = Option;

alias wit = toForeign;

// NOTE: There are some weird cases that might need special checks.
//   result<u32>     // no data associated with the error case
//   result<_, u32>  // no data associated with the success case
//   result          // no data associated with either case
// NOTE: I could add a result type in `joka.types`, but I don't like them.
alias WitResult = Result;

// A `WitTuple` and a `WitRecord` are just structs.
//   In D, you can also use the `tupleof` property to access fields with a number.

// --- User-defined Types

// NOTE: Translate members that are not types to distinct structs that use `alias this`.
//   The layout of a Joka union is the same as a WIT variant: type first and then data.
alias WitVariant = Union;

// A `WitEnum` is just an enum.

alias WitResource = WitU32;

// A `WitFlag` is just a number (bit set).
// A `WitInterface` is just an empty struct with types and static functions.

unittest {
    int[3] buffer = [1, 2, 3];

    auto x1 = WitList!int(buffer);
    assert(x1.length == 3);
    assert(x1.ptr != null);
    assert(x1[0] == 1);
    assert(buffer.wit.length == 3);

    auto x2 = WitOption!int();
    assert(x2.isSome == false);
    assert(x2.data == 0);
    x2 = 4;
    assert(x2.isSome == true);
    assert(x2.data == 4);
    x2.clear();
    assert(x2.isSome == false);
    assert(Maybe!int().wit.isNone == true);
    assert(Maybe!int(4).wit.isSome == true);

    auto x3 = WitResult!(int, WitNoData)();
    assert(x3.isSome == false);
    x3 = 4;
    assert(x3.isSome == true);
    assert(x3.data.value == 4);
    x3.clear();
    assert(x3.isSome == false);

    auto x4 = WitVariant!(WitNoData, int)();
    assert(x4.isType!int == false);
    x4 = 4;
    assert(x4.isType!int == true);
    assert(x4.as!int == 4);
    x4 = WitNoData();
    assert(x4.isType!WitNoData == true);
}
