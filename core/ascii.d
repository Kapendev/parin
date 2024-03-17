// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The ascii module assists in handling ASCII characters.

module popka.core.ascii;

@safe @nogc nothrow:

enum {
    digitChars = "0123456789",
    upperChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    lowerChars = "abcdefghijklmnopqrstuvwxyz",
    alphaChars = upperChars ~ lowerChars,
    spaceChars = " \t\v\r\n\f",
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
    return isDigit(c) ? cast(char) (c - 48) : '0';
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

unittest {}
