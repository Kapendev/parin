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

/// A value paired with its iteration index.
struct IndexedValue(V) {
    V value;
    Sz index;
    alias value this;
}

/// A range that iterates over a numeric interval with a given step.
struct NumericRange(I) {
    I index;
    I stop;
    I step;

    pragma(inline, true) @safe nothrow @nogc:

    this(I start, I stop, I step = 1) {
        this.index = start;
        this.stop = stop;
        this.step = step;
    }

    bool empty() {
        return step > 0 ? index >= stop : index <= stop;
    }

    I front() {
        return index;
    }

    void popFront() {
        index += step;
    }
}

/// A range that iterates over a read-only view of an array.
struct ArrayRange(T) {
    const(T)[] data;
    Sz index;

    pragma(inline, true) @safe nothrow @nogc:

    bool empty() {
        return index >= data.length;
    }

    T front() {
        return data[index];
    }

    void popFront() {
        index += 1;
    }

    Sz length() {
        return data.length;
    }

    T opIndex(Sz i) {
        return data[i];
    }
}

/// A range that pairs each element of a range with its iteration index.
struct EnumeratedRange(R) {
    alias FrontType = IndexedValue!(typeof(R.front()));

    R range;
    Sz index;

    @safe nothrow @nogc:

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

    @safe nothrow @nogc:

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

    @safe nothrow @nogc:

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

/// A range that stops iteration after a given number of elements.
struct TakeRange(R) {
    R range;
    Sz count;

    @safe nothrow @nogc:

    bool empty() {
        return range.empty || count == 0;
    }

    auto front() {
        return range.front;
    }

    void popFront() {
        range.popFront();
        count -= 1;
    }
}

/// A range that iterates over two ranges in sequence.
struct ChainRange(R1, R2) if (is(typeof(R1.front()) == typeof(R2.front()))) {
    R1 a;
    R2 b;

    @safe nothrow @nogc:

    bool empty() {
        return a.empty && b.empty;
    }

    auto front() {
        return a.empty ? b.front : a.front;
    }

