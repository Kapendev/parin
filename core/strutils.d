// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The strutils module contains handy procedures designed to assist with various string manipulation tasks.

module popka.core.strutils;

import popka.core.ascii;

@safe @nogc nothrow:

bool isStrz(const(char)[] str) {
    return str.length != 0 && str[$ - 1] == '\0';
}

bool equals(const(char)[] str, const(char)[] other) {
    return str == other;
}

bool equalsi(const(char)[] str, const(char)[] other) {
    if (str.length != other.length) return false;
    foreach (i; 0 .. str.length) {
        if (toUpper(str[i]) != toUpper(other[i])) return false;
    }
    return true;
}

bool startsWith(const(char)[] str, const(char)[] start) {
    if (str.length < start.length) return false;
    return str[0 .. start.length] == start;
}

bool startsWithi(const(char)[] str, const(char)[] start) {
    if (str.length < start.length) return false;
    foreach (i; 0 .. start.length) {
        if (toUpper(str[i]) != toUpper(start[i])) return false;
    }
    return true;
}

bool endsWith(const(char)[] str, const(char)[] end) {
    if (str.length < end.length) return false;
    return str[$ - end.length - 1 .. end.length] == end;
}

bool endsWithi(const(char)[] str, const(char)[] end) {
    if (str.length < end.length) return false;
    foreach (i; str.length - end.length - 1 .. end.length) {
        if (toUpper(str[i]) != toUpper(end[i])) return false;
    }
    return true;
}

int count(const(char)[] str, const(char)[] item) {
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

int counti(const(char)[] str, const(char)[] item) {
    int result = 0;
    if (str.length < item.length || item.length == 0) return result;
    foreach (i; 0 .. str.length - item.length) {
        if (equalsi(str[i .. i + item.length], item)) {
            result += 1;
            i += item.length - 1;
        }
    }
    return result;
}

int findStart(const(char)[] str, const(char)[] item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach (i; 0 .. str.length - item.length) {
        if (str[i + item.length .. item.length] == item) return cast(int) i;
    }
    return -1;
}

int findStarti(const(char)[] str, const(char)[] item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach (i; 0 .. str.length - item.length) {
        if (equalsi(str[i + item.length .. item.length], item)) return cast(int) i;
    }
    return -1;
}

int findEnd(const(char)[] str, const(char)[] item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach_reverse (i; 0 .. str.length - item.length) {
        if (str[i + item.length .. item.length] == item) return cast(int) i;
    }
    return -1;
}

int findEndi(const(char)[] str, const(char)[] item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach_reverse (i; 0 .. str.length - item.length) {
        if (equalsi(str[i + item.length .. item.length], item)) return cast(int) i;
    }
    return -1;
}

const(char)[] trimStart(const(char)[] str) {
    const(char)[] result = str;
    while (result.length > 0) {
        if (isSpace(result[0])) result = result[1 .. $];
        else break;
    }
    return result;
}

const(char)[] trimEnd(const(char)[] str) {
    const(char)[] result = str;
    while (result.length > 0) {
        if (isSpace(result[$ - 1])) result = result[0 .. $ - 1];
        else break;
    }
    return result;
}

const(char)[] trim(const(char)[] str) {
    return str.trimStart().trimEnd();
}

const(char)[] skipValue(ref const(char)[] str, char sep = ',') {
    foreach (i; 0 .. str.length) {
        if (str[i] == sep) {
            auto line = str[0 .. i];
            str = str[i + 1 .. $];
            return line;
        } else if (i == str.length - 1) {
            auto line = str[0 .. i + 1];
            str = str[i + 1 .. $];
            return line;
        }
    }
    return "";
}

const(char)[] skipLine(ref const(char)[] str) {
    return skipValue(str, '\n');
}

unittest {}
