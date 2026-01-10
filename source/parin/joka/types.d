// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `types` module provides basic type definitions, compile-time functions and ASCII string helpers.
module parin.joka.types;

alias Sz      = size_t;         /// The result of sizeof.
alias Pd      = ptrdiff_t;      /// The result of pointer math.
alias Str     = char[];         /// A string slice of chars.
alias Str16   = wchar[];        /// A string slice of wchars.
alias Str32   = dchar[];        /// A string slice of dchars.
alias IStr    = const(char)[];  /// A string slice of constant chars.
alias IStr16  = const(wchar)[]; /// A string slice of constant wchars.
alias IStr32  = const(dchar)[]; /// A string slice of constant dchars.
alias Strz    = char*;          /// A C string of chars.
alias Strz16  = wchar*;         /// A C string of wchars.
alias Strz32  = dchar*;         /// A C string of dchars.
alias IStrz   = const(char)*;   /// A C string of constant chars.
alias IStrz16 = const(wchar)*;  /// A C string of constant wchars.
alias IStrz32 = const(dchar)*;  /// A C string of constant dchars.

alias UnionType       = ubyte; /// The type of a tagged union.
alias AliasArgs(A...) = A;     /// The type of compile time alias arguments.

enum kilobyte = 1024;            /// The size of one kilobyte in bytes.
enum megabyte = 1024 * kilobyte; /// The size of one megabyte in bytes.
enum gigabyte = 1024 * megabyte; /// The size of one gigabyte in bytes.
enum terabyte = 1024 * gigabyte; /// The size of one terabyte in bytes.
enum petabyte = 1024 * terabyte; /// The size of one petabyte in bytes.
enum exabyte  = 1024 * petabyte; /// The size of one exabyte in bytes.

/// A type representing error values.
enum Fault : ubyte {
    none,          /// Not an error.
    some,          /// A generic error.
    bug,           /// An implementation error.
    invalid,       /// An invalid data error.
    overflow,      /// An overflow error.
    range,         /// A range violation error.
    assertion,     /// An assertion error.
    unconfigured,  /// A missing configuration error.
    unauthorized,  /// A permission or access rights error.
    unrecognized,  /// An unknown or unsupported type error.
    cannotFind,    /// A wrong path error.
    cannotCreate,  /// A creation permissions error.
    cannotDestroy, /// A destruction permissions error.
    cannotOpen,    /// An open permissions error.
    cannotClose,   /// A close permissions error.
    cannotRead,    /// A read permissions error.
    cannotWrite,   /// A write permissions error.
}

/// A static array.
/// It exists mainly because of BetterC + `struct[N]`.
struct StaticArray(T, Sz N) {
    alias Self = StaticArray!(T, N);
    enum length = N;   /// The length of the array.
    enum capacity = N; /// The capacity of the array. This member exists to make metaprogramming easier.

    align(T.alignof) ubyte[T.sizeof * N] _data;

    pragma(inline, true) @trusted nothrow @nogc:

    mixin sliceOps!(Self, T);

    this(const(T)[] items...) {
        if (items.length > N) assert(0, "Too many items.");
        auto me = this.items;
        foreach (i; 0 .. N) me[i] = cast(T) items[i];
    }

    /// Returns the items of the array.
    T[] items() {
        return (cast(T*) _data.ptr)[0 .. N];
    }

    /// Returns the pointer of the array.
    T* ptr() {
        return cast(T*) _data.ptr;
    }
}

/// Represents an optional value.
/// It can also hold an error code when a value is missing, and errors are referred to as faults in Joka.
struct Maybe(T) {
    alias Base = T;

    T _data;
    Fault _fault = Fault.some;

    @safe nothrow @nogc:

    this(const(T) value) {
        opAssign(value);
    }

    this(Fault fault) {
        opAssign(fault);
    }

    this(const(T) value, Fault fault) {
        if (fault) this(fault);
        else this(value);
    }

    void opAssign(Maybe!T rhs) {
        _data = rhs._data;
        _fault = rhs._fault;
    }

    @trusted
    void opAssign(const(T) rhs) {
        _data = cast(T) rhs;
        _fault = Fault.none;
    }

    void opAssign(Fault rhs) {
        _fault = rhs;
    }

    static Maybe!T some(T newValue) {
        return Maybe!T(newValue);
    }

    static Maybe!T none(Fault newFault = Fault.some) {
        return Maybe!T(newFault);
    }

    /// Returns the value without fault checking.
    ref T xx() {
        return _data;
    }

    /// Returns the fault.
    Fault fault() {
        return _fault;
    }

    /// Returns the value and traps the fault if it exists.
    ref T get(ref Fault trap) {
        trap = _fault;
        return _data;
    }

    /// Returns the value, or asserts if a fault exists.
    ref T get() {
        if (_fault) assert(0, "Fault was detected.");
        return _data;
    }

    /// Returns the value. Returns a default value when there is a fault.
    T getOr(T other) {
        return _fault ? other : _data;
    }

    /// Returns the value. Returns a default value when there is a fault.
    T getOr() {
        return _data;
    }

    /// Returns true when there is a fault.
    bool isNone() {
        return _fault != 0;
    }

    /// Returns true when there is a value.
    bool isSome() {
        return _fault == 0;
    }

    /// Clears the value, making it none.
    void clear() {
        _fault = Fault.some;
    }
}

union UnionData(A...) {
    static assert(A.length != 0, "Arguments must contain at least one element.");

    static foreach (i, T; A) {
        mixin("T _m", toCleanNumber!i, ";");
    }

    alias Types = A;
    alias Base = A[0];
}

struct Union(A...) {
    UnionData!A _data;
    UnionType _type;

    alias Types = A;
    alias Base = A[0];

    @trusted
    auto call(IStr func, AA...)(AA args) {
        switch (_type) {
            static foreach (i, T; A) {
                static assert(__traits(hasMember, T, func), funcImplementationErrorMessage!(T, func));
                mixin("case ", i, ": return _data._m", toCleanNumber!i, ".", func, "(args);");
            }
            default: assert(0, "WTF!");
        }
    }

    @trusted nothrow @nogc:

    static foreach (i, T; A) {
        this(const(T) value) {
            opAssign(value);
        }

        void opAssign(const(T) rhs) {
            auto temp = UnionData!A();
            *(cast(T*) &temp) = cast(T) rhs;
            _data = temp;
            _type = i;
        }
    }

    UnionType type() {
        return _type;
    }

    IStr typeName() {
        switch (_type) {
            static foreach (i, T; A) {
                mixin("case ", i, ": return T.stringof;");
            }
            default: assert(0, "WTF!");
        }
    }

    bool isType(T)() {
        static assert(isInAliasArgs!(T, A), "Type `" ~ T.stringof ~ "` is not part of the variant.");
        return _type == findInAliasArgs!(T, A);
    }

    ref Base base() {
        debug assert(isBaseAliasingSafe, "Not all union members start with base type `" ~ Base.stringof ~ "`.");
        return _data._m0;
    }

    ref T as(T)() {
        mixin("return _data._m", findInAliasArgs!(T, A), ";");
    }

    ref T to(T)() {
        if (isType!T) {
            return as!T;
        } else {
            static foreach (i, TT; A) {
                if (i == _type) {
                    assert(0, "Value is `" ~ A[i].stringof ~ "` and not `" ~ T.stringof ~ "`.");
                }
            }
            assert(0, "WTF!");
        }
    }

    static bool isBaseAliasingSafe() {
        foreach (T; A[1 .. $]) {
            if (is(T == struct)) {
                if (is(typeof(T.tupleof[0]) == struct)) {
                    if (!is(typeof(T.tupleof[0].tupleof[0]) == Base)) {
                        return false;
                    }
                } else if (!is(typeof(T.tupleof[0]) == Base)) {
                    return false;
                }
            } else {
                if (!is(T == Base)) return false;
            }
        }
        return true;
    }

    template typeOf(T) {
        static assert(isInAliasArgs!(T, A), "Type `" ~ T.stringof ~ "` is not part of the variant.");
        enum typeOf = findInAliasArgs!(T, A);
    }

    template typeNameOf(T) {
        static assert(isInAliasArgs!(T, A), "Type `" ~ T.stringof ~ "` is not part of the variant.");
        enum typeNameOf = T.stringof;
    }
}

T toUnion(T)(UnionType type) if (isUnionType!T) {
    T result;
    static foreach (i, Type; T.Types) {
        if (i == type) {
            result = Type.init;
            goto loopExit;
        }
    }
    loopExit:
    return result;
}

T toUnion(T)(IStr typeName) if (isUnionType!T) {
    T result;
    static foreach (i, Type; T.Types) {
        if (Type.stringof == typeName) {
            result = Type.init;
            goto loopExit;
        }
    }
    loopExit:
    return result;
}

