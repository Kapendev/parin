#!/bin/env -S dmd -run

/// A helper script to assist with the web export process.

import std.path;
import std.stdio;
import std.file;
import std.process;
import std.string;

// TODO: Clean it! Well... Not right now, but do it.

enum dflags = ["-betterC", "-i", "--release"];              // The compiler flags passed to ldc. Local dependencies can be added here.
enum output = buildPath(".", "web", "index.html");          // The output file that can be run with emrun.

enum sourceDir = buildPath(".", "source");                  // The source folder of the project.
enum assetsDir = buildPath(".", "assets");                  // The assets folder of the projecr.

enum dubFile = buildPath(".", "dub.json");                  // The dub that was hopefully created by the setup script.
enum libraryFile = buildPath(".", "web", "libraylib.a");    // The raylib WebAssembly library that will be passed to emcc.
enum shellFile = buildPath(".", ".__default_shell__.html"); // The default shell file that will be created and used.

enum dubWebConfig = "web";                                  // The dub config that will be used to create a library file for the web.
enum dubLibName = "webgame";                                // The library name that dub will output with the web config.

enum shellFileContent = `<!doctype html>
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

/// Get the object files in the current folder.
string[] objectFiles() {
    string[] result;
    foreach (item; dirEntries(".", SpanMode.shallow)) {
        if (item.name.endsWith(".o")) {
            result ~= item.name;
        }
    }
    return result;
}

/// Delete object files in the current folder.
void deleteObjectFiles() {
    foreach (file; objectFiles) {
        std.file.remove(file);
    }
}

int main(string[] args) {
    // Pass extra arguments to ldc if needed.
    writeln("If arguments are passed, then the project is not treated as a DUB project.");
    string[] extraArgs = [];
    foreach (arg; args[1 .. $]) {
        extraArgs ~= arg;
    }

    auto isDubProject = exists(dubFile) && extraArgs.length == 0;

    // Check if the files that are needed for building exist.
    if (!exists(sourceDir)) {
        writeln("Folder `", sourceDir, "` does not exist. Create one.");
        return 1;
    }
    if (!exists(libraryFile)) {
        writeln("File `", libraryFile, "` does not exist. Download it from the raylib repository and place it in the specified folder.");
        return 1;
    }

    // Delete old object files inside current folder.
    deleteObjectFiles();

    if (isDubProject) {
        // Create a library.
        auto dub = spawnProcess(["dub", "build", "--compiler", "ldc2", "--config", dubWebConfig, "--build", "release"]).wait();
        if (dub != 0) return dub;
    } else {
        // Find the first D files and create the object files.
        string[] firstFiles = [];
        foreach (item; dirEntries(sourceDir, SpanMode.shallow)) {
            if (!item.name.endsWith(".d")) continue;
            firstFiles ~= item.name;
        }
        // TODO: Needs testing.
        auto ldc2 = spawnProcess(["ldc2", "-c", "-mtriple=wasm32-unknown-unknown-wasm", "-checkaction=halt"] ~ [("I" ~ sourceDir)] ~ extraArgs ~ dflags ~ firstFiles).wait();
        if (ldc2 != 0) return ldc2;
    }

    // Create the shell file that is needed by emcc.
    std.file.write(shellFile, shellFileContent);

    // Check if the assets folder is empty because emcc will cry about it.
    bool isAssetsDirEmpty = true;
    if (exists(assetsDir)) {
        foreach (item; dirEntries(assetsDir, SpanMode.breadth)) {
            if (item.name.isDir) continue;
            isAssetsDirEmpty = false;
            break;
        }
    }

    // Build the web app.
    if (isDubProject) {
        // Search for the library file that was created.
        string dubLibraryFile = [];
        foreach (item; dirEntries(".", SpanMode.breadth)) {
            if (item.name.indexOf(dubLibName) != -1) {
                dubLibraryFile = item.name;
                break;
            }
        }
        // Compile project.
        if (isAssetsDirEmpty) {
            auto emcc = spawnProcess(["emcc", "-o", output, dubLibraryFile, "-DPLATFORM_WEB", libraryFile, "-s", "USE_GLFW=3", "-s", "ERROR_ON_UNDEFINED_SYMBOLS=0", "--shell-file", shellFile]).wait();
            if (emcc != 0) {
                // Cleanup.
                std.file.remove(dubLibraryFile);
                std.file.remove(shellFile);
                deleteObjectFiles();
                return emcc;
            }
        } else {
            auto emcc = spawnProcess(["emcc", "-o", output, dubLibraryFile, "-DPLATFORM_WEB", libraryFile, "-s", "USE_GLFW=3", "-s", "ERROR_ON_UNDEFINED_SYMBOLS=0", "--shell-file", shellFile, "--preload-file", assetsDir]).wait();
            if (emcc != 0) {
                // Cleanup.
                std.file.remove(dubLibraryFile);
                std.file.remove(shellFile);
                deleteObjectFiles();
                return emcc;
            }
        }
        // Cleanup.
        std.file.remove(dubLibraryFile);
    } else {
        // Compile project.
        if (isAssetsDirEmpty) {
            auto emcc = spawnProcess(["emcc", "-o", output] ~ objectFiles ~ ["-DPLATFORM_WEB", libraryFile, "-s", "USE_GLFW=3", "-s", "ERROR_ON_UNDEFINED_SYMBOLS=0", "--shell-file", shellFile]).wait();
            if (emcc != 0) {
                // Cleanup.
                std.file.remove(shellFile);
                deleteObjectFiles();
                return emcc;
            }
        } else {
            auto emcc = spawnProcess(["emcc", "-o", output] ~ objectFiles ~ ["-DPLATFORM_WEB", libraryFile, "-s", "USE_GLFW=3", "-s", "ERROR_ON_UNDEFINED_SYMBOLS=0", "--shell-file", shellFile, "--preload-file", assetsDir]).wait();
            if (emcc != 0) {
                // Cleanup.
                std.file.remove(shellFile);
                deleteObjectFiles();
                return emcc;
            }
        }
    }
    // Cleanup.
    std.file.remove(shellFile);
    deleteObjectFiles();

    // Run the web app.
    return spawnProcess(["emrun", output]).wait();
}
