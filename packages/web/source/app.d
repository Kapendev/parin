#!/bin/env -S dmd -run

// [Noby Script]

version (Windows) {
    enum emrunName = "emrun.bat";
    enum emccName = "emcc.bat";
} else {
    enum emrunName = "emrun";
    enum emccName = "emcc";
}

enum sourceDir   = join(".", "source");
enum assetsDir   = join(".", "assets");
enum outputFile  = join(".", "web", "index.html");
enum shellFile   = join(".", ".__default_shell__.html");
enum libFile     = join(".", "web", "libraylib.a");
enum dubFile     = join(".", "dub.json");
enum dubConfig   = "web";
enum dubLibName  = "webgame";
enum dflags      = ["-i", "-betterC", "--release"];

enum shellFileContent = `
<!doctype html>
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
`[1 .. $];

int main() {
    auto isSimpProject = !dubFile.isX;
    // Check if the files that are needed exist.
    if (!sourceDir.isX) { echo("Folder `", sourceDir, "` doesn't exist. Create one."); return 1; }
    if (!assetsDir.isX) { echo("Folder `", assetsDir, "` doesn't exist. Create one."); return 1; }
    if (!libFile.isX)   { echo("File `"  , libFile  , "` doesn't exist. Download it from raylib releases."); return 1; }
    clear(".", ".o");
    // Compile the game.
    if (isSimpProject) {
        IStr[] args = ["ldc2", "-c", "-checkaction=halt", "-mtriple=wasm32-unknown-unknown-wasm", "I" ~ sourceDir];
        args ~= dflags;
        foreach (path; ls(sourceDir)) if (path.endsWith(".d")) args ~= path;
        if (cmd(args)) return 1;
    } else {
        if (cmd("dub", "build", "--compiler", "ldc2", "--build", "release", "--config", dubConfig)) return 1;
    }
    // Check if the assets folder is empty because emcc will cry about it.
    paste(shellFile, shellFileContent);
    bool isAssetsDirEmpty = true;
    foreach (path; ls(assetsDir)) {
        if (path.isF) { isAssetsDirEmpty = false; break; }
    }
    // Build the web app.
    IStr dubLibFile = "";
    foreach (path; ls) {
        if (path.findStart(dubLibName) != -1) { dubLibFile = path; break; }
    }
    IStr[] args = [emccName, "-o", outputFile, libFile, "-DPLATFORM_WEB", "-s", "USE_GLFW=3", "-s", "ERROR_ON_UNDEFINED_SYMBOLS=0", "--shell-file", shellFile];
    if (!isAssetsDirEmpty) { args ~= "--preload-file"; args ~= assetsDir; }
    if (isSimpProject) {
        foreach (path; ls) if (path.endsWith(".o")) args ~= path;
    } else {
        args ~= dubLibFile;
    }
    if (cmd(args)) {
        rm(shellFile);
        rm(dubLibFile);
        clear(".", ".o");
        return 1;
    }
    rm(shellFile);
    rm(dubLibFile);
    clear(".", ".o");
    // Run the web app.
    return cmd(emrunName, outputFile);
}

// [Noby Library]

enum cloneExt = "._cl";

Level minLogLevel = Level.info;

alias Sz      = size_t;         /// The result of sizeof, ...
alias Str     = char[];         /// A string slice of chars.
alias IStr    = const(char)[];  /// A string slice of constant chars.

enum Level : ubyte {
    none,
    info,
    warning,
    error,
}

bool isX(IStr path) {
    import std.file;
    return path.exists;
}

bool isF(IStr path) {
    import std.file;
    return path.exists;
}

bool isD(IStr path) {
    import std.file;
    return path.isDir;
}

void echo(A...)(A args) {
    import std.stdio;
    writeln(args);
}

void echon(A...)(A args) {
    import std.stdio;
    write(args);
}

void cp(IStr source, IStr target) {
    import std.file;
    copy(source, target);
}

void rm(IStr path) {
    import std.file;
    if (path.isX) remove(path);
}

void mkdir(IStr path, bool isRecursive = false) {
    import std.file;
    if (!path.isX) {
        if (isRecursive) mkdirRecurse(path);
        else std.file.mkdir(path);
    }
}

void rmdir(IStr path, bool isRecursive = false) {
    import std.file;
    if (!path.isX) {
        if (isRecursive) rmdirRecurse(path);
        else std.file.rmdir(path);
    }
}

IStr cat(IStr path) {
    import std.file;
    return path.isX ? readText(path) : "";
}

IStr[] ls(IStr path = ".", bool isRecursive = false) {
    import std.file;
    IStr[] result = [];
    foreach (dir; dirEntries(cast(string) path, isRecursive ? SpanMode.breadth : SpanMode.shallow)) {
        result ~= dir.name;
    }
    return result;
}

IStr basename(IStr path) {
    import std.path;
    return baseName(path);
}

IStr realpath(IStr path) {
    import std.path;
    return absolutePath(cast(string) path);
}

IStr read() {
    import std.stdio;
    import std.string;
    return readln().strip();
}

IStr readYesNo(IStr text, IStr firstValue = "?") {
    auto result = firstValue;
    while (true) {
        if (result.length == 0) result = "Y";
        if (result.isYesOrNo) break;
        echon(text, " [Y/n] ");
        result = read();
    }
    return result;
}


IStr join(IStr[] args...) {
    import std.path;
    return buildPath(args);
}

bool isYes(IStr arg) {
    return (arg.length == 1 && (arg[0] == 'Y' || arg[0] == 'y'));
}

bool isNo(IStr arg) {
    return (arg.length == 1 && (arg[0] == 'N' || arg[0] == 'n'));
}

bool isYesOrNo(IStr arg) {
    return arg.isYes || arg.isNo;
}

bool startsWith(IStr str, IStr start) {
    if (str.length < start.length) return false;
    return str[0 .. start.length] == start;
}

bool endsWith(IStr str, IStr end) {
    if (str.length < end.length) return false;
    return str[$ - end.length .. $] == end;
}

int findStart(IStr str, IStr item) {
    import std.string;
    return cast(int) str.indexOf(item);
}

void clear(IStr path = ".", IStr ext = "") {
    foreach (file; ls(path)) {
        if (file.endsWith(ext)) rm(file);
    }
}

void paste(IStr path, IStr content, bool isOnlyMaking = false) {
    import std.file;
    if (isOnlyMaking) {
        if (!path.isX) write(path, content);
    } else {
        write(path, content);
    }
}

void clone(IStr path) {
    if (path.isX) paste(path ~ cloneExt, cat(path));
}

void restore(IStr path, bool isOnlyRemoving = false) {
    auto clonePath = path ~ cloneExt;
    if (clonePath.isX) {
        if (!isOnlyRemoving) paste(path, cat(clonePath));
        rm(clonePath);
    }
}

void log(Level level, IStr text) {
    if (minLogLevel == 0 || minLogLevel > level) return;
    with (Level) final switch (level) {
        case info:    echo("[INFO] ", text); break;
        case warning: echo("[WARNING] ", text); break;
        case error:   echo("[ERROR] ", text); break;
        case none:    break;
    }
}

void logf(A...)(Level level, IStr text, A args) {
    import std.format;
    log(level, text.format(args));
}

int cmd(IStr[] args...) {
    import std.stdio;
    import std.process;
    writeln("[CMD] ", args);
    try {
        return spawnProcess(args).wait();
    } catch (Exception e) {
        return 1;
    }
}
