#!/bin/env -S dmd -run

/// A helper script that automates the project setup.

import std.file;
import std.path;
import std.stdio;
import std.string;
import std.process;

enum assetsDir       = buildPath(".", "assets");
enum webDir          = buildPath(".", "web");
enum readmeFile      = buildPath(".", "README.md");
enum gitignoreFile   = buildPath(".", ".gitignore");
enum dubFile         = buildPath(".", "dub.json");
enum dubLockFile     = buildPath(".", "dub.selections.json");

enum readmeFileContent = "# Game Title

This game was created using [Parin](https://github.com/Kapendev/parin).

To compile the game, run:

```sh
command arg1 arg2 ...
```
";

enum gitignoreFileContent = `.dub
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
`;

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
`;

/// Creates the assets and web folders inside the current folder.
void makeFolders() {
    if (!exists(assetsDir)) std.file.mkdir(assetsDir);
    if (!exists(webDir)) std.file.mkdir(webDir);
    std.file.write(buildPath(assetsDir, ".gitkeep"), "");
    std.file.write(buildPath(webDir, ".gitkeep"), "");
}

/// Creates the basic project setup of a parin project inside the current folder.
void makeBasicSetup() {
    makeFolders();
    if (!exists(readmeFile)) std.file.write(readmeFile, readmeFileContent);
    if (!exists(gitignoreFile)) std.file.write(gitignoreFile, gitignoreFileContent);
}

/// The setup code for simple standalone projects.
int runSimpSetup(string[] args, bool isFirstRun) {
    makeBasicSetup();
    return 0;
}

/// The setup code for dub projects.
int runDubSetup(string[] args, bool isFirstRun) {
    // Create the backup copies.
    auto dubCopyFile = buildPath(".", "._dub_copy");
    auto dubLockCopyFile = buildPath(".", "._dub_lock_copy");
    if (exists(dubFile)) std.file.write(dubCopyFile, std.file.readText(dubFile));
    if (exists(dubLockFile)) std.file.write(dubLockCopyFile, std.file.readText(dubLockFile));
    // Create the basic files and folders.
    // NOTE: An empty dub project has a gitignore file and we don't want that file.
    if (isFirstRun && exists(gitignoreFile)) std.file.remove(gitignoreFile);
    makeBasicSetup();

    // Find the app file.
    auto appDir = buildPath(".", "src");
    if (!exists(appDir)) appDir = buildPath(".", "source");
    auto appFile = buildPath(appDir, "main.d");
    if (!exists(appFile)) appFile = buildPath(appDir, "app.d");
    // Replace the app file content if needed.
    if (exists(appFile)) {
        if (isFirstRun) std.file.write(appFile, appFileContent);
    } else {
        std.file.write(appFile, appFileContent);
    }

    // Get a yes or no from the user and download the raylib libraries if the user said yes.
    auto arg = (args.length != 0) ? args[0] : "?";
    while (true) {
        if (arg.length == 0) arg = "Y";
        foreach (c; "YyNn") {
            if (arg.length != 1) break;
            if (arg[0] == c) goto whileExit;
        }
        write("Would you like to download the raylib libraries? [Y/n] ");
        arg = readln().strip();
    }
    whileExit:
    if (arg == "Y" || arg == "y") {
        auto dub1 = spawnProcess(["dub", "add", "raylib-d", "--verror"]).wait();
        auto dub2 = spawnProcess(["dub", "run", "raylib-d:install", "--verror", "--", "-q", "-u=no"]).wait();
        // Remove the backup copies if something failed.
        if (dub1 != 0 || dub2 != 0) {
            if (exists(dubCopyFile)) std.file.remove(dubCopyFile);
            if (exists(dubLockCopyFile)) std.file.remove(dubLockCopyFile);
            return 1;
        }
    }

    // Replace the dub file content if needed.
    if (isFirstRun) {
        std.file.write(dubFile, dubFileContent);
        if (exists(dubLockFile)) std.file.remove(dubLockFile);
        // Remove the backup copies.
        if (exists(dubCopyFile)) std.file.remove(dubCopyFile);
        if (exists(dubLockCopyFile)) std.file.remove(dubLockCopyFile);
    } else {
        // Replace the "dirty" files with the backup copies.
        // NOTE: raylib-d will change the content of the dub file and this is considered dirty.
        if (exists(dubCopyFile)) {
            std.file.write(dubFile, std.file.readText(dubCopyFile));
            std.file.remove(dubCopyFile);
        }
        if (exists(dubLockCopyFile)) {
            std.file.write(dubLockFile, std.file.readText(dubLockCopyFile));
            std.file.remove(dubLockCopyFile);
        }
    }
    return 0;
}

int main(string[] args) {
    auto result = 0;
    auto isFirstRun = !exists(assetsDir);
    auto isSimpProject = !exists(dubFile);
    if (isSimpProject) {
        result = runSimpSetup(args[1 .. $], isFirstRun);
    } else {
        result = runDubSetup(args[1 .. $], isFirstRun);
    }
    if (result == 0) writeln("Done!");
    return result;
}
