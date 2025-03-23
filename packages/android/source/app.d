#!/bin/env -S dmd -run

// [Noby Script]

version (Windows) {
    enum makeName = "mingw32-make";
    enum sdkmanagerName = ".\\android\\sdk\\cmdline-tools\\bin\\sdkmanager.bat";
} else {
    enum makeName = "make";
    enum sdkmanagerName = "./android/sdk/cmdline-tools/bin/sdkmanager";
}

enum buildDirs = [
    "./src",
    "./android",
    "./android/build",
    "./android/sdk",
    "./android/ndk",
    "./assets",
    "./include",
    "./lib",
    "./lib/arm64-v8a",
];

enum sdkInstallNames = [
    "platform-tools",
    "platforms;android-29",
    "build-tools;29.0.3",
];

enum javaContent = `
package com.raylib.game;
public class NativeLoader extends android.app.NativeActivity {
    static {
        System.loadLibrary("main");
    }
}
`[1 .. $];

// TODO: Look at it.
enum manifestContent = `
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
        package="com.raylib.game"
        android:versionCode="1" android:versionName="1.0" >
    <uses-sdk android:minSdkVersion="23" android:targetSdkVersion="34"/>
    <uses-feature android:glEsVersion="0x00020000" android:required="true"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <application android:allowBackup="false" android:label="Game" android:icon="@drawable/icon">
        <activity android:name="com.raylib.game.NativeLoader"
            android:theme="@android:style/Theme.NoTitleBar.Fullscreen"
            android:configChanges="orientation|keyboardHidden|screenSize"
            android:exported="true"
            android:screenOrientation="landscape" android:launchMode="singleTask"
            android:clearTaskOnLaunch="true">
            <meta-data android:name="android.app.lib_name" android:value="main"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
`[1 .. $];

int main(string[] args) {
    logw("Script is not done!");
    logi("Base on: https://github.com/raysan5/raylib/wiki/Working-for-Android");
    return 1;
    // Downloading sdk stuff.
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
    // Build raylib.
    // Just testing how things should look. Will not work, so don't run this.
    cmd(makeName, "-C", "path", "PLATFORM=PLATFORM_ANDROID", "ANDROID_NDK=../../android/ndk", "ANDROID_ARCH=arm64", "ANDROID_API_VERSION=34");
    mv("libraylib.a", "../../lib/arm64-v8a");
    cmd(makeName, "-C", "path", "clean");
    // Icon stuff.
    cp("raylib/logo/raylib_36x36.png", "assets/icon_ldpi.png");
    cp("raylib/logo/raylib_48x48.png", "assets/icon_mdpi.png");
    cp("raylib/logo/raylib_72x72.png", "assets/icon_hdpi.png");
    cp("raylib/logo/raylib_96x96.png", "assets/icon_xhdpi.png");
    // Ket stuff.
    // ...
    // Java stuff.
    paste("android/build/src/com/raylib/game/NativeLoader.java", javaContent, true);
    paste("android/build/AndroidManifest.xml", manifestContent, true);
    // Build project.
    // WTF are those flags that are just there to make things harder to read. -Werror=format-security????
    // Also, it has a icon part again for some reason. WE ALREADY HAD AN ICON STEP IN THIS WIKI PAGE, WHY NOT JUST PUT IT THERE??
    // Will probably have to use the arm64 target with ldc.
    return 0;
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

void mv(IStr source, IStr target) {
    cp(source, target);
    rm(source);
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
