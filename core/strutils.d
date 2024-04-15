// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The strutils module contains procedures
/// designed to assist with various string manipulation tasks.

module popka.core.strutils;

@safe @nogc nothrow:

enum digitChars = "0123456789";
enum upperChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
enum lowerChars = "abcdefghijklmnopqrstuvwxyz";
enum alphaChars = upperChars ~ lowerChars;
enum spaceChars = " \t\v\r\n\f";

bool isStrz(const(char)[] str) {
    return str.length != 0 && str[$ - 1] == '\0';
}

bool isDigit(char c) {
    return c >= '0' && c <= '9';
}

bool isDigit(const(char)[] str) {
    foreach (c; str) {
        if (!isDigit(c)) return false;
    }
    return true;
}

bool isUpper(char c) {
    return c >= 'A' && c <= 'Z';
}

bool isUpper(const(char)[] str) {
    foreach (c; str) {
        if (!isUpper(c)) return false;
    }
    return true;
}

bool isLower(char c) {
    return c >= 'a' && c <= 'z';
}

bool isLower(const(char)[] str) {
    foreach (c; str) {
        if (!isLower(c)) return false;
    }
    return true;
}

bool isAlpha(char c) {
    return isLower(c) || isUpper(c);
}

bool isAlpha(const(char)[] str) {
    foreach (c; str) {
        if (!isAlpha(c)) return false;
    }
    return true;
}

bool isSpace(char c) {
    foreach (sc; spaceChars) {
        if (c == sc) return true;
    }
    return false;
}

bool isSpace(const(char)[] str) {
    foreach (c; str) {
        if (!isSpace(c)) return false;
    }
    return true;
}

char toDigit(char c) {
    return isDigit(c) ? cast(char) (c - 48) : '?';
}

void toDigit(char[] str) {
    foreach (ref c; str) {
        c = toDigit(c);
    }
}

char toUpper(char c) {
    return isLower(c) ? cast(char) (c - 32) : c;
}

void toUpper(char[] str) {
    foreach (ref c; str) {
        c = toUpper(c);
    }
}

char toLower(char c) {
    return isUpper(c) ? cast(char) (c + 32) : c;
}

void toLower(char[] str) {
    foreach (ref c; str) {
        c = toLower(c);
    }
}

bool equals(const(char)[] str, const(char)[] other) {
    return str == other;
}

bool equalsCaseInsensitive(const(char)[] str, const(char)[] other) {
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

bool startsWithCaseInsensitive(const(char)[] str, const(char)[] start) {
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

bool endsWithCaseInsensitive(const(char)[] str, const(char)[] end) {
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

int countCaseInsensitive(const(char)[] str, const(char)[] item) {
    int result = 0;
    if (str.length < item.length || item.length == 0) return result;
    foreach (i; 0 .. str.length - item.length) {
        if (equalsCaseInsensitive(str[i .. i + item.length], item)) {
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

int findStartCaseInsensitive(const(char)[] str, const(char)[] item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach (i; 0 .. str.length - item.length) {
        if (equalsCaseInsensitive(str[i + item.length .. item.length], item)) return cast(int) i;
    }
    return -1;
}

int findEnd(const(char)[] str, const(char)[] item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach_reverse (i; 0 .. str.length - item.length) {
        if (str[i + item.length .. i + item.length + item.length] == item) return cast(int) i;
    }
    return -1;
}

int findEndCaseInsensitive(const(char)[] str, const(char)[] item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach_reverse (i; 0 .. str.length - item.length) {
        if (equalsCaseInsensitive(str[i + item.length .. i + item.length + item.length], item)) return cast(int) i;
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

// NOTE: Maybe think of other name.
const(char)[] dirName(const(char)[] path) {
    version (Windows) {
        auto end = findEnd(path, "\\");
    } else {
        auto end = findEnd(path, "/");
    }
    if (end == -1) {
        return ".";
    } else {
        // TODO: Might have some bug in find prodecure.
        return path[0 .. end + 1];
    }
}

// NOTE: Maybe think of other name.
const(char)[] makePath(const(char)[][] args...) {
    static char[1024] buffer = void;

    if (args.length == 0) {
        return ".";
    }

    auto result = buffer[];
    auto length = 0;
    foreach (i, arg; args) {
        result.copyStrChars(arg, length);
        length += arg.length;
        if (i != args.length - 1) {
            version (Windows) {
                result.copyStrChars("\\", length);
            } else {
                result.copyStrChars("/", length);
            }
            length += 1;
        }
    }
    result = result[0 .. length];
    return result;
}

// TODO: Add sep that is a string.

const(char)[] skipValue(ref const(char)[] str, char sep) {
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

void copyStrChars(char[] str, const(char)[] source, size_t startIndex = 0) {
    foreach (i, c; source) {
        str[startIndex + i] = c;
    }
}

void copyStr(ref char[] str, const(char)[] source, size_t startIndex = 0) {
    copyStrChars(str, source, startIndex);
    str = str[0 .. startIndex + source.length];
}
