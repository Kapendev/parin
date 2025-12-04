// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `algo` module includes functions that work with ranges.
module parin.joka.algo;

import parin.joka.types;

@safe nothrow @nogc:

struct ValueIndex(V, I) {
    V value;
    I index;
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
    }

    return Range(slice);
}

auto range(I)(I start, I stop, I step = 1) {
    static struct Range {
        I index;
        I stop;
        I step;

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

    return Range(start, stop, step);
}

auto range(I)(I stop) {
    return range(0, stop);
}

auto enumerate(R, I)(R range, I start = 0) {
    static assert(!(is(R : const(A)[N], A, Sz N)), "Static arrays can't be passed.");

    static if (is(R : const(T)[], T)) {
        return enumerate(range.toRange());
    } else {
        alias Front = ValueIndex!(typeof(R.front()), I);

        static struct Range {
            R range;
            I index;

            bool empty() {
                return range.empty;
            }

            Front front() {
                return Front(range.front, index);
            }

            void popFront() {
                range.popFront();
                index += 1;
            }
        }

        return Range(range, start);
    }
}

auto sum(R)(R range) {
    static assert(!(is(R : const(A)[N], A, Sz N)), "Static arrays can't be passed.");

    static if (is(R : const(T)[], T)) {
        return sum(range.toRange());
    } else {
        enum isValueIndexType = is(typeof(R.front()) : const(ValueIndex!(V, I)), V, I);

        static if (isValueIndexType) {
            auto result = typeof(R.front().value).init;
        } else {
            auto result = typeof(R.front()).init;
        }
        foreach (item; range) {
            static if (isValueIndexType) {
                result += item.value;
            } else {
                result += item;
            }
        }
        return result;
    }
}

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
}
