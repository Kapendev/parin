// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `ascii` module provides functions designed to assist with ascii strings.
module joka.ascii;

import joka.memory;
import joka.types;

@safe:

// TODO: Need to add more `intoBuffer*` functions.
//   Like the split function is kinda not worth using lol.
//   Concat too probably.
//   Having helpers is fine, but yeah.

enum defaultAsciiBufferCount    = 16;   // Generic string count.
enum defaultAsciiBufferSize     = 1536; // Generic string length.
enum defaultAsciiFmtBufferCount = 32;   // Arg count.
enum defaultAsciiFmtBufferSize  = 512;  // Arg length.

enum digitChars    = "0123456789";                         /// The set of decimal numeric characters.
enum upperChars    = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";         /// The set of uppercase letters.
enum lowerChars    = "abcdefghijklmnopqrstuvwxyz";         /// The set of lowercase letters.
enum alphaChars    = upperChars ~ lowerChars;              /// The set of letters.
enum spaceChars    = " \t\v\r\n\f";                        /// The set of whitespace characters.
enum symbolChars   = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"; /// The set of symbol characters.
enum hexDigitChars = "0123456789abcdefABCDEF";             /// The set of hexadecimal numeric characters.

version (Windows) {
    enum pathSep = '\\';
    enum pathSepStr = "\\";
    enum pathSepOther = '/';
    enum pathSepOtherStr = "/";
} else {
    enum pathSep = '/';          /// The primary OS path separator as a character.
    enum pathSepStr = "/";       /// The primary OS path separator as a string.
    enum pathSepOther = '\\';    /// The complementary OS path separator as a character.
    enum pathSepOtherStr = "\\"; /// The complementary OS path separator as a string.
}

enum sp = Sep(" ");  /// Space separator.
enum cm = Sep(", "); /// Comma + space separator.

/// Separator marker for printing, ...
struct Sep { IStr value; }

/// Converts the value to its string representation.
@trusted
IStr toStr(T)(T value) {
    static assert(
        !isArrayType!T,
        "Static arrays can't be passed to `toStr`. This may also happen indirectly when using printing functions. Convert to a slice first."
    );

    static if (isCharType!T) {
        return charToStr(value);
    } else static if (isBoolType!T) {
        return boolToStr(value);
    } else static if (isUnsignedType!T) {
        return unsignedToStr(value);
    } else static if (isSignedType!T) {
        return signedToStr(value);
    } else static if (isFloatingType!T) {
        return doubleToStr(value, 2);
    } else static if (isStrType!T) {
        return value;
    } else static if (isCStrType!T) {
        return cStrToStr(value);
    } else static if (is(T == enum)) {
        return enumToStr(value);
    } else static if (__traits(hasMember, T, "toStr")) {
        return value.toStr();
    } else static if (__traits(hasMember, T, "toString")) {
        // I'm a nice person.
        return value.toString();
    } else {
        static assert(0, "Type `" ~ T.stringof ~ "` doesn't implement the `toStr` function.");
    }
}

deprecated("Use `fmtIntoBuffer` instead. All `format*` functions in Joka will be renamed to `fmt*` to avoid collisions with `std.format`.")
alias formatIntoBuffer = fmtIntoBuffer;
deprecated("Use `fmt` instead. All `format*` functions in Joka will be renamed to `fmt*` to avoid collisions with `std.format`.")
alias format = fmt;

/// Formats the given string by replacing `{}` placeholders with argument values in order.
/// Options within placeholders are not supported.
/// For custom formatting use a wrapper type with a `toStr` method.
/// Writes into the buffer and returns the formatted string.
@trusted nothrow @nogc
IStr fmtIntoBufferWithStrs(Str buffer, IStr fmtStr, IStr[] args...) {
    auto result = buffer;
    auto resultLength = 0;
    auto fmtStrIndex = 0;
    auto argIndex = 0;
    while (fmtStrIndex < fmtStr.length) {
        auto c1 = fmtStr[fmtStrIndex];
        auto c2 = fmtStrIndex + 1 >= fmtStr.length ? '+' : fmtStr[fmtStrIndex + 1];
        if (c1 == '{' && c2 == '}') {
            if (argIndex == args.length) assert(0, "A placeholder doesn't have an argument.");
            if (copyChars(result, args[argIndex], resultLength)) return "";
            resultLength += args[argIndex].length;
            fmtStrIndex += 2;
            argIndex += 1;
        } else {
            result[resultLength] = c1;
            resultLength += 1;
            fmtStrIndex += 1;
        }
    }
    if (argIndex != args.length) assert(0, "An argument doesn't have a placeholder.");
    result = result[0 .. resultLength];
    return result;
}

