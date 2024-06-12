// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The strutils module contains procedures
/// designed to assist with string manipulation tasks.

module popka.core.strutils;

import popka.core.traits;

@safe @nogc nothrow:

enum digitChars = "0123456789";
enum upperChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
enum lowerChars = "abcdefghijklmnopqrstuvwxyz";
enum alphaChars = upperChars ~ lowerChars;
enum spaceChars = " \t\v\r\n\f";

version (Windows) {
    enum pathSeparator = '\\';
    enum otherPathSeparator = '/';
} else {
    enum pathSeparator = '/';
    enum otherPathSeparator = '\\';
}

enum ToValueResultError : ubyte {
    none,
    invalid,
    overflow,
}

struct ToStrOptions {
    bool boolIsShort = false;
    ubyte floatPrecision = 2;
}

struct ToValueResult(T) {
    T value;
    ToValueResultError error;
}

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

@trusted
size_t length(const(char)* strz) {
    size_t result = 0;
    while (strz[result] != '\0') {
        result += 1;
    }
    return result;
}

bool equals(const(char)[] str, const(char)[] other) {
    return str == other;
}

bool equals(const(char)[] str, char other) {
    return equals(str, charToStr(other));
}

bool equalsIgnoreCase(const(char)[] str, const(char)[] other) {
    if (str.length != other.length) return false;
    foreach (i; 0 .. str.length) {
        if (toUpper(str[i]) != toUpper(other[i])) return false;
    }
    return true;
}

bool equalsIgnoreCase(const(char)[] str, char other) {
    return equalsIgnoreCase(str, charToStr(other));
}

bool startsWith(const(char)[] str, const(char)[] start) {
    if (str.length < start.length) return false;
    return str[0 .. start.length] == start;
}

bool startsWith(const(char)[] str, char start) {
    return startsWith(str, charToStr(start));
}

bool startsWithIgnoreCase(const(char)[] str, const(char)[] start) {
    if (str.length < start.length) return false;
    return str[0 .. start.length].equalsIgnoreCase(start);
}

bool startsWithIgnoreCase(const(char)[] str, char start) {
    return startsWithIgnoreCase(str, charToStr(start));
}

bool endsWith(const(char)[] str, const(char)[] end) {
    if (str.length < end.length) return false;
    return str[$ - end.length .. $] == end;
}

bool endsWith(const(char)[] str, char end) {
    return endsWith(str, charToStr(end));
}

bool endsWithIgnoreCase(const(char)[] str, const(char)[] end) {
    if (str.length < end.length) return false;
    return str[$ - end.length .. $].equalsIgnoreCase(end);
}

