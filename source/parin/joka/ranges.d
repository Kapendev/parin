// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

// NOTE: Maybe look at this for more ideas: https://github.com/opendlang/d/blob/main/source/odc/algorthimswishlist.md
//   I'm fine with not including any allocation, sorting or mutation functions.
//   Ideas from Monkyyy:
//     most important: map filter reduce acc last count backwards chunks cycle chain stride
//     important but hard: sort(nlogn) radixsort transposed takemap cache splitter joiner (grouped with splitter, not hard)
//     old notes: find balencedpern swapkeyvalue half1 half2 enumerate repeat
//     trivail: any all issorted max min sum product stripleft stripright padleft padright takeexact center drop take

/// The `ranges` module includes functions that work with ranges.
module parin.joka.ranges;

import parin.joka.types;

// A numeric range value.
alias Nrv = int;
static assert(Nrv.min < 0, "Type `NumericRangeValue` should be a signed type.");

struct ValueIndex(V) {
    V value;
    Nrv index;
    alias value this;
}

// NOTE: Maybe this should be a generic type, but ehhh.
struct NumericRange {
    Nrv start;
    Nrv stop;
    Nrv step;
    Nrv index;

    pragma(inline, true) @safe nothrow @nogc:

    bool empty() {
        return step > 0 ? index >= stop : index <= stop;
    }

    Nrv front() {
        return index;
    }

    void popFront() {
        index += step;
    }

    Nrv back() {
        return cast(Nrv) (stop - (index - start) - 1);
    }

    void popBack() {
        index += step;
    }
}

// NOTE: It's using a pointer because it keeps the sturct small. Was something like 24LU with a slice.
struct SliceRange(T) {
    const(T)* slice;
    Nrv sliceLength;
    Nrv index;

    pragma(inline, true) @trusted nothrow @nogc:

    bool empty() {
        return index >= sliceLength;
    }

    T front() {
        return slice[index];
    }

    void popFront() {
        index += 1;
    }

    T back() {
        return slice[sliceLength - index - 1];
    }

    void popBack() {
        index += 1;
    }

    Nrv length() {
        return cast(Nrv) sliceLength;
    }

    T opIndex(size_t i) {
        return slice[i];
    }
}

struct EnumeratedRange(R) {
    alias FrontBack = ValueIndex!(typeof(R.front()));

    R range;
    Nrv index;

    pragma(inline, true) @safe nothrow @nogc:

    bool empty() {
        return range.empty;
    }

    FrontBack front() {
        return FrontBack(range.front, index);
    }

    void popFront() {
        range.popFront();
        index += 1;
    }

    static if (__traits(hasMember, R, "back") && __traits(hasMember, R, "popBack")) {
        FrontBack back() {
            return FrontBack(range.back, index);
        }

        void popBack() {
            range.popBack();
            index += 1;
        }
    }
}

// NOTE: This type is mixing map and filter into one idea. Just me trying things.
struct TransformedRange(R, F) {
    R range;
    F func;
    bool isFilter;

    void skipToNext(bool canIncludeSelf) {
        if (!canIncludeSelf) range.popFront();
        while (!range.empty && !func(range.front)) range.popFront();
    }

    bool empty() {
        if (isFilter) {
            skipToNext(true);
            return range.empty;
        }
        return range.empty;
    }

    auto front() {
        if (isFilter) {
            return range.front;
        }
        return func(range.front);
    }

    void popFront() {
        if (isFilter) {
            skipToNext(false);
            return;
        }
        range.popFront();
    }

    static if (__traits(hasMember, R, "back") && __traits(hasMember, R, "popBack")) {
        auto back() {
            if (isFilter) assert(0, "Can't use filter or map with `foreach_reverse`.");
            return func(range.back);
        }

        void popBack() {
            if (isFilter) assert(0, "Can't use filter or map with `foreach_reverse`.");
            range.popBack();
        }
    }
}

