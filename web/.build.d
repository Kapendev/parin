#!/bin/env rdmd

/// A helper script to assist with the web export process.
/// This script is designed with the idea that Popka is included inside your source folder, but it can work without Popka too.
/// Just copy-paste the web folder into your project and run the script from your project folder.

module build;

import std.format;
import std.path;
import std.stdio;
import std.file;
import std.process;


// The config.
// ----------
enum lflags = "";
enum dflags = "";
enum output = buildPath(".", "web", "index.html");
enum isPopkaIncluded = true;

enum shellFile = buildPath(".", "web", "shell.html");
enum libraryFile = buildPath(".", "web", "libraylib.a");
enum sourceDir = buildPath(".", "source");
enum assetsDir = buildPath(".", "assets");

enum popkaDir = buildPath(sourceDir, "popka");
enum popkaAltDir = buildPath(sourceDir, "popka", "source", "popka");
// ----------


/// Check if path exists and print an error message if needed.
bool check(const(char)[] path, bool isLoud = true) {
    if (!exists(path)) {
        if (isLoud) writeln("Error: '", path, "' doesn't exist.");
        return true;
    }
    return false;
}

bool run(const(char)[] command) {
    writeln(command);
    auto shell = executeShell(command);
    if (shell.output.length != 0) writeln(shell.output);
    return shell.status != 0;
}

int main(string[] args) {
    // Check args.
    auto mode = args.length > 1 ? args[1] : "build";
    if (mode != "build" && mode != "run") {
        writeln("Error: '", mode, "' isn't a mode.");
        return -1;
    }

    // Check the files that are needed for building.
    if (shellFile.check) return 1;
    if (libraryFile.check) return 1;
    if (sourceDir.check) return 1;
    if (assetsDir.check) return 1;

    // Get the first D files files inside the source folder.
    char[] firstFiles = [];
    foreach (item; dirEntries(sourceDir, SpanMode.shallow)) {
        if (item.name[$ - 2 .. $] == ".d") {
            firstFiles ~= item.name;
            firstFiles ~= " ";
        }
    }

    // Build the source code.
    if (isPopkaIncluded) {
        auto popkaParentDir = popkaAltDir;
        if (popkaAltDir.check(false)) {
            if (popkaDir.check(false)) {
                writeln("Error: Popka doesn't exist.");
                return 1;
            }
            popkaParentDir = popkaDir;
        }
        popkaParentDir = buildPath(popkaParentDir, "..");
        enum command = "ldc2 -c -betterC -mtriple=wasm32-unknown-unknown-wasm -checkaction=halt %s %s -I%s -I%s -i %s";
        if (run(command.format(lflags, dflags, popkaParentDir, sourceDir, firstFiles))) return 1;
    } else {
        enum command = "ldc2 -c -betterC -mtriple=wasm32-unknown-unknown-wasm -checkaction=halt %s %s -I%s -i %s";
        if (run(command.format(lflags, dflags, sourceDir, firstFiles))) return 1;
    }

    // Build the web app.
    bool isAssetsDirEmpty = true;
    foreach (item; dirEntries(assetsDir, SpanMode.shallow)) {
        isAssetsDirEmpty = false;
        break;
    }
    if (isAssetsDirEmpty) {
        enum command = "emcc -o %s *.o -Wall -DPLATFORM_WEB %s -s USE_GLFW=3 -s ERROR_ON_UNDEFINED_SYMBOLS=0 --shell-file %s";
        if (run(command.format(output, libraryFile, shellFile))) return 1;
    } else {
        enum command = "emcc -o %s *.o -Wall -DPLATFORM_WEB %s -s USE_GLFW=3 -s ERROR_ON_UNDEFINED_SYMBOLS=0 --shell-file %s --preload-file %s";
        if (run(command.format(output, libraryFile, shellFile, assetsDir))) return 1;
    }

    // Run web app.
    if (mode == "run") {
        enum command = "emrun %s";
        if (run(command.format(output))) return 1;
    }
    return 0;
}