char[defaultAsciiFmtBufferSize][defaultAsciiFmtBufferCount] _fmtIntoBufferDataBuffer = void;
IStr[defaultAsciiFmtBufferCount]                            _fmtIntoBufferSliceBuffer = void;
char[defaultAsciiBufferSize][defaultAsciiBufferCount]       _fmtBuffer = void;
byte                                                        _fmtBufferIndex = 0;

/// Formats the given string by replacing `{}` placeholders with argument values in order.
/// Options within placeholders are not supported.
/// For custom formatting use a wrapper type with a `toStr` method.
/// Writes into the buffer and returns the formatted string.
@trusted
IStr fmtIntoBuffer(A...)(Str buffer, IStr fmtStr, A args) {
    static assert(args.length <= defaultAsciiFmtBufferCount, "Too many format arguments.");
    foreach (i, arg; args) {
        auto slice = _fmtIntoBufferDataBuffer[i][];
        auto temp = arg.toStr();
        if (slice.copyStr(temp)) return ""; // assert(0, "An argument did not fit in the internal temporary buffer.");
        _fmtIntoBufferSliceBuffer[i] = slice;
    }
    return fmtIntoBufferWithStrs(buffer, fmtStr, _fmtIntoBufferSliceBuffer[0 .. args.length]);
}

/// Formats into an internal static ring buffer and returns the slice.
/// The slice is temporary and may be overwritten by later calls to `fmt`.
/// For details on formatting, see the `fmtIntoBuffer` function.
@trusted
IStr fmt(A...)(IStr fmtStr, A args) {
    _fmtBufferIndex = (_fmtBufferIndex + 1) % _fmtBuffer.length;
    auto buffer = _fmtBuffer[_fmtBufferIndex][];

    // `fmtIntoBuffer` body copy-pasted here to avoid one template.
    static assert(args.length <= defaultAsciiFmtBufferCount, "Too many format arguments.");
    foreach (i, arg; args) {
        auto slice = _fmtIntoBufferDataBuffer[i][];
        auto temp = arg.toStr();
        if (slice.copyStr(temp)) assert(0, "An argument did not fit in the internal temporary buffer.");
        _fmtIntoBufferSliceBuffer[i] = slice;
    }
    return fmtIntoBufferWithStrs(buffer, fmtStr, _fmtIntoBufferSliceBuffer[0 .. args.length]);
}

@safe nothrow @nogc:

pragma(inline, true) {
    /// Returns true if the character is a digit (0-9).
    bool isDigit(char c) {
        return c >= '0' && c <= '9';
    }

    /// Returns true if the character is an uppercase letter (A-Z).
    bool isUpper(char c) {
        return c >= 'A' && c <= 'Z';
    }

    /// Returns true the character is a lowercase letter (a-z).
    bool isLower(char c) {
        return c >= 'a' && c <= 'z';
    }

    /// Returns true if the character is an alphabetic letter (A-Z, a-z).
    bool isAlpha(char c) {
        return isLower(c) || isUpper(c);
    }

    /// Returns true if the character is a whitespace character (space, tab, ...).
    bool isSpace(char c) {
        return (c >= '\t' && c <= '\r') || (c == ' ');
    }

    /// Returns true if the character is a symbol (!, ", ...).
    bool isSymbol(char c) {
        return (c >= '!' && c <= '/') || (c >= ':' && c <= '@') || (c >= '[' && c <= '`') || (c >= '{' && c <= '~');
    }

    /// Returns true if the character is a hexadecimal digit (0-9, A-F, a-f).
    bool isHexDigit(char c) {
        return isDigit(c) || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f');
    }

    /// Returns true if the string represents a C string.
    bool isCStr(IStr str) {
        return str.length != 0 && str[$ - 1] == '\0';
    }

    /// Converts the character to uppercase if it is a lowercase letter.
    char toUpper(char c) {
        return isLower(c) ? cast(char) (c - 32) : c;
    }

    /// Converts the character to lowercase if it is an uppercase letter.
    char toLower(char c) {
        return isUpper(c) ? cast(char) (c + 32) : c;
    }

    /// Converts all lowercase letters in the string to uppercase.
    void toUpper(Str str) {
        foreach (ref c; str) c = toUpper(c);
    }

    /// Converts all uppercase letters in the string to lowercase.
    void toLower(Str str) {
        foreach (ref c; str) c = toLower(c);
    }

    /// Returns the length of the C string.
    @trusted
    Sz cStrLength(ICStr str) {
        Sz result = 0;
        while (str[result]) result += 1;
        return result;
    }
}