bool isUnionType(T)() {
    return is(T : Union!A, A...);
}

bool isStrType(T)() {
    return is(T : IStr);
}

bool isStrzType(T)() {
    return is(T : IStrz);
}

int findInAliasArgs(T, A...)() {
    int result = -1;
    static foreach (i, TT; A) {
        static if (is(T == TT)) {
            result = i;
        }
    }
    return result;
}

bool isInAliasArgs(T, A...)() {
    return findInAliasArgs!(T, A) != -1;
}

IStr funcImplementationErrorMessage(T, IStr func)() {
    return "Type `" ~ T.stringof ~ "` doesn't implement the `" ~ func ~ "` function.";
}

IStr toCleanNumber(alias i)() {
    enum str = i.stringof;
    static if (str[$ - 1] == 'L' || str[$ - 1] == 'l' || str[$ - 1] == 'U' || str[$ - 1] == 'u') {
        static if (str[$ - 2] == 'L' || str[$ - 2] == 'l' || str[$ - 2] == 'U' || str[$ - 2] == 'u') {
            return str[0 .. $ - 2];
        } else {
            return str[0 .. $ - 1];
        }
    } else {
        return str;
    }
}

@trusted
Sz offsetOf(T, IStr member)() if (__traits(hasMember, T, member)) {
    T temp = void;
    return (cast(ubyte*) mixin("&temp.", member)) - (cast(ubyte*) &temp);
}

@safe nothrow @nogc pure
bool isNan(double x) {
    return !(x == x);
}

mixin template distinct(T) {
    alias Base = T;

    T _data;
    alias _data this;

    @safe nothrow @nogc {
        this(T value) {
            this._data = value;
        }

        this(typeof(this) value) {
            this._data = value._data;
        }
    }
}

deprecated("Use `sliceOps` instead.")
alias addSliceOps = sliceOps;

mixin template sliceOps(T, TT) if (__traits(hasMember, T, "items")) {
    pragma(inline, true) @trusted nothrow @nogc {
        TT[] opSlice(Sz dim)(Sz i, Sz j) {
            return items[i .. j];
        }

        TT[] opIndex() {
            return items[];
        }

        TT[] opIndex(TT[] slice) {
            return slice;
        }

        ref TT opIndex(Sz i) {
            return items[i];
        }

        void opIndexAssign(const(TT) rhs, Sz i) {
            items[i] = cast(TT) rhs;
        }

        void opIndexOpAssign(const(char)[] op)(const(TT) rhs, Sz i) {
            mixin("items[i]", op, "= cast(TT) rhs;");
        }

        Sz opDollar(Sz dim)() {
            return items.length;
        }
    }
}

deprecated("Use `xyzwOps` instead.")
alias addXyzwOps = xyzwOps;

mixin template xyzwOps(T, TT, Sz N, IStr form = "xyzw") if (__traits(hasMember, T, "items") && N >= 2 && N <= 4 && N == form.length) {
    pragma(inline, true) @trusted nothrow @nogc {
        T opUnary(IStr op)() {
            static if (N == 2) {
                return T(
                    mixin(op, form[0]),
                    mixin(op, form[1]),
                );
            } else static if (N == 3) {
                return T(
                    mixin(op, form[0]),
                    mixin(op, form[1]),
                    mixin(op, form[2]),
                );
            } else static if (N == 4) {
                return T(
                    mixin(op, form[0]),
                    mixin(op, form[1]),
                    mixin(op, form[2]),
                    mixin(op, form[3]),
                );
            }
        }

        T opBinary(IStr op)(T rhs) {
            static if (N == 2) {
                return T(
                    cast(TT) mixin(form[0], op, "rhs.", form[0]),
                    cast(TT) mixin(form[1], op, "rhs.", form[1]),
                );
            } else static if (N == 3) {
                return T(
                    cast(TT) mixin(form[0], op, "rhs.", form[0]),
                    cast(TT) mixin(form[1], op, "rhs.", form[1]),
                    cast(TT) mixin(form[2], op, "rhs.", form[2]),
                );
            } else static if (N == 4) {
                return T(
                    cast(TT) mixin(form[0], op, "rhs.", form[0]),
                    cast(TT) mixin(form[1], op, "rhs.", form[1]),
                    cast(TT) mixin(form[2], op, "rhs.", form[2]),
                    cast(TT) mixin(form[3], op, "rhs.", form[3]),
                );
            }
        }

        T opBinary(IStr op)(TT rhs) {
            static if (N == 2) {
                return T(
                    cast(TT) mixin(form[0], op, "rhs"),
                    cast(TT) mixin(form[1], op, "rhs"),
                );
            } else static if (N == 3) {
                return T(
                    cast(TT) mixin(form[0], op, "rhs"),
                    cast(TT) mixin(form[1], op, "rhs"),
                    cast(TT) mixin(form[2], op, "rhs"),
                );
            } else static if (N == 4) {
                return T(
                    cast(TT) mixin(form[0], op, "rhs"),
                    cast(TT) mixin(form[1], op, "rhs"),
                    cast(TT) mixin(form[2], op, "rhs"),
                    cast(TT) mixin(form[3], op, "rhs"),
                );
            }
        }

        T opBinaryRight(IStr op)(TT lhs) {
            static if (N == 2) {
                return T(
                    cast(TT) mixin("lhs", op, form[0]),
                    cast(TT) mixin("lhs", op, form[1]),
                );
            } else static if (N == 3) {
                return T(
                    cast(TT) mixin("lhs", op, form[0]),
                    cast(TT) mixin("lhs", op, form[1]),
                    cast(TT) mixin("lhs", op, form[2]),
                );
            } else static if (N == 4) {
                return T(
                    cast(TT) mixin("lhs", op, form[0]),
                    cast(TT) mixin("lhs", op, form[1]),
                    cast(TT) mixin("lhs", op, form[2]),
                    cast(TT) mixin("lhs", op, form[3]),
                );
            }
        }

        void opOpAssign(IStr op)(T rhs) {
            static if (N == 2) {
                mixin(form[0], op, "=rhs.", form[0], ";");
                mixin(form[1], op, "=rhs.", form[1], ";");
            } else static if (N == 3) {
                mixin(form[0], op, "=rhs.", form[0], ";");
                mixin(form[1], op, "=rhs.", form[1], ";");
                mixin(form[2], op, "=rhs.", form[2], ";");
            } else static if (N == 4) {
                mixin(form[0], op, "=rhs.", form[0], ";");
                mixin(form[1], op, "=rhs.", form[1], ";");
                mixin(form[2], op, "=rhs.", form[2], ";");
                mixin(form[3], op, "=rhs.", form[3], ";");
            }
        }

        void opOpAssign(IStr op)(TT rhs) {
            static if (N == 2) {
                mixin(form[0], op, "=rhs;");
                mixin(form[1], op, "=rhs;");
            } else static if (N == 3) {
                mixin(form[0], op, "=rhs;");
                mixin(form[1], op, "=rhs;");
                mixin(form[2], op, "=rhs;");
            } else static if (N == 4) {
                mixin(form[0], op, "=rhs;");
                mixin(form[1], op, "=rhs;");
                mixin(form[2], op, "=rhs;");
                mixin(form[3], op, "=rhs;");
            }
        }

        TT[] opSlice(Sz dim)(Sz i, Sz j) {
            return items[i .. j];
        }

        TT[] opIndex() {
            return items;
        }

        TT[] opIndex(TT[] slice) {
            return slice;
        }

        ref TT opIndex(Sz i) {
            return items[i];
        }

        void opIndexAssign(const(TT) rhs, Sz i) {
            items[i] = cast(TT) rhs;
        }

        void opIndexOpAssign(IStr op)(const(TT) rhs, Sz i) {
            mixin("items[i]", op, "= cast(TT) rhs;");
        }

        Sz opDollar(Sz dim)() {
            return N;
        }
    }

    @trusted nothrow @nogc pure {
        T _swizzleN(G)(const(G)[] args...) {
            if (args.length != N) assert(0, "Wrong swizzle length.");
            T result = void;
            foreach (i, arg; args) result.items.ptr[i] = items[arg];
            return result;
        }

        T _swizzleC(IStr args...) {
            if (args.length != N) assert(0, "Wrong swizzle length.");
            T result = void;
            foreach (i, arg; args) {
                auto hasBadArg = true;
                foreach (j, c; form) if (c == arg) {
                    result.items.ptr[i] = items.ptr[j];
                    hasBadArg = false;
                    break;
                }
                if (hasBadArg) assert(0, "Invalid swizzle component.");
            }
            return result;
        }

        T swizzle(G)(const(G)[] args...) {
            static if (is(G == char)) {
                return _swizzleC(args);
            } else {
                return _swizzleN(args);
            }
        }

        TT min() {
            auto result = mixin(form[0]);
            foreach (item; items.ptr[1 .. N]) if (item < result) result = item;
            return result;
        }

        TT max() {
            auto result = mixin(form[0]);
            foreach (item; items.ptr[1 .. N]) if (item > result) result = item;
            return result;
        }
    }
}

