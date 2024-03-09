// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The strconv module offers procedures for both
/// parsing strings into numeric data types
/// and formatting numbers into string representations.

module popka.core.strconv;

struct ToStrOptions {
    uint floatPrecision = 2;
}

struct ToNumResult(T) {
    alias Error = ubyte;
    enum : Error {
        ok,
        invalid,
        overflow,
    }

    T value;
    Error error;
}

const(char)[] boolToStr(bool value) {
    static char[64] buf = void;
    auto result = buf[];

    if (value) {
        result[0 .. 4] = "true";
        result = result[0 .. 4];
    } else {
        result[0 .. 5] = "false";
        result = result[0 .. 5];
    }
    return result;
}

const(char)[] unsignedToStr(ulong value) {
    static char[64] buf = void;
    auto result = buf[];
    
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
    static char[64] buf = void;
    auto result = buf[];
    
    if (value < 0) {
        auto temp = unsignedToStr(-value);
        result[0] = '-';
        foreach (i, c; temp) {
            result[1 + i] = c;
        }
        result = result[0 .. 1 + temp.length];
    } else {
        auto temp = unsignedToStr(value);
        foreach (i, c; temp) {
            result[i] = c;
        }
        result = result[0 .. temp.length];
    }
    return result;
}

const(char)[] floatToStr(double value, uint precision = 2) {
    static char[64] buf = void;
    auto result = buf[];

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
        result[i .. i + temp.length] = temp;
        if (temp.length < fractionalDigitCount) {
            i -= fractionalDigitCount - temp.length;
            result[i .. i + fractionalDigitCount - temp.length] = '0';
        }
        i -= 2;
        result[i .. i + 2] = "0.";
    } else {
        if (fractionalDigitCount == 0) {
            i -= (precision == 0 ? 1 : precision);
            result[i .. i + (precision == 0 ? 1 : precision)] = '0';
            i -= 1;
            result[i] = '.';
            i -= temp.length;
            result[i .. i + temp.length] = temp;
        } else {
            i -= fractionalDigitCount;
            result[i .. i + fractionalDigitCount] = temp[$ - fractionalDigitCount .. $];
            i -= 1;
            result[i] = '.';
            i -= (temp.length - fractionalDigitCount);
            result[i .. i + (temp.length - fractionalDigitCount)] = temp[0 .. $ - fractionalDigitCount];
        }
    }

    if (precision == 0) {
        result = result[i .. $];
    } else {
        result = result[i .. $ - fractionalDigitCount + (precision > fractionalDigitCount ? fractionalDigitCount : precision)];
    }
    return result;
}

const(char)[] charToStr(char value) {
    static char[1] buf = void;
    auto result = buf[];

    result[0] = value;
    result = result[0 .. 1];
    return result;
}

const(char)[] strzToStr(const(char)* value) {
    static char[1024] buf = void;
    auto result = buf[];

    size_t strzLength = 0;
    while (value[strzLength] != '\0') {
        result[strzLength] = value[strzLength];
        strzLength += 1;
    }
    result = result[0 .. strzLength];
    return result;
}

const(char)[] strToStr(const(char)[] value) {
    return value;
}

const(char)[] toStr(T)(T value, ToStrOptions options = ToStrOptions()) {
    enum isBool = is(T == bool);
    enum isUnsigned = is(T == ubyte) || is(T == ushort) || is(T == uint) || is(T == ulong);
    enum isSigned = is(T == byte) || is(T == short) || is(T == int) || is(T == long);
    enum isFloat = is(T == float) || is(T == double);
    enum isChar = is(T == char) || is(T == const(char)) || is(T == immutable(char));
    enum isStrz = is(T : const(char)*);
    enum isStr = is(T : const(char)[]);

    static if (isBool) {
        return boolToStr(value);
    } else static if (isUnsigned) {
        return unsignedToStr(value);
    } else static if (isSigned) {
        return signedToStr(value);
    } else static if (isFloat) {
        return floatToStr(value, options.floatPrecision);
    } else static if (isChar) {
        return charToStr(value);
    } else static if (isStrz) {
        return strzToStr(value);
    } else static if (isStr) {
        return strToStr(value);
    } else {
        static assert(0, "The 'toStr' function exclusively handles numerical valueues, booleans, characters and strings.");
    }
}

ToNumResult!bool toBool(const(char)[] str) {
    auto result = ToNumResult!bool();
    if (str == "true") {
        result.value = true;
    } else if (str == "false") {
        result.value = false;
    } else {
        result.error = result.invalid;
    }
    return result;
}

ToNumResult!ulong toUnsigned(const(char)[] str) {
    auto result = ToNumResult!ulong();

    if (str.length == 0) {
        result.error = result.invalid;
    } else if (str.length >= 18) {
        result.error = result.overflow;
    } else {
        ulong level = 1;
        foreach_reverse (i, c; str) {
            if (c < '0' || c > '9') {
                result.error = result.invalid;
                break;
            }
            auto digit = c - '0';
            result.value += digit * level;
            level *= 10;
        }
    }
    return result;
}

ToNumResult!long toSigned(const(char)[] str) {
    auto result = ToNumResult!long();

    if (str.length == 0) {
        result.error = result.invalid;
    } else if (str.length >= 18) {
        result.error = result.overflow;
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

ToNumResult!double toFloat(const(char)[] str) {
    auto result = ToNumResult!double();

    foreach (i, c; str) {
        if (c == '.') {
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
    return result;
}

const(char)* toStrz(const(char)[] str) {
    static char[1024] buf = void;
    auto result = buf[];

    foreach (i, c; str) {
        result[i] = c;
    }
    result[str.length] = '\0';
    return result.ptr;
}

unittest {}