/// Returns true if the two strings are equal, ignoring case.
bool equalsNoCase(IStr str, IStr other) {
    if (str.length != other.length) return false;
    foreach (i; 0 .. str.length) if (toUpper(str[i]) != toUpper(other[i])) return false;
    return true;
}

/// Returns true if the string is equal to the specified character, ignoring case.
bool equalsNoCase(IStr str, char other) {
    return equalsNoCase(str, charToStr(other));
}

/// Returns true if the string starts with the specified substring.
bool startsWith(IStr str, IStr start) {
    if (str.length < start.length) return false;
    return str[0 .. start.length] == start;
}

/// Returns true if the string starts with the specified character.
bool startsWith(IStr str, char start) {
    return startsWith(str, charToStr(start));
}

/// Returns true if the string ends with the specified substring.
bool endsWith(IStr str, IStr end) {
    if (str.length < end.length) return false;
    return str[$ - end.length .. $] == end;
}

/// Returns true if the string ends with the specified character.
bool endsWith(IStr str, char end) {
    return endsWith(str, charToStr(end));
}

/// Counts the number of occurrences of the specified substring in the string.
int countItem(IStr str, IStr item) {
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

/// Counts the number of occurrences of the specified character in the string.
int countItem(IStr str, char item) {
    return countItem(str, charToStr(item));
}

/// Finds the starting index of the first occurrence of the specified substring in the string, or returns -1 if not found.
int findStart(IStr str, IStr item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach (i; 0 .. str.length - item.length + 1) {
        if (str[i .. i + item.length] == item) return cast(int) i;
    }
    return -1;
}

/// Finds the starting index of the first occurrence of the specified character in the string, or returns -1 if not found.
int findStart(IStr str, char item) {
    return findStart(str, charToStr(item));
}

/// Finds the ending index of the first occurrence of the specified substring in the string, or returns -1 if not found.
int findEnd(IStr str, IStr item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach_reverse (i; 0 .. str.length - item.length + 1) {
        if (str[i .. i + item.length] == item) return cast(int) i;
    }
    return -1;
}

/// Finds the ending index of the first occurrence of the specified character in the string, or returns -1 if not found.
int findEnd(IStr str, char item) {
    return findEnd(str, charToStr(item));
}

/// Finds the first occurrence of the specified item in the slice, or returns -1 if not found.
int findItem(IStr[] items, IStr item) {
    foreach (i, it; items) if (it == item) return cast(int) i;
    return -1;
}

/// Finds the first occurrence of the specified start in the slice, or returns -1 if not found.
int findItemThatStartsWith(IStr[] items, IStr start) {
    foreach (i, it; items) if (it.startsWith(start)) return cast(int) i;
    return -1;
}

/// Finds the first occurrence of the specified end in the slice, or returns -1 if not found.
int findItemThatEndsWith(IStr[] items, IStr end) {
    foreach (i, it; items) if (it.endsWith(end)) return cast(int) i;
    return -1;
}

/// Removes whitespace characters from the beginning of the string.
IStr trimStart(IStr str) {
    IStr result = str;
    while (result.length > 0) {
        if (isSpace(result[0])) result = result[1 .. $];
        else break;
    }
    return result;
}

/// Removes whitespace characters from the end of the string.
IStr trimEnd(IStr str) {
    IStr result = str;
    while (result.length > 0) {
        if (isSpace(result[$ - 1])) result = result[0 .. $ - 1];
        else break;
    }
    return result;
}

/// Removes whitespace characters from both the beginning and end of the string.
IStr trim(IStr str) {
    return str.trimStart().trimEnd();
}

/// Removes the specified prefix from the beginning of the string if it exists.
IStr removePrefix(IStr str, IStr prefix) {
    if (str.startsWith(prefix)) return str[prefix.length .. $];
    else return str;
}

/// Removes the specified suffix from the end of the string if it exists.
IStr removeSuffix(IStr str, IStr suffix) {
    if (str.endsWith(suffix)) return str[0 .. $ - suffix.length];
    else return str;
}

/// Advances the string by the specified number of characters.
IStr advanceStr(IStr str, Sz amount) {
    if (str.length < amount) return str[$ .. $];
    else return str[amount .. $];
}

/// Copies characters from the source string to the destination string starting at the specified index.
@trusted
Fault copyChars(Str str, IStr source, Sz startIndex = 0) {
    if (str.length < source.length + startIndex) return Fault.overflow;
    jokaMemcpy(&str[startIndex], source.ptr, source.length);
    return Fault.none;
}

/// Copies characters from the source string to the destination string starting at the specified index and adjusts the length of the destination string.
Fault copyStr(ref Str str, IStr source, Sz startIndex = 0) {
    auto fault = copyChars(str, source, startIndex);
    if (fault) return fault;
    str = str[0 .. startIndex + source.length];
    return Fault.none;
}

/// Concatenates the strings.
/// Writes into the buffer and returns the result.
IStr concatIntoBuffer(Str buffer, IStr[] args...) {
    if (args.length == 0) return ".";
    auto result = buffer;
    auto length = 0;
    foreach (i, arg; args) {
        result.copyChars(arg, length);
        length += arg.length;
    }
    result = result[0 .. length];
    return result;
}

/// Concatenates the strings using a static buffer and returns the result.
IStr concat(IStr[] args...) {
    static char[defaultAsciiBufferSize][defaultAsciiBufferCount] buffers = void;
    static byte bufferIndex = 0;

    if (args.length == 0) return ".";
    bufferIndex = (bufferIndex + 1) % buffers.length;
    return concatIntoBuffer(buffers[bufferIndex][], args);
}

/// Splits the string using a static buffer and returns the result.
@trusted
IStr[] split(IStr str, IStr sep) {
    static IStr[defaultAsciiBufferSize][defaultAsciiBufferCount] buffers = void;
    static byte bufferIndex = 0;

    bufferIndex = (bufferIndex + 1) % buffers.length;
    auto length = 0;
    while (str.length != 0) {
        buffers[bufferIndex][length] = str.skipValue(sep);
        length += 1;
    }
    return buffers[bufferIndex][0 .. length];
}

/// Splits the string using a static buffer and returns the result.
IStr[] split(IStr str, char sep) {
    return split(str, charToStr(sep));
}

/// Returns the directory of the path, or "." if there is no directory.
IStr pathDirName(IStr path) {
    auto end = findEnd(path, pathSepStr);
    if (end == -1) return ".";
    else return path[0 .. end];
}

/// Returns the extension of the path.
IStr pathExtName(IStr path) {
    auto end = findEnd(path, ".");
    if (end == -1) return "";
    else return path[end .. $];
}

/// Returns the base name of the path.
IStr pathBaseName(IStr path) {
    auto end = findEnd(path, pathSepStr);
    if (end == -1) return path;
    else return path[end + 1 .. $];
}

/// Returns the base name of the path without the extension.
IStr pathBaseNameNoExt(IStr path) {
    return path.pathBaseName[0 .. $ - path.pathExtName.length];
}

/// Removes path separators from the beginning of the path.
IStr pathTrimStart(IStr path) {
    IStr result = path;
    while (result.length > 0) {
        if (result[0] == pathSep || result[0] == pathSepOther) result = result[1 .. $];
        else break;
    }
    return result;

}

/// Removes path separators from the end of the path.
IStr pathTrimEnd(IStr path) {
    IStr result = path;
    while (result.length > 0) {
        if (result[$ - 1] == pathSep || result[$ - 1] == pathSepOther) result = result[0 .. $ - 1];
        else break;
    }
    return result;
}

/// Removes path separators from the beginning and end of the path.
IStr pathTrim(IStr path) {
    return path.pathTrimStart().pathTrimEnd();
}

/// Formats the path to a standard form, normalizing separators.
IStr pathFormat(IStr path) {
    static char[defaultAsciiBufferSize][defaultAsciiBufferCount] buffers = void;
    static byte bufferIndex = 0;

    if (path.length == 0) return ".";
    bufferIndex = (bufferIndex + 1) % buffers.length;
    auto result = buffers[bufferIndex][];
    foreach (i, c; path) {
        if (c == pathSepOther) {
            result[i] = pathSep;
        } else {
            result[i] = c;
        }
    }
    result = result[0 .. path.length];
    return result;
}

/// Concatenates the paths, ensuring proper path separators between them.
IStr pathConcat(IStr[] args...) {
    static char[defaultAsciiBufferSize][defaultAsciiBufferCount] buffers = void;
    static byte bufferIndex = 0;

    if (args.length == 0) return ".";
    bufferIndex = (bufferIndex + 1) % buffers.length;
    auto result = buffers[bufferIndex][];
    auto length = 0;
    auto isFirst = true;
    foreach (i, arg; args) {
        if (arg.length == 0) continue;
        auto cleanArg = arg;
        if (cleanArg[0] == pathSep || cleanArg[0] == pathSepOther) {
            cleanArg = cleanArg.pathTrimStart();
            if (isFirst) {
                result[length] = pathSep;
                length += 1;
            }
        }
        cleanArg = cleanArg.pathTrimEnd();
        result.copyChars(cleanArg, length);
        length += cleanArg.length;
        if (i != args.length - 1) {
            result[length] = pathSep;
            length += 1;
        }
        isFirst = false;
    }
    if (length == 0) return ".";
    result = result[0 .. length];
    return result;
}

/// Splits the path using a static buffer and returns the result.
@trusted
IStr[] pathSplit(IStr str) {
    static IStr[defaultAsciiBufferSize][defaultAsciiBufferCount] buffers = void;
    static byte bufferIndex = 0;

    bufferIndex = (bufferIndex + 1) % buffers.length;
    auto length = 0;
    while (str.length != 0) {
        buffers[bufferIndex][length] = str.skipValue(pathSep);
        length += 1;
    }
    return buffers[bufferIndex][0 .. length];
}

/// Skips over the next occurrence of the specified separator in the string, returning the substring before the separator and updating the input string to start after the separator.
IStr skipValue(ref inout(char)[] str, IStr sep) {
    if (str.length < sep.length || sep.length == 0) {
        str = str[$ .. $];
        return "";
    }
    foreach (i; 0 .. str.length - sep.length) {
        if (str[i .. i + sep.length] == sep) {
            auto line = str[0 .. i];
            str = str[i + sep.length .. $];
            return line;
        }
    }
    auto line = str[0 .. $];
    if (str[$ - sep.length .. $] == sep) {
        line = str[0 .. $ - 1];
    }
    str = str[$ .. $];
    return line;
}

/// Skips over the next occurrence of the specified separator in the string, returning the substring before the separator and updating the input string to start after the separator.
IStr skipValue(ref inout(char)[] str, char sep) {
    return skipValue(str, charToStr(sep));
}

/// Skips over the next line in the string, returning the substring before the line break and updating the input string to start after the line break.
IStr skipLine(ref inout(char)[] str) {
    auto result = skipValue(str, '\n');
    if (result.length != 0 && result[$ - 1] == '\r') result = result[0 .. $ - 1];
    return result;
}

/// Converts the boolean value to its string representation.
IStr boolToStr(bool value, bool shortMode = false) {
    return value ? (shortMode ? "T" : "true") : (shortMode ? "F" : "false");
}

/// Converts the character to its string representation.
IStr charToStr(char value) {
    static char[1] buffer = void;

    auto result = buffer[];
    result[0] = value;
    result = result[0 .. 1];
    return result;
}

/// Converts the unsigned long value to its string representation.
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

/// Converts the signed long value to its string representation.
IStr signedToStr(long value) {
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

/// Converts the double value to its string representation with the specified precision.
IStr doubleToStr(double value, ulong precision = 2) {
    static char[64] buffer = void;

    if (!(value == value)) return "nan";
    if (precision == 0) return signedToStr(cast(long) value);

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
        if (value < 0.0) {
            cleanNumberStr = cleanNumberStr[1 .. $];
        }
        i -= cleanNumberStr.length;
        result.copyChars(cleanNumberStr, i);
        foreach (j; 0 .. rightDigitCount - cleanNumberStr.length) {
            i -= 1;
            result[i] = '0';
        }
        i -= 2;
        result.copyChars("0.", i);
        if (value < 0.0) {
            i -= 1;
            result[i] = '-';
        }
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
        result = result[0 .. cast(Sz) ($ - rightDigitCount + precision)];
    }
    return result[i .. $];
}

/// Converts the C string to a string.
@trusted
IStr cStrToStr(ICStr value) {
    return value[0 .. value.cStrLength];
}

/// Converts the enum value to its string representation.
IStr enumToStr(T)(T value) {
    switch (value) {
        static foreach (m; __traits(allMembers, T)) {
            mixin("case T.", m, ": return m;");
        }
        default: return "?";
    }
}

/// Converts the string to a bool.
Maybe!bool toBool(IStr str) {
    if (str == "false" || str == "F" || str == "f") {
        return Maybe!bool(false);
    } else if (str == "true" || str == "T" || str == "t") {
        return Maybe!bool(true);
    } else {
        return Maybe!bool(Fault.cantParse);
    }
}

/// Converts the string to a ulong.
Maybe!ulong toUnsigned(IStr str) {
    if (str.length == 0 || str.length >= 18) {
        return Maybe!ulong(Fault.overflow);
    } else {
        if (str.length == 1 && str[0] == '+') {
            return Maybe!ulong(Fault.cantParse);
        }
        ulong value = 0;
        ulong level = 1;
        foreach_reverse (i, c; str[(str[0] == '+' ? 1 : 0) .. $]) {
            if (isDigit(c)) {
                value += (c - '0') * level;
                level *= 10;
            } else {
                return Maybe!ulong(Fault.cantParse);
            }
        }
        return Maybe!ulong(value);
    }
}

/// Converts the character to a ulong.
Maybe!ulong toUnsigned(char c) {
    if (isDigit(c)) {
        return Maybe!ulong(c - '0');
    } else {
        return Maybe!ulong(Fault.cantParse);
    }
}

/// Converts the string to a long.
Maybe!long toSigned(IStr str) {
    if (str.length == 0 || str.length >= 18) {
        return Maybe!long(Fault.overflow);
    } else {
        auto temp = toUnsigned(str[(str[0] == '-' ? 1 : 0) .. $]);
        return Maybe!long(str[0] == '-' ? -temp.xx : temp.xx, temp.fault);
    }
}

/// Converts the character to a long.
Maybe!long toSigned(char c) {
    if (isDigit(c)) {
        return Maybe!long(c - '0');
    } else {
        return Maybe!long(Fault.cantParse);
    }
}

/// Converts the string to a double.
Maybe!double toDouble(IStr str) {
    if (str == "nan") return Maybe!double(double.nan);
    auto dotIndex = findStart(str, '.');
    if (dotIndex == -1) {
        auto temp = toSigned(str);
        return Maybe!double(temp.xx, temp.fault);
    } else {
        auto left = toSigned(str[0 .. dotIndex]);
        auto right = toSigned(str[dotIndex + 1 .. $]);
        if (left.isNone || right.isNone) {
            return Maybe!double(Fault.cantParse);
        } else if (str[dotIndex + 1] == '-' || str[dotIndex + 1] == '+') {
            return Maybe!double(Fault.cantParse);
        } else {
            auto sign = str[0] == '-' ? -1 : 1;
            auto level = 10;
            foreach (i; 1 .. str[dotIndex + 1 .. $].length) {
                level *= 10;
            }
            return Maybe!double(left.xx + sign * (right.xx / (cast(double) level)));
        }
    }
}

/// Converts the character to a double.
Maybe!double toDouble(char c) {
    if (isDigit(c)) {
        return Maybe!double(c - '0');
    } else {
        return Maybe!double(Fault.cantParse);
    }
}

/// Converts the string to an enum value.
Maybe!T toEnum(T)(IStr str) {
    switch (str) {
        static foreach (m; __traits(allMembers, T)) {
            mixin("case m: return Maybe!T(T.", m, ");");
        }
        default: return Maybe!T(Fault.cantParse);
    }
}

/// Converts the string to a C string.
@trusted
Maybe!ICStr toCStr(IStr str) {
    static char[defaultAsciiBufferSize] buffer = void;

    if (buffer.length < str.length) {
        return Maybe!ICStr(Fault.cantParse);
    } else {
        auto value = buffer[];
        value.copyChars(str);
        value[str.length] = '\0';
        return Maybe!ICStr(value.ptr);
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

    assert(isDigit('?') == false);
    assert(isDigit('0') == true);
    assert(isDigit('9') == true);
    assert(isUpper('h') == false);
    assert(isUpper('H') == true);
    assert(isLower('H') == false);
    assert(isLower('h') == true);
    assert(isSpace('?') == false);
    assert(isSpace('\r') == true);
    assert(isCStr("hello") == false);
    assert(isCStr("hello\0") == true);

    str = buffer[];
    str.copyStr("Hello");
    assert(str == "Hello");
    str.toUpper();
    assert(str == "HELLO");
    str.toLower();
    assert(str == "hello");

    str = buffer[];
    str.copyStr("Hello\0");
    assert(isCStr(str) == true);
    assert(str.ptr.cStrLength + 1 == str.length);

    str = buffer[];
    str.copyStr("Hello");
    assert(str.equalsNoCase("HELLO") == true);
    assert(str.startsWith("H") == true);
    assert(str.startsWith("Hell") == true);
    assert(str.startsWith("Hello") == true);
    assert(str.endsWith("o") == true);
    assert(str.endsWith("ello") == true);
    assert(str.endsWith("Hello") == true);

    str = buffer[];
    str.copyStr("hello hello world.");
    assert(str.countItem("hello") == 2);
    assert(str.findStart("HELLO") == -1);
    assert(str.findStart("hello") == 0);
    assert(str.findEnd("HELLO") == -1);
    assert(str.findEnd("hello") == 6);

    str = buffer[];
    str.copyStr(" Hello world. ");
    assert(str.trimStart() == "Hello world. ");
    assert(str.trimEnd() == " Hello world.");
    assert(str.trim() == "Hello world.");
    assert(str.removePrefix("Hello") == str);
    assert(str.trim().removePrefix("Hello") == " world.");
    assert(str.removeSuffix("world.") == str);
    assert(str.trim().removeSuffix("world.") == "Hello ");
    assert(str.advanceStr(0) == str);
    assert(str.advanceStr(1) == str[1 .. $]);
    assert(str.advanceStr(str.length) == "");
    assert(str.advanceStr(str.length + 1) == "");

    str = buffer[];
    str.copyStr("999: Nine Hours, Nine Persons, Nine Doors");
    assert(str.split(',').length == 3);
    assert(str.split(',')[0] == "999: Nine Hours");
    assert(str.split(',')[1] == " Nine Persons");
    assert(str.split(',')[2] == " Nine Doors");

    version (Windows) {
    } else {
        assert(pathConcat("one", "two") == "one/two");
        assert(pathConcat("one", "/two") == "one/two");
        assert(pathConcat("one", "/two/") == "one/two");
        assert(pathConcat("one/", "/two/") == "one/two");
        assert(pathConcat("/one/", "/two/") == "/one/two");
        assert(pathConcat("", "two/") == "two");
        assert(pathConcat("", "/two/") == "/two");
    }
    assert(pathConcat("one", "two").pathDirName() == "one");
    assert(pathConcat("one").pathDirName() == ".");
    assert(pathConcat("one.csv").pathExtName() == ".csv");
    assert(pathConcat("one").pathExtName() == "");
    assert(pathConcat("one", "two").pathBaseName() == "two");
    assert(pathConcat("one").pathBaseName() == "one");
    assert(pathFormat("one/two") == pathConcat("one", "two"));
    assert(pathFormat("one\\two") == pathConcat("one", "two"));

    str = buffer[];
    str.copyStr("one, two ,three,");
    assert(skipValue(str, ',') == "one");
    assert(skipValue(str, ',') == " two ");
    assert(skipValue(str, ',') == "three");
    assert(skipValue(str, ',') == "");
    assert(str.length == 0);
    assert(skipValue(str, "\r\n") == "");
    assert(skipLine(str) == "");

    assert(boolToStr(false) == "false");
    assert(boolToStr(true) == "true");
    assert(boolToStr(false, true) == "F");
    assert(boolToStr(true, true) == "T");
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
    assert(doubleToStr(-0.69, 0) == "0");
    assert(doubleToStr(-0.69, 1) == "-0.6");
    assert(doubleToStr(-0.69, 2) == "-0.69");
    assert(doubleToStr(-0.69, 3) == "-0.690");
    assert(doubleToStr(double.nan) == "nan");

    assert(cStrToStr("Hello\0") == "Hello");

    assert(enumToStr(TestEnum.one) == "one");
    assert(enumToStr(TestEnum.two) == "two");

    assert(toBool("false").isSome == true);
    assert(toBool("F").isSome == true);
    assert(toBool("f").isSome == true);
    assert(toBool("true").isSome == true);
    assert(toBool("T").isSome == true);
    assert(toBool("t").isSome == true);

    assert(toUnsigned("1_069").isSome == false);
    assert(toUnsigned("1_069").getOr() == 0);
    assert(toUnsigned("+1069").isSome == true);
    assert(toUnsigned("+1069").getOr() == 1069);
    assert(toUnsigned("1069").isSome == true);
    assert(toUnsigned("1069").getOr() == 1069);
    assert(toUnsigned('+').isSome == false);
    assert(toUnsigned('+').getOr() == 0);
    assert(toUnsigned('0').isSome == true);
    assert(toUnsigned('0').getOr() == 0);
    assert(toUnsigned('9').isSome == true);
    assert(toUnsigned('9').getOr() == 9);

    assert(toSigned("1_069").isSome == false);
    assert(toSigned("1_069").getOr() == 0);
    assert(toSigned("-1069").isSome == true);
    assert(toSigned("-1069").getOr() == -1069);
    assert(toSigned("+1069").isSome == true);
    assert(toSigned("+1069").getOr() == 1069);
    assert(toSigned("1069").isSome == true);
    assert(toSigned("1069").getOr() == 1069);
    assert(toSigned('+').isSome == false);
    assert(toSigned('+').getOr() == 0);
    assert(toSigned('0').isSome == true);
    assert(toSigned('0').getOr() == 0);
    assert(toSigned('9').isSome == true);
    assert(toSigned('9').getOr() == 9);

    assert(toDouble("1_069").isSome == false);
    assert(toDouble(".1069").isSome == false);
    assert(toDouble("1069.").isSome == false);
    assert(toDouble(".").isSome == false);
    assert(toDouble("-1069.-69").isSome == false);
    assert(toDouble("-1069.+69").isSome == false);
    assert(toDouble("-1069").isSome == true);
    assert(toDouble("-1069").getOr() == -1069);
    assert(toDouble("+1069").isSome == true);
    assert(toDouble("+1069").getOr() == 1069);
    assert(toDouble("1069").isSome == true);
    assert(toDouble("1069").getOr() == 1069);
    assert(toDouble("1069.0").isSome == true);
    assert(toDouble("1069.0").getOr() == 1069);
    assert(toDouble("-1069.0095").isSome == true);
    assert(toDouble("-1069.0095").getOr() == -1069.0095);
    assert(toDouble("+1069.0095").isSome == true);
    assert(toDouble("+1069.0095").getOr() == 1069.0095);
    assert(toDouble("1069.0095").isSome == true);
    assert(toDouble("1069.0095").getOr() == 1069.0095);
    assert(toDouble("-0.0095").isSome == true);
    assert(toDouble("-0.0095").getOr() == -0.0095);
    assert(toDouble("+0.0095").isSome == true);
    assert(toDouble("+0.0095").getOr() == 0.0095);
    assert(toDouble("0.0095").isSome == true);
    assert(toDouble("0.0095").getOr() == 0.0095);
    assert(toDouble('+').isSome == false);
    assert(toDouble('0').isSome == true);
    assert(toDouble('9').isSome == true);
    assert(toDouble('9').getOr() == 9);
    assert(!(toDouble("nan").getOr() == double.nan));

    assert(toEnum!TestEnum("?").isSome == false);
    assert(toEnum!TestEnum("?").getOr() == TestEnum.one);
    assert(toEnum!TestEnum("one").isSome == true);
    assert(toEnum!TestEnum("one").getOr() == TestEnum.one);
    assert(toEnum!TestEnum("two").isSome == true);
    assert(toEnum!TestEnum("two").getOr() == TestEnum.two);

    assert(toCStr("Hello").getOr().cStrLength == "Hello".length);
    assert(toCStr("Hello").getOr().cStrToStr() == "Hello");
    assert(fmt("Hello {}!", "world") == "Hello world!");
    assert(fmt("({}, {})", -69, -420) == "(-69, -420)");
}