// Function test.
unittest {
    alias Number = Union!(float, double);
    struct Foo { int x; byte y; byte z; int w; }

    assert(toUnion!Number(Number.typeOf!float).as!float.isNan == true);
    assert(toUnion!Number(Number.typeOf!double).as!double.isNan == true);
    assert(toUnion!Number(Number.typeNameOf!float).as!float.isNan == true);
    assert(toUnion!Number(Number.typeNameOf!double).as!double.isNan == true);

    assert(isInAliasArgs!(int, AliasArgs!(float)) == false);
    assert(isInAliasArgs!(int, AliasArgs!(float, int)) == true);

    assert(offsetOf!(Foo, "x") == 0);
    assert(offsetOf!(Foo, "y") == 4);
    assert(offsetOf!(Foo, "z") == 5);
    assert(offsetOf!(Foo, "w") == 8);
}

// Maybe test.
unittest {
    assert(Maybe!int().fault == Fault.some);
    assert(Maybe!int().getOr() == 0);
    assert(Maybe!int(0).fault == Fault.none);
    assert(Maybe!int(0).getOr() == 0);
    assert(Maybe!int(69).fault == Fault.none);
    assert(Maybe!int(69).getOr() == 69);
    assert(Maybe!int(Fault.none).fault == Fault.none);
    assert(Maybe!int(Fault.none).getOr() == 0);
    assert(Maybe!int(Fault.some).fault == Fault.some);
    assert(Maybe!int(Fault.some).getOr() == 0);
    assert(Maybe!int(69, Fault.none).fault == Fault.none);
    assert(Maybe!int(69, Fault.none).getOr() == 69);
    assert(Maybe!int(69, Fault.some).fault == Fault.some);
    assert(Maybe!int(69, Fault.some).getOr() == 0);
}

// Union test.
unittest {
    alias Number = Union!(float, double);

    assert(Number().typeName == "float");
    assert(Number().isType!float == true);
    assert(Number().isType!double == false);
    assert(Number().as!float.isNan);
    assert(Number(0.0f).typeName == "float");
    assert(Number(0.0f).isType!float == true);
    assert(Number(0.0f).isType!double == false);
    assert(Number(0.0f).as!float == 0);
    assert(Number(0.0).isType!float == false);
    assert(Number(0.0).isType!double == true);
    assert(Number(0.0).typeName == "double");
    assert(Number(0.0).as!double == 0);
    assert(Number.typeOf!float == 0);
    assert(Number.typeOf!double == 1);
    assert(Number.typeNameOf!float == "float");
    assert(Number.typeNameOf!double == "double");

    auto number = Number();
    number = 0.0;
    assert(number.as!double == 0);
    number = 0.0f;
    assert(number.as!float == 0);
    number.as!float += 69.0f;
    assert(number.as!float == 69);

    auto numberPtr = &number.as!float();
    *numberPtr *= 10;
    assert(number.as!float == 690);

    assert(Number.isBaseAliasingSafe == false);
    struct Foo1 { float a; }
    struct Foo2 { alias x = int; float b; }
    struct Foo3 { Foo1 c; }
    assert(Union!(float, Foo1).isBaseAliasingSafe == true);
    assert(Union!(float, Foo2).isBaseAliasingSafe == true);
    assert(Union!(float, Foo3).isBaseAliasingSafe == true);
    assert(Union!(float, Foo1, Foo2, Foo3).isBaseAliasingSafe == true);
}

// Distinct test.
unittest {
    struct Foo { mixin distinct!int; }

    assert(is(Foo == int) == false);
    assert(is(Foo : int) == true);
    assert(is(int : Foo) == false);

    auto a = Foo(0);
    a = 1;
    a += 2;
    assert(a == 3);

    auto b = a;
    assert(b == a);
}

// --- ASCII

@safe:

enum defaultAsciiBufferCount = 16;   /// Generic string count.
enum defaultAsciiBufferSize  = 2048; /// Generic string length.

enum defaultAsciiFmtArgStr         = "{}"; /// The format argument symbol.
enum defaultAsciiFmtArgBufferCount = 32;   /// Format argument count.
enum defaultAsciiFmtArgBufferSize  = 1024; /// Format argument length.
enum defaultAsciiFmtBufferCount    = 32;   /// Format string count.
enum defaultAsciiFmtBufferSize     = 2048; /// Format string length.

enum digitChars    = "0123456789";                         /// The set of decimal numeric characters.
enum upperChars    = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";         /// The set of uppercase letters.
enum lowerChars    = "abcdefghijklmnopqrstuvwxyz";         /// The set of lowercase letters.
enum alphaChars    = upperChars ~ lowerChars;              /// The set of letters.
enum spaceChars    = " \t\v\r\n\f";                        /// The set of whitespace characters.
enum symbolChars   = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"; /// The set of symbol characters.
enum hexDigitChars = "0123456789abcdefABCDEF";             /// The set of hexadecimal numeric characters.

version (Windows) {
    enum pathSep = '\\';
    enum pathSepStr = "\\";
    enum pathSepOther = '/';
    enum pathSepOtherStr = "/";
} else {
    enum pathSep = '/';          /// The primary OS path separator as a character.
    enum pathSepStr = "/";       /// The primary OS path separator as a string.
    enum pathSepOther = '\\';    /// The complementary OS path separator as a character.
    enum pathSepOtherStr = "\\"; /// The complementary OS path separator as a string.
}

enum sp = Sep(" ");  /// Space separator.
enum cm = Sep(", "); /// Comma + space separator.

/// Path separator style.
enum PathSepStyle {
    native,  /// The platform's default separator.
    posix,   /// The `/` separator.
    windows, /// The `\` separator.
}

/// A string pair.
struct IStrPair { IStr a; IStr b; }

/// Separator marker for printing.
struct Sep { IStr value; }

/// A wrapper type for priting floats and doubles.
struct Floating {
    double value = 0.0; /// The value.
    uint precision = 2; /// The number of digits after the dot.

    @safe nothrow @nogc:

    IStr toStr() {
        return floatingToStr(value, precision);
    }

    IStr toString() {
        return toStr();
    }
}

// ---------- IES Support
static if (__traits(compiles, { import core.interpolation; })) {
    public import core.interpolation;
} else {
    // pragma(msg, "Joka: Using custom interpolation functions.");

    // Functions below are copy-pasted from core.interpolation.

    public IStr __getEmptyString() @nogc pure nothrow @safe {
        return "";
    }

    struct InterpolationHeader {
        alias toString = __getEmptyString;
    }

    struct InterpolationFooter {
        alias toString = __getEmptyString;
    }

    struct InterpolatedLiteral(IStr text) {
        static IStr toString() @nogc pure nothrow @safe {
            return text;
        }
    }

    struct InterpolatedExpression(IStr text) {
        enum expression = text;
        alias toString = __getEmptyString;
    }
}

// NOTE: A BetterC fix. It's only needed when using IES.
version (D_BetterC) {
    extern(C) @nogc pure nothrow @safe
    IStr _D4core13interpolation16__getEmptyStringFNaNbNiNfZAya() { return ""; }
}

// NOTE: Helper functions.
template isInterLitType(TT) { enum isInterLitType = is(TT == InterpolatedLiteral!_, alias _); }
template isInterExpType(TT) { enum isInterExpType = is(TT == InterpolatedExpression!_, alias _); }
// ----------

/// Converts the value to its string representation.
@trusted
IStr toStr(T)(T value) {
    static assert(
        !(is(T : const(A)[N], A, Sz N)), // !isArrayType
        "Static arrays can't be passed to `toStr`. This may also happen indirectly when using printing functions. Convert to a slice first."
    );

    static if (is(T == enum)) { // isEnumType
        return enumToStr(value);
    } else static if (is(T == char) || is(T == const(char)) || is(T == immutable(char))) { // isCharType
        return charToStr(value);
    } else static if (is(T == bool) || is(T == const(bool)) || is(T == immutable(bool))) { // isBoolType
        return boolToStr(value);
    } else static if (__traits(isUnsigned, T)) { // isUnsignedType
        return unsignedToStr(value);
    } else static if (__traits(isIntegral, T)) { // isSignedType
        return signedToStr(value);
    } else static if (__traits(isFloating, T)) { // isFloating
        return floatingToStr(value, 2);
    } else static if (is(T : IStr)) { // isStrType
        return value;
    } else static if (is(T : IStrz)) { // isStrzType
        return strzToStr(value);
    } else static if (__traits(hasMember, T, "toStr")) {
        return value.toStr();
    } else static if (__traits(hasMember, T, "toString")) {
        return value.toString();
    } else {
        static assert(0, "Type doesn't implement the `toStr` function.");
    }
}

