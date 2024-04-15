// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The strconv module offers procedures for both
/// parsing strings into numeric data types
/// and formatting numbers into string representations.

module popka.core.strconv;

import popka.core.strutils;
import popka.core.traits;

@safe @nogc nothrow:

enum ToValueResultError : ubyte {
    none,
    invalid,
    overflow,
}

struct ToStrOptions {
    ubyte floatPrecision = 2;
}

struct ToValueResult(T) {
    T value;
    ToValueResultError error;
}

const(char)[] charToStr(char value) {
    static char[1] buffer = void;
    auto result = buffer[];

    result[0] = value;
    result = result[0 .. 1];
    return result;
}

const(char)[] boolToStr(bool value) {
    static char[8] buffer = void;

    auto result = buffer[];
    if (value) {
        result.copyStr("true");
    } else {
        result.copyStr("false");
    }
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

    auto result = buffer[];
    auto fractionalDigitCount = 0;
    auto cleanNumber = value;
    while (cleanNumber != cast(double) (cast(long) cleanNumber)) {
        fractionalDigitCount += 1;
        cleanNumber *= 10;
    }
    
    auto temp = signedToStr(cast(long) cleanNumber);
    auto i = result.length;

    if (temp.length <= fractionalDigitCount) {
        i -= temp.length;
        result.copyStrChars(temp, i);
        if (temp.length < fractionalDigitCount) {
            i -= fractionalDigitCount - temp.length;
            result[i .. i + fractionalDigitCount - temp.length] = '0';
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
            i -= temp.length;
            result.copyStrChars(temp, i);
        } else {
            i -= fractionalDigitCount;
            result.copyStrChars(temp[$ - fractionalDigitCount .. $], i);
            i -= 1;
            result[i] = '.';
            i -= (temp.length - fractionalDigitCount);
            result.copyStrChars(temp[0 .. $ - fractionalDigitCount], i);
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
    static if (isChar!T) {
        return charToStr(value);
    } else static if (isBool!T) {
        return boolToStr(value);
    } else static if (isUnsigned!T) {
        return unsignedToStr(value);
    } else static if (isSigned!T) {
        return signedToStr(value);
    } else static if (isDouble!T) {
        return doubleToStr(value, options.floatPrecision);
    } else static if (isStr!T) {
        return value;
    } else static if (isStrz!T) {
        return strzToStr(value);
    } else static if (isEnum!T) {
        return enumToStr(value);
    } else {
        static assert(0, "The 'toStr' function doesn't handle this type.");
    }
}

ToValueResult!bool toBool(const(char)[] str) {
    auto result = ToValueResult!bool();
    if (str == "true") {
        result.value = true;
    } else if (str == "false") {
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
            if (c < '0' || c > '9') {
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

ulong toUnsignedWithNone(const(char)[] str) {
    auto conv = toUnsigned(str);
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

long toSignedWithNone(const(char)[] str) {
    auto conv = toSigned(str);
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
        result.error = ToValueResultError.invalid;
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

unittest {
    auto text1 = "1.0";
    auto conv1 = toDouble(text1);
    assert(conv1.value == 1.0);
    assert(conv1.error == ToValueResultError.none);

    auto text2 = "1";
    auto conv2 = toDouble(text2);
    assert(conv2.value == 0.0);
    assert(conv2.error == ToValueResultError.invalid);
}
