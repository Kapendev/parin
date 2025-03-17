#!/bin/env -S dmd -i -run

/// A helper script that adds a header to every file in a directory.

import std.file;
import std.stdio;
import std.string;
import std.algorithm;
import std.parallelism;

enum fileExt = ".d";
enum header = "// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.41
// ---";

int main(string[] args) {
    if (args.length == 1) {
        writeln("Provide a directory containing `%s` files.".format(fileExt));
        return 0;
    }

    // Basic error checking.
    auto targetDir = args[1];
    if (!targetDir.exists) {
        writeln("Path `%s` does not exist.".format(targetDir));
        return 1;
    }
    auto tempIndex = header.countUntil("\n");
    if (tempIndex == -1) {
        writeln("Header separator does not exist.");
        writeln("The first line of the header is the header separator.");
        return 1;
    }
    auto headerSep = header[0 .. tempIndex];

    // Add the header to the files.
    foreach (file; dirEntries(targetDir, SpanMode.breadth).parallel) {
        if (!file.name.endsWith(fileExt)) continue;

        auto text = readText(file.name);
        if (text.startsWith(headerSep)) {
            foreach (i, c; text) {
                if (i <= headerSep.length) continue;
                if (i == text.length - headerSep.length) {
                    writeln("File `%s` does not have a second header separator.".format(file.name));
                    writeln("A header separator looks like this: `%s`".format(headerSep));
                    break;
                }
                if (text[i .. i + headerSep.length] == headerSep) {
                    std.file.write(file.name, header ~ text[i + headerSep.length .. $]);
                    break;
                }
            }
        } else {
            std.file.write(file.name, header ~ "\n\n" ~ text);
        }
    }
    return 0;
}