/// Formats the given string by replacing `{}` placeholders with argument values in order.
/// Options within placeholders are not supported.
/// For custom formatting use a wrapper type with a `toStr` method.
/// Writes into the buffer and returns the formatted string.
@trusted nothrow @nogc
IStr fmtIntoBufferWithStrs(Str buffer, IStr fmtStr, IStr[] args...) {
    auto result = buffer;
    auto resultLength = 0;
    auto fmtStrIndex = 0;
    auto argIndex = 0;
    while (fmtStrIndex < fmtStr.length) {
        auto c1 = fmtStr[fmtStrIndex];
        auto c2 = fmtStrIndex + 1 >= fmtStr.length ? '+' : fmtStr[fmtStrIndex + 1];
        if (c1 == defaultAsciiFmtArgStr[0] && c2 == defaultAsciiFmtArgStr[1]) {
            if (argIndex == args.length) assert(0, "A placeholder doesn't have an argument.");
            if (copyChars(result, args[argIndex], resultLength)) return "";
            resultLength += args[argIndex].length;
            fmtStrIndex += 2;
            argIndex += 1;
        } else {
            result[resultLength] = c1;
            resultLength += 1;
            fmtStrIndex += 1;
        }
    }
    if (argIndex != args.length) assert(0, "An argument doesn't have a placeholder.");
    result = result[0 .. resultLength];
    return result;
}

char[defaultAsciiFmtArgBufferSize][defaultAsciiFmtArgBufferCount] _fmtIntoBufferDataBuffer = void;
IStr[defaultAsciiFmtArgBufferCount]                               _fmtIntoBufferSliceBuffer = void;
char[defaultAsciiFmtBufferSize][defaultAsciiFmtBufferCount]       _fmtBuffer = void;
byte                                                              _fmtBufferIndex = 0;

/// Formats the given string by replacing `{}` placeholders with argument values in order.
/// Options within placeholders are not supported.
/// For custom formatting use a wrapper type with a `toStr` method.
/// Writes into the buffer and returns the formatted string.
@trusted
IStr fmtIntoBuffer(A...)(Str buffer, IStr fmtStr, A args) {
    static assert(args.length <= defaultAsciiFmtArgBufferCount, "Too many format arguments.");
    Str tempSlice;
    foreach (i, arg; args) {
        tempSlice = _fmtIntoBufferDataBuffer[i][];
        if (tempSlice.copyStr(arg.toStr())) return ""; // "An argument did not fit in the internal temporary buffer."
        _fmtIntoBufferSliceBuffer[i] = tempSlice;
    }
    return fmtIntoBufferWithStrs(buffer, fmtStr, _fmtIntoBufferSliceBuffer[0 .. args.length]);
}

IStr fmtIntoBuffer(A...)(Str buffer, InterpolationHeader header, A args, InterpolationFooter footer) {
    // NOTE: Both `fmtStr` and `fmtArgs` can be copy-pasted when working with IES. Main copy is in the `fmt` function.
    enum fmtStr = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T) { result ~= args[i].toString(); }
            else static if (isInterExpType!T) { result ~= defaultAsciiFmtArgStr; }
        } return result;
    }();
    enum fmtArgs = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T || isInterExpType!T) {}
            else { result ~= "args[" ~ i.stringof ~ "],"; }
        } return result;
    }();
    return mixin("fmtIntoBuffer(buffer, fmtStr,", fmtArgs, ")");
}

/// Formats into an internal static ring buffer and returns the slice.
/// The slice is temporary and may be overwritten by later calls to `fmt`.
/// For details on formatting, see the `fmtIntoBuffer` function.
@trusted
IStr fmt(A...)(IStr fmtStr, A args) {
    _fmtBufferIndex = (_fmtBufferIndex + 1) % _fmtBuffer.length;
    auto buffer = _fmtBuffer[_fmtBufferIndex][];

    // `fmtIntoBuffer` body copy-pasted here to avoid one template.
    static assert(args.length <= defaultAsciiFmtArgBufferCount, "Too many format arguments.");
    Str tempSlice;
    foreach (i, arg; args) {
        tempSlice = _fmtIntoBufferDataBuffer[i][];
        if (tempSlice.copyStr(arg.toStr())) return ""; // "An argument did not fit in the internal temporary buffer."
        _fmtIntoBufferSliceBuffer[i] = tempSlice;
    }
    return fmtIntoBufferWithStrs(buffer, fmtStr, _fmtIntoBufferSliceBuffer[0 .. args.length]);
}

IStr fmt(A...)(InterpolationHeader header, A args, InterpolationFooter footer) {
    // NOTE: Both `fmtStr` and `fmtArgs` can be copy-pasted when working with IES. Main copy is in the `fmt` function.
    enum fmtStr = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T) { result ~= args[i].toString(); }
            else static if (isInterExpType!T) { result ~= defaultAsciiFmtArgStr; }
        } return result;
    }();
    enum fmtArgs = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T || isInterExpType!T) {}
            else { result ~= "args[" ~ i.stringof ~ "],"; }
        } return result;
    }();
    return mixin("fmt(fmtStr,", fmtArgs, ")");
}

@safe nothrow @nogc:

/// Formats into an internal static ring buffer and returns the slice.
/// This function can be used for types that create a lot of template bloat.
/// Example: GVec2, GVec3, GVec4, GRect, ...
IStr fmtSignedGroup(IStr[] fmtStrs, long[] args...) {
    if (fmtStrs.length != args.length) assert(0, "Argument count and format count should be the same.");
    switch (fmtStrs.length) {
        case 1:
            return concat(
                fmtStrs[0].fmt(args[0]),
            );
        case 2:
            return concat(
                fmtStrs[0].fmt(args[0]),
                fmtStrs[1].fmt(args[1]),
            );
        case 3:
            return concat(
                fmtStrs[0].fmt(args[0]),
                fmtStrs[1].fmt(args[1]),
                fmtStrs[2].fmt(args[2]),
            );
        case 4:
            return concat(
                fmtStrs[0].fmt(args[0]),
                fmtStrs[1].fmt(args[1]),
                fmtStrs[2].fmt(args[2]),
                fmtStrs[3].fmt(args[3]),
            );
        default:
            assert(0, "Argument count should be between 1 and 4.");
    }
}

/// Formats into an internal static ring buffer and returns the slice.
/// This function can be used for types that create a lot of template bloat.
/// Example: GVec2, GVec3, GVec4, GRect, ...
IStr fmtFloatingGroup(IStr[] fmtStrs, double[] args...) {
    if (fmtStrs.length != args.length) assert(0, "Argument count and format count should be the same.");
    switch (fmtStrs.length) {
        case 1:
            return concat(
                fmtStrs[0].fmt(args[0]),
            );
        case 2:
            return concat(
                fmtStrs[0].fmt(args[0]),
                fmtStrs[1].fmt(args[1]),
            );
        case 3:
            return concat(
                fmtStrs[0].fmt(args[0]),
                fmtStrs[1].fmt(args[1]),
                fmtStrs[2].fmt(args[2]),
            );
        case 4:
            return concat(
                fmtStrs[0].fmt(args[0]),
                fmtStrs[1].fmt(args[1]),
                fmtStrs[2].fmt(args[2]),
                fmtStrs[3].fmt(args[3]),
            );
        default:
            assert(0, "Argument count should be between 1 and 4.");
    }
}

pragma(inline, true) {
    /// Wraps a floating value with formatting options.
    Floating flo(double value, uint precision) {
        return Floating(value, precision);
    }

    /// Returns true if the character is a digit (0-9).
    bool isDigit(char c) {
        return c >= '0' && c <= '9';
    }

    /// Returns true if the character is an uppercase letter (A-Z).
    bool isUpper(char c) {
        return c >= 'A' && c <= 'Z';
    }

    /// Returns true the character is a lowercase letter (a-z).
    bool isLower(char c) {
        return c >= 'a' && c <= 'z';
    }

    /// Returns true if the character is an alphabetic letter (A-Z, a-z).
    bool isAlpha(char c) {
        return isLower(c) || isUpper(c);
    }

    /// Returns true if the character is a whitespace character (space, tab, ...).
    bool isSpace(char c) {
        return (c >= '\t' && c <= '\r') || (c == ' ');
    }

    /// Returns true if the character is a symbol (!, ", ...).
    bool isSymbol(char c) {
        return (c >= '!' && c <= '/') || (c >= ':' && c <= '@') || (c >= '[' && c <= '`') || (c >= '{' && c <= '~');
    }

    /// Returns true if the character is a hexadecimal digit (0-9, A-F, a-f).
    bool isHexDigit(char c) {
        return isDigit(c) || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f');
    }

    /// Returns true if the string represents a C string.
    bool isStrz(IStr str) {
        return str.length != 0 && str[$ - 1] == '\0';
    }

    /// Converts the character to uppercase if it is a lowercase letter.
    char toUpper(char c) {
        return isLower(c) ? cast(char) (c - 32) : c;
    }

    /// Converts the character to lowercase if it is an uppercase letter.
    char toLower(char c) {
        return isUpper(c) ? cast(char) (c + 32) : c;
    }

    /// Converts all lowercase letters in the string to uppercase.
    Str toUpper(Str str) {
        foreach (ref c; str) c = toUpper(c);
        return str;
    }

    /// Converts all uppercase letters in the string to lowercase.
    Str toLower(Str str) {
        foreach (ref c; str) c = toLower(c);
        return str;
    }

    /// Returns the length of the C string.
    @trusted
    Sz strzLength(IStrz str) {
        Sz result = 0;
        while (str[result]) result += 1;
        return result;
    }
}

