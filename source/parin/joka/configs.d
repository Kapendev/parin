// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `configs` module includes build and configuration file helpers.
module parin.joka.configs;

import parin.joka.types;

enum defaultBuildInfoSep = ':';
enum defaultBuildInfoSepStr = ":";

/// Returns the value associated with a key from a build info file.
/// The file uses the format: "key: value"
/// Returns an empty string if the key is not found.
/// Example: `buildInfo("version")` returns `"1.0.0"` for the line `version: 1.0.0`.
@safe nothrow @nogc
IStr buildInfo(IStr path = "build_info.txt")(IStr key) {
    return buildInfoFromContent!(cast(IStr) import(path), key);
}

/// Returns the value associated with a key from a build info line.
/// The line uses the format: "key: value"
/// Returns an empty string if the line is invalid.
/// Example: `buildInfoFromLine("version: 1.0.0")` returns `"1.0.0"`.
@safe nothrow @nogc
IStr buildInfoFromLine(IStr line, Sz keyLength = 0) {
    line = line.trim();
    if (line.length == 0) return "";
    auto keyEndIndex = keyLength ? (cast(int) keyLength) : line.findStart(defaultBuildInfoSepStr);
    if (keyEndIndex == -1) return "";
    return line[keyEndIndex .. $].trimStart().trimStart(defaultBuildInfoSepStr).trim();
}

/// Returns the value associated with a key from a build info string.
/// The lines of the string use the format: "key: value"
/// Returns an empty string if the key is not found.
/// Example: `buildInfoFromContent("version: 1.0.0\nname: DMD", "name")` returns `"DMD"`.
@safe nothrow @nogc
IStr buildInfoFromContent(IStr content, IStr key) {
    if (key.length == 0) return "";
    for (auto line = content.skipLine().trim();; line = content.skipLine().trim()) {
        if (line.length > key.length && line.startsWith(key) && (line[key.length] == defaultBuildInfoSep || line[key.length] == ' ')) {
            return line.buildInfoFromLine(key.length);
        }
        if (content.length == 0) break;
    }
    return "";
}

/// Parses a build info string into a struct by matching field names to keys.
/// The lines of the string use the format: "key: value"
/// Supports bool, integer, floating point, and string fields.
/// Example: `parseBuildInfoFromContent("age: 69\ncount: 42", info)` sets `info.age` and `info.count`.
void parseBuildInfoFromContent(T)(IStr content, ref T info) if (is(T == struct)) {
    for (auto line = content.skipLine().trim();; line = content.skipLine().trim()) {
        static foreach (i, m; T.tupleof) {
            if (line.length > m.stringof.length && line.startsWith(m.stringof) && (line[m.stringof.length] == defaultBuildInfoSep || line[m.stringof.length] == ' ')) {
                auto value = line.buildInfoFromLine(m.stringof.length);
                static if (is(immutable(typeof(T.tupleof[i])) == immutable(bool))) { // isBoolType
                    info.tupleof[i] = toBool(value).getOr();
                } else static if (__traits(isUnsigned, immutable(typeof(T.tupleof[i])))) { // isUnsignedType
                    info.tupleof[i] = cast(typeof(T.tupleof[i])) toUnsigned(value).getOr();
                } else static if (__traits(isIntegral, immutable(typeof(T.tupleof[i])))) { // isSignedType
                    info.tupleof[i] = cast(typeof(T.tupleof[i])) toSigned(value).getOr();
                } else static if (__traits(isFloating, immutable(typeof(T.tupleof[i])))) { // isFloating
                    info.tupleof[i] = cast(typeof(T.tupleof[i])) toFloating(value).getOr();
                } else static if (is(typeof(T.tupleof[i]) : IStr)) { // isStrType
                    info.tupleof[i] = value;
                }
            }
        }
        if (content.length == 0) break;
    }
}

unittest {
    assert("".buildInfoFromLine == "");
    assert("key".buildInfoFromLine == "");
    assert("key:".buildInfoFromLine == "");
    assert(":".buildInfoFromLine == "");
    assert(":value".buildInfoFromLine == "value");
    assert("key:value".buildInfoFromLine == "value");
    assert("  key  :  value  ".buildInfoFromLine == "value");

    auto dummyContent = "
        # A comment.
        version: 1.0.0
        name: Cool Project
        run: true
        age: 69
        age2: 69
        time: 1
        time2: 1
    ";
    assert(dummyContent.buildInfoFromContent("") == "");
    assert(dummyContent.buildInfoFromContent("ver") == "");
    assert(dummyContent.buildInfoFromContent("version") == "1.0.0");
    assert(dummyContent.buildInfoFromContent("name") == "Cool Project");

    struct Info {
        IStr name;
        bool run;
        int age;
        uint age2;
        float time;
        double time2;
    }

    auto info = Info();
    dummyContent.parseBuildInfoFromContent(info);
    assert(info.name == "Cool Project");
    assert(info.run == true);
    assert(info.age == 69);
    assert(info.age2 == 69);
    assert(info.time == 1);
    assert(info.time2 == 1);
}
