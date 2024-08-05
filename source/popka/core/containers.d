// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `containers` module provides various data structures.
module popka.core.containers;

import popka.core.ascii;
import popka.core.stdc;
import popka.core.types;

@safe @nogc nothrow:

enum defaultListCapacity = 64;

alias LStr   = List!char;
alias LStr16 = List!wchar;
alias LStr32 = List!dchar;

struct List(T) {
    T[] items;
    Sz capacity;

    @safe @nogc nothrow:

    this(const(T)[] args...) {
        foreach (arg; args) {
            append(arg);
        }
    }

    this(List!T list) {
        foreach (item; list.items) {
            append(item);
        }
    }

    this(FlagList!T list) {
        foreach (item; list.items) {
            append(item);
        }
    }

    T[] opSlice(Sz dimension)(Sz i, Sz j) {
        return items[i .. j];
    }

    T[] opIndex() {
        return items[];
    }

    // D calls this function when the slice operator is used. Does something but I do not remember what lol.
    T[] opIndex(T[] slice) {
        return slice;
    }

    // D will let you get the pointer of the array item if you return a ref value.
    ref T opIndex(Sz i) {
        return items[i];
    }

    @trusted
    void opIndexAssign(const(T) rhs, Sz i) {
        items[i] = cast(T) rhs;
    }

    @trusted
    void opIndexOpAssign(IStr op)(const(T) rhs, Sz i) {
        mixin("items[i] " ~ op ~ "= cast(T) rhs;");
    }

    bool opEquals(List!T rhs) {
        return items == rhs.items;
    }

    @trusted
    bool opEquals(const(T)[] rhs) {
        return items == cast(T[]) rhs;
    }

    Sz opDollar(Sz dimension)() {
        return items.length;
    }

    Sz length() {
        return items.length;
    }

    @trusted
    T* ptr() {
        return items.ptr;
    }

    @trusted
    void append(const(T)[] args...) {
        foreach (arg; args) {
            Sz newLength = length + 1;
            if (newLength > capacity) {
                capacity = findListCapacity(newLength);
                items = (cast(T*) realloc(items.ptr, capacity * T.sizeof))[0 .. newLength];
            } else {
                items = items.ptr[0 .. newLength];
            }
            items[$ - 1] = cast(T) arg;
        }
    }

    void remove(Sz i) {
        items[i] = items[$ - 1];
        items = items[0 .. $ - 1];
    }

    T pop() {
        if (length > 0) {
            T temp = items[$ - 1];
            remove(length - 1);
            return temp;
        } else {
            return T.init;
        }
    }

    @trusted
    void reserve(Sz capacity) {
        auto targetCapacity = findListCapacity(capacity);
        if (targetCapacity > this.capacity) {
            this.capacity = targetCapacity;
            items = (cast(T*) realloc(items.ptr, this.capacity * T.sizeof))[0 .. length];
        }
    }

    void resize(Sz length) {
        if (length <= this.length) {
            items = items[0 .. length];
        } else {
            reserve(length);
            foreach (i; 0 .. length - this.length) {
                append(T.init);
            }
        }
    }

    @trusted
    void fill(const(T) value) {
        foreach (ref item; items) {
            item = cast(T) value;
        }
    }

    void clear() {
        items = items[0 .. 0];
    }

    @trusted
    void free() {
        .free(items.ptr);
        items = [];
        capacity = 0;
    }
}

struct FlagList(T) {
    List!T data;
    List!bool flags;
    Sz hotIndex;
    Sz openIndex;
    Sz length;

    @safe @nogc nothrow:

    this(const(T)[] args...) {
        foreach (arg; args) {
            append(arg);
        }
    }

    this(List!T list) {
        foreach (item; list.items) {
            append(item);
        }
    }

    this(FlagList!T list) {
        data.resize(list.data.length);
        flags.resize(list.flags.length);
        foreach (i; 0 .. flags.length) {
            data[i] = list.data[i];
            flags[i] = list.flags[i];
        }
        hotIndex = list.hotIndex;
        openIndex = list.openIndex;
        length = list.length;
    }

    ref T opIndex(Sz i) {
        if (!has(i)) {
            assert(0, "ID `[{}]` does not exist.".format(i));
        }
        return data[i];
    }

    @trusted
    void opIndexAssign(const(T) rhs, Sz i) {
        if (!has(i)) {
            assert(0, "ID `[{}]` does not exist.".format(i));
        }
        data[i] = cast(T) rhs;
    }

    @trusted
    void opIndexOpAssign(IStr op)(const(T) rhs, Sz i) {
        if (!has(i)) {
            assert(0, "ID `[{}]` does not exist.".format(i));
        }
        mixin("data[i] ", op, "= cast(T) rhs;");
    }

    Sz capacity() {
        return data.capacity;
    }

