#!/bin/env rdmd

/// A helper script that automates the project setup.

import std;

enum assetsDir = buildPath(".", "assets");
enum webDir = buildPath(".", "web");

enum appFile = buildPath(".", "source", "app.d");
enum dubFile = buildPath(".", "dub.json");
enum dubCopyFile = buildPath(".", ".__dub_copy__.json");
enum dubLockFile = buildPath(".", "dub.selections.json");
enum dubLockCopyFile = buildPath(".", ".__dub_selections_copy__.json");
enum gitignoreFile = buildPath(".", ".gitignore");

enum appFileContent = `import parin;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    drawDebugText("Hello world!", Vec2(8));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
`;

enum dubFileContent = `{
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
            "dflags": ["-i"],
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
            "dflags": ["-i"],
            "libs": [
                "raylib"
            ]
        },
        {
            "name": "osx",
            "targetType": "executable",
            "platforms": ["osx"],
            "dflags": ["-i"],
            "lflags": ["-L.", "-rpath", "@executable_path/"],
            "libs": [
                "raylib.500"
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
`;

enum gitignoreFileContent = `.dub
game
web
lib*
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
`;

int main(string[] args) {
    auto isDubProject = exists(dubFile);
    auto isFirstRun = !exists(assetsDir);
    auto canDownloadLibs = true;

    // Sometimes I remove the app.d file and this makes a new one lol.
    // Also raylib-d:install does not like it when you don't have one.
    if (isDubProject) {
        if (!exists(appFile)) std.file.write(appFile, appFileContent);
        if (!isFirstRun) {
            std.file.write(dubCopyFile, std.file.readText(dubFile));
            if (exists(dubLockFile)) std.file.write(dubLockCopyFile, std.file.readText(dubLockFile));
        }
    }

    // User input stuff.
    if (isDubProject) {
        auto arg = (args.length == 2) ? args[1] : "";
        if (arg.length == 0) {
            write("Would you like to download the raylib libraries? [Y/n] ");
            arg = readln().strip();
        }
        canDownloadLibs = arg != "N" && arg != "n";
    }

    // Use the raylib-d script to download the raylib library files.
    if (isDubProject && canDownloadLibs) {
        writeln("Say \"yes\" to all prompts.\n");
        auto dub1 = spawnProcess(["dub", "add", "raylib-d"]).wait();
        if (dub1 != 0) {
            if (!isFirstRun) {
                std.file.remove(dubCopyFile);
                if (exists(dubLockCopyFile)) std.file.remove(dubLockCopyFile);
            }
            return dub1;
        }
        auto dub2 = spawnProcess(["dub", "run", "raylib-d:install"]).wait();
        if (dub2 != 0) {
            if (!isFirstRun) {
                std.file.remove(dubCopyFile);
                if (exists(dubLockCopyFile)) std.file.remove(dubLockCopyFile);
            }
            return dub2;
        }
    }

    // Remove old files.
    if (isDubProject) {
        if (isFirstRun && exists(appFile)) std.file.remove(appFile);
        if (exists(dubFile)) std.file.remove(dubFile);
        if (exists(dubLockFile)) std.file.remove(dubLockFile);
    }
    if (isFirstRun && exists(gitignoreFile)) std.file.remove(gitignoreFile);

    // Create new files.
    if (isDubProject) {
        if (isFirstRun) std.file.write(appFile, appFileContent);
        if (exists(dubCopyFile)) {
            std.file.write(dubFile, std.file.readText(dubCopyFile));
            std.file.remove(dubCopyFile);
            if (exists(dubLockCopyFile)) std.file.write(dubLockFile, std.file.readText(dubLockCopyFile));
            if (exists(dubLockCopyFile)) std.file.remove(dubLockCopyFile);
        } else {
            std.file.write(dubFile, dubFileContent);
        }
    }
    if (isFirstRun) std.file.write(gitignoreFile, gitignoreFileContent);

    // Create folders.
    if (!exists(assetsDir)) std.file.mkdir(assetsDir);
    if (!exists(webDir)) std.file.mkdir(webDir);

    writeln("\nHappy hacking!");
    return 0;
}
