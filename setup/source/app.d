#!/bin/env -S dmd -run

// [Noby Script]

enum assetsDir   = join(".", "assets");
enum webDir      = join(".", "web");
enum readmeFile  = join(".", "README.md");
enum gitFile     = join(".", ".gitignore");
enum dubFile     = join(".", "dub.json");
enum dubLockFile = join(".", "dub.selections.json");

enum readmeFileContent = `
# Title

This game was created with [Parin](https://github.com/Kapendev/parin).

To compile the game, run: ...
`[1 .. $];

enum gitFileContent = `
.dub
game
lib*
test*
*.wasm
*.so
*.dylib
*.dll
*.a
*.lib
*.exe
*.pdb
*.o
*.obj
*.lst
`[1 .. $];

enum appFileContent = `
import parin;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    drawDebugText("Hello world!", Vec2(8));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
`[1 .. $];

enum dubFileContent = `
{
    "name" : "game",
    "description" : "A game made with Parin.",
    "authors" : ["Name"],
    "copyright" : "Copyright © 2024, Name",
    "license" : "proprietary",
    "dependencies": {
        "joka": "*",
        "parin": "*"
    },
    "configurations": [
        {
            "name": "linux",
            "targetType": "executable",
            "platforms": ["linux"],
            "lflags": ["-L.", "-rpath=$$ORIGIN"],
            "libs": [
                "raylib",
                "GL",
                "m",
                "pthread",
                "dl",
                "rt",
                "X11"
            ]
        },
        {
            "name": "windows",
            "targetType": "executable",
            "platforms": ["windows"],
            "libs": [
                "raylib"
            ]
        },
        {
            "name": "osx",
            "targetType": "executable",
            "platforms": ["osx"],
            "lflags": ["-L.", "-rpath", "@executable_path/"],
            "libs": [
                "raylib"
            ]
        },
        {
            "name": "web",
            "targetType": "staticLibrary",
            "targetName": "webgame",
            "dflags": ["-mtriple=wasm32-unknown-unknown-wasm", "-checkaction=halt", "-betterC", "-i", "--release"]
        }
    ]
}
`[1 .. $];

/// Creates the basic project setup of a parin project inside the current folder.
void makeBasicSetup() {
    mkdir(assetsDir);
    mkdir(webDir);
    paste(join(assetsDir, ".gitkeep"), "");
    paste(join(webDir, ".gitkeep"), "");
    paste(readmeFile, readmeFileContent, true);
    paste(gitFile, gitFileContent, true);
}

/// The setup code for simple projects.
int runSimpSetup(string[] args, bool isFirstRun) {
    makeBasicSetup();
    return 0;
}

/// The setup code for dub projects.
int runDubSetup(string[] args, bool isFirstRun) {
    // Create basic stuff and clone the dub files.
    if (isFirstRun) {
        rm(gitFile);
    } else {
        clone(dubFile);
        clone(dubLockFile);
    }
    makeBasicSetup();
    // Find the main file and replace its content.
    auto appDir = join(".", "src");
    if (!appDir.isX) appDir = join(".", "source");
    auto appFile = join(appDir, "main.d");
    if (!appFile.isX) appFile = join(appDir, "app.d");
    paste(appFile, appFileContent, !isFirstRun);
    // Get a yes or no and download the raylib libraries.
    IStr arg = readYesNo("Would you like to download raylib?", args.length > 1 ? args[1] : "?");
    if (arg.isYes) {
        echo("Downloading...");
        auto hasDubLockFileNow = dubLockFile.isX;
        auto dub1 = cmd("dub", "add", "raylib-d", "--verror");
        auto dub2 = cmd("dub", "run", "raylib-d:install", "--verror", "--", "-q", "-u=no");
        // Remove the lock file from the install script.
        if (hasDubLockFileNow != dubLockFile.isX) rm(dubLockFile);
        // Remove the backup copies if something failed.
        if (dub1 || dub2) {
            restore(dubFile, true);
            restore(dubLockFile, true);
            return 1;
        }
    }
    // Clean stuff.
    if (isFirstRun) paste(dubFile, dubFileContent);
    restore(dubFile);
    restore(dubLockFile);
    return 0;
}

int main(string[] args) {
    auto result = 0;
    auto isFirstRun = !assetsDir.isX;
    auto isSimpProject = !dubFile.isX;
    if (isSimpProject) {
        result = runSimpSetup(args[1 .. $], isFirstRun);
    } else {
        result = runDubSetup(args[1 .. $], isFirstRun);
    }
    if (result == 0) echo("Done!");
    return result;
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
    IStr[] result;
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
