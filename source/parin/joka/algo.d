// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

// NOTE: Maybe look at this: https://github.com/opendlang/d/blob/main/source/odc/algorthimswishlist.md

/// The `algo` module includes functions that work with ranges.
module parin.joka.algo;

import parin.joka.ascii;
import parin.joka.types;

@safe nothrow @nogc:

struct ValueIndex(V, I) {
    V value;
    I index;
    alias value this;

    @safe nothrow @nogc:

    IStr toStr() {
        return "{}".fmt(value);
    }

    IStr toString() {
        return toStr();
    }
}

alias NumericRangeValue = int;

struct NumericRange {
    NumericRangeValue start;
    NumericRangeValue stop;
    NumericRangeValue step;
    NumericRangeValue index;

    @safe nothrow @nogc:

    bool empty() {
        return step > 0 ? index >= stop : index <= stop;
    }

    NumericRangeValue front() {
        return index;
    }

    void popFront() {
        index += step;
    }

    NumericRangeValue back() {
        return stop - (index - start) - 1;
    }

    void popBack() {
        index += step;
    }
}

NumericRange range(NumericRangeValue start, NumericRangeValue stop, NumericRangeValue step = 1) {
    return NumericRange(start, stop, step, start);
}

NumericRange range(NumericRangeValue stop) {
    return range(0, stop);
}

auto toRange(T)(const(T)[] slice) {
    static struct Range {
        const(T)[] slice;
        Sz index;

        bool empty() {
            return index >= slice.length;
        }

        T front() {
            return slice[index];
        }

        void popFront() {
            index += 1;
        }

        T back() {
            return slice[$ - index - 1];
        }

        void popBack() {
            index += 1;
        }

        Sz length() {
            return slice.length;
        }

        T opIndex(Sz i) {
            return slice[i];
        }
    }

    return Range(slice);
}