/// Returns true if the two strings are equal, ignoring case.
bool equalsNoCase(IStr str, IStr other) {
    if (str.length != other.length) return false;
    foreach (i; 0 .. str.length) if (toUpper(str[i]) != toUpper(other[i])) return false;
    return true;
}

/// Returns true if the string is equal to the specified character, ignoring case.
bool equalsNoCase(IStr str, char other) {
    return equalsNoCase(str, charToStr(other));
}

/// Returns true if the string starts with the specified substring.
bool startsWith(IStr str, IStr start) {
    if (str.length < start.length) return false;
    return str[0 .. start.length] == start;
}

/// Returns true if the string starts with the specified character.
bool startsWith(IStr str, char start) {
    return startsWith(str, charToStr(start));
}

/// Returns true if the string ends with the specified substring.
bool endsWith(IStr str, IStr end) {
    if (str.length < end.length) return false;
    return str[$ - end.length .. $] == end;
}

/// Returns true if the string ends with the specified character.
bool endsWith(IStr str, char end) {
    return endsWith(str, charToStr(end));
}

/// Counts the number of occurrences of the specified substring in the string.
int countItem(IStr str, IStr item) {
    int result = 0;
    if (str.length < item.length || item.length == 0) return result;
    foreach (i; 0 .. str.length - item.length) {
        if (str[i .. i + item.length] == item) {
            result += 1;
            i += item.length - 1;
        }
    }
    return result;
}

/// Counts the number of occurrences of the specified character in the string.
int countItem(IStr str, char item) {
    return countItem(str, charToStr(item));
}

/// Finds the starting index of the first occurrence of the specified substring in the string, or returns -1 if not found.
int findStart(IStr str, IStr item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach (i; 0 .. str.length - item.length + 1) {
        if (str[i .. i + item.length] == item) return cast(int) i;
    }
    return -1;
}

/// Finds the starting index of the first occurrence of the specified character in the string, or returns -1 if not found.
int findStart(IStr str, char item) {
    return findStart(str, charToStr(item));
}

/// Finds the ending index of the first occurrence of the specified substring in the string, or returns -1 if not found.
int findEnd(IStr str, IStr item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach_reverse (i; 0 .. str.length - item.length + 1) {
        if (str[i .. i + item.length] == item) return cast(int) i;
    }
    return -1;
}

/// Finds the ending index of the first occurrence of the specified character in the string, or returns -1 if not found.
int findEnd(IStr str, char item) {
    return findEnd(str, charToStr(item));
}

/// Finds the first occurrence of the specified item in the slice, or returns -1 if not found.
int findItem(IStr[] items, IStr item) {
    foreach (i, it; items) if (it == item) return cast(int) i;
    return -1;
}

/// Finds the first occurrence of the specified start in the slice, or returns -1 if not found.
int findItemThatStartsWith(IStr[] items, IStr start) {
    foreach (i, it; items) if (it.startsWith(start)) return cast(int) i;
    return -1;
}

/// Finds the first occurrence of the specified end in the slice, or returns -1 if not found.
int findItemThatEndsWith(IStr[] items, IStr end) {
    foreach (i, it; items) if (it.endsWith(end)) return cast(int) i;
    return -1;
}

/// Removes whitespace characters from the beginning of the string.
IStr trimStart(IStr str) {
    IStr result = str;
    while (result.length > 0) {
        if (isSpace(result[0])) result = result[1 .. $];
        else break;
    }
    return result;
}

/// Removes whitespace characters from the end of the string.
IStr trimEnd(IStr str) {
    IStr result = str;
    while (result.length > 0) {
        if (isSpace(result[$ - 1])) result = result[0 .. $ - 1];
        else break;
    }
    return result;
}

/// Removes whitespace characters from both the beginning and end of the string.
IStr trim(IStr str) {
    return str.trimStart().trimEnd();
}

/// Removes the specified prefix from the beginning of the string if it exists.
IStr removePrefix(IStr str, IStr prefix) {
    if (str.startsWith(prefix)) return str[prefix.length .. $];
    else return str;
}

/// Removes the specified suffix from the end of the string if it exists.
IStr removeSuffix(IStr str, IStr suffix) {
    if (str.endsWith(suffix)) return str[0 .. $ - suffix.length];
    else return str;
}

/// Advances the string by the specified number of characters.
IStr advanceStr(IStr str, Sz amount) {
    if (str.length < amount) return str[$ .. $];
    else return str[amount .. $];
}

/// Copies characters from the source string to the destination string starting at the specified index.
@trusted
Fault copyChars(Str str, IStr source, Sz startIndex = 0) {
    if (str.length < source.length + startIndex) return Fault.overflow;
    str[startIndex .. startIndex + source.length] = source[];
    return Fault.none;
}

/// Copies characters from the source string to the destination string starting at the specified index and adjusts the length of the destination string.
Fault copyStr(ref Str str, IStr source, Sz startIndex = 0) {
    auto fault = copyChars(str, source, startIndex);
    if (fault) return fault;
    str = str[0 .. startIndex + source.length];
    return Fault.none;
}

/// Concatenates the strings.
/// Writes into the buffer and returns the result.
IStr concatIntoBuffer(Str buffer, IStr[] args...) {
    if (args.length == 0) return ".";
    auto result = buffer;
    auto length = 0;
    foreach (i, arg; args) {
        result.copyChars(arg, length);
        length += arg.length;
    }
    result = result[0 .. length];
    return result;
}

/// Concatenates the strings using a static buffer and returns the result.
IStr concat(IStr[] args...) {
    static char[defaultAsciiBufferSize][defaultAsciiBufferCount] buffers = void;
    static byte bufferIndex = 0;

    if (args.length == 0) return ".";
    bufferIndex = (bufferIndex + 1) % buffers.length;
    return concatIntoBuffer(buffers[bufferIndex][], args);
}

/// Splits the string using a static buffer and returns the result.
@trusted
IStr[] split(IStr str, IStr sep) {
    static IStr[defaultAsciiBufferSize][defaultAsciiBufferCount] buffers = void;
    static byte bufferIndex = 0;

    bufferIndex = (bufferIndex + 1) % buffers.length;
    auto length = 0;
    while (str.length != 0) {
        buffers[bufferIndex][length] = str.skipValue(sep);
        length += 1;
    }
    return buffers[bufferIndex][0 .. length];
}

/// Splits the string using a static buffer and returns the result.
IStr[] split(IStr str, char sep) {
    return split(str, charToStr(sep));
}

/// Returns true if the given path is absolute.
bool isAbsolutePath(IStr path, PathSepStyle style = PathSepStyle.native) {
    if (path.length == 0) return false;
    auto isPosix = style == PathSepStyle.posix;
    if (style == PathSepStyle.native) {
        version (Windows) isPosix = false;
        else isPosix = true;
    }
    if (isPosix) {
        return path.startsWith("/");
    } else {
        if (path.startsWith("\\\\")) {
            return true; // UNC.
        } else if (path[0].isAlpha) {
            return path[1 .. $].startsWith(":\\") || path[1 .. $].startsWith(":/"); // Drive.
        } else if (path.startsWith("/") || path.startsWith("\\")) {
            return true; // Rooted.
        } else {
            return false;
        }
    }
}

/// Returns the main and alternate separators for the given style.
IStrPair pathSepStrPair(PathSepStyle style) {
    with (PathSepStyle) final switch (style) {
        case native: return IStrPair(pathSepStr, pathSepOtherStr);
        case posix: return IStrPair("/", "\\");
        case windows: return IStrPair("\\", "/");
    }
}

