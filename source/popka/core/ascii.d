// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The `ascii` module provides functions designed to assist with ascii strings.
module popka.core.ascii;

import popka.core.containers;
import popka.core.faults;
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
        assert(0, "Destination string `{}` must be at least as long as the source string `{}`.".format(str, source));
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

IStr doubleToStr(double value, ulong precision = 2) {
    static char[64] buffer = void;

    if (precision == 0) {
        return signedToStr(cast(long) value);
    }

    auto result = buffer[];
    auto cleanNumber = value;
    auto rightDigitCount = 0;
    while (cleanNumber != cast(double) (cast(long) cleanNumber)) {
        rightDigitCount += 1;
        cleanNumber *= 10;
    }

    // Add extra zeros at the end if needed.
    // I do this because it makes it easier to remove the zeros later.
    if (precision > rightDigitCount) {
        foreach (j; 0 .. precision - rightDigitCount) {
            rightDigitCount += 1;
            cleanNumber *= 10;
        }
    }

    // Digits go in the buffer from right to left.
    auto cleanNumberStr = signedToStr(cast(long) cleanNumber);
    auto i = result.length; 
    // Check two cases: 0.NN, N.NN
    if (cast(long) value == 0) {
        i -= cleanNumberStr.length;
        result.copyChars(cleanNumberStr, i);
        foreach (j; 0 .. rightDigitCount - cleanNumberStr.length) {
            i -= 1;
            result[i] = '0';
        }
        i -= 2;
        result.copyChars("0.", i);
    } else {
        i -= rightDigitCount;
        result.copyChars(cleanNumberStr[$ - rightDigitCount .. $], i);
        i -= 1;
        result[i] = '.';
        i -= cleanNumberStr.length - rightDigitCount;
        result.copyChars(cleanNumberStr[0 .. $ - rightDigitCount], i);
    }
    // Remove extra zeros at the end if needed.
    if (precision < rightDigitCount) {
        result = result[0 .. $ - rightDigitCount + precision];
    }
    return result[i .. $];
}

@trusted
IStr cStrToStr(ICStr value) {
    return value[0 .. value.length];
}

IStr enumToStr(T)(T value) {
    switch (value) {
        static foreach (member; __traits(allMembers, T)) {
            mixin("case T." ~ member ~ ": return member;");
        }
        default: assert(0, "WTF!");
    }
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
        static assert(0, "Type `" ~ T.stringof ~ "` does not implement the `toStr` function.");
    }
}

Result!bool toBool(IStr str) {
    if (str == "false") {
        return Result!bool(false);
    } else if (str == "true") {
        return Result!bool(true);
    } else {
        return Result!bool(Fault.invalid);
    }
}

Result!ulong toUnsigned(IStr str) {
    if (str.length == 0 || str.length >= 18) {
        return Result!ulong(Fault.invalid);
    } else {
        if (str.length == 1 && str[0] == '+') {
            return Result!ulong(Fault.invalid);
        }
        ulong value = 0;
        ulong level = 1;
        foreach_reverse (i, c; str[(str[0] == '+' ? 1 : 0) .. $]) {
            if (isDigit(c)) {
                value += (c - '0') * level;
                level *= 10;
            } else {
                return Result!ulong(Fault.invalid);
            }
        }
        return Result!ulong(value);
    }
}

Result!ulong toUnsigned(char c) {
    if (isDigit(c)) {
        return Result!ulong(c - '0');
    } else {
        return Result!ulong(Fault.invalid);
    }
}

Result!long toSigned(IStr str) {
    if (str.length == 0 || str.length >= 18) {
        return Result!long(Fault.invalid);
    } else {
        auto temp = toUnsigned(str[(str[0] == '-' ? 1 : 0) .. $]);
        return Result!long(str[0] == '-' ? -temp.value : temp.value, temp.fault);
    }
}

Result!long toSigned(char c) {
    if (isDigit(c)) {
        return Result!long(c - '0');
    } else {
        return Result!long(Fault.invalid);
    }
}

