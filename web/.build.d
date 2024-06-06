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
enum dflags = "-O --release";
enum cflags = "-Os";
enum output = buildPath(".", "web", "index.html");
enum isPopkaIncluded = true;

enum shellFile = buildPath(".", "web", "shell.html");
enum libraryFile = buildPath(".", "web", "libraylib.a");
enum sourceDir = buildPath(".", "source");
enum assetsDir = buildPath(".", "assets");

enum popkaDir = buildPath(sourceDir, "popka");
enum popkaAltDir = buildPath(popkaDir, "source", "popka");
enum defaultShellFile = buildPath(".", ".__defaultShell__.html");
// ----------


// This is used if a shell file does not exist.
enum defaultShellContent = `
    <!doctype html>
    <html lang="EN-us">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <title>game</title>
        <meta name="title" content="game">
        <meta name="viewport" content="width=device-width">
        <style>
            body { margin: 0px; }
            canvas.emscripten { border: 0px none; background-color: black; }
        </style>
        <script type='text/javascript' src="https://cdn.jsdelivr.net/gh/eligrey/FileSaver.js/dist/FileSaver.min.js"> </script>
        <script type='text/javascript'>
            function saveFileFromMEMFSToDisk(memoryFSname, localFSname) // This can be called by C/C++ code
            {
                var isSafari = false; // Not supported, navigator.userAgent access is being restricted
                var data = FS.readFile(memoryFSname);
                var blob;
                if (isSafari) blob = new Blob([data.buffer], { type: "application/octet-stream" });
                else blob = new Blob([data.buffer], { type: "application/octet-binary" });
                saveAs(blob, localFSname);
            }
        </script>
    </head>
    <body>
        <canvas class=emscripten id=canvas oncontextmenu=event.preventDefault() tabindex=-1></canvas>
        <p id="output" />
        <script>
            var Module = {
                print: (function() {
                    var element = document.getElementById('output');
                    if (element) element.value = ''; // clear browser cache
                    return function(text) {
                        if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
                        console.log(text);
                        if (element) {
                            element.value += text + "\n";
                            element.scrollTop = element.scrollHeight; // focus on bottom
                        }
                    };
                })(),
                canvas: (function() {
                    var canvas = document.getElementById('canvas');
                    return canvas;
                })()
            };
        </script>
        {{{ SCRIPT }}}
    </body>
    </html>
`;


/// Check if path exists and print an error message if needed.
bool check(const(char)[] path, bool isLoud = true) {
    if (!exists(path)) {
        if (isLoud) writeln("Error: '", path, "' doesn't exist.");
        return true;
    }
    return false;
}

/// Run a command and print the output.
bool run(const(char)[] command, bool isLoud = true) {
    writeln(command);
    auto shell = executeShell(command);
    // Ignore Python bug.
    if (shell.output.length != 0) {
        enum pythonBug = "not list";
        if (shell.output.length > pythonBug.length && shell.output[$ - pythonBug.length - 1 .. $ - 1] == pythonBug) {
            return false;
        }
        if (isLoud) writeln(shell.output);
    }
    return shell.status != 0;
}

int main(string[] args) {
    // Check args.
    auto mode = args.length > 1 ? args[1] : "build";
    if (mode != "build" && mode != "run") {
        writeln("Error: '", mode, "' isn't a mode.\nModes: build, run");
        return -1;
    }

    // Check the files that are needed for building.
    auto canUseDefaultShell = shellFile.check(false);
    if (libraryFile.check) return 1;
    if (sourceDir.check) return 1;
    if (assetsDir.check) return 1;

    // Get the first D files files inside the source folder.
    char[] firstFiles = [];
    foreach (item; dirEntries(sourceDir, SpanMode.shallow)) {
        if (item.name.length > 2 && item.name[$ - 2 .. $] == ".d") {
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

    // Create a default shell file if needed.
    if (canUseDefaultShell) std.file.write(defaultShellFile, defaultShellContent);

    // Build the web app.
    bool isAssetsDirEmpty = true;
    foreach (item; dirEntries(assetsDir, SpanMode.shallow)) {
        isAssetsDirEmpty = false;
        break;
    }
    if (isAssetsDirEmpty) {
        enum command = "emcc -o %s *.o -Os -Wall -DPLATFORM_WEB %s -s USE_GLFW=3 -s ERROR_ON_UNDEFINED_SYMBOLS=0 --shell-file %s";
        if (run(command.format(output, libraryFile, canUseDefaultShell ? defaultShellFile : shellFile))) {
            if (canUseDefaultShell) std.file.remove(defaultShellFile);
            return 1;
        }
    } else {
        enum command = "emcc -o %s *.o %s -Wall -DPLATFORM_WEB %s -s USE_GLFW=3 -s ERROR_ON_UNDEFINED_SYMBOLS=0 --shell-file %s --preload-file %s";
        if (run(command.format(output, cflags, libraryFile, canUseDefaultShell ? defaultShellFile : shellFile, assetsDir))) {
            if (canUseDefaultShell) std.file.remove(defaultShellFile);
            return 1;
        }
    }

    // Delete default shell file if needed.
    if (canUseDefaultShell) std.file.remove(defaultShellFile);

    // Delete object files.
    foreach (item; dirEntries(".", SpanMode.shallow)) {
        if (item.name.length > 2 && item.name[$ - 2 .. $] == ".o") {
            std.file.remove(item.name);
        }
    }

    // Run web app.
    if (mode == "run") {
        enum command = "emrun %s";
        if (run(command.format(output))) return 1;
    }
    return 0;
}