/// Returns the directory of the path, or "." if there is no directory.
IStr pathDirName(IStr path, PathSepStyle style = PathSepStyle.native) {
    auto pair = pathSepStrPair(style);
    auto end = findEnd(path, pair.a);
    if (end == -1) return ".";
    else return path[0 .. end];
}

/// Returns the extension of the path.
IStr pathExtName(IStr path) {
    auto end = findEnd(path, ".");
    if (end == -1) return "";
    else return path[end .. $];
}

/// Returns the base name of the path.
IStr pathBaseName(IStr path, PathSepStyle style = PathSepStyle.native) {
    auto pair = pathSepStrPair(style);
    auto end = findEnd(path, pair.a);
    if (end == -1) return path;
    else return path[end + 1 .. $];
}

/// Returns the base name of the path without the extension.
IStr pathBaseNameNoExt(IStr path) {
    return path.pathBaseName[0 .. $ - path.pathExtName.length];
}

/// Removes path separators from the beginning of the path.
IStr pathTrimStart(IStr path, PathSepStyle style = PathSepStyle.native) {
    auto result = path;
    auto pair = pathSepStrPair(style);
    while (result.length > 0) {
        if (result[0] == pair.a[0] || result[0] == pair.b[0]) result = result[1 .. $];
        else break;
    }
    return result;

}

/// Removes path separators from the end of the path.
IStr pathTrimEnd(IStr path, PathSepStyle style = PathSepStyle.native) {
    auto result = path;
    auto pair = pathSepStrPair(style);
    while (result.length > 0) {
        if (result[$ - 1] == pair.a[0] || result[$ - 1] == pair.b[0]) result = result[0 .. $ - 1];
        else break;
    }
    return result;
}

/// Removes path separators from the beginning and end of the path.
IStr pathTrim(IStr path) {
    return path.pathTrimStart().pathTrimEnd();
}

/// Formats the path to a standard form, normalizing separators.
IStr pathFmt(IStr path, PathSepStyle style = PathSepStyle.native) {
    static char[defaultAsciiBufferSize][defaultAsciiBufferCount] buffers = void;
    static byte bufferIndex = 0;

    if (path.length == 0) return ".";
    bufferIndex = (bufferIndex + 1) % buffers.length;
    auto bufferSlice = buffers[bufferIndex][];
    auto pair = pathSepStrPair(style);
    foreach (i, c; path) bufferSlice[i] = c == pair.b[0] ? pair.a[0] : c;
    return bufferSlice[0 .. path.length];
}

/// Concatenates the paths, ensuring proper path separators between them.
IStr pathConcat(IStr[] args...) {
    return pathConcat(PathSepStyle.native, args);
}

/// Concatenates the paths, ensuring proper path separators between them.
IStr pathConcat(PathSepStyle style, IStr[] args...) {
    static char[defaultAsciiBufferSize][defaultAsciiBufferCount] buffers = void;
    static byte bufferIndex = 0;

    if (args.length == 0) return ".";
    bufferIndex = (bufferIndex + 1) % buffers.length;
    auto bufferSlice = buffers[bufferIndex][];
    auto pair = pathSepStrPair(style);
    auto length = 0;
    auto isFirst = true;
    foreach (i, arg; args) {
        if (arg.length == 0) continue;
        auto cleanArg = arg;
        if (cleanArg[0] == pair.a[0] || cleanArg[0] == pair.b[0]) {
            cleanArg = cleanArg.pathTrimStart();
            if (isFirst) {
                bufferSlice[length] = pair.a[0];
                length += 1;
            }
        }
        cleanArg = cleanArg.pathTrimEnd();
        bufferSlice.copyChars(cleanArg, length);
        length += cleanArg.length;
        if (i != args.length - 1) {
            bufferSlice[length] = pair.a[0];
            length += 1;
        }
        isFirst = false;
    }
    if (length == 0) return ".";
    return bufferSlice[0 .. length];
}

/// Splits the path using a static buffer and returns the result.
@trusted
IStr[] pathSplit(IStr str, PathSepStyle style = PathSepStyle.native) {
    static IStr[defaultAsciiBufferSize][defaultAsciiBufferCount] buffers = void;
    static byte bufferIndex = 0;

    bufferIndex = (bufferIndex + 1) % buffers.length;
    auto pair = pathSepStrPair(style);
    auto length = 0;
    while (str.length != 0) {
        buffers[bufferIndex][length] = str.skipValue(pair.a);
        length += 1;
    }
    return buffers[bufferIndex][0 .. length];
}

/// Skips over the next occurrence of the specified separator in the string, returning the substring before the separator and updating the input string to start after the separator.
IStr skipValue(ref inout(char)[] str, IStr sep) {
    if (str.length < sep.length || sep.length == 0) {
        str = str[$ .. $];
        return "";
    }
    foreach (i; 0 .. str.length - sep.length) {
        if (str[i .. i + sep.length] == sep) {
            auto line = str[0 .. i];
            str = str[i + sep.length .. $];
            return line;
        }
    }
    auto line = str[0 .. $];
    if (str[$ - sep.length .. $] == sep) {
        line = str[0 .. $ - 1];
    }
    str = str[$ .. $];
    return line;
}

/// Skips over the next occurrence of the specified separator in the string, returning the substring before the separator and updating the input string to start after the separator.
IStr skipValue(ref inout(char)[] str, char sep) {
    return skipValue(str, charToStr(sep));
}

/// Skips over the next line in the string, returning the substring before the line break and updating the input string to start after the line break.
IStr skipLine(ref inout(char)[] str) {
    auto result = skipValue(str, '\n');
    if (result.length != 0 && result[$ - 1] == '\r') result = result[0 .. $ - 1];
    return result;
}

/// Converts the boolean value to its string representation.
IStr boolToStr(bool value, bool isShortName = false, bool isLower = false) {
    return value ? (isShortName ? (isLower ? "t" : "T") : "true") : (isShortName ? (isLower ? "f" : "F") : "false");
}

/// Converts the character to its string representation.
IStr charToStr(char value) {
    static char[1] buffer = void;

    auto result = buffer[];
    result[0] = value;
    result = result[0 .. 1];
    return result;
}

/// Converts the unsigned long value to its string representation.
IStr unsignedToStr(ulong value) {
    static char[64] buffer = void;

    auto result = buffer[];
    if (value == 0) {
        result[0] = '0';
        result = result[0 .. 1];
    } else {
        auto digitCount = 0;
        for (auto temp = value; temp != 0; temp /= 10) {
            result[$ - 1 - digitCount] = (temp % 10) + '0';
            digitCount += 1;
        }
        result = result[$ - digitCount .. $];
    }
    return result;
}

/// Converts the signed long value to its string representation.
IStr signedToStr(long value) {
    static char[64] buffer = void;

    auto result = buffer[];
    if (value < 0) {
        auto temp = unsignedToStr(-value);
        result[0] = '-';
        result.copyStr(temp, 1);
    } else {
        auto temp = unsignedToStr(value);
        result.copyStr(temp, 0);
    }
    return result;
}

/// Converts the double value to its string representation with the specified precision.
IStr floatingToStr(double value, uint precision = 2) {
    static char[64] buffer = void;

    if (value.isNan) return "nan";
    if (precision == 0) return signedToStr(cast(long) value);

    auto result = buffer[];
    auto cleanNumber = value;
    auto rightDigitCount = 0;
    while (cleanNumber != cast(double) (cast(long) cleanNumber)) {
        rightDigitCount += 1;
        cleanNumber *= 10;
    }

    // Add extra zeros at the end if needed.
    // I do this because it makes it easier to remove the zeros later.
    if (precision > rightDigitCount) {
        foreach (j; 0 .. precision - rightDigitCount) {
            rightDigitCount += 1;
            cleanNumber *= 10;
        }
    }

    // Digits go in the buffer from right to left.
    auto cleanNumberStr = signedToStr(cast(long) cleanNumber);
    auto i = result.length;
    // Check two cases: 0.NN, N.NN
    if (cast(long) value == 0) {
        if (value < 0.0) {
            cleanNumberStr = cleanNumberStr[1 .. $];
        }
        i -= cleanNumberStr.length;
        result.copyChars(cleanNumberStr, i);
        foreach (j; 0 .. rightDigitCount - cleanNumberStr.length) {
            i -= 1;
            result[i] = '0';
        }
        i -= 2;
        result.copyChars("0.", i);
        if (value < 0.0) {
            i -= 1;
            result[i] = '-';
        }
    } else {
        i -= rightDigitCount;
        result.copyChars(cleanNumberStr[$ - rightDigitCount .. $], i);
        i -= 1;
        result[i] = '.';
        i -= cleanNumberStr.length - rightDigitCount;
        result.copyChars(cleanNumberStr[0 .. $ - rightDigitCount], i);
    }
    // Remove extra zeros at the end if needed.
    if (precision < rightDigitCount) {
        result = result[0 .. cast(Sz) ($ - rightDigitCount + precision)];
    }
    return result[i .. $];
}