Result!double toDouble(IStr str) {
    auto dotIndex = findStart(str, '.');
    if (dotIndex == -1) {
        auto temp = toSigned(str);
        return Result!double(temp.value, temp.fault);
    } else {
        auto left = toSigned(str[0 .. dotIndex]);
        auto right = toSigned(str[dotIndex + 1 .. $]);
        if (left.isNone || right.isNone) {
            return Result!double(Fault.invalid);
        } else if (str[dotIndex + 1] == '-' || str[dotIndex + 1] == '+') {
            return Result!double(Fault.invalid);
        } else {
            auto sign = str[0] == '-' ? -1 : 1;
            auto level = 10;
            foreach (i; 1 .. str[dotIndex + 1 .. $].length) {
                level *= 10;
            }
            return Result!double(left.value + sign * (right.value / (cast(double) level)));
        }
    }
}

Result!double toDouble(char c) {
    if (isDigit(c)) {
        return Result!double(c - '0');
    } else {
        return Result!double(Fault.invalid);
    }
}

Result!T toEnum(T)(IStr str) {
    switch (str) {
        static foreach (member; __traits(allMembers, T)) {
            mixin("case " ~ member.stringof ~ ": return Result!T(T." ~ member ~ ");");
        }
        default: return Result!T(Fault.invalid);
    }
}