    @trusted
    T* ptr() {
        return data.ptr;
    }

    bool has(Sz id) {
        return id < flags.length && flags[id];
    }

    @trusted
    void append(const(T)[] args...) {
        foreach (arg; args) {
            if (openIndex == flags.length) {
                data.append(arg);
                flags.append(true);
                hotIndex = openIndex;
                openIndex = flags.length;
                length += 1;
            } else {
                auto isFull = true;
                foreach (i; openIndex .. flags.length) {
                    if (!flags[i]) {
                        data[i] = arg;
                        flags[i] = true;
                        hotIndex = i;
                        openIndex = i;
                        isFull = false;
                        break;
                    }
                }
                if (isFull) {
                    data.append(arg);
                    flags.append(true);
                    hotIndex = flags.length - 1;
                    openIndex = flags.length;
                }
                length += 1;
            }
        }
    }

    void remove(Sz i) {
        if (!has(i)) {
            assert(0, "ID `[{}]` does not exist.".format(i));
        }
        flags[i] = false;
        hotIndex = i;
        if (i < openIndex) {
            openIndex = i;
        }
        length -= 1;
    }

    @trusted
    void fill(const(T) value) {
        foreach (ref item; items) {
            item = cast(T) value;
        }
    }

    void clear() {
        data.clear();
        flags.clear();
        hotIndex = 0;
        openIndex = 0;
        length = 0;
    }

    void free() {
        data.free();
        flags.free();
        hotIndex = 0;
        openIndex = 0;
        length = 0;
    }

    auto ids() {
        struct Range {
            bool[] flags;
            Sz id;

            bool empty() {
                return id == flags.length;
            }
            
            Sz front() {
                return id;
            }
            
            void popFront() {
                id += 1;
                while (id != flags.length && !flags[id]) {
                    id += 1;
                }
            }
        }

        Sz id = 0;
        while (id < flags.length && !flags[id]) {
            id += 1;
        }
        return Range(flags.items, id);
    }

    auto items() {
        struct Range {
            T[] data;
            bool[] flags;
            Sz id;

            bool empty() {
                return id == flags.length;
            }
            
            ref T front() {
                return data[id];
            }
            
            void popFront() {
                id += 1;
                while (id != flags.length && !flags[id]) {
                    id += 1;
                }
            }
        }

        Sz id = 0;
        while (id < flags.length && !flags[id]) {
            id += 1;
        }
        return Range(data.items, flags.items, id);
    }
}

struct Grid(T) {
    List!T tiles;
    Sz rowCount;
    Sz colCount;

    @safe @nogc nothrow:

    this(Sz rowCount, Sz colCount) {
        resize(rowCount, colCount);
    }

    T[] opIndex() {
        return tiles[];
    }

    ref T opIndex(Sz row, Sz col) {
        if (!has(row, col)) {
            assert(0, "Tile `[{}, {}]` does not exist.".format(row, col));
        }
        return tiles[colCount * row + col];
    }

    void opIndexAssign(T rhs, Sz row, Sz col) {
        if (!has(row, col)) {
            assert(0, "Tile `[{}, {}]` does not exist.".format(row, col));
        }
        tiles[colCount * row + col] = rhs;
    }

    void opIndexOpAssign(IStr op)(T rhs, Sz row, Sz col) {
        if (!has(row, col)) {
            assert(0, "Tile `[{}, {}]` does not exist.".format(row, col));
        }
        mixin("tiles[colCount * row + col] " ~ op ~ "= rhs;");
    }

    Sz opDollar(Sz dimension)() {
        static if (dimension == 0) {
            return rowCount;
        } else static if (dimension == 1) {
            return colCount;
        } else {
            assert(0, "WTF!");
        }
    }

    Sz length() {
        return tiles.length;
    }

    Sz capacity() {
        return tiles.capacity;
    }

    @trusted
    T* ptr() {
        return tiles.ptr;
    }

    bool has(Sz row, Sz col) {
        return row < rowCount && col < colCount;
    }

    void resize(Sz rowCount, Sz colCount) {
        this.tiles.resize(rowCount * colCount);
        this.rowCount = rowCount;
        this.colCount = colCount;
    }

    void fill(T value) {
        tiles.fill(value);
    }

    void clear() {
        tiles.clear();
        rowCount = 0;
        colCount = 0;
    }

    void free() {
        tiles.free();
        rowCount = 0;
        colCount = 0;
    }
}

Sz findListCapacity(Sz length) {
    Sz result = defaultListCapacity;
    while (result < length) {
        result *= 2;
    }
    return result;
}

// Function test.
unittest {
    assert(findListCapacity(0) == defaultListCapacity);
    assert(findListCapacity(defaultListCapacity) == defaultListCapacity);
    assert(findListCapacity(defaultListCapacity + 1) == defaultListCapacity * 2);
}