auto enumerate(R)(R range, NumericRangeValue start = 0) {
    static assert(!(is(R : const(A)[N], A, Sz N)), "Static arrays are not supported.");

    static if (is(R : const(T)[], T)) {
        return enumerate(range.toRange());
    } else {
        alias FrontBack = ValueIndex!(typeof(R.front()), NumericRangeValue);

        static struct Range {
            R range;
            NumericRangeValue index;

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

        return Range(range, start);
    }
}

auto map(R, F)(R range, F func) {
    static assert(!(is(R : const(A)[N], A, Sz N)), "Static arrays are not supported.");

    static if (is(R : const(T)[], T)) {
        return map(range.toRange(), func);
    } else {
        static struct Range {
            R range;
            F func;

            bool empty() {
                return range.empty;
            }

            auto front() {
                return func(range.front);
            }

            void popFront() {
                range.popFront();
            }

            static if (__traits(hasMember, R, "back") && __traits(hasMember, R, "popBack")) {
                auto back() {
                    return func(range.back);
                }

                void popBack() {
                    range.popBack();
                }
            }
        }

        return Range(range, func);
    }
}

auto filter(R, F)(R range, F func) {
    static assert(!(is(R : const(A)[N], A, Sz N)), "Static arrays are not supported.");

    static if (is(R : const(T)[], T)) {
        return filter(range.toRange(), func);
    } else {
        static struct Range {
            R range;
            F func;

            void skipToNext(bool canIncludeSelf) {
                if (!canIncludeSelf) range.popFront();
                while (!range.empty && !func(range.front)) range.popFront();
            }

            bool empty() {
                skipToNext(true);
                return range.empty;
            }

            auto front() {
                return range.front;
            }

            void popFront() {
                skipToNext(false);
            }
        }

        return Range(range, func);
    }
}

auto filterBack(R, F)(R range, F func) {
    static assert(!(is(R : const(A)[N], A, Sz N)), "Static arrays are not supported.");

    static if (is(R : const(T)[], T)) {
        return filterBack(range.toRange(), func);
    } else {
        static struct Range {
            R range;
            F func;

            void skipToNext(bool canIncludeSelf) {
                if (!canIncludeSelf) range.popBack();
                while (!range.empty && !func(range.back)) range.popBack();
            }

            bool empty() {
                skipToNext(true);
                return range.empty;
            }

            auto back() {
                return range.back;
            }

            void popBack() {
                skipToNext(false);
            }
        }

        return Range(range, func);
    }
}

auto reduce(R, F, T)(R range, F func, T initial) {
    static assert(!(is(R : const(A)[N], A, Sz N)), "Static arrays are not supported.");

    static if (is(R : const(T)[], T)) {
        return reduce(range.toRange(), func, initial);
    } else {
        enum isValueIndexType = is(typeof(R.front()) : const(ValueIndex!(V, I)), V, I);

        auto result = initial;
        foreach (item; range) {
            static if (isValueIndexType) {
                result.value = func(result, item);
            } else {
                result = func(result, item);
            }
        }
        return result;
    }
}

auto reduce(R, F)(R range, F func) {
    static if (is(R : const(T)[], T)) {
        return reduce(range.toRange(), func);
    } else {
        if (range.empty) return range.front.init;
        auto initial = range.front;
        range.popFront();
        return reduce(range, func, initial);
    }
}

auto min(R)(R range) {
    enum isValueIndexType = is(typeof(R.front()) : const(ValueIndex!(V, I)), V, I);

    static if (is(R : const(S)[], S)) {
        alias T = typeof(range[0]);
    } else static if (isValueIndexType) {
        alias T = typeof(R.front().value);
    } else {
        alias T = typeof(R.front());
    }

    return range.reduce((T x, T y) => x < y ? x : y);
}

auto max(R)(R range) {
    enum isValueIndexType = is(typeof(R.front()) : const(ValueIndex!(V, I)), V, I);

    static if (is(R : const(S)[], S)) {
        alias T = typeof(range[0]);
    } else static if (isValueIndexType) {
        alias T = typeof(R.front().value);
    } else {
        alias T = typeof(R.front());
    }

    return range.reduce((T x, T y) => x > y ? x : y);
}

auto sum(R)(R range) {
    enum isValueIndexType = is(typeof(R.front()) : const(ValueIndex!(V, I)), V, I);

    static if (is(R : const(S)[], S)) {
        alias T = typeof(range[0]);
    } else static if (isValueIndexType) {
        alias T = typeof(R.front().value);
    } else {
        alias T = typeof(R.front());
    }

    return range.reduce((T x, T y) => x + y);
}

auto product(R)(R range) {
    enum isValueIndexType = is(typeof(R.front()) : const(ValueIndex!(V, I)), V, I);

    static if (is(R : const(S)[], S)) {
        alias T = typeof(range[0]);
    } else static if (isValueIndexType) {
        alias T = typeof(R.front().value);
    } else {
        alias T = typeof(R.front());
    }

    return range.reduce((T x, T y) => x * y);
}

@safe nothrow @nogc
unittest {
    auto temp = 0;
    auto start = 0;
    auto stop = 4;
    auto step = 1;
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

    assert(range(3).map((int x) => x * 2).sum == 6);
    assert(range(9).filter((int x) => x == 2 || x == 4).sum == 6);
    assert(range(0, 4).reduce((int x, int y) => x + y) == 6);
    assert(range(0, 4).reduce((int x, int y) => x * y) == 0);
    assert(range(1, 4).reduce((int x, int y) => x * y) == 6);
    assert(slice.reduce((int x, int y) => x + y) == 6);
    assert(range(2, 6).min == 2);
    assert(range(2, 6).max == 5);
    assert(slice.min == 2);
    assert(slice.max == 2);

    // You like my coode?
    assert(
        range(1, 5)
            .map((int x) => x * 2)
            .filter((int x) => x > 4)
            .reduce((int a, int b) => a + b)
        == 14
    );
}
