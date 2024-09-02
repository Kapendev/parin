#!/bin/env rdmd

/// A helper script that automates the project setup.

import std;

enum assetsDir = buildPath(".", "assets");
enum webDir = buildPath(".", "web");

enum appFile = buildPath(".", "source", "app.d");
enum dubFile = buildPath(".", "dub.json");
enum dubLockFile = buildPath(".", "dub.selections.json");
enum gitignoreFile = buildPath(".", ".gitignore");

enum appFileContent = `import popka;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    drawDebugText("Hello world!", Vec2(8.0));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
`;

enum dubFileContent = `{
    "name" : "game",
    "description" : "A game made with Popka.",
    "authors" : ["Name"],
    "copyright" : "Copyright © 2024, Name",
    "license" : "proprietary",
    "dependencies": {
        "joka": "*",
        "popka": "*"
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

    // Use the raylib-d script to download the raylib library files.
    if (isDubProject) {
        writeln("\n  Simply say \"yes\" to all prompts.  \n");
        auto dub1 = spawnProcess(["dub", "add", "raylib-d"]).wait();
        if (dub1 != 0) return dub1;
        auto dub2 = spawnProcess(["dub", "run", "raylib-d:install"]).wait();
        if (dub2 != 0) return dub2;
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
        std.file.write(dubFile, dubFileContent);
    }
    if (isFirstRun) std.file.write(gitignoreFile, gitignoreFileContent);

    // Create folders.
    if (!exists(assetsDir)) std.file.mkdir(assetsDir);
    if (!exists(webDir)) std.file.mkdir(webDir);
    return 0;
}