/// Converts the C string to a string.
@trusted
IStr strzToStr(IStrz value) {
    return value[0 .. value.strzLength];
}

/// Converts the enum value to its string representation.
IStr enumToStr(T)(T value) {
    switch (value) {
        static foreach (m; __traits(allMembers, T)) {
            mixin("case T.", m, ": return m;");
        }
        default: return "?";
    }
}

/// Converts the string to a bool.
Maybe!bool toBool(IStr str, bool isFullNameOnly = false, bool isUpperOnly = false) {
    if (str == "false" || (isFullNameOnly ? false : (isUpperOnly ? str == "F" : str == "F" || str == "f"))) {
        return Maybe!bool(false);
    } else if (str == "true" || (isFullNameOnly ? false : (isUpperOnly ? str == "T" : str == "T" || str == "t"))) {
        return Maybe!bool(true);
    } else {
        return Maybe!bool(Fault.invalid);
    }
}

/// Converts the string to a ulong.
Maybe!ulong toUnsigned(IStr str) {
    if (str.length == 0 || str.length >= 18) {
        return Maybe!ulong(Fault.overflow);
    } else {
        if (str.length == 1 && str[0] == '+') {
            return Maybe!ulong(Fault.invalid);
        }
        ulong value = 0;
        ulong level = 1;
        foreach_reverse (i, c; str[(str[0] == '+' ? 1 : 0) .. $]) {
            if (isDigit(c)) {
                value += (c - '0') * level;
                level *= 10;
            } else {
                return Maybe!ulong(Fault.invalid);
            }
        }
        return Maybe!ulong(value);
    }
}

/// Converts the character to a ulong.
Maybe!ulong toUnsigned(char c) {
    if (isDigit(c)) {
        return Maybe!ulong(c - '0');
    } else {
        return Maybe!ulong(Fault.invalid);
    }
}

/// Converts the string to a long.
Maybe!long toSigned(IStr str) {
    if (str.length == 0 || str.length >= 18) {
        return Maybe!long(Fault.overflow);
    } else {
        auto temp = toUnsigned(str[(str[0] == '-' ? 1 : 0) .. $]);
        return Maybe!long(str[0] == '-' ? -temp.xx : temp.xx, temp.fault);
    }
}

/// Converts the character to a long.
Maybe!long toSigned(char c) {
    if (isDigit(c)) {
        return Maybe!long(c - '0');
    } else {
        return Maybe!long(Fault.invalid);
    }
}

/// Converts the string to a double.
Maybe!double toFloating(IStr str) {
    if (str == "nan" || str == "NaN" || str == "NAN") return Maybe!double(double.nan);
    auto dotIndex = findStart(str, '.');
    if (dotIndex == -1) {
        auto temp = toSigned(str);
        return Maybe!double(temp.xx, temp.fault);
    } else {
        auto left = toSigned(str[0 .. dotIndex]);
        auto right = toSigned(str[dotIndex + 1 .. $]);
        if (left.isNone || right.isNone) {
            return Maybe!double(Fault.invalid);
        } else if (str[dotIndex + 1] == '-' || str[dotIndex + 1] == '+') {
            return Maybe!double(Fault.invalid);
        } else {
            auto sign = str[0] == '-' ? -1 : 1;
            auto level = 10;
            foreach (i; 1 .. str[dotIndex + 1 .. $].length) {
                level *= 10;
            }
            return Maybe!double(left.xx + sign * (right.xx / (cast(double) level)));
        }
    }
}

/// Converts the character to a double.
Maybe!double toFloating(char c) {
    if (isDigit(c)) {
        return Maybe!double(c - '0');
    } else {
        return Maybe!double(Fault.invalid);
    }
}

/// Converts the string to an enum value.
@trusted
Maybe!T toEnum(T)(IStr str, bool noCase = false, bool canIgnoreSpaceAndSymbol = false) {
    if (noCase || canIgnoreSpaceAndSymbol) {
        char[256] enumBuffer = void;
        foreach (m; __traits(allMembers, T)) {
            if (canIgnoreSpaceAndSymbol) {
                auto slice = enumBuffer[];
                auto sliceLength = 0;
                foreach (i, c; str) {
                    if (c.isSpace || c.isSymbol) continue;
                    if (sliceLength >= enumBuffer.length) return Maybe!T(Fault.overflow);
                    slice[sliceLength] = c;
                    sliceLength += 1;
                }
                slice = slice[0 .. sliceLength];
                if (noCase ? m.equalsNoCase(slice) : m == slice) return Maybe!T(mixin("T.", m));
            } else {
                if (noCase ? m.equalsNoCase(str) : m == str) return Maybe!T(mixin("T.", m));
            }
        }
        return Maybe!T(Fault.invalid);
    } else {
        switch (str) {
            static foreach (m; __traits(allMembers, T)) {
                mixin("case m: return Maybe!T(T.", m, ");");
            }
            default: return Maybe!T(Fault.invalid);
        }
    }
}

/// Converts the string to a C string.
@trusted
Maybe!IStrz toStrz(IStr str) {
    static char[defaultAsciiBufferSize] buffer = void;

    if (buffer.length < str.length + 1) return Maybe!IStrz(Fault.overflow);
    buffer.copyChars(str);
    buffer[str.length] = '\0';
    return Maybe!IStrz(buffer.ptr);
}