/// Command-line argument types.
enum ArgType {
    singleItem,  /// A standalone argument (e.g. file.txt)
    shortOption, /// A short option (e.g. -v)
    longOption,  /// A long option (e.g. --verbose)
}

/// A parsed token from the command-line arguments.
struct ArgToken {
    ArgType type; /// The type of the argument.
    IStr name;    /// The name of the argument. Always present.
    IStr value;   /// The value of the argument. May be empty.

    @safe nothrow @nogc:

    IStr toStr() {
        return name;
    }

    alias toString = toStr;
}

/// A range of parsed tokens from the command-line arguments.
struct ArgTokenRange {
    const(IStr)[] args;

    @safe nothrow @nogc:

    @trusted
    this(const(IStr)[] args...) {
        this.args = args;
    }

    bool empty() {
        return args.length == 0;
    }

    ArgToken front() {
        auto cleanArg = args[0].trim();
        auto equalIndex = cleanArg.findEnd("=");
        if (cleanArg.length == 0) return ArgToken();
        else if (cleanArg == "-") return ArgToken(ArgType.singleItem, "-", "");
        else if (cleanArg == "--") return ArgToken(ArgType.singleItem, "--", "");

        auto a = cleanArg.startsWith("-") ? (cleanArg.startsWith("--") ? ArgType.longOption : ArgType.shortOption) : ArgType.singleItem;
        auto startIndex = a == ArgType.singleItem ? 0 : a == ArgType.shortOption ? 1 : 2;
        auto b = cleanArg[startIndex .. equalIndex != -1 ? equalIndex : $];
        auto c = cleanArg[equalIndex != -1 ? equalIndex + 1 : $ .. $];
        return ArgToken(a, b, c);
    }

    void popFront() {
        args = args[1 .. $];
    }
}

@safe nothrow @nogc {
    alias toRange = range;

    NumericRange range(Nrv start, Nrv stop, Nrv step = 1) {
        return NumericRange(start, stop, step, start);
    }

    NumericRange range(Nrv stop) {
        return range(0, stop);
    }

    @trusted
    SliceRange!T range(T)(const(T)[] slice) {
        return SliceRange!T(slice.ptr, cast(Nrv) slice.length);
    }


    EnumeratedRange!R enumerate(R)(R range, Nrv start = 0) if (rangeIsNotStaticArrayType!R) {
        static if (is(R : const(T)[], T)) {
            return enumerate(range.toRange());
        } else {
            return EnumeratedRange!R(range, start);
        }
    }
}

TransformedRange!(R, F) map(R, F)(R range, F func) if (rangeIsNotStaticArrayType!R) {
    static if (is(R : const(T)[], T)) {
        return map(range.toRange(), func);
    } else {
        return TransformedRange!(R, F)(range, func);
    }
}

TransformedRange!(R, F) filter(R, F)(R range, F func) if (rangeIsNotStaticArrayType!R) {
    static if (is(R : const(T)[], T)) {
        return filter(range.toRange(), func);
    } else {
        return TransformedRange!(R, F)(range, func, true);
    }
}

T reduce(R, F, T)(R range, F func, T initial) if (rangeIsNotStaticArrayType!R) {
    static if (is(R : const(T)[], T)) {
        return reduce(range.toRange(), func, initial);
    } else {
        auto result = initial;
        foreach (item; range) {
            static if (rangeHasValueIndexType!R) {
                result.value = func(result, item);
            } else {
                result = func(result, item);
            }
        }
        return result;
    }
}

auto reduce(R, F)(R range, F func) if (rangeIsNotStaticArrayType!R) {
    static if (is(R : const(T)[], T)) {
        return reduce(range.toRange(), func);
    } else {
        if (range.empty) return typeof(range.front()).init;
        auto initial = range.front;
        range.popFront();
        return reduce(range, func, initial);
    }
}

