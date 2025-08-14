#!/bin/env -S dmd -run

// [Noby Script]

enum assetsDir   = "assets";
enum webDir      = "web";
enum readmeFile  = "README.md";
enum gitFile     = ".gitignore";
enum dubFile     = "dub.json";
enum dubLockFile = "dub.selections.json";

enum readmeFileContent = "
# Super Cool Title

This game was created with [Parin](https://github.com/Kapendev/parin).
To compile and play, run:

```cmd
dub run
```
"[1 .. $];

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

// Called once when the game starts.
void ready() {
    lockResolution(320, 180);
}

// Called every frame while the game is running.
// If true is returned, then the game will stop running.
bool update(float dt) {
    drawDebugText("Hello world!", Vec2(8));
    return false;
}

// Called once when the game ends.
void finish() {}

// Creates a main function that calls the given functions.
mixin runGame!(ready, update, finish);
`[1 .. $];

enum dubFileContent = `
{
    "name" : "game",
    "description" : "A game made with Parin.",
    "authors" : ["Name"],
    "copyright" : "Copyright © 2025, Name",
    "license" : "proprietary",
    "dependencies": {
        "joka": "*",
        "parin": "*"
    },
    "configurations": [
        {
            "name": "default",
            "targetType": "executable"
        },
        {
            "name": "wasm",
            "targetType": "library",
            "targetName": "game_wasm",
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
    auto appDir = "src";
    if (!appDir.isX) appDir = "source";
    auto appFile = join(appDir, "main.d");
    if (!appFile.isX) appFile = join(appDir, "app.d");
    paste(appFile, appFileContent, !isFirstRun);
    // Clean stuff.
    if (isFirstRun) paste(dubFile, dubFileContent);
    restore(dubFile);
    restore(dubLockFile);
    return 0;
}

int main(string[] args) {
    isCmdLineHidden = true;
    isCmdOutputHidden = true;
    auto result = 0;
    auto isFirstRun = !assetsDir.isX;
    auto isSimpProject = !dubFile.isX;
    if (isSimpProject) {
        result = runSimpSetup(args, isFirstRun);
    } else {
        result = runDubSetup(args, isFirstRun);
    }
    if (result == 0) echo("Done!");
    return result;
}

// [Noby Library]

Level minLogLevel = Level.info;
bool isCmdLineHidden = false;
bool isCmdOutputHidden = false;

enum cloneExt = "._cl";

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
    return path.isX && path.isFile;
}

bool isD(IStr path) {
    import std.file;
    return path.isX && path.isDir;
}

void echo(A...)(A args) {
    import std.stdio;
    writeln(args);
}

void echon(A...)(A args) {
    import std.stdio;
    write(args);
}

void echof(A...)(IStr text, A args) {
    import std.stdio;
    writefln(text, args);
}

void echofn(A...)(IStr text, A args) {
    import std.stdio;
    writef(text, args);
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
    if (path.isX) {
        if (isRecursive) rmdirRecurse(path);
        else std.file.rmdir(path);
    }
}

IStr pwd() {
    import std.file;
    return getcwd();
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
    return readln().trim();
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

IStr fmt(A...)(IStr text, A args...) {
    import std.format;
    return format(text, args);
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
    if (str.length < item.length || item.length == 0) return -1;
    foreach (i; 0 .. str.length - item.length + 1) {
        if (str[i .. i + item.length] == item) return cast(int) i;
    }
    return -1;
}

int findEnd(IStr str, IStr item) {
    if (str.length < item.length || item.length == 0) return -1;
    foreach_reverse (i; 0 .. str.length - item.length + 1) {
        if (str[i .. i + item.length] == item) return cast(int) i;
    }
    return -1;
}

IStr trimStart(IStr str) {
    IStr result = str;
    while (result.length > 0) {
        auto isSpace = (result[0] >= '\t' && result[0] <= '\r') || (result[0] == ' ');
        if (isSpace) result = result[1 .. $];
        else break;
    }
    return result;
}

IStr trimEnd(IStr str) {
    IStr result = str;
    while (result.length > 0) {
        auto isSpace = (result[$ - 1] >= '\t' && result[$ - 1] <= '\r') || (result[$ - 1] == ' ');
        if (isSpace) result = result[0 .. $ - 1];
        else break;
    }
    return result;
}

IStr trim(IStr str) {
    return str.trimStart().trimEnd();
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
    if (path.isX) cp(path, path ~ cloneExt);
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

void logi(IStr text) {
    log(Level.info, text);
}

void logw(IStr text) {
    log(Level.warning, text);
}

void loge(IStr text) {
    log(Level.error, text);
}

void logf(A...)(Level level, IStr text, A args) {
    log(level, text.fmt(args));
}

int cmd(IStr[] args...) {
    import std.process;
    if (!isCmdLineHidden) echo("[CMD] ", args);
    try {
        if (isCmdOutputHidden) {
            auto result = execute(args);
            if (result.status == 0) return 0;
            echo(result.output);
            return result.status;
        } else {
            return spawnProcess(args).wait();
        }
    } catch (Exception e) {
        return 1;
    }
}
