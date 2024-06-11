#!/bin/env rdmd

/// A helper script to assist with the web export process.
/// This script is designed with the idea that Popka is included inside your source folder, but it can work without Popka too.
/// Just copy-paste the web folder into your project and run the script from your project folder.

import std.string;
import std.format;
import std.path;
import std.stdio;
import std.file;
import std.process;


// The config.
// ----------
enum dflags = "-betterC -O --release";                             // The compiler flags passed to ldc. Local dependencies can be added here.
enum cflags = "";                                                  // The flags passed to emcc.
enum output = buildPath(".", "web", "index.html");                 // The output file that can be run with emrun.
enum isPopkaIncluded = true;                                       // Can be used to ignore the Popka library.

enum shellFile = buildPath(".", "web", "shell.html");              // The shell that will be passed to emcc. A default shell will be used if it doesn't exist.
enum libraryFile = buildPath(".", "web", "libraylib.a");           // The raylib WebAssembly library that will be passed to emcc.
enum sourceDir = buildPath(".", "source");                         // The source folder of the project.
enum assetsDir = buildPath(".", "assets");                         // The assets folder of the projecr. This parameter is optional.

enum popkaDir = buildPath(sourceDir, "popka");                     // The first Popka path.
enum popkaAltDir = buildPath(".", "web", "popka");                 // The second Popka path.
enum defaultShellFile = buildPath(".", ".__default_shell__.html"); // The default shell file that will be created if no shell file exists.

enum dubFile = buildPath(".", "dub.json");                         // DUB is not supported 100%, but it works if it is used with the setup script.
enum dubWebConfig = "web";                                         // The config that will be used to create a library file for the web.
enum dubLibName = "webgame";                                       // The library name that DUB will output with the web config.
// ----------


// This is used if a shell file does not exist.
enum defaultShellContent = `<!doctype html>
<html lang="EN-us">
<head>
    <title>game</title>
    <meta charset="utf-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta name="viewport" content="width=device-width">
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
`;


/// Check if path exists and print an error message if needed.
bool check(const(char)[] path, bool isLoud = true) {
    if (!exists(path)) {
        if (isLoud) writeln("Error: `", path, "` doesn't exist.");
        return true;
    }
    return false;
}

/// Run a command and print the output.
bool run(const(char)[] command, bool isLoud = true) {
    writeln("Command: ", command);
    auto shell = executeShell(command);
    if (isLoud && shell.output.length != 0) writeln("Output: ", shell.output);
    return shell.status != 0;
}

/// Delete object files in current folder.
void deleteObjectFiles() {
    foreach (item; dirEntries(".", SpanMode.shallow)) {
        if (item.name.length > 2 && item.name[$ - 2 .. $] == ".o") {
            std.file.remove(item.name);
        }
    }
}

int main(string[] args) {
    // Can pass extra flags to ldc if needed.
    writeln("Info: All arguments are passed to LDC. If arguments are passed, then the project is not treated as a DUB project.");
    char[] extraFlags = [];
    if (args.length > 1) {
        foreach (arg; args[1 .. $]) {
            extraFlags ~= arg;
        }
    }
    // If this is a DUB project, then we skip some parts of the script.
    auto isDUBProject = !check(dubFile, false) && extraFlags.length == 0;

    // Check the files that are needed for building.
    auto canUseDefaultShell = shellFile.check(false);
    if (libraryFile.check) return 1;
    if (!isDUBProject) {
        if (sourceDir.check) return 1;
    }

    char[] firstFiles = [];
    if (!isDUBProject) {
        // Get the first D files inside the source folder.
        foreach (item; dirEntries(sourceDir, SpanMode.shallow)) {
            if (item.name.length > 2 && item.name[$ - 2 .. $] == ".d") {
                firstFiles ~= item.name;
                firstFiles ~= " ";
            }
        }
    }

    // Delete old object files inside current folder.
    deleteObjectFiles();

    if (!isDUBProject) {
        // Build the source code.
        // Popka is needed for the web export. It will search inside the source and web folder.
        auto popkaParentDir = "";
        if (!popkaDir.check(false)) {
            popkaParentDir = buildPath(popkaDir, "..");
        } else if (!popkaAltDir.check(false)) {
            popkaParentDir = buildPath(popkaAltDir, "..");
        } else {
            writeln();
            writeln("Warning: Popka doesn't exist inside your project. Maybe add it inside your web or source folder if you see an error.");
            writeln("You can also include by passing `-Ipath_to_popka_parent_dir`.");
            writeln();
        }
        if (popkaParentDir.length == 0) {
            enum command = "ldc2 -c -mtriple=wasm32-unknown-unknown-wasm -checkaction=halt %s %s -I%s -i %s";
            if (run(command.format(extraFlags, dflags, sourceDir, firstFiles))) return 1;
        } else {
            enum command = "ldc2 -c -mtriple=wasm32-unknown-unknown-wasm -checkaction=halt %s %s -I%s -I%s -i %s";
            if (run(command.format(extraFlags, dflags, popkaParentDir, sourceDir, firstFiles))) return 1;
        }
    } else {
        enum command = "dub build --compiler ldc --config %s --build release";
        if (run(command.format(dubWebConfig))) return 1;
    }

    // Create a default shell file if needed.
    if (canUseDefaultShell) std.file.write(defaultShellFile, defaultShellContent);

    // Build the web app.
    bool isAssetsDirEmpty = true;
    if (assetsDir.check(false) == false) {
        foreach (item; dirEntries(assetsDir, SpanMode.breadth)) {
            if (item.name.isDir) continue;
            isAssetsDirEmpty = false;
            break;
        }
    }
    if (!isDUBProject) {
        if (isAssetsDirEmpty) {
            enum command = "emcc -o %s *.o %s -Wall -DPLATFORM_WEB %s -s USE_GLFW=3 -s ERROR_ON_UNDEFINED_SYMBOLS=0 --shell-file %s";
            if (run(command.format(output, cflags, libraryFile, canUseDefaultShell ? defaultShellFile : shellFile))) {
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
    } else {
        // Search for the library file that DUB created.
        auto dubLib = "";
        foreach (item; dirEntries(".", SpanMode.breadth)) {
            if (item.name.indexOf(dubLibName) != -1) {
                dubLib = item.name;
                break;
            }
        }
        if (dubLib.check) return 1;

        if (isAssetsDirEmpty) {
            enum command = "emcc -o %s %s %s -Wall -DPLATFORM_WEB %s -s USE_GLFW=3 -s ERROR_ON_UNDEFINED_SYMBOLS=0 --shell-file %s";
            if (run(command.format(output, dubLib, cflags, libraryFile, canUseDefaultShell ? defaultShellFile : shellFile))) {
                if (canUseDefaultShell) std.file.remove(defaultShellFile);
                std.file.remove(dubLib);
                return 1;
            }
        } else {
            enum command = "emcc -o %s %s %s -Wall -DPLATFORM_WEB %s -s USE_GLFW=3 -s ERROR_ON_UNDEFINED_SYMBOLS=0 --shell-file %s --preload-file %s";
            if (run(command.format(output, dubLib, cflags, libraryFile, canUseDefaultShell ? defaultShellFile : shellFile, assetsDir))) {
                if (canUseDefaultShell) std.file.remove(defaultShellFile);
                std.file.remove(dubLib);
                return 1;
            }
        }
        std.file.remove(dubLib);
    }

    // Delete default shell file if needed.
    if (canUseDefaultShell) std.file.remove(defaultShellFile);

    // Delete new object files inside current folder.
    deleteObjectFiles();

    // Run web app.
    if (run("emrun %s".format(output))) return 1;
    return 0;
}
