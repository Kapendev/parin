#!/bin/env -S dmd -run

int main(string[] args) {
    auto flags = Flags();
    foreach (arg; args[1 .. $]) {
        if (arg.length < 2) arg = "lol";
        if (arg[0] == '-') arg = arg[1 .. $];
        if (arg[0] == '-') arg = arg[1 .. $];
        auto hasInvalidFlag = true;
        static foreach (i, m; flags.tupleof) {
            if (m.stringof == arg) {
                flags.tupleof[i] = true;
                hasInvalidFlag = false;
            }
        }
        if (hasInvalidFlag) {
            writeln(helpText);
            return 0;
        }
    }

    auto sourcePath = "source";
    if (!sourcePath.exists) sourcePath = "src";
    if (!sourcePath.exists) sourcePath = ".";
    auto webPath = "web";
    if (!webPath.exists) webPath = sourcePath;
    auto assetsPath = "assets";
    if (!assetsPath.exists) assetsPath = sourcePath;
    auto parinImportPath = buildPath(sourcePath, "parin").exists ? sourcePath : "";
    if (!parinImportPath.exists) parinImportPath = getImportPathFromDub("parin");

    auto outputPath = buildPath(webPath, "index.html");
    auto shellPath = buildPath(webPath, "shell.html");
    if (!shellPath.exists) std.file.write(shellPath, shellText);

    auto libPath = buildPath(webPath, "libraylib.a");
    if (!libPath.exists) libPath = buildPath(webPath, "libraylib.web.a");
    if (!libPath.exists) std.file.write(libPath, import("libraylib.a"));

    auto mainFilePaths = dirEntries(sourcePath, SpanMode.shallow)
        .filter!(entry => entry.name.endsWith(".d"))
        .map!((entry => entry.name))
        .array;

    auto dflags = ["-i"];
    if (flags.betterc) dflags ~= ["-betterC", "--checkaction=halt"];
    dflags ~= flags.release ? ["-release"] : ["--d-debug", "-g"];

    auto command = ["ldc2", "--mtriple=wasm32-emscripten"] ~ dflags;
    command ~= mainFilePaths;
    command ~= libPath;
    if (sourcePath != parinImportPath) command ~= "-I=" ~ sourcePath;
    command ~= "-I=" ~ parinImportPath;
    command ~= "-J=" ~ buildPath(parinImportPath, "parin");
    command ~= "-of=" ~ outputPath;
    command ~= "--Xcc=-DPLATFORM_WEB";
    command ~= "--Xcc=-sUSE_GLFW=3";
    command ~= "--Xcc=-sEXPORTED_RUNTIME_METHODS=HEAPF32,requestFullscreen";
    command ~= "--Xcc=-sINITIAL_MEMORY=67108864";
    command ~= "--Xcc=-sALLOW_MEMORY_GROWTH=1";
    command ~= "--Xcc=--shell-file";
    command ~= "--Xcc=" ~ shellPath;
    // Check if the assets folder is empty because emcc will cry about it.
    if (assetsPath.exists) {
        foreach (entry; dirEntries(assetsPath, SpanMode.shallow)) {
            if (entry.name.exists) {
                command ~= "--Xcc=--preload-file";
                command ~= ("--Xcc=" ~ assetsPath);
                break;
            }
        }
    }
    if (run(command)) return 1;

    foreach (entry; dirEntries(".", SpanMode.shallow)) {
        if (entry.name.endsWith(".o") || entry.name.endsWith(".obj")) entry.remove();
    }
    foreach (entry; dirEntries(webPath, SpanMode.shallow)) {
        if (entry.name.endsWith(".o") || entry.name.endsWith(".obj")) entry.remove();
    }
    return (flags.build || !outputPath.exists) ? 0 : run([emrunName, outputPath]);
}

import std.stdio;
import std.file;
import std.process;
import std.array;
import std.algorithm;
import std.path;
import std.string;

enum helpText = "
Usage:
  ldc2 -run build_web.d [flags]
Flags:
  -betterc  Use the `-betterC` flag.
  -release  Use the `-release` flag.
  -build    Avoid emrun after a successful build.
"[1 .. $ - 1];

enum shellText = `
<!doctype html>
<html lang="EN-us">
<head>
    <meta charset="utf-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta name="viewport" content="width=device-width">
    <title>App</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🧶</text></svg>">
    <style>
        body { margin: 0px; overflow: hidden; }
        canvas.emscripten { border: 0px none; background-color: black; }

        loading {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            display: flex; /* Center content horizontally and vertically */
            justify-content: center;
            align-items: center;
            background-color: rgba(0, 0, 0, 0.5); /* Semi-transparent background */
            z-index: 100; /* Ensure loading indicator sits above content */
        }

        .spinner {
            border: 16px solid #c0c0c0; /* Big */
            border-top: 16px solid #343434; /* Small */
            border-radius: 50%;
            width: 120px;
            height: 120px;
            animation: spin 2s linear infinite;
        }

        .center {
            position: fixed;
            inset: 0px;
            width: 120px;
            height: 120px;
            margin: auto;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        canvas {
            display: none; /* Initially hide the canvas */
        }
    </style>
</head>
<body>
    <div id="loading">
        <div class="center">
            <div class="spinner"></div>
        </div>
    </div>
    <canvas class=emscripten id=canvas oncontextmenu=event.preventDefault() tabindex=-1></canvas>
    <p id="output" />
    <script>
        var Module = {
            canvas: (function() {
                var canvas = document.getElementById('canvas');
                return canvas;
            })(),
            preRun: [function() {
                // Show loading indicator
                document.getElementById("loading").style.display = "block";
            }],
            postRun: [function() {
                // Hide loading indicator and show canvas
                document.getElementById("loading").style.display = "none";
                document.getElementById("canvas").style.display = "block";
            }]
        };
    </script>
    {{{ SCRIPT }}}
</body>
</html>
`[1 .. $ - 1];

version (Windows) {
    enum emrunName = "emrun.bat";
    enum emccName = "emcc.bat";
} else {
    enum emrunName = "emrun";
    enum emccName = "emcc";
}

struct Flags {
    bool betterc; // Use the `-betterC` flag.
    bool release; // Use the `-release` flag.
    bool build;   // Avoid emrun after a successful build.
}

string getImportPathFromDub(string packageName, string packageSourceName = "source") {
    auto target = buildPath(packageName, packageSourceName);
    version (Windows) {
        target ~= `\"`;
    } else {
        target ~= `/"`;
    }

    auto content = execute(["dub", "describe"]).output;
    auto lineIndex = 0UL;
    foreach (i, c; content) {
        if (c != '\n') continue;
        auto line = content[lineIndex .. i].strip().strip(",");
        if (line.endsWith(target)) {
            return line[line.indexOf('"') + 1 .. $ - 1];
        }
        lineIndex = i + 1;
    }

    return "";
}

int run(string[] args...) {
    writeln("COMMAND: ", args);
    try {
        return spawnProcess(args).wait();
    } catch (Exception e) {
        return 1;
    }
}

// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin-template
// ---