@trusted
Result!ICStr toCStr(IStr str) {
    static char[1024] buffer = void;

    if (buffer.length < str.length) {
        return Result!ICStr(Fault.invalid);
    } else {
        auto value = buffer[];
        value.copyChars(str);
        value[str.length] = '\0';
        return Result!ICStr(value.ptr);
    }
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
    enum TestEnum {
        one,
        two,
    }

    char[128] buffer = void;
    Str str;

    assert(isDigit("0123456789?") == false);
    assert(isDigit("0123456789") == true);
    assert(isUpper("hello") == false);
    assert(isUpper("HELLO") == true);
    assert(isLower("HELLO") == false);
    assert(isLower("hello") == true);
    assert(isSpace(" \t\r\n ") == true);
    assert(isCStr("hello") == false);
    assert(isCStr("hello\0") == true);

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

    assert(boolToStr(false) == "false");
    assert(boolToStr(true) == "true");
    assert(charToStr('L') == "L");

    assert(unsignedToStr(0) == "0");
    assert(unsignedToStr(69) == "69");
    assert(signedToStr(0) == "0");
    assert(signedToStr(69) == "69");
    assert(signedToStr(-69) == "-69");
    assert(signedToStr(-69) == "-69");

    assert(doubleToStr(0.00, 0) == "0");
    assert(doubleToStr(0.00, 1) == "0.0");
    assert(doubleToStr(0.00, 2) == "0.00");
    assert(doubleToStr(0.00, 3) == "0.000");
    assert(doubleToStr(0.60, 1) == "0.6");
    assert(doubleToStr(0.60, 2) == "0.60");
    assert(doubleToStr(0.60, 3) == "0.600");
    assert(doubleToStr(0.09, 1) == "0.0");
    assert(doubleToStr(0.09, 2) == "0.09");
    assert(doubleToStr(0.09, 3) == "0.090");
    assert(doubleToStr(69.0, 1) == "69.0");
    assert(doubleToStr(69.0, 2) == "69.00");
    assert(doubleToStr(69.0, 3) == "69.000");

    assert(cStrToStr("Hello\0") == "Hello");

    assert(enumToStr(TestEnum.one) == "one");
    assert(enumToStr(TestEnum.two) == "two");

    assert(toBool("F").isSome == false);
    assert(toBool("F").unwrapOr() == false);
    assert(toBool("T").isSome == false);
    assert(toBool("T").unwrapOr() == false);
    assert(toBool("false").isSome == true);
    assert(toBool("false").unwrapOr() == false);
    assert(toBool("true").isSome == true);
    assert(toBool("true").unwrapOr() == true);

    assert(toUnsigned("1_069").isSome == false);
    assert(toUnsigned("1_069").unwrapOr() == 0);
    assert(toUnsigned("+1069").isSome == true);
    assert(toUnsigned("+1069").unwrapOr() == 1069);
    assert(toUnsigned("1069").isSome == true);
    assert(toUnsigned("1069").unwrapOr() == 1069);
    assert(toUnsigned('+').isSome == false);
    assert(toUnsigned('+').unwrapOr() == 0);
    assert(toUnsigned('0').isSome == true);
    assert(toUnsigned('0').unwrapOr() == 0);
    assert(toUnsigned('9').isSome == true);
    assert(toUnsigned('9').unwrapOr() == 9);

    assert(toSigned("1_069").isSome == false);
    assert(toSigned("1_069").unwrapOr() == 0);
    assert(toSigned("-1069").isSome == true);
    assert(toSigned("-1069").unwrapOr() == -1069);
    assert(toSigned("+1069").isSome == true);
    assert(toSigned("+1069").unwrapOr() == 1069);
    assert(toSigned("1069").isSome == true);
    assert(toSigned("1069").unwrapOr() == 1069);
    assert(toSigned('+').isSome == false);
    assert(toSigned('+').unwrapOr() == 0);
    assert(toSigned('0').isSome == true);
    assert(toSigned('0').unwrapOr() == 0);
    assert(toSigned('9').isSome == true);
    assert(toSigned('9').unwrapOr() == 9);

    assert(toDouble("1_069").isSome == false);
    assert(toDouble("1_069").unwrapOr() == 0);
    assert(toDouble(".1069").isSome == false);
    assert(toDouble(".1069").unwrapOr() == 0);
    assert(toDouble("1069.").isSome == false);
    assert(toDouble("1069.").unwrapOr() == 0);
    assert(toDouble(".").isSome == false);
    assert(toDouble(".").unwrapOr() == 0);
    assert(toDouble("-1069.-69").isSome == false);
    assert(toDouble("-1069.-69").unwrapOr() == 0);
    assert(toDouble("-1069.+69").isSome == false);
    assert(toDouble("-1069.+69").unwrapOr() == 0);
    assert(toDouble("-1069").isSome == true);
    assert(toDouble("-1069").unwrapOr() == -1069);
    assert(toDouble("+1069").isSome == true);
    assert(toDouble("+1069").unwrapOr() == 1069);
    assert(toDouble("1069").isSome == true);
    assert(toDouble("1069").unwrapOr() == 1069);
    assert(toDouble("1069.0").isSome == true);
    assert(toDouble("1069.0").unwrapOr() == 1069);
    assert(toDouble("-1069.0095").isSome == true);
    assert(toDouble("-1069.0095").unwrapOr() == -1069.0095);
    assert(toDouble("+1069.0095").isSome == true);
    assert(toDouble("+1069.0095").unwrapOr() == 1069.0095);
    assert(toDouble("1069.0095").isSome == true);
    assert(toDouble("1069.0095").unwrapOr() == 1069.0095);
    assert(toDouble("-0.0095").isSome == true);
    assert(toDouble("-0.0095").unwrapOr() == -0.0095);
    assert(toDouble("+0.0095").isSome == true);
    assert(toDouble("+0.0095").unwrapOr() == 0.0095);
    assert(toDouble("0.0095").isSome == true);
    assert(toDouble("0.0095").unwrapOr() == 0.0095);
    assert(toDouble('+').isSome == false);
    assert(toDouble('+').unwrapOr() == 0);
    assert(toDouble('0').isSome == true);
    assert(toDouble('0').unwrapOr() == 0);
    assert(toDouble('9').isSome == true);
    assert(toDouble('9').unwrapOr() == 9);
    
    assert(toEnum!TestEnum("?").isSome == false);
    assert(toEnum!TestEnum("?").unwrapOr() == TestEnum.one);
    assert(toEnum!TestEnum("one").isSome == true);
    assert(toEnum!TestEnum("one").unwrapOr() == TestEnum.one);
    assert(toEnum!TestEnum("two").isSome == true);
    assert(toEnum!TestEnum("two").unwrapOr() == TestEnum.two);

    assert(toCStr("Hello").unwrapOr().length == "Hello".length);
    assert(toCStr("Hello").unwrapOr().cStrToStr() == "Hello");

    // TODO: Write tests for `format` when it is done.
}