// List test.
unittest {
    LStr text;

    text = LStr();
    assert(text.length == 0);
    assert(text.capacity == 0);
    assert(text.ptr == null);

    text = LStr("abc");
    assert(text.length == 3);
    assert(text.capacity == defaultListCapacity);
    assert(text.ptr != null);
    text.free();
    assert(text.length == 0);
    assert(text.capacity == 0);
    assert(text.ptr == null);

    text = LStr("Hello world!");
    assert(text.length == "Hello world!".length);
    assert(text.capacity == defaultListCapacity);
    assert(text.ptr != null);
    assert(text[] == text.items);
    assert(text[0] == text.items[0]);
    assert(text[0 .. $] == text.items[0 .. $]);
    assert(text[0] == 'H');
    text[0] = 'h';
    assert(text[0] == 'h');
    text.append("!!");
    assert(text == "hello world!!!");
    assert(text.pop() == '!');
    assert(text.pop() == '!');
    assert(text == "hello world!");
    text.resize(0);
    assert(text == "");
    assert(text.length == 0);
    assert(text.capacity == defaultListCapacity);
    assert(text.pop() == char.init);
    text.resize(1);
    assert(text[0] == char.init);
    assert(text.length == 1);
    assert(text.capacity == defaultListCapacity);
    text.clear();
    text.reserve(5);
    assert(text.length == 0);
    assert(text.capacity == defaultListCapacity);
    text.reserve(defaultListCapacity + 1);
    assert(text.length == 0);
    assert(text.capacity == defaultListCapacity * 2);
    text.free();
}

// FlagList test.
unittest {
    FlagList!int numbers;

    numbers = FlagList!int();
    assert(numbers.length == 0);
    assert(numbers.capacity == 0);
    assert(numbers.ptr == null);
    assert(numbers.hotIndex == 0);
    assert(numbers.openIndex == 0);

    numbers = FlagList!int(1, 2, 3);
    assert(numbers.length == 3);
    assert(numbers.capacity == defaultListCapacity);
    assert(numbers.ptr != null);
    assert(numbers.hotIndex == 2);
    assert(numbers.openIndex == 3);
    assert(numbers[0] == 1);
    assert(numbers[1] == 2);
    assert(numbers[2] == 3);
    assert(numbers.has(0) == true);
    assert(numbers.has(1) == true);
    assert(numbers.has(2) == true);
    assert(numbers.has(3) == false);
    numbers.remove(1);
    assert(numbers.has(0) == true);
    assert(numbers.has(1) == false);
    assert(numbers.has(2) == true);
    assert(numbers.has(3) == false);
    assert(numbers.hotIndex == 1);
    assert(numbers.openIndex == 1);
    numbers.append(1);
    assert(numbers.has(0) == true);
    assert(numbers.has(1) == true);
    assert(numbers.has(2) == true);
    assert(numbers.has(3) == false);
    assert(numbers.hotIndex == 1);
    assert(numbers.openIndex == 1);
    numbers.append(4);
    assert(numbers.has(0) == true);
    assert(numbers.has(1) == true);
    assert(numbers.has(2) == true);
    assert(numbers.has(3) == true);
    assert(numbers.hotIndex == 3);
    assert(numbers.openIndex == 4);
    numbers.clear();
    numbers.append(1);
    assert(numbers.has(0) == true);
    assert(numbers.has(1) == false);
    assert(numbers.has(2) == false);
    assert(numbers.has(3) == false);
    assert(numbers.hotIndex == 0);
    assert(numbers.openIndex == 1);
    numbers.free();
    assert(numbers.length == 0);
    assert(numbers.capacity == 0);
    assert(numbers.ptr == null);
    assert(numbers.hotIndex == 0);
    assert(numbers.openIndex == 0);
}

// Grid test
unittest {
    Grid!int numbers;

    numbers = Grid!int();
    assert(numbers.length == 0);
    assert(numbers.capacity == 0);
    assert(numbers.ptr == null);
    assert(numbers.rowCount == 0);
    assert(numbers.colCount == 0);

    numbers = Grid!int(8, 8);
    assert(numbers.length == 8 * 8);
    assert(numbers.capacity == defaultListCapacity);
    assert(numbers.ptr != null);
    assert(numbers.rowCount == 8);
    assert(numbers.colCount == 8);
    assert(numbers[0, 0] == 0);
    assert(numbers[7, 7] == 0);
    assert(numbers.has(7, 8) == false);
    assert(numbers.has(8, 7) == false);
    assert(numbers.has(8, 8) == false);
    numbers.free();
    assert(numbers.length == 0);
    assert(numbers.capacity == 0);
    assert(numbers.ptr == null);
    assert(numbers.rowCount == 0);
    assert(numbers.colCount == 0);
}
