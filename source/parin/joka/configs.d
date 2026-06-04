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
    parseBuildInfo(cast(IStr) import(path), result);
    return result;
}

/// Returns true if a build info line starts with the given key.
/// The line uses the format: "key: value"
/// Example: `buildInfoLineHasKey("version: 1.0.0", "version")` returns `true`.
@safe nothrow @nogc
bool buildInfoLineHasKey(IStr line, IStr key) {
    return line.length > key.length && line.startsWith(key) && (line[key.length] == defaultBuildInfoSep || line[key.length] == ' ');
}

/// Returns the section name from a build info header line like `[window]`, or an empty string if the line is not a header.
/// Example: `buildInfoLineHeader("[window]")` returns `"window"`.
@safe nothrow @nogc
IStr buildInfoLineHeader(IStr line) {
    line = line.trim();
    if (line.startsWith("[") && line.endsWith("]")) return line[1 .. $ - 1].trim();
    return "";
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
    foreach (line; content.byLine(true)) {
        if (line.buildInfoLineHasKey(key)) return line.buildInfoFromLine(key.length);
    }
    return "";
}

/// Parses a build info value string into a field.
/// Returns false on success and true if the field type is not supported.
/// Example: `parseBuildInfoValue("69", info.age)` sets `info.age` to `69`.
bool parseBuildInfoValue(T)(IStr value, ref T field) {
    static if (is(immutable(T) == immutable(bool))) { // isBoolType
        field = toBool(value).getOr();
        return false;
    } else static if (__traits(isUnsigned, T)) { // isUnsignedType
        field = cast(T) toUnsigned(value).getOr();
        return false;
    } else static if (__traits(isIntegral, T)) { // isSignedType
        field = cast(T) toSigned(value).getOr();
        return false;
    } else static if (__traits(isFloating, T)) { // isFloating
        field = cast(T) toFloating(value).getOr();
        return false;
    } else static if (is(T : IStr)) { // isStrType
        field = value;
        return false;
    } else static if (is(T == Vec2)) {
        value = value.trimStart("(").trimEnd(")").trim();
        field.x = cast(float) value.skipSpace().toFloating().getOr();
        field.y = cast(float) value.skipSpace().toFloating().getOr();
        return false;
    } else static if (is(T == IVec2)) {
        value = value.trimStart("(").trimEnd(")").trim();
        field.x = cast(int) value.skipSpace().toSigned().getOr();
        field.y = cast(int) value.skipSpace().toSigned().getOr();
        return false;
    } else static if (is(T == Vec3)) {
        value = value.trimStart("(").trimEnd(")").trim();
        field.x = cast(float) value.skipSpace().toFloating().getOr();
        field.y = cast(float) value.skipSpace().toFloating().getOr();
        field.z = cast(float) value.skipSpace().toFloating().getOr();
        return false;
    } else static if (is(T == IVec3)) {
        value = value.trimStart("(").trimEnd(")").trim();
        field.x = cast(int) value.skipSpace().toSigned().getOr();
        field.y = cast(int) value.skipSpace().toSigned().getOr();
        field.z = cast(int) value.skipSpace().toSigned().getOr();
        return false;
    } else static if (is(T == Vec4)) {
        value = value.trimStart("(").trimEnd(")").trim();
        field.x = cast(float) value.skipSpace().toFloating().getOr();
        field.y = cast(float) value.skipSpace().toFloating().getOr();
        field.z = cast(float) value.skipSpace().toFloating().getOr();
        field.w = cast(float) value.skipSpace().toFloating().getOr();
        return false;
    } else static if (is(T == IVec4)) {
        value = value.trimStart("(").trimEnd(")").trim();
        field.x = cast(int) value.skipSpace().toSigned().getOr();
        field.y = cast(int) value.skipSpace().toSigned().getOr();
        field.z = cast(int) value.skipSpace().toSigned().getOr();
        field.w = cast(int) value.skipSpace().toSigned().getOr();
        return false;
    } else static if (is(T == Rect)) {
        value = value.trimStart("(").trimEnd(")").trim();
        field.position.x = cast(float) value.skipSpace().toFloating().getOr();
        field.position.y = cast(float) value.skipSpace().toFloating().getOr();
        field.size.x = cast(float) value.skipSpace().toFloating().getOr();
        field.size.y = cast(float) value.skipSpace().toFloating().getOr();
        return false;
    } else static if (is(T == IRect)) {
        value = value.trimStart("(").trimEnd(")").trim();
        field.position.x = cast(int) value.skipSpace().toSigned().getOr();
        field.position.y = cast(int) value.skipSpace().toSigned().getOr();
        field.size.x = cast(int) value.skipSpace().toSigned().getOr();
        field.size.y = cast(int) value.skipSpace().toSigned().getOr();
        return false;
    } else static if (is(T == SRect)) {
        value = value.trimStart("(").trimEnd(")").trim();
        field.position.x = cast(int) value.skipSpace().toSigned().getOr();
        field.position.y = cast(int) value.skipSpace().toSigned().getOr();
        field.size.x = cast(short) value.skipSpace().toSigned().getOr();
        field.size.y = cast(short) value.skipSpace().toSigned().getOr();
        return false;
    } else static if (is(T == Line)) {
        value = value.trimStart("(").trimEnd(")").trim();
        field.a.x = cast(float) value.skipSpace().toFloating().getOr();
        field.a.y = cast(float) value.skipSpace().toFloating().getOr();
        field.b.x = cast(float) value.skipSpace().toFloating().getOr();
        field.b.y = cast(float) value.skipSpace().toFloating().getOr();
        return false;
    } else static if (is(T == Circ)) {
        value = value.trimStart("(").trimEnd(")").trim();
        field.position.x = cast(float) value.skipSpace().toFloating().getOr();
        field.position.y = cast(float) value.skipSpace().toFloating().getOr();
        field.radius = cast(float) value.skipSpace().toFloating().getOr();
        return false;
    } else static if (is(T : const(SliceT)[], SliceT)) {
        value = value.trimStart("(").trimEnd(")").trim();
        foreach (ref item; field) {
            static if (__traits(isUnsigned, SliceT)) {
                item = cast(SliceT) value.skipSpace().toUnsigned().getOr();
            } else static if (__traits(isIntegral, SliceT)) {
                item = cast(SliceT) value.skipSpace().toSigned().getOr();
            } else static if (__traits(isFloating, SliceT)) {
                item = cast(SliceT) value.skipSpace().toFloating().getOr();
            }
        }
        return false;
    } else {
        return true;
    }
}

/// Parses a build info string into a struct by matching field names to keys.
/// The lines of the string use the format: "key: value"
/// Supports bool, integer, floating point, and string fields.
/// Example: `parseBuildInfo("age: 69\ncount: 42", info)` sets `info.age` and `info.count`.
@trusted
void parseBuildInfo(T)(IStr content, ref T info) if (is(T == struct)) {
    bool[T.tupleof.length] wasSet = void;
    foreach (line; content.byLine(true)) {
        static foreach (i, m; T.tupleof) {
            if (line.buildInfoLineHasKey(m.stringof)) wasSet[i] = !parseBuildInfoValue(line.buildInfoFromLine(m.stringof.length), info.tupleof[i]);
        }
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

        smallArray: (1 2 3 4 5 6 7 8)

        area: 32 64 128 128
        circ: 1 1 1
        line: 1 1 1 1
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

        byte[8] smallArray;

        IRect area;
        Circ circ;
        Line line;
    }

    auto info = Info();
    parseBuildInfo(dummyContent, info);
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
    foreach (i, item; info.smallArray) assert(item == i + 1);

    assert(info.area == IRect(32, 64, 128, 128));
    assert(info.circ == Circ(1, 1, 1));
    assert(info.line == Line(1, 1, 1, 1));
}
