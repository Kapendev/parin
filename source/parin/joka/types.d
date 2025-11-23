// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `types` module provides basic type definitions and compile-time functions such as type checking.
module parin.joka.types;

@safe nothrow @nogc:

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

alias UnionType = ubyte;
alias AliasArgs(A...) = A;

enum kilobyte = 1024;
enum megabyte = 1024 * kilobyte;
enum gigabyte = 1024 * megabyte;
enum terabyte = 1024 * gigabyte;
enum petabyte = 1024 * terabyte;
enum exabyte  = 1024 * petabyte;

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
    enum length = N;
    enum capacity = N;

    align(T.alignof) ubyte[T.sizeof * N] _data;

    pragma(inline, true) @trusted nothrow @nogc:

    mixin addSliceOps!(Self, T);

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
struct Maybe(T) {
    T _data;                   /// The value.
    Fault _fault = Fault.some; /// The error code.

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

    /// Returns the value and traps the error if it exists.
    ref T get(ref Fault trap) {
        trap = _fault;
        return _data;
    }

    /// Returns the value, or asserts if an error exists.
    ref T get() {
        if (_fault) assert(0, "Fault was detected.");
        return _data;
    }

    /// Returns the value. Returns a default value when there is an error.
    T getOr(T other) {
        return _fault ? other : _data;
    }

    /// Returns the value. Returns a default value when there is an error.
    T getOr() {
        return _data;
    }

    /// Returns true when there is an error.
    bool isNone() {
        return _fault != 0;
    }

    /// Returns true when there is a value.
    bool isSome() {
        return _fault == 0;
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

pure
bool isNan(double x) {
    return !(x == x);
}

mixin template addSliceOps(T, TT) if (__traits(hasMember, T, "items")) {
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

mixin template addXyzwOps(T, TT, Sz N, IStr form = "xyzw") if (__traits(hasMember, T, "items") && N >= 2 && N <= 4 && N == form.length) {
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
            foreach (i, arg; args) result.items[i] = items[arg];
            return result;
        }

        T _swizzleC(IStr args...) {
            if (args.length != N) assert(0, "Wrong swizzle length.");
            T result = void;
            foreach (i, arg; args) {
                auto hasBadArg = true;
                foreach (j, c; form) if (c == arg) {
                    result.items[i] = items[j];
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
            foreach (item; items[1 .. $]) if (item < result) result = item;
            return result;
        }

        TT max() {
            auto result = mixin(form[0]);
            foreach (item; items[1 .. $]) if (item > result) result = item;
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

// Variant test.
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
}
