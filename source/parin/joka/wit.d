/// The `wit` module provides some types used by WIT files.
module parin.joka.wit;

import parin.joka.types;

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
alias WitString = WitList!(WitCharU8);
alias WitNoData = NoData; // Can be used with `WitResult`.

struct WitList(T) {
    T* ptr;
    WitSz length;

    alias items this;

    @trusted nothrow @nogc:

    this(T* ptr, WitSz length) {
        this.ptr = ptr;
        this.length = length;
    }

    this(T[] slice) {
        opAssign(slice);
    }

    void opAssign(T[] slice) {
        ptr = slice.ptr;
        length = cast(WitSz) slice.length;
    }

    pragma(inline, true)
    inout(T)[] items() inout {
        return ptr[0 .. length];
    }
}

struct WitOption(T) {
    WitBool isSome;
    T data;

    @trusted nothrow @nogc:

    this(in const(T) data) {
        opAssign(data);
    }

    void opAssign(in WitOption!T rhs) {
        isSome = rhs.isSome;
        data = cast(T) rhs.data;
    }

    void opAssign(in const(T) rhs) {
        isSome = true;
        data = cast(T) rhs;
    }

    pragma(inline, true)
    bool isNone() {
        return !isSome;
    }

    void clear() {
        isSome = false;
    }
}

// NOTE: There are some weird cases that might need special checks.
//   result<u32>     // no data associated with the error case
//   result<_, u32>  // no data associated with the success case
//   result          // no data associated with either case
struct WitResult(T, E) {
    union WitResultUnion {
        T value;
        E error;
    }

    WitBool isSome;
    WitResultUnion data;

    @trusted nothrow @nogc:

    this(in const(T) value) {
        opAssign(value);
    }

    this(in const(E) value) {
        opAssign(value);
    }

    void opAssign(in WitResult!(T, E) rhs) {
        isSome = rhs.isSome;
        data = cast(WitResultUnion) rhs.data;
    }

    void opAssign(in const(T) rhs) {
        isSome = true;
        data.value = cast(T) rhs;
    }

    void opAssign(in const(E) rhs) {
        isSome = false;
        data.error = cast(E) rhs;
    }

    pragma(inline, true)
    bool isNone() {
        return !isSome;
    }

    void clear() {
        isSome = false;
    }
}

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

    auto x2 = WitOption!int();
    assert(x2.isSome == false);
    assert(x2.data == 0);
    x2 = 4;
    assert(x2.isSome == true);
    assert(x2.data == 4);
    x2.clear();
    assert(x2.isSome == false);

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