auto min(R)(R range) {
    alias T = rangeFrontType!R;
    return range.reduce((T x, T y) => x < y ? x : y);
}

auto max(R)(R range) {
    alias T = rangeFrontType!R;
    return range.reduce((T x, T y) => x > y ? x : y);
}

auto sum(R)(R range) {
    alias T = rangeFrontType!R;
    return range.reduce((T x, T y) => cast(T) (x + y));
}

auto product(R)(R range) {
    alias T = rangeFrontType!R;
    return range.reduce((T x, T y) => cast(T) (x * y));
}

template rangeIsNotStaticArrayType(R) {
    enum rangeIsNotStaticArrayType = !(is(R : const(A)[N], A, Sz N));
}

template rangeHasValueIndexType(R) {
    enum rangeHasValueIndexType = is(typeof(R.front()) : const(ValueIndex!V), V);
}

template rangeFrontType(R) {
    static if (is(R : const(S)[], S)) {
        R temp;
        alias rangeFrontType = typeof(temp[0]);
    } else static if (is(typeof(R.front()) : const(ValueIndex!V), V)) {
        alias rangeFrontType = typeof(R.front().value);
    } else {
        alias rangeFrontType = typeof(R.front());
    }
}

@safe nothrow @nogc
unittest {
    Nrv temp = 0;
    Nrv start = 0;
    Nrv stop = 4;
    Nrv step = 1;
    assert(range(temp, stop, step).sum == 6);
    assert(range(temp, stop, step).enumerate().sum == 6);
    foreach (i; range(temp, stop, step)) {
        assert(i >= start && i < stop);
        assert(i == temp);
        temp += step;
    }

    temp = 0;
    start = 0;
    stop = -4;
    step = -1;
    assert(range(temp, stop, step).sum == -6);
    assert(range(temp, stop, step).enumerate().sum == -6);
    foreach (i; range(temp, stop, step)) {
        assert(i <= start && i > stop);
        assert(i == temp);
        temp += step;
    }

    assert(range(10).sum == 45);
    assert(range(10).enumerate().sum == 45);

    int[3] array = [2, 2, 2];
    int[] slice = array[];
    assert(slice.sum == 6);

    assert(range(3).map((Nrv x) => x * 2).sum == 6);
    assert(range(9).filter((Nrv x) => x == 2 || x == 4).sum == 6);
    assert(range(0, 4).reduce((Nrv x, Nrv y) => cast(Nrv) (x + y)) == 6);
    assert(range(0, 4).reduce((Nrv x, Nrv y) => cast(Nrv) (x * y)) == 0);
    assert(range(1, 4).reduce((Nrv x, Nrv y) => cast(Nrv) (x * y)) == 6);
    assert(slice.reduce((int x, int y) => x + y) == 6);
    assert(range(2, 6).min == 2);
    assert(range(2, 6).max == 5);
    assert(slice.min == 2);
    assert(slice.max == 2);

    assert(
        range(1, 5)
            .map((Nrv x) => cast(Nrv) (x * 2))
            .filter((Nrv x) => x > 4)
            .reduce((Nrv a, Nrv b) => cast(Nrv) (a + b))
        == 14
    );
}

// Arg test.
unittest {
    foreach (token; ArgTokenRange("b", "-c", "--d")) {
        with (ArgType) final switch (token.type) {
            case singleItem: assert(token.name == "b"); break;
            case shortOption: assert(token.name == "c"); break;
            case longOption: assert(token.name == "d"); break;
        }
    }

    foreach (token; ArgTokenRange("b=2", "-c=3", "--d=4")) {
        with (ArgType) final switch (token.type) {
            case singleItem:
                assert(token.name == "b");
                assert(token.value == "2");
                break;
            case shortOption:
                assert(token.name == "c");
                assert(token.value == "3");
                break;
            case longOption:
                assert(token.name == "d");
                assert(token.value == "4");
                break;
        }
    }
}
