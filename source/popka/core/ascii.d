// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `ascii` module provides functions designed to assist with ascii strings.

module popka.core.ascii;

import popka.core.containers;
import popka.core.errors;
import popka.core.traits;
import popka.core.types;

@safe @nogc nothrow:

enum digitChars = "0123456789";
enum upperChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
enum lowerChars = "abcdefghijklmnopqrstuvwxyz";
enum alphaChars = upperChars ~ lowerChars;
enum spaceChars = " \t\v\r\n\f";

version (Windows) {
    enum pathSep = '\\';
    enum otherPathSep = '/';
} else {
    enum pathSep = '/';
    enum otherPathSep = '\\';
}

struct ToStrOptions {
    ubyte doublePrecision = 2;
}

bool isDigit(char c) {
    return c >= '0' && c <= '9';
}

bool isDigit(IStr str) {
    foreach (c; str) {
        if (!isDigit(c)) return false;
    }
    return true;
}

bool isUpper(char c) {
    return c >= 'A' && c <= 'Z';
}

bool isUpper(IStr str) {
    foreach (c; str) {
        if (!isUpper(c)) return false;
    }
    return true;
}

bool isLower(char c) {
    return c >= 'a' && c <= 'z';
}

bool isLower(IStr str) {
    foreach (c; str) {
        if (!isLower(c)) return false;
    }
    return true;
}

bool isAlpha(char c) {
    return isLower(c) || isUpper(c);
}