bool endsWithIgnoreCase(const(char)[] str, char end) {
    return endsWithIgnoreCase(str, charToStr(end));
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

int count(const(char)[] str, char item) {
    return count(str, charToStr(item));
}

int countIgnoreCase(const(char)[] str, const(char)[] item) {
    int result = 0;
    if (str.length < item.length || item.length == 0) return result;
    foreach (i; 0 .. str.length - item.length) {
        if (str[i .. i + item.length].equalsIgnoreCase(item)) {
            result += 1;
            i += item.length - 1;
        }
    }
    return result;
}

int countIgnoreCase(const(char)[] str, char item) {
    return countIgnoreCase(str, charToStr(item));
}

int findStart(const(char)[] str, const(char)[] item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach (i; 0 .. str.length - item.length) {
        if (str[i .. i + item.length] == item) return cast(int) i;
    }
    return -1;
}

int findStart(const(char)[] str, char item) {
    return findStart(str, charToStr(item));
}

int findStartIgnoreCase(const(char)[] str, const(char)[] item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach (i; 0 .. str.length - item.length) {
        if (str[i .. i + item.length].equalsIgnoreCase(item)) return cast(int) i;
    }
    return -1;
}

int findStartIgnoreCase(const(char)[] str, char item) {
    return findStartIgnoreCase(str, charToStr(item));
}

int findEnd(const(char)[] str, const(char)[] item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach_reverse (i; 0 .. str.length - item.length) {
        if (str[i .. i + item.length] == item) return cast(int) i;
    }
    return -1;
}

int findEnd(const(char)[] str, char item) {
    return findEnd(str, charToStr(item));
}

int findEndIgnoreCase(const(char)[] str, const(char)[] item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach_reverse (i; 0 .. str.length - item.length) {
        if (str[i .. i + item.length].equalsIgnoreCase(item)) return cast(int) i;
    }
    return -1;
}

int findEndIgnoreCase(const(char)[] str, char item) {
    return findEndIgnoreCase(str, charToStr(item));
}

const(char)[] advance(const(char)[] str, size_t amount) {
    if (str.length < amount) {
        return str[$ .. $];
    } else {
        return str[amount .. $];
    }
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

const(char)[] removePrefix(const(char)[] str, const(char)[] prefix) {
    if (str.startsWith(prefix)) {
        return str[prefix.length .. $];
    } else {
        return str;
    }
}

const(char)[] removeSuffix(const(char)[] str, const(char)[] suffix) {
    if (str.endsWith(suffix)) {
        return str[0 .. $ - suffix.length];
    } else {
        return str;
    }
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

const(char)[] pathDir(const(char)[] path) {
    auto end = findEnd(path, pathSeparator);
    if (end == -1) {
        return ".";
    } else {
        return path[0 .. end];
    }
}

// TODO: Make it more safe? Look at how Python does it.
const(char)[] pathConcat(const(char)[][] args...) {
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
            result.copyStrChars(charToStr(pathSeparator), length);
            length += 1;
        }
    }
    result = result[0 .. length];
    return result;
}

const(char)[] skipValue(ref inout(char)[] str, const(char)[] separator) {
    if (str.length < separator.length || separator.length == 0) {
        str = str[$ .. $];
        return "";
    }
    foreach (i; 0 .. str.length - separator.length) {
        if (str[i .. i + separator.length] == separator) {
            auto line = str[0 .. i];
            str = str[i + separator.length .. $];
            return line;
        }
    }
    auto line = str[0 .. $];
    if (str[$ - separator.length .. $] == separator) {
        line = str[0 .. $ - 1];
    }
    str = str[$ .. $];
    return line;
}

const(char)[] skipValue(ref inout(char)[] str, char separator) {
    return skipValue(str, charToStr(separator));
}

const(char)[] skipLine(ref inout(char)[] str) {
    return skipValue(str, '\n');
}

const(char)[] boolToStr(bool value, bool isShort = false) {
    if (isShort) {
        return value ? "t" : "f";
    } else {
        return value ? "true" : "false";
    }
}

const(char)[] charToStr(char value) {
    static char[1] buffer = void;

    auto result = buffer[];
    result[0] = value;
    result = result[0 .. 1];
    return result;
}

const(char)[] unsignedToStr(ulong value) {
    static char[64] buffer = void;

    auto result = buffer[];
    if (value == 0) {
        result[0] = '0';
        result = result[0 .. 1];
    } else {
        auto digitCount = 0;
        for (auto temp = value; temp != 0; temp /= 10) {
            result[$ - 1 - digitCount] = (temp % 10) + '0';
            digitCount += 1;
        }
        result = result[$ - digitCount .. $];
    }
    return result;
}

const(char)[] signedToStr(long value) {
    static char[64] buffer = void;

    auto result = buffer[];
    if (value < 0) {
        auto temp = unsignedToStr(-value);
        result[0] = '-';
        result.copyStr(temp, 1);
    } else {
        auto temp = unsignedToStr(value);
        result.copyStr(temp, 0);
    }
    return result;
}

const(char)[] doubleToStr(double value, uint precision = 2) {
    static char[64] buffer = void;

    auto result = buffer[];        // You know what this is.
    auto cleanNumber = value;      // Number that has all the digits on the left side.
    auto fractionalDigitCount = 0; // Digit count on the right size.
    while (cleanNumber != cast(double) (cast(long) cleanNumber)) {
        fractionalDigitCount += 1;
        cleanNumber *= 10;
    }

    auto i = result.length; // We put the numbers in the buffer from right to left.
    auto cleanNumberStr = signedToStr(cast(long) cleanNumber);
    // TODO: Fix N.00 bug and make it more simple.
    if (cleanNumberStr.length <= fractionalDigitCount) {
        i -= cleanNumberStr.length;
        result.copyStrChars(cleanNumberStr, i);
        if (cleanNumberStr.length < fractionalDigitCount) {
            i -= fractionalDigitCount - cleanNumberStr.length;
            result[i .. i + fractionalDigitCount - cleanNumberStr.length] = '0';
        }
        i -= 2;
        result[i] = '0';
        result[i + 1] = '.';
    } else {
        if (fractionalDigitCount == 0) {
            i -= (precision == 0 ? 1 : precision);
            result[i .. i + (precision == 0 ? 1 : precision)] = '0';
            i -= 1;
            result[i] = '.';
            i -= cleanNumberStr.length;
            result.copyStrChars(cleanNumberStr, i);
        } else {
            i -= fractionalDigitCount;
            result.copyStrChars(cleanNumberStr[$ - fractionalDigitCount .. $], i);
            i -= 1;
            result[i] = '.';
            i -= (cleanNumberStr.length - fractionalDigitCount);
            result.copyStrChars(cleanNumberStr[0 .. $ - fractionalDigitCount], i);
        }
    }

    if (precision == 0) {
        result = result[i .. $];
    } else {
        result = result[i .. $ - fractionalDigitCount + (precision > fractionalDigitCount ? fractionalDigitCount : precision)];
    }
    return result;
}

const(char)[] enumToStr(T)(T value) {
    static char[64] buffer = void;

    auto result = buffer[];
    auto name = "";
    final switch (value) {
        static foreach (member; __traits(allMembers, T)) {
            mixin("case T." ~ member ~ ": name = member; goto switchExit;");
        }
    }
    switchExit:

    foreach (i, c; name) {
        result[i] = c;
    }
    result = result[0 .. name.length];
    return result;
}

@trusted
const(char)[] strzToStr(const(char)* value) {
    static char[1024] buffer = void;

    auto result = buffer[];
    size_t strzLength = 0;
    while (value[strzLength] != '\0') {
        result[strzLength] = value[strzLength];
        strzLength += 1;
    }
    result = result[0 .. strzLength];
    return result;
}

const(char)[] toStr(T)(T value, ToStrOptions options = ToStrOptions()) {
    static if (isCharType!T) {
        return charToStr(value);
    } else static if (isBoolType!T) {
        return boolToStr(value, options.boolIsShort);
    } else static if (isUnsignedType!T) {
        return unsignedToStr(value);
    } else static if (isSignedType!T) {
        return signedToStr(value);
    } else static if (isDoubleType!T) {
        return doubleToStr(value, options.floatPrecision);
    } else static if (isStrType!T) {
        return value;
    } else static if (isStrzType!T) {
        return strzToStr(value);
    } else static if (isEnumType!T) {
        return enumToStr(value);
    } else {
        static assert(0, "The 'toStr' function does not handle the '" ~ T.stringof ~ "' type.");
    }
}

ToValueResult!bool toBool(const(char)[] str) {
    auto result = ToValueResult!bool();
    if (str == "t" || str == "true") {
        result.value = true;
    } else if (str == "f" || str == "false") {
        result.value = false;
    } else {
        result.error = ToValueResultError.invalid;
    }
    return result;
}

ulong toBoolWithNone(const(char)[] str) {
    auto conv = toBool(str);
    if (conv.error) {
        return false;
    } else {
        return conv.value;
    }
}

ToValueResult!ulong toUnsigned(const(char)[] str) {
    auto result = ToValueResult!ulong();
    if (str.length == 0) {
        result.error = ToValueResultError.invalid;
    } else if (str.length >= 18) {
        result.error = ToValueResultError.overflow;
    } else {
        ulong level = 1;
        foreach_reverse (i, c; str) {
            if (!isDigit(c)) {
                result.error = ToValueResultError.invalid;
                break;
            }
            auto digit = c - '0';
            result.value += digit * level;
            level *= 10;
        }
    }
    return result;
}

ToValueResult!ulong toUnsigned(char c) {
    auto result = ToValueResult!ulong();
    if (isDigit(c)) {
        result.value = c - '0';
    } else {
        result.error = ToValueResultError.invalid;
    }
    return result;
}

ulong toUnsignedWithNone(const(char)[] str) {
    auto conv = toUnsigned(str);
    if (conv.error) {
        return 0;
    } else {
        return conv.value;
    }
}

ulong toUnsignedWithNone(char c) {
    auto conv = toUnsigned(c);
    if (conv.error) {
        return 0;
    } else {
        return conv.value;
    }
}

ToValueResult!long toSigned(const(char)[] str) {
    auto result = ToValueResult!long();
    if (str.length == 0) {
        result.error = ToValueResultError.invalid;
    } else if (str.length >= 18) {
        result.error = ToValueResultError.overflow;
    } else {
        if (str[0] == '-') {
            auto conv = toUnsigned(str[1 .. $]);
            if (conv.error) {
                result.error = conv.error;
            } else {
                result.value = -conv.value;
            }
        } else {
            auto conv = toUnsigned(str);
            if (conv.error) {
                result.error = conv.error;
            } else {
                result.value = conv.value;
            }
        }
    }
    return result;
}

ToValueResult!long toSigned(char c) {
    auto result = ToValueResult!long();
    auto conv = toUnsigned(c);
    if (conv.error) {
        result.error = conv.error;
    } else {
        result.value = cast(long) conv.value;
    }
    return result;
}

long toSignedWithNone(const(char)[] str) {
    auto conv = toSigned(str);
    if (conv.error) {
        return 0;
    } else {
        return conv.value;
    }
}

long toSignedWithNone(char c) {
    auto conv = toSigned(c);
    if (conv.error) {
        return 0;
    } else {
        return conv.value;
    }
}

ToValueResult!double toDouble(const(char)[] str) {
    auto result = ToValueResult!double();
    result.value = 0.0;
    auto hasDot = false;
    foreach (i, c; str) {
        if (c == '.') {
            hasDot = true;
            auto lhs = toSigned(str[0 .. i]);
            if (lhs.error) {
                result.error = lhs.error;
            } else {
                auto rhs = toSigned(str[i + 1 .. $]);
                if (rhs.error) {
                    result.error = rhs.error;
                } else {
                    auto rhsLevel = 10;
                    foreach (_; 1 .. str[i + 1 .. $].length) {
                        rhsLevel *= 10;
                    }
                    result.value = lhs.value + ((lhs.value < 0 ? -1 : 1) * rhs.value / cast(double) rhsLevel);
                }
            }
            break;
        }
    }
    if (!hasDot) {
        auto conv = toSigned(str);
        result.value = conv.value;
        result.error = conv.error;
    }
    return result;
}

double toDoubleWithNone(const(char)[] str) {
    auto conv = toDouble(str);
    if (conv.error) {
        return 0.0;
    } else {
        return conv.value;
    }
}

ToValueResult!T toEnum(T)(const(char)[] str) {
    auto result = ToValueResult!T();
    switch (str) {
        static foreach (member; __traits(allMembers, T)) {
            mixin("case " ~ member.stringof ~ ": result.value = T." ~ member ~ "; goto switchExit;");
        }
        default: result.error = ToValueResultError.invalid;
    }
    switchExit:
    return result;
}

T toEnumWithNone(T)(const(char)[] str) {
    auto conv = toEnum!T(str);
    if (conv.error) {
        return T.init;
    } else {
        return conv.value;
    }
}

@trusted
const(char)* toStrz(const(char)[] str) {
    static char[1024] buffer = void;

    auto result = buffer[];
    foreach (i, c; str) {
        result[i] = c;
    }
    result[str.length] = '\0';
    return result.ptr;
}

const(char)[] fmt(A...)(const(char)[] str, A args) {
    static char[1024][4] bufs = void;
    static auto bufi = 0;

    bufi = (bufi + 1) % bufs.length;
    auto result = bufs[bufi][];
    auto resi = 0;
    auto stri = 0;
    auto argi = 0;

    while (stri < str.length) {
        auto c1 = str[stri];
        auto c2 = stri + 1 >= str.length ? '+' : str[stri + 1];
        if (c1 == '{' && c2 == '}' && argi < args.length) {
            static foreach (i, arg; args) {
                if (i == argi) {
                    auto temp = toStr(arg);
                    foreach (i, c; temp) {
                        result[resi + i] = c;
                    }
                    resi += temp.length;
                    stri += 2;
                    argi += 1;
                    goto loopExit;
                }
            }
            loopExit:
        } else {
            result[resi] = c1;
            resi += 1;
            stri += 1;
        }
    }
    result = result[0 .. resi];
    return result;
}

unittest {
    assert(isDigit("0123456789?") == false);
    assert(isDigit("0123456789") == true);
    assert(isUpper("hello") == false);
    assert(isUpper("HELLO") == true);
    assert(isLower("HELLO") == false);
    assert(isLower("hello") == true);
    assert(isSpace(" \t\r\n ") == true);
    
    char[128] buffer = void;
    char[] str = [];

    str = buffer[];
    str.copyStr("Hello");
    assert(str == "Hello");
    str.toUpper();
    assert(str == "HELLO");
    str.toLower();
    assert(str == "hello");

    str.copyStr("Hello");
    assert(str.equals("HELLO") == false);
    assert(str.equalsIgnoreCase("HELLO") == true);
    assert(str.startsWith("HELL") == false);
    assert(str.startsWithIgnoreCase("HELL") == true);
    assert(str.endsWith("LO") == false);
    assert(str.endsWithIgnoreCase("LO") == true);

    str = buffer[];
    str.copyStr("Hello hello world.");
    assert(str.count("HELLO") == 0);
    assert(str.countIgnoreCase("HELLO") == 2);
    assert(str.findStart("HELLO") == -1);
    assert(str.findStartIgnoreCase("HELLO") == 0);
    assert(str.findEnd("HELLO") == -1);
    assert(str.findEndIgnoreCase("HELLO") == 6);
    assert(str.advance(0) == str);
    assert(str.advance(1) == str[1 .. $]);
    assert(str.advance(str.length) == "");
    assert(str.advance(str.length + 1) == "");

    str = buffer[];
    str.copyStr(" Hello world. ");
    assert(str.trimStart() == "Hello world. ");
    assert(str.trimEnd() == " Hello world.");
    assert(str.trim() == "Hello world.");
    assert(str.removePrefix("Hello") == str);
    assert(str.trim().removePrefix("Hello") == " world.");
    assert(str.removeSuffix("world.") == str);
    assert(str.trim().removeSuffix("world.") == "Hello ");

    assert(pathConcat("one", "two").pathDir() == "one");
    assert(pathConcat("one").pathDir() == ".");

    str = buffer[];
    str.copyStr("one, two ,three,");
    assert(skipValue(str, ',') == "one");
    assert(skipValue(str, ',') == " two ");
    assert(skipValue(str, ',') == "three");
    assert(skipValue(str, ',') == "");
    assert(str.length == 0);

    // TODO: I need to write more tests for toValue procedures.
    auto text1 = "1.0";
    auto conv1 = toDouble(text1);
    assert(conv1.value == 1.0);
    assert(conv1.error == ToValueResultError.none);

    auto text2 = "1";
    auto conv2 = toDouble(text2);
    assert(conv2.value == 1.0);
    assert(conv2.error == ToValueResultError.none);

    auto text3 = "1?";
    auto conv3 = toDouble(text3);
    assert(conv3.value == 0.0);
    assert(conv3.error == ToValueResultError.invalid);

    assert(fmt("") == "");
    assert(fmt("{}") == "{}");
    assert(fmt("{}", "1") == "1");
    assert(fmt("{} {}", "1", "2") == "1 2");
    assert(fmt("{} {} {}", "1", "2", "3") == "1 2 3");
    assert(fmt("{} {} {}", 1, -2, 3.69) == "1 -2 3.69");
    assert(fmt("{}", 420, 320, 220, 120, 20) == "420");
    assert(fmt("", 1, -2, 3.69) == "");
    assert(fmt("({})", fmt("({}, {})", false, true)) == "((false, true))");

    // TODO: Uncoment when the N.00 bug is fixed.
    // assert(fmt("{}", 0.00) == "0.00");
    // assert(fmt("{}", 0.50) == "0.50");
    // assert(fmt("{}", 1.00) == "1.00");
    // assert(fmt("{}", 1.50) == "1.50");
}
