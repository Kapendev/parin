#!/bin/env -S dmd -run

// [Noby Script]

// I need to rewrite this one day, but eeehhhhh.
// The problem is that things are not consistent between diffrent modes.
// And the script is a little hard to read.
// Maybe make nob better too.

version (Windows) {
    enum emrunName = "emrun.bat";
    enum emccName = "emcc.bat";
} else {
    enum emrunName = "emrun";
    enum emccName = "emcc";
}

enum libFileData = cast(const(ubyte)[]) import("libraylib.a");
enum shellFileData = cast(const(char)[]) import("emscripten_shell.html");
enum assetsDir   = "assets";
enum webDir      = "web";
enum outputFile  = join(webDir, "index.html");
enum libFile     = join(webDir, "libraylib.a");
enum shellFile   = join(webDir, "emscripten_shell.html");
enum faviconFile = join(webDir, "favicon.ico");
enum dubFile     = "dub.json";
enum dubConfig   = "wasm";
enum dubLibName  = "game_wasm";
enum cflags      = [
    "-DPLATFORM_WEB",
    "-sEXPORTED_RUNTIME_METHODS=HEAPF32,requestFullscreen",
    "-sUSE_GLFW=3",
    "-sERROR_ON_UNDEFINED_SYMBOLS=0",
    "-sINITIAL_MEMORY=67108864",
    "-sALLOW_MEMORY_GROWTH=1",
];
enum cflagsExtraForRl = [
    "-sASYNCIFY",
];

int doDefaultProject(IStr sourceDir, bool isSimpProject) {
    // Compile the game.
    if (isSimpProject) {
        IStr[] args = ["ldc2", "-i", "-c", "-mtriple=wasm32-unknown-unknown-wasm", "-checkaction=halt", "-betterC"];
        if (isReleaseBuild) args ~= "--release";
        args ~= "-I=" ~ sourceDir;
        args ~= "-J=" ~ join(sourceDir, "parin");
        foreach (path; ls(sourceDir)) if (path.endsWith(".d")) { args ~= path; }
        if (cmd(args)) return 1;
    } else {
        IStr[] args = ["dub", "build", "--compiler", "ldc2", "--config", dubConfig];
        if (isReleaseBuild) args ~= ["--build", "release"];
        if (cmd(args)) return 1;
    }
    // Build the web app.
    IStr dubLibFile = "";
    IStr[] args = [emccName, "-o", outputFile, libFile];
    args ~= "--shell-file";
    args ~= shellFile;
    args ~= cflags;
    if (isRlProject) args ~= cflagsExtraForRl;
    // Check if the assets folder is empty because emcc will cry about it.
    if (assetsDir.isX) {
        foreach (path; ls(assetsDir, true)) {
            if (path.isF) {
                args ~= "--preload-file";
                args ~= assetsDir;
                break;
            }
        }
    }
    if (isSimpProject) {
        foreach (path; ls) if (path.endsWith(".o")) args ~= path;
    } else {
        foreach (path; ls) if (path.findStart(dubLibName) != -1) { dubLibFile = path; break; }
        args ~= dubLibFile;
    }
    auto result = cmd(args);
    clear(".", ".o");
    rm(dubLibFile);
    return result;
}