// Function test.
@trusted
unittest {
    enum TestEnum {
        one,
        two,
        oneAndTwo,
    }

    char[128] buffer = void;
    Str str;

    assert(isDigit('?') == false);
    assert(isDigit('0') == true);
    assert(isDigit('9') == true);
    assert(isUpper('h') == false);
    assert(isUpper('H') == true);
    assert(isLower('H') == false);
    assert(isLower('h') == true);
    assert(isSpace('?') == false);
    assert(isSpace('\r') == true);
    assert(isStrz("hello") == false);
    assert(isStrz("hello\0") == true);

    str = buffer[];
    str.copyStr("Hello");
    assert(str == "Hello");
    str.toUpper();
    assert(str == "HELLO");
    str.toLower();
    assert(str == "hello");

    str = buffer[];
    str.copyStr("Hello\0");
    assert(isStrz(str) == true);
    assert(str.ptr.strzLength + 1 == str.length);

    str = buffer[];
    str.copyStr("Hello");
    assert(str.equalsNoCase("HELLO") == true);
    assert(str.startsWith("H") == true);
    assert(str.startsWith("Hell") == true);
    assert(str.startsWith("Hello") == true);
    assert(str.endsWith("o") == true);
    assert(str.endsWith("ello") == true);
    assert(str.endsWith("Hello") == true);

    str = buffer[];
    str.copyStr("hello hello world.");
    assert(str.countItem("hello") == 2);
    assert(str.findStart("HELLO") == -1);
    assert(str.findStart("hello") == 0);
    assert(str.findEnd("HELLO") == -1);
    assert(str.findEnd("hello") == 6);

    str = buffer[];
    str.copyStr(" Hello world. ");
    assert(str.trimStart() == "Hello world. ");
    assert(str.trimEnd() == " Hello world.");
    assert(str.trim() == "Hello world.");
    assert(str.removePrefix("Hello") == str);
    assert(str.trim().removePrefix("Hello") == " world.");
    assert(str.removeSuffix("world.") == str);
    assert(str.trim().removeSuffix("world.") == "Hello ");
    assert(str.advanceStr(0) == str);
    assert(str.advanceStr(1) == str[1 .. $]);
    assert(str.advanceStr(str.length) == "");
    assert(str.advanceStr(str.length + 1) == "");

    str = buffer[];
    str.copyStr("999: Nine Hours, Nine Persons, Nine Doors");
    assert(str.split(',').length == 3);
    assert(str.split(',')[0] == "999: Nine Hours");
    assert(str.split(',')[1] == " Nine Persons");
    assert(str.split(',')[2] == " Nine Doors");

    version (Windows) {
    } else {
        assert(pathConcat("one", "two") == "one/two");
        assert(pathConcat("one", "/two") == "one/two");
        assert(pathConcat("one", "/two/") == "one/two");
        assert(pathConcat("one/", "/two/") == "one/two");
        assert(pathConcat("/one/", "/two/") == "/one/two");
        assert(pathConcat("", "two/") == "two");
        assert(pathConcat("", "/two/") == "/two");
    }
    assert(isAbsolutePath("\\\\dw", PathSepStyle.windows) == true);
    assert(isAbsolutePath("C:/dw", PathSepStyle.windows) == true);
    assert(isAbsolutePath("c:/dw", PathSepStyle.windows) == true);
    assert(isAbsolutePath("C:dw", PathSepStyle.windows) == false);
    assert(isAbsolutePath("c:dw", PathSepStyle.windows) == false);
    assert(isAbsolutePath("C:", PathSepStyle.windows) == false);
    assert(isAbsolutePath("c:", PathSepStyle.windows) == false);
    assert(pathConcat("one", "two").pathDirName() == "one");
    assert(pathConcat("one").pathDirName() == ".");
    assert(pathConcat("one.csv").pathExtName() == ".csv");
    assert(pathConcat("one").pathExtName() == "");
    assert(pathConcat("one", "two").pathBaseName() == "two");
    assert(pathConcat("one").pathBaseName() == "one");
    assert(pathFmt("one/two") == pathConcat("one", "two"));
    assert(pathFmt("one\\two") == pathConcat("one", "two"));

    str = buffer[];
    str.copyStr("one, two ,three,");
    assert(skipValue(str, ',') == "one");
    assert(skipValue(str, ',') == " two ");
    assert(skipValue(str, ',') == "three");
    assert(skipValue(str, ',') == "");
    assert(str.length == 0);
    assert(skipValue(str, "\r\n") == "");
    assert(skipLine(str) == "");

    assert(boolToStr(false) == "false");
    assert(boolToStr(false, true) == "F");
    assert(boolToStr(false, true, true) == "f");
    assert(boolToStr(true) == "true");
    assert(boolToStr(true, true) == "T");
    assert(boolToStr(true, true, true) == "t");
    assert(charToStr('L') == "L");

    assert(unsignedToStr(0) == "0");
    assert(unsignedToStr(69) == "69");
    assert(signedToStr(0) == "0");
    assert(signedToStr(69) == "69");
    assert(signedToStr(-69) == "-69");
    assert(signedToStr(-69) == "-69");

    assert(floatingToStr(0.00, 0) == "0");
    assert(floatingToStr(0.00, 1) == "0.0");
    assert(floatingToStr(0.00, 2) == "0.00");
    assert(floatingToStr(0.00, 3) == "0.000");
    assert(floatingToStr(0.60, 1) == "0.6");
    assert(floatingToStr(0.60, 2) == "0.60");
    assert(floatingToStr(0.60, 3) == "0.600");
    assert(floatingToStr(0.09, 1) == "0.0");
    assert(floatingToStr(0.09, 2) == "0.09");
    assert(floatingToStr(0.09, 3) == "0.090");
    assert(floatingToStr(69.0, 1) == "69.0");
    assert(floatingToStr(69.0, 2) == "69.00");
    assert(floatingToStr(69.0, 3) == "69.000");
    assert(floatingToStr(-0.69, 0) == "0");
    assert(floatingToStr(-0.69, 1) == "-0.6");
    assert(floatingToStr(-0.69, 2) == "-0.69");
    assert(floatingToStr(-0.69, 3) == "-0.690");
    assert(floatingToStr(double.nan) == "nan");

    assert(strzToStr("Hello\0") == "Hello");

    assert(enumToStr(TestEnum.one) == "one");
    assert(enumToStr(TestEnum.two) == "two");

    assert(toBool("false").isSome == true);
    assert(toBool("true").isSome == true);
    assert(toBool("F").isSome == true);
    assert(toBool("f").isSome == true);
    assert(toBool("T").isSome == true);
    assert(toBool("t").isSome == true);
    assert(toBool("false", true).isSome == true);
    assert(toBool("true", true).isSome == true);
    assert(toBool("F", true).isSome == false);
    assert(toBool("f", true).isSome == false);
    assert(toBool("T", true).isSome == false);
    assert(toBool("t", true).isSome == false);
    assert(toBool("false", true, true).isSome == true);
    assert(toBool("true", true, true).isSome == true);
    assert(toBool("F", true, true).isSome == false);
    assert(toBool("f", true, true).isSome == false);
    assert(toBool("T", true, true).isSome == false);
    assert(toBool("t", true, true).isSome == false);
    assert(toBool("false", false, true).isSome == true);
    assert(toBool("true", false, true).isSome == true);
    assert(toBool("F", false, true).isSome == true);
    assert(toBool("f", false, true).isSome == false);
    assert(toBool("T", false, true).isSome == true);
    assert(toBool("t", false, true).isSome == false);

    assert(toUnsigned("1_069").isSome == false);
    assert(toUnsigned("1_069").getOr() == 0);
    assert(toUnsigned("+1069").isSome == true);
    assert(toUnsigned("+1069").getOr() == 1069);
    assert(toUnsigned("1069").isSome == true);
    assert(toUnsigned("1069").getOr() == 1069);
    assert(toUnsigned('+').isSome == false);
    assert(toUnsigned('+').getOr() == 0);
    assert(toUnsigned('0').isSome == true);
    assert(toUnsigned('0').getOr() == 0);
    assert(toUnsigned('9').isSome == true);
    assert(toUnsigned('9').getOr() == 9);

    assert(toSigned("1_069").isSome == false);
    assert(toSigned("1_069").getOr() == 0);
    assert(toSigned("-1069").isSome == true);
    assert(toSigned("-1069").getOr() == -1069);
    assert(toSigned("+1069").isSome == true);
    assert(toSigned("+1069").getOr() == 1069);
    assert(toSigned("1069").isSome == true);
    assert(toSigned("1069").getOr() == 1069);
    assert(toSigned('+').isSome == false);
    assert(toSigned('+').getOr() == 0);
    assert(toSigned('0').isSome == true);
    assert(toSigned('0').getOr() == 0);
    assert(toSigned('9').isSome == true);
    assert(toSigned('9').getOr() == 9);

    assert(toFloating("1_069").isSome == false);
    assert(toFloating(".1069").isSome == false);
    assert(toFloating("1069.").isSome == false);
    assert(toFloating(".").isSome == false);
    assert(toFloating("-1069.-69").isSome == false);
    assert(toFloating("-1069.+69").isSome == false);
    assert(toFloating("-1069").isSome == true);
    assert(toFloating("-1069").getOr() == -1069);
    assert(toFloating("+1069").isSome == true);
    assert(toFloating("+1069").getOr() == 1069);
    assert(toFloating("1069").isSome == true);
    assert(toFloating("1069").getOr() == 1069);
    assert(toFloating("1069.0").isSome == true);
    assert(toFloating("1069.0").getOr() == 1069);
    assert(toFloating("-1069.0095").isSome == true);
    assert(toFloating("-1069.0095").getOr() == -1069.0095);
    assert(toFloating("+1069.0095").isSome == true);
    assert(toFloating("+1069.0095").getOr() == 1069.0095);
    assert(toFloating("1069.0095").isSome == true);
    assert(toFloating("1069.0095").getOr() == 1069.0095);
    assert(toFloating("-0.0095").isSome == true);
    assert(toFloating("-0.0095").getOr() == -0.0095);
    assert(toFloating("+0.0095").isSome == true);
    assert(toFloating("+0.0095").getOr() == 0.0095);
    assert(toFloating("0.0095").isSome == true);
    assert(toFloating("0.0095").getOr() == 0.0095);
    assert(toFloating('+').isSome == false);
    assert(toFloating('0').isSome == true);
    assert(toFloating('9').isSome == true);
    assert(toFloating('9').getOr() == 9);
    assert(!(toFloating("nan").getOr() == double.nan));

    assert(toEnum!TestEnum("?").isSome == false);
    assert(toEnum!TestEnum("?").getOr() == TestEnum.one);
    assert(toEnum!TestEnum("one").isSome == true);
    assert(toEnum!TestEnum("one").getOr() == TestEnum.one);
    assert(toEnum!TestEnum("two").isSome == true);
    assert(toEnum!TestEnum("two").getOr() == TestEnum.two);
    assert(toEnum!TestEnum("TWO").isSome == false);
    assert(toEnum!TestEnum("TWO", true).isSome == true);
    assert(toEnum!TestEnum("  TWO  ", true, false).isSome == false);
    assert(toEnum!TestEnum("  TWO  ", true, true).isSome == true);
    assert(toEnum!TestEnum(" -TWO- ", true, true).isSome == true);
    assert(toEnum!TestEnum("One and Two", true, true).isSome == true);
    assert(toEnum!TestEnum("one-and-two", true, true).isSome == true);

    assert(toStrz("Hello").getOr().strzLength == "Hello".length);
    assert(toStrz("Hello").getOr().strzToStr() == "Hello");
    assert(fmt("Hello {}!", "world") == "Hello world!");
    assert(fmt("({}, {})", -69, -420) == "(-69, -420)");

    assert(fmt("Number: {}", 1.54321.flo(0)) == "Number: 1");
    assert(fmt("Number: {}", 1.54321.flo(1)) == "Number: 1.5");
    assert(fmt("Number: {}", 1.54321.flo(2)) == "Number: 1.54");
}
