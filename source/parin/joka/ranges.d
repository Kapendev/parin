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

/// The common integer type used by the range module.
alias Int = Pd;

/// A value paired with its iteration index.
struct IndexedValue(V) {
    V value;
    Int index;
    alias value this;
}

/// A range that iterates over a numeric interval with a given step.
struct NumericRange {
    Int index;
    Int stop;
    Int step;

    pragma(inline, true) @safe nothrow @nogc:

    this(Int start, Int stop, Int step = 1) {
        this.index = start;
        this.stop = stop;
        this.step = step;
    }

    this(Int stop) {
        this(0, stop);
    }

    bool empty() {
        return step > 0 ? index >= stop : index <= stop;
    }

    Int front() {
        return index;
    }

    void popFront() {
        index += step;
    }
}

/// A range that iterates over a read-only view of an array.
struct ArrayRange(T) {
    const(T)[] data;
    Int index;

    pragma(inline, true) @safe nothrow @nogc:

    bool empty() {
        return index >= length || index < 0;
    }

    T front() {
        return data[index];
    }

    void popFront() {
        index += 1;
    }

    Int length() {
        return cast(Int) data.length;
    }

    T opIndex(Int i) {
        return data[i];
    }
}

/// A range that pairs each element of a range with its iteration index.
struct EnumeratedRange(R) {
    alias FrontType = IndexedValue!(typeof(R.front()));

    R range;
    Int index;

    pragma(inline, true) @safe nothrow @nogc:

    bool empty() {
        return range.empty;
    }

    FrontType front() {
        return FrontType(range.front, index);
    }

    void popFront() {
        range.popFront();
        index += 1;
    }
}

/// A range that applies a function to each element of a range.
struct MapRange(R, F) {
    R range;
    F func;

    pragma(inline, true) @safe nothrow @nogc:

    bool empty() {
        return range.empty;
    }

    auto front() {
        return func(range.front);
    }

    void popFront() {
        range.popFront();
    }
}

/// A range that skips elements of a range that do not satisfy a predicate.
struct FilterRange(R, F) {
    R range;
    F func;

    pragma(inline, true) @safe nothrow @nogc:

    this(R range, F func) {
        this.range = range;
        this.func = func;
        advance();
    }

    void advance() {
        while (!range.empty && !func(range.front)) range.popFront();
    }

    bool empty() {
        return range.empty;
    }

    auto front() {
        return range.front;
    }

    void popFront() {
        range.popFront();
        advance();
    }
}

@safe nothrow @nogc {
    NumericRange range(Int start, Int stop, Int step = 1) {
        return NumericRange(start, stop, step);
    }

    NumericRange range(Int stop) {
        return NumericRange(stop);
    }

    ArrayRange!T range(T)(const(T)[] data) {
        return ArrayRange!T(data);
    }
}

EnumeratedRange!R enumerate(R)(R range, Int start = 0) {
    return EnumeratedRange!R(range, start);
}

MapRange!(R, F) map(R, F)(R range, F func) {
    return MapRange!(R, F)(range, func);
}

FilterRange!(R, F) filter(R, F)(R range, F func) {
    return FilterRange!(R, F)(range, func);
}

@trusted
T reduce(R, F, T)(R range, F func, T initial) {
    auto result = initial;
    foreach (item; range) {
        result = cast(T) func(result, item);
    }
    return result;
}

bool any(R, F)(R range, F func) {
    foreach (item; range) {
        if (func(item)) return true;
    }
    return false;
}

bool all(R, F)(R range, F func) {
    foreach (item; range) {
        if (!func(item)) return false;
    }
    return true;
}

Int countIf(R, F)(R range, F func) {
    auto result = Int.init;
    foreach (item; range) {
        result += func(item);
    }
    return result;
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

@safe nothrow @nogc
unittest {
    // NumericRange: forward iteration
    Int temp = 0;
    foreach (i; range(0, 4)) {
        assert(i == temp);
        temp += 1;
    }

    // NumericRange: negative step
    temp = 0;
    foreach (i; range(0, -4, -1)) {
        assert(i == temp);
        temp -= 1;
    }

    // NumericRange: single-arg shorthand
    assert(range(0, 10).reduce((Int x, Int y) => x + y, 0) == 45);

    // ArrayRange
    Int[5] slice = [1, 2, 3, 4, 5];
    assert(slice.range().reduce((Int x, Int y) => x + y, 0) == 15);
    assert(slice.range()[2] == 3);
    assert(slice.range().length == 5);

    // EnumeratedRange: index starts at 0
    temp = 0;
    foreach (item; range(10, 13).enumerate()) {
        assert(item.index == temp);
        temp += 1;
    }

    // EnumeratedRange: non-zero start index
    temp = 5;
    foreach (item; range(10, 13).enumerate(5)) {
        assert(item.index == temp);
        temp += 1;
    }

    // MapRange
    assert(range(0, 4).map((Int x) => x * 2).reduce((Int x, Int y) => x + y, 0) == 12);

    // FilterRange: basic
    assert(range(0, 9).filter((Int x) => x == 2 || x == 4).reduce((Int x, Int y) => x + y, 0) == 6);

    // FilterRange: empty() is idempotent
    auto f = range(0, 5).filter((Int x) => x % 2 == 0);
    assert(!f.empty);
    assert(!f.empty); // second call must not skip elements
    assert(f.front == 0);

    // FilterRange: all elements filtered out
    assert(range(0, 5).filter((Int x) => x > 10).reduce((Int x, Int y) => x + y, 0) == 0);

    // map then filter then reduce
    assert(
        range(1, 5)
            .map((Int x) => cast(Int) (x * 2))
            .filter((Int x) => x > 4)
            .reduce((Int a, Int b) => cast(Int) (a + b), cast(Int) 0)
        == 14
    );

    // any / all / countIf
    assert(range(0, 5).any((Int x) => x == 3));
    assert(!range(0, 5).any((Int x) => x == 9));
    assert(range(1, 5).all((Int x) => x > 0));
    assert(!range(0, 5).all((Int x) => x > 0));
    assert(range(0, 10).countIf((Int x) => x % 2 == 0) == 5);
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
