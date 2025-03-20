#!/bin/env -S dmd -run

// [Noby Script]

enum buildDirs = [
    "./src",
    "./android",
    "./android/build",
    "./android/sdk",
    "./android/ndk",
    "./assets",
    "./include",
    "./lib",
    "./lib/armeabi-v7a",
    "./lib/arm64-v8a",
    "./lib/x86",
    "./lib/x86_64",
];

enum sdkInstallNames = [
    "platform-tools",
    "platforms;android-29",
    "build-tools;29.0.3",
];

version (Windows) {
    enum sdkmanagerName = ".\\android\\sdk\\cmdline-tools\\bin\\sdkmanager.bat";
} else {
    enum sdkmanagerName = "./android/sdk/cmdline-tools/bin/sdkmanager";
}

int main(string[] args) {
    logw("Script is not done yet.");
    foreach (path; buildDirs) mkdir(path);
    if (readYesNo("Would you like to install sdk packages?", args.length > 1 ? args[1] : "?").isYes) {
        if (cmd(sdkmanagerName, "--sdk_root=./android/sdk", "--update")) {
            echo("X doesn't exist. Download it from Y.");
            return 1;
        }
        foreach (name; sdkInstallNames) {
            if (cmd(sdkmanagerName, "--sdk_root=./android/sdk", "--install", name)) return 1;
        }
    }
    return 0;
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