    void popFront() {
        if (a.empty) {
            b.popFront();
        } else {
            a.popFront();
        }
    }
}

@safe nothrow @nogc {
    /// Returns a numeric range.
    NumericRange!I range(I)(I start, I stop, I step = 1) {
        return NumericRange!I(start, stop, step);
    }

    /// Returns an array range.
    ArrayRange!T range(T)(const(T)[] data) {
        return ArrayRange!T(data);
    }
}

/// Returns a range that pairs each element with its iteration index.
EnumeratedRange!R enumerate(R)(R range, Sz start = 0) {
    return EnumeratedRange!R(range, start);
}

/// Returns a range that applies a function to each element.
MapRange!(R, F) map(R, F)(R range, F func) {
    return MapRange!(R, F)(range, func);
}

/// Returns a range that skips elements not satisfying a predicate.
FilterRange!(R, F) filter(R, F)(R range, F func) {
    return FilterRange!(R, F)(range, func);
}

/// Returns the result of applying a function cumulatively to all elements.
T reduce(R, F, T)(R range, F func, T initial) {
    auto result = initial;
    foreach (item; range) result = func(result, item);
    return result;
}

/// Returns a range that stops after a given number of elements.
TakeRange!R take(R)(R range, Sz count) {
    return TakeRange!R(range, count);
}

/// Returns a range with the first N elements skipped.
R drop(R)(R range, Sz count) {
    foreach (i; 0 .. count) if (!range.empty) range.popFront();
    return range;
}

/// Returns a range with leading elements skipped while a predicate holds.
R dropWhile(R, F)(R range, F func) {
    while (!range.empty && func(range.front)) range.popFront();
    return range;
}

/// Returns a range that iterates over two ranges in sequence.
ChainRange!(R1, R2) chain(R1, R2)(R1 range1, R2 range2) {
    return ChainRange!(R1, R2)(range1, range2);
}

/// Returns the smallest element in a range.
auto min(T)(T range) {
    auto result = range.front;
    range.popFront();
    foreach (item; range) if (item < result) result = item;
    return result;
}

/// Returns the largest element in a range.
auto max(T)(T range) {
    auto result = range.front;
    range.popFront();
    foreach (item; range) if (item > result) result = item;
    return result;
}

/// Returns the sum of all elements in a range.
auto sum(T)(T range) {
    auto result = range.front;
    range.popFront();
    foreach (item; range) result += item;
    return result;
}

/// Returns the product of all elements in a range.
auto product(T)(T range) {
    auto result = range.front;
    range.popFront();
    foreach (item; range) result *= item;
    return result;
}

/// Returns the last element in a range.
auto last(R)(R range) {
    auto result = range.front;
    foreach (item; range) result = item;
    return result;
}

/// Returns true if any element satisfies a predicate.
bool any(R, F)(R range, F func) {
    foreach (item; range) if (func(item)) return true;
    return false;
}

/// Returns true if all elements satisfy a predicate.
bool all(R, F)(R range, F func) {
    foreach (item; range) if (!func(item)) return false;
    return true;
}

/// Returns the number of elements satisfying a predicate.
Sz countIf(R, F)(R range, F func) {
    auto result = Sz.init;
    foreach (item; range) result += func(item);
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
    // NumericRange
    auto temp = 0;
    foreach (i; range(0, 4)) {
        assert(i == temp);
        temp += 1;
    }
    temp = 0;
    foreach (i; range(0, -4, -1)) {
        assert(i == temp);
        temp -= 1;
    }
    assert(range(0, 10).reduce((int x, int y) => x + y, 0) == 45);

    // ArrayRange
    int[5] slice = [1, 2, 3, 4, 5];
    assert(slice.range().reduce((int x, int y) => x + y, 0) == 15);
    assert(slice.range()[2] == 3);
    assert(slice.range().length == 5);

    // EnumeratedRange
    temp = 0;
    foreach (item; range(10, 13).enumerate()) {
        assert(item.index == temp);
        temp += 1;
    }
    temp = 5;
    foreach (item; range(10, 13).enumerate(5)) {
        assert(item.index == temp);
        temp += 1;
    }

    // MapRange
    assert(range(0, 4).map((int x) => x * 2).reduce((int x, int y) => x + y, 0) == 12);
    assert(
        range(1, 5)
            .map((int x) => x * 2)
            .filter((int x) => x > 4)
            .reduce((int a, int b) => a + b, 0)
            == 14
    );

    // FilterRange
    assert(range(0, 9).filter((int x) => x == 2 || x == 4).reduce((int x, int y) => x + y, 0) == 6);
    auto f = range(0, 5).filter((int x) => x % 2 == 0);
    assert(!f.empty);
    assert(!f.empty); // Second call must not skip elements.
    assert(f.front == 0);
    assert(range(0, 5).filter((int x) => x > 10).reduce((int x, int y) => x + y, 0) == 0);

    // any/all/countIf
    assert(range(0, 5).any((int x) => x == 3));
    assert(!range(0, 5).any((int x) => x == 9));
    assert(range(1, 5).all((int x) => x > 0));
    assert(!range(0, 5).all((int x) => x > 0));
    assert(range(0, 10).countIf((int x) => x % 2 == 0) == 5);

    // TakeRange
    assert(range(0, 10).take(3).reduce((int a, int b) => a + b, 0) == 3);
    assert(range(0, 10).take(0).empty);

    // drop
    assert(range(0, 5).drop(3).reduce((int a, int b) => a + b, 0) == 7);
    assert(range(0, 3).drop(3).empty);

    // ChainRange
    assert(chain(range(0, 3), range(3, 6)).reduce((int a, int b) => a + b, 0) == 15);

    // min/max
    assert(range(1, 6).min == 1);
    assert(range(1, 6).max == 5);

    // dropWhile
    assert(range(0, 5).dropWhile((int x) => x < 3).reduce((int a, int b) => a + b, 0) == 7);
    assert(range(0, 5).dropWhile((int x) => x < 9).empty);

    // last
    assert(range(0, 5).last == 4);
    assert(range(1, 2).last == 1);

    // sum/product
    assert(range(1, 6).sum == 15);
    assert(range(1, 6).product == 120);
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
