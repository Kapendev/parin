// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `configs` module includes build and configuration file helpers.
module parin.joka.configs;

import parin.joka.types;
import parin.joka.math;

enum defaultBuildInfoSep = ':';
enum defaultBuildInfoSepStr = ":";
enum defaultBuildInfoPath = "build_info.txt";

/// Returns the value associated with a key from a build info file.
/// The file uses the format: "key: value"
/// Returns an empty string if the key is not found.
/// Example: `buildInfo("version")` returns `"1.0.0"` for the line `version: 1.0.0`.
IStr buildInfo(IStr path = defaultBuildInfoPath)(IStr key) {
    return buildInfoFromContent!(cast(IStr) import(path), key);
}

/// Returns the structure associated with a build info file.
/// The file uses the format: "key: value"
/// Example: `buildInfoStruct!MyInfo()`
T buildInfoStruct(T, IStr path = defaultBuildInfoPath)() {
    auto result = T();
    parseBuildInfoFromContent(cast(IStr) import(path), result);
    return result;
}

/// Returns the value associated with a key from a build info line.
/// The line uses the format: "key: value"
/// Returns an empty string if the line is invalid.
/// Example: `buildInfoFromLine("version: 1.0.0")` returns `"1.0.0"`.
@safe nothrow @nogc
IStr buildInfoFromLine(IStr line, Sz keyLength = 0) {
    line = line.trim();
    if (line.length == 0 || line.startsWith("#")) return "";
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
    bool[T.tupleof.length] wasSet;
    for (auto line = content.skipLine().trim();; line = content.skipLine().trim()) {
        static foreach (i, m; T.tupleof) {
            if (line.length > m.stringof.length && line.startsWith(m.stringof) && (line[m.stringof.length] == defaultBuildInfoSep || line[m.stringof.length] == ' ')) {
                auto value = line.buildInfoFromLine(m.stringof.length);
                static if (is(immutable(typeof(T.tupleof[i])) == immutable(bool))) { // isBoolType
                    info.tupleof[i] = toBool(value).getOr();
                    wasSet[i] = true;
                } else static if (__traits(isUnsigned, typeof(T.tupleof[i]))) { // isUnsignedType
                    info.tupleof[i] = cast(typeof(T.tupleof[i])) toUnsigned(value).getOr();
                    wasSet[i] = true;
                } else static if (__traits(isIntegral, typeof(T.tupleof[i]))) { // isSignedType
                    info.tupleof[i] = cast(typeof(T.tupleof[i])) toSigned(value).getOr();
                    wasSet[i] = true;
                } else static if (__traits(isFloating, typeof(T.tupleof[i]))) { // isFloating
                    info.tupleof[i] = cast(typeof(T.tupleof[i])) toFloating(value).getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) : IStr)) { // isStrType
                    info.tupleof[i] = value;
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == float[2])) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i][0] = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i][1] = cast(float) value.skipSpace().toFloating().getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == Vec2)) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i].x = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i].y = cast(float) value.skipSpace().toFloating().getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == int[2])) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i][0] = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i][1] = cast(int) value.skipSpace().toSigned().getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == IVec2)) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i].x = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i].y = cast(int) value.skipSpace().toSigned().getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == float[3])) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i][0] = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i][1] = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i][2] = cast(float) value.skipSpace().toFloating().getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == Vec3)) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i].x = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i].y = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i].z = cast(float) value.skipSpace().toFloating().getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == int[3])) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i][0] = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i][1] = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i][2] = cast(int) value.skipSpace().toSigned().getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == IVec3)) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i].x = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i].y = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i].z = cast(int) value.skipSpace().toSigned().getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == float[4])) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i][0] = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i][1] = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i][2] = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i][3] = cast(float) value.skipSpace().toFloating().getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == Vec4)) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i].x = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i].y = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i].z = cast(float) value.skipSpace().toFloating().getOr();
                    info.tupleof[i].w = cast(float) value.skipSpace().toFloating().getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == int[4])) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i][0] = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i][1] = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i][2] = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i][3] = cast(int) value.skipSpace().toSigned().getOr();
                    wasSet[i] = true;
                } else static if (is(typeof(T.tupleof[i]) == IVec4)) {
                    value = value.trimStart("(").trimEnd(")").trim();
                    info.tupleof[i].x = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i].y = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i].z = cast(int) value.skipSpace().toSigned().getOr();
                    info.tupleof[i].w = cast(int) value.skipSpace().toSigned().getOr();
                    wasSet[i] = true;
                }
            }
        }
        if (content.length == 0) break;
    }

    static foreach (i, m; T.tupleof) {
        static if (isInUdaArgs!(requiredMember, T.tupleof[i])) {
            if (!wasSet[i]) assert(0, "Required member `" ~ m.stringof ~ "` not set.");
        }
    }
}

unittest {
    assert(buildInfoFromLine("") == "");
    assert(buildInfoFromLine("key") == "");
    assert(buildInfoFromLine("key:") == "");
    assert(buildInfoFromLine(":") == "");
    assert(buildInfoFromLine(":value") == "value");
    assert(buildInfoFromLine("key:value") == "value");
    assert(buildInfoFromLine("  key  :  value  ") == "value");

    auto dummyContent = "
        # A comment.
        name:    Cool Project
        version: 1.0.0

        good: true
        cool: t
        epic: T

        age:    69
        height: 420
        time:   1.0

        size:  (64 64)
        v3:    111 222 333
        v4:    1   2   3   4
        array: 12  34
    ";

    assert(buildInfoFromContent(dummyContent, "") == "");
    assert(buildInfoFromContent(dummyContent, "ver") == "");
    assert(buildInfoFromContent(dummyContent, "version") == "1.0.0");
    assert(buildInfoFromContent(dummyContent, "name") == "Cool Project");

    struct Info {
        // NOTE: Set all the fields for the test.
        @requiredMember:

        IStr name;

        bool good;
        bool cool;
        bool epic;

        int age;
        uint height;
        float time;

        IVec2 size;
        IVec3 v3;
        IVec4 v4;
        int[2] array;
    }

    auto info = Info();
    parseBuildInfoFromContent(dummyContent, info);
    assert(info.name == "Cool Project");
    assert(info.good == true);
    assert(info.cool == true);
    assert(info.epic == true);
    assert(info.age == 69);
    assert(info.height == 420);
    assert(info.time == 1.0);
    assert(info.size == IVec2(64, 64));
    assert(info.v3 == IVec3(111, 222, 333));
    assert(info.v4 == IVec4(1, 2, 3, 4));
    assert(info.array[0] == 12);
    assert(info.array[1] == 34);
}
