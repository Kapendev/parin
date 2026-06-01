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

unittest {
    assert("".buildInfoFromLine == "");
    assert("key".buildInfoFromLine == "");
    assert("key:".buildInfoFromLine == "");
    assert("key:value".buildInfoFromLine == "value");
    assert("  key  :  value  ".buildInfoFromLine == "value");

    auto dummyContent = "
        # A comment.
        version: 1.0.0
        name: Cool Project
    ";
    assert(dummyContent.buildInfoFromContent("") == "");
    assert(dummyContent.buildInfoFromContent("ver") == "");
    assert(dummyContent.buildInfoFromContent("version") == "1.0.0");
    assert(dummyContent.buildInfoFromContent("name") == "Cool Project");
}