bool isAlpha(IStr str) {
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

bool isSpace(IStr str) {
    foreach (c; str) {
        if (!isSpace(c)) return false;
    }
    return true;
}

bool isCStr(IStr str) {
    return str.length != 0 && str[$ - 1] == '\0';
}

char toUpper(char c) {
    return isLower(c) ? cast(char) (c - 32) : c;
}

void toUpper(Str str) {
    foreach (ref c; str) {
        c = toUpper(c);
    }
}

char toLower(char c) {
    return isUpper(c) ? cast(char) (c + 32) : c;
}

void toLower(Str str) {
    foreach (ref c; str) {
        c = toLower(c);
    }
}

@trusted
Sz length(ICStr str) {
    Sz result = 0;
    while (str[result] != '\0') {
        result += 1;
    }
    return result;
}

bool equals(IStr str, IStr other) {
    return str == other;
}

bool equals(IStr str, char other) {
    return equals(str, charToStr(other));
}

bool equalsNoCase(IStr str, IStr other) {
    if (str.length != other.length) return false;
    foreach (i; 0 .. str.length) {
        if (toUpper(str[i]) != toUpper(other[i])) return false;
    }
    return true;
}

bool equalsNoCase(IStr str, char other) {
    return equalsNoCase(str, charToStr(other));
}

bool startsWith(IStr str, IStr start) {
    if (str.length < start.length) return false;
    return str[0 .. start.length] == start;
}

bool startsWith(IStr str, char start) {
    return startsWith(str, charToStr(start));
}

bool endsWith(IStr str, IStr end) {
    if (str.length < end.length) return false;
    return str[$ - end.length .. $] == end;
}

bool endsWith(IStr str, char end) {
    return endsWith(str, charToStr(end));
}

int count(IStr str, IStr item) {
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

int count(IStr str, char item) {
    return count(str, charToStr(item));
}

int findStart(IStr str, IStr item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach (i; 0 .. str.length - item.length + 1) {
        if (str[i .. i + item.length] == item) return cast(int) i;
    }
    return -1;
}

int findStart(IStr str, char item) {
    return findStart(str, charToStr(item));
}

int findEnd(IStr str, IStr item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach_reverse (i; 0 .. str.length - item.length + 1) {
        if (str[i .. i + item.length] == item) return cast(int) i;
    }
    return -1;
}

int findEnd(IStr str, char item) {
    return findEnd(str, charToStr(item));
}

IStr trimStart(IStr str) {
    IStr result = str;
    while (result.length > 0) {
        if (isSpace(result[0])) result = result[1 .. $];
        else break;
    }
    return result;
}

IStr trimEnd(IStr str) {
    IStr result = str;
    while (result.length > 0) {
        if (isSpace(result[$ - 1])) result = result[0 .. $ - 1];
        else break;
    }
    return result;
}

IStr trim(IStr str) {
    return str.trimStart().trimEnd();
}

IStr removePrefix(IStr str, IStr prefix) {
    if (str.startsWith(prefix)) {
        return str[prefix.length .. $];
    } else {
        return str;
    }
}

IStr removeSuffix(IStr str, IStr suffix) {
    if (str.endsWith(suffix)) {
        return str[0 .. $ - suffix.length];
    } else {
        return str;
    }
}

IStr advance(IStr str, Sz amount) {
    if (str.length < amount) {
        return str[$ .. $];
    } else {
        return str[amount .. $];
    }
}

void copyChars(Str str, IStr source, Sz startIndex = 0) {
    if (str.length < source.length) {
        assert(0, "The destination string `{}` must be at least as long as the source string `{}`.".format(str, source));
    }
    foreach (i, c; source) {
        str[startIndex + i] = c;
    }
}

void copy(ref Str str, IStr source, Sz startIndex = 0) {
    copyChars(str, source, startIndex);
    str = str[0 .. startIndex + source.length];
}

IStr pathDir(IStr path) {
    auto end = findEnd(path, pathSep);
    if (end == -1) {
        return ".";
    } else {
        return path[0 .. end];
    }
}

// TODO: Make it more safe? Look at how Python does it.
IStr pathConcat(IStr[] args...) {
    static char[1024][4] buffers = void;
    static byte bufferIndex = 0;

    if (args.length == 0) {
        return ".";
    }

    bufferIndex = (bufferIndex + 1) % buffers.length;

    auto result = buffers[bufferIndex][];
    auto length = 0;
    foreach (i, arg; args) {
        result.copyChars(arg, length);
        length += arg.length;
        if (i != args.length - 1) {
            result.copyChars(charToStr(pathSep), length);
            length += 1;
        }
    }
    result = result[0 .. length];
    return result;
}

IStr skipValue(ref inout(char)[] str, IStr separator) {
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

IStr skipValue(ref inout(char)[] str, char separator) {
    return skipValue(str, charToStr(separator));
}

IStr skipLine(ref inout(char)[] str) {
    return skipValue(str, '\n');
}

IStr boolToStr(bool value) {
    return value ? "true" : "false";
}

IStr charToStr(char value) {
    static char[1] buffer = void;

    auto result = buffer[];
    result[0] = value;
    result = result[0 .. 1];
    return result;
}

IStr unsignedToStr(ulong value) {
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

IStr signedToStr(long value) {
    static char[64] buffer = void;

    auto result = buffer[];
    if (value < 0) {
        auto temp = unsignedToStr(-value);
        result[0] = '-';
        result.copy(temp, 1);
    } else {
        auto temp = unsignedToStr(value);
        result.copy(temp, 0);
    }
    return result;
}

// TODO: Fix N.00 bug and make it more simple.
IStr doubleToStr(double value, uint precision = 2) {
    static char[64] buffer = void;

    if (value != value) {
        return "nan";
    }

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
        result.copyChars(cleanNumberStr, i);
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
            result.copyChars(cleanNumberStr, i);
        } else {
            i -= fractionalDigitCount;
            result.copyChars(cleanNumberStr[$ - fractionalDigitCount .. $], i);
            i -= 1;
            result[i] = '.';
            i -= (cleanNumberStr.length - fractionalDigitCount);
            result.copyChars(cleanNumberStr[0 .. $ - fractionalDigitCount], i);
        }
    }

    if (precision == 0) {
        result = result[i .. $];
    } else {
        result = result[i .. $ - fractionalDigitCount + (precision > fractionalDigitCount ? fractionalDigitCount : precision)];
    }
    return result;
}

@trusted
IStr cStrToStr(ICStr value) {
    return value[0 .. value.length];
}

IStr enumToStr(T)(T value) {
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

IStr toStr(T)(T value, ToStrOptions options = ToStrOptions()) {
    static if (isCharType!T) {
        return charToStr(value);
    } else static if (isBoolType!T) {
        return boolToStr(value);
    } else static if (isUnsignedType!T) {
        return unsignedToStr(value);
    } else static if (isSignedType!T) {
        return signedToStr(value);
    } else static if (isDoubleType!T) {
        return doubleToStr(value, options.doublePrecision);
    } else static if (isStrType!T) {
        return value;
    } else static if (isCStrType!T) {
        return cStrToStr(value);
    } else static if (isEnumType!T) {
        return enumToStr(value);
    } else static if (__traits(hasMember, T, "toStr")) {
        return value.toStr();
    } else {
        static assert(0, "The `toStr` function does not handle the `" ~ T.stringof ~ "` type. Implement a `toStr` function for that type.");
    }
}

BasicResult!bool toBool(IStr str) {
    auto result = BasicResult!bool();
    if (str == "true") {
        result.value = true;
    } else if (str == "false") {
        result.value = false;
    } else {
        result.error = BasicError.invalid;
    }
    return result;
}

ulong toBoolWithNone(IStr str) {
    auto conv = toBool(str);
    if (conv.error) {
        return false;
    } else {
        return conv.value;
    }
}

BasicResult!ulong toUnsigned(IStr str) {
    auto result = BasicResult!ulong();
    if (str.length == 0) {
        result.error = BasicError.invalid;
    } else if (str.length >= 18) {
        result.error = BasicError.overflow;
    } else {
        ulong level = 1;
        foreach_reverse (i, c; str) {
            if (!isDigit(c)) {
                result.error = BasicError.invalid;
                break;
            }
            auto digit = c - '0';
            result.value += digit * level;
            level *= 10;
        }
    }
    return result;
}

BasicResult!ulong toUnsigned(char c) {
    auto result = BasicResult!ulong();
    if (isDigit(c)) {
        result.value = c - '0';
    } else {
        result.error = BasicError.invalid;
    }
    return result;
}

ulong toUnsignedWithNone(IStr str) {
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

BasicResult!long toSigned(IStr str) {
    auto result = BasicResult!long();
    if (str.length == 0) {
        result.error = BasicError.invalid;
    } else if (str.length >= 18) {
        result.error = BasicError.overflow;
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

BasicResult!long toSigned(char c) {
    auto result = BasicResult!long();
    auto conv = toUnsigned(c);
    if (conv.error) {
        result.error = conv.error;
    } else {
        result.value = cast(long) conv.value;
    }
    return result;
}

long toSignedWithNone(IStr str) {
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

BasicResult!double toDouble(IStr str) {
    auto result = BasicResult!double();
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

double toDoubleWithNone(IStr str) {
    auto conv = toDouble(str);
    if (conv.error) {
        return 0.0;
    } else {
        return conv.value;
    }
}

BasicResult!T toEnum(T)(IStr str) {
    auto result = BasicResult!T();
    switch (str) {
        static foreach (member; __traits(allMembers, T)) {
            mixin("case " ~ member.stringof ~ ": result.value = T." ~ member ~ "; goto switchExit;");
        }
        default: result.error = BasicError.invalid;
    }
    switchExit:
    return result;
}

T toEnumWithNone(T)(IStr str) {
    auto conv = toEnum!T(str);
    if (conv.error) {
        return T.init;
    } else {
        return conv.value;
    }
}

@trusted
ICStr toCStr(IStr str) {
    static char[1024] buffer = void;

    auto result = buffer[];
    foreach (i, c; str) {
        result[i] = c;
    }
    result[str.length] = '\0';
    return result.ptr;
}

// TODO: Check if the args count is the same with the `{}` count.
IStr format(A...)(IStr formatStr, A args) {
    static char[1024][8] buffers = void;
    static byte bufferIndex = 0;

    bufferIndex = (bufferIndex + 1) % buffers.length;

    auto result = buffers[bufferIndex][];
    auto resultIndex = 0;
    auto formatStrIndex = 0;
    auto argIndex = 0;

    while (formatStrIndex < formatStr.length) {
        auto c1 = formatStr[formatStrIndex];
        auto c2 = formatStrIndex + 1 >= formatStr.length ? '+' : formatStr[formatStrIndex + 1];
        if (c1 == '{' && c2 == '}' && argIndex < args.length) {
            static foreach (i, arg; args) {
                if (i == argIndex) {
                    auto temp = toStr(arg);
                    foreach (i, c; temp) {
                        result[resultIndex + i] = c;
                    }
                    resultIndex += temp.length;
                    formatStrIndex += 2;
                    argIndex += 1;
                    goto loopExit;
                }
            }
            loopExit:
        } else {
            result[resultIndex] = c1;
            resultIndex += 1;
            formatStrIndex += 1;
        }
    }
    result = result[0 .. resultIndex];
    return result;
}

// TODO: Check if the args count is the same with the `{}` count.
void formatl(A...)(ref LStr text, IStr formatStr, A args) {
    text.clear();

    auto formatStrIndex = 0;
    auto argIndex = 0;

    while (formatStrIndex < formatStr.length) {
        auto c1 = formatStr[formatStrIndex];
        auto c2 = formatStrIndex + 1 >= formatStr.length ? '+' : formatStr[formatStrIndex + 1];
        if (c1 == '{' && c2 == '}' && argIndex < args.length) {
            static foreach (i, arg; args) {
                if (i == argIndex) {
                    auto temp = toStr(arg);
                    foreach (i, c; temp) {
                        text.append(c);
                    }
                    formatStrIndex += 2;
                    argIndex += 1;
                    goto loopExit;
                }
            }
            loopExit:
        } else {
            text.append(c1);
            formatStrIndex += 1;
        }
    }
}

// Function test.
@trusted
unittest {
    assert(isDigit("0123456789?") == false);
    assert(isDigit("0123456789") == true);
    assert(isUpper("hello") == false);
    assert(isUpper("HELLO") == true);
    assert(isLower("HELLO") == false);
    assert(isLower("hello") == true);
    assert(isSpace(" \t\r\n ") == true);
    assert(isCStr("hello") == false);
    assert(isCStr("hello\0") == true);

    char[128] buffer = void;
    Str str;

    str = buffer[];
    str.copy("Hello");
    assert(str == "Hello");
    str.toUpper();
    assert(str == "HELLO");
    str.toLower();
    assert(str == "hello");

    str = buffer[];
    str.copy("Hello\0");
    assert(isCStr(str) == true);
    assert(str.ptr.length + 1 == str.length);

    str = buffer[];
    str.copy("Hello");
    assert(str.equals("HELLO") == false);
    assert(str.equalsNoCase("HELLO") == true);
    assert(str.startsWith("H") == true);
    assert(str.startsWith("Hell") == true);
    assert(str.startsWith("Hello") == true);
    assert(str.endsWith("o") == true);
    assert(str.endsWith("ello") == true);
    assert(str.endsWith("Hello") == true);

    str = buffer[];
    str.copy("hello hello world.");
    assert(str.count("hello") == 2);
    assert(str.findStart("HELLO") == -1);
    assert(str.findStart("hello") == 0);
    assert(str.findEnd("HELLO") == -1);
    assert(str.findEnd("hello") == 6);

    str = buffer[];
    str.copy(" Hello world. ");
    assert(str.trimStart() == "Hello world. ");
    assert(str.trimEnd() == " Hello world.");
    assert(str.trim() == "Hello world.");
    assert(str.removePrefix("Hello") == str);
    assert(str.trim().removePrefix("Hello") == " world.");
    assert(str.removeSuffix("world.") == str);
    assert(str.trim().removeSuffix("world.") == "Hello ");
    assert(str.advance(0) == str);
    assert(str.advance(1) == str[1 .. $]);
    assert(str.advance(str.length) == "");
    assert(str.advance(str.length + 1) == "");
    assert(pathConcat("one", "two").pathDir() == "one");
    assert(pathConcat("one").pathDir() == ".");

    str = buffer[];
    str.copy("one, two ,three,");
    assert(skipValue(str, ',') == "one");
    assert(skipValue(str, ',') == " two ");
    assert(skipValue(str, ',') == "three");
    assert(skipValue(str, ',') == "");
    assert(str.length == 0);

    

    // TODO: I need to write more tests for toValue procedures.
    auto text1 = "1.0";
    auto conv1 = toDouble(text1);
    assert(conv1.value == 1.0);
    assert(conv1.error == BasicError.none);

    auto text2 = "1";
    auto conv2 = toDouble(text2);
    assert(conv2.value == 1.0);
    assert(conv2.error == BasicError.none);

    auto text3 = "1?";
    auto conv3 = toDouble(text3);
    assert(conv3.value == 0.0);
    assert(conv3.error == BasicError.invalid);

    assert(format("") == "");
    assert(format("{}") == "{}");
    assert(format("{}", "1") == "1");
    assert(format("{} {}", "1", "2") == "1 2");
    assert(format("{} {} {}", "1", "2", "3") == "1 2 3");
    assert(format("{} {} {}", 1, -2, 3.69) == "1 -2 3.69");
    assert(format("{}", 420, 320, 220, 120, 20) == "420");
    assert(format("", 1, -2, 3.69) == "");
    assert(format("({})", format("({}, {})", false, true)) == "((false, true))");

    // TODO: Uncoment when the N.00 bug is fixed.
    // assert(format("{}", 0.00) == "0.00");
    // assert(format("{}", 0.50) == "0.50");
    // assert(format("{}", 1.00) == "1.00");
    // assert(format("{}", 1.50) == "1.50");
}