int doGcProject(IStr sourceDir, bool isSimpProject) {
    // Both DUB and no-DUB projects work the same because I don't care and you should vendor things anyway imo lololol.
    // The are some hacks here. One of them is that we need to have the package folders of parin.

    IStr parinPackagePath = "parin_package";
    if (!parinPackagePath.isX) parinPackagePath = join(webDir, "parin_package");
    if (!parinPackagePath.isX) cmd("git", "clone", "--depth", "1", "https://github.com/Kapendev/parin", parinPackagePath); // Could be removed, but I think most poeple don't care and just want to build something.
    auto parinPackageSourcePath = join(parinPackagePath, "source");

    auto webPackagePath = join(parinPackagePath, "packages", "web");
    auto webPackageSourcePath = join(webPackagePath, "source");

    auto hasParinInSource = false;
    auto hasJokaInSource = false;
    IStr[] files;
    foreach (path; ls(sourceDir, true)) {
        if (path.findEnd("_package") != -1) continue;
        if (path.findStart("parin") != -1 && path.endsWith(".d")) {
            hasParinInSource = true;
            files ~= path;
            continue;
        }
        if (path.endsWith(".d")) files ~= path;
    }
    if (!hasParinInSource) {
        foreach (path; ls(parinPackageSourcePath, true)) if (path.endsWith(".d")) files ~= path;
    }

    IStr[] args = ["opend"];
    if (isReleaseBuild) args ~= "publish";
    else args ~= "build";
    args ~= ["--target=emscripten", "-of" ~ outputFile];
    // The hack part.
    args ~= files;
    args ~= "-I=" ~ sourceDir;
    if (!isSimpProject) {
        args ~= "-I=" ~ parinPackageSourcePath;
    }
    // The good part.
    args ~= "-L=" ~ libFile;
    args ~= "-L=-L" ~ webPackageSourcePath;
    args ~= "-L=-sEXPORTED_RUNTIME_METHODS=HEAPF32,requestFullscreen";
    args ~= "-L=-DPLATFORM_WEB";
    args ~= "-L=-sUSE_GLFW=3";
    args ~= "-L=-sERROR_ON_UNDEFINED_SYMBOLS=0";
    args ~= "-L=-sINITIAL_MEMORY=67108864";
    args ~= "-L=-sALLOW_MEMORY_GROWTH=1";
    args ~= "-L=--shell-file";
    args ~= "-L=" ~ shellFile;
    // Check if the assets folder is empty because emcc will cry about it.
    if (assetsDir.isX) {
        foreach (path; ls(assetsDir, true)) {
            if (path.isF) {
                args ~= "-L=--preload-file";
                args ~= "-L=" ~ assetsDir;
                break;
            }
        }
    }
    if (isRlProject) {
        foreach (f; cflagsExtraForRl) args ~= "-L=" ~ f;
    }
    auto result = cmd(args);
    clear(".", ".o");
    return result;
}

auto isGcProject = false;
auto isRlProject = false;
auto isReleaseBuild = true;
auto isBuildOnly = false;
auto isTargetItch = false;

int main(string[] mainArgs) {
    import stdfile = std.file; // Hack import because nob.d is bad and should be rewritten in Rust.

    foreach (arg; mainArgs) {
        if (arg == "gc" || arg == "-gc" || arg == "--gc") isGcProject = true;
        if (arg == "rl" || arg == "-rl" || arg == "--rl") isRlProject = true;
        if (arg == "debug" || arg == "-debug" || arg == "--debug") isReleaseBuild = false;
        if (arg == "build" || arg == "-build" || arg == "--build") isBuildOnly = true;
        if (arg == "itch" || arg == "-itch" || arg == "--itch") isTargetItch = true;
    }
    auto isSimpProject = !dubFile.isX;
    auto sourceDir = "source";
    if (!sourceDir.isX) sourceDir = "src";
    if (!sourceDir.isX) sourceDir = ".";
    if (!webDir.isX) mkdir(webDir);
    if (!libFile.isX) stdfile.write(libFile, libFileData);
    if (!shellFile.isX) stdfile.write(shellFile, shellFileData);
    if (!faviconFile.isX) stdfile.write(faviconFile, ""); // Don't ask.
    clear(".", ".o");
    if (isGcProject) {
        if (doGcProject(sourceDir, isSimpProject)) return 1;
    } else {
        if (doDefaultProject(sourceDir, isSimpProject)) return 1;
    }
    clear(".", ".o");
    // For making the ZIP file that itch.io needs.
    if (isTargetItch) {
        auto target = join(webDir, "game_web.zip");
        if (target.isX) rm(target);
        version (Windows) {
            echo("Was too lazy to think how to zip on Windows. Open an issue on GitHub.");
        } else {
            if (cmd("zip", "--version")) {
                echo("Can't create archive without `zip` installed.");
            } else {
                IStr[] args = [
                    "zip",
                    "-j",
                    target,
                    join(webDir, "favicon.ico"),
                    join(webDir, "index.html"),
                    join(webDir, "index.js"),
                    join(webDir, "index.wasm"),
                ];
                if (join(webDir, "index.data").isX) args ~= join(webDir, "index.data");
                if (cmd(args)) return 1;
            }
        }
    }
    // Run the web app.
    return isBuildOnly ? 0 : cmd(emrunName, outputFile);
}

// [Noby Library]

Level minLogLevel = Level.info;
bool isCmdLineHidden = false;

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
        return spawnProcess(args).wait();
    } catch (Exception e) {
        return 1;
    }
}
