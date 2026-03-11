/// The `wit` module provides basic type definitions, compile-time functions and ASCII string helpers.
module parin.joka.wit;

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

struct WitList(T) {
    T* _ptr;
    WitSz _length;

    alias items this;

    @trusted nothrow @nogc pure:

    this(const(T)[] slice) {
        opAssign(slice);
    }

    void opAssign(const(T)[] slice) {
        _ptr = cast(T*) slice.ptr;
        _length = cast(WitSz) slice.length;
    }

    inout(T)[] items() inout {
        return _ptr[0 .. _length];
    }
}

struct WitOption(T) {
    WitBool isSome;
    T value;
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
    WitResultUnion value;
}

// A `WitTuple` and a `WitRecord` are just structs.
//   In D, you can also use the `tupleof` property to access fields with a number.

// --- User-defined Types

alias WitVariantTag = WitU8;

struct WitVariant(A...) if (A.length != 0) {
    union WitVariantUnion {
        static foreach (i, T; A) { mixin("T _m", i, ";"); }
    }

    WitVariantTag tag;
    WitVariantUnion value;
}

// A `WitEnum` is just a D enum.

alias WitResource = WitU32;

// A `WitFlag` is just a number (bit set).
