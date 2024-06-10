#!/bin/env rdmd

/// A helper script that automates the project setup.
/// This script is designed with the idea that you use DUB.

import std.format;
import std.path;
import std.stdio;
import std.file;
import std.process;


// The config.
// ----------
enum noLibsArg = "offline";

enum dubFile = buildPath(".", "dub.json");
enum dubyFile = buildPath(".", "dub.selections.json");
enum appFile = buildPath(".", "source", "app.d");
enum gitignoreFile = buildPath(".", ".gitignore");

enum assetsDir = buildPath(".", "assets");
enum webDir = buildPath(".", "web");
// ----------


enum defaultDubContent = `{
"name" : "game",
"description" : "A game made with Popka.",
"authors" : ["Name"],
"copyright" : "Copyright © 2024, Name",
"license" : "proprietary",
"dependencies": {
    "popka": "*"
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
            "raylib.500"
        ]
    }
]
}
`;

enum defaultGitignoreContent = `.dub
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

enum defaultAppContent = `import popka;

bool gameLoop() {
    draw("Hello world!");
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    updateWindow!gameLoop();
}

mixin addGameStart!(gameStart, 640, 360);
`;

/// Check if path exists and print an error message if needed.
bool check(const(char)[] path, bool isLoud = true) {
    if (!exists(path)) {
        if (isLoud) writeln("Error: `", path, "` doesn't exist.");
        return true;
    }
    return false;
}

/// Run a command and print the output.
bool run(const(char)[] command, bool isLoud = true) {
    writeln("Command: ", command);
    auto shell = executeShell(command);
    if (isLoud && shell.output.length != 0) writeln("Output: ", shell.output);
    return shell.status != 0;
}

/// Deletes a file if it exists.
void deleteFile(const(char)[] path) {
    if (!check(path, false)) {
        std.file.remove(path);
    }
}

int main(string[] args) {
    writeln("Info: Pass `%s` if you don't want to download raylib.".format(noLibsArg));
    if (check(dubFile, false)) {
        writeln("Error: This is not a DUB project.");
        return 1;
    }
    // Skip if the folders already exist.
    if (!check(assetsDir, false) || !check(webDir, false)) {
        return 0;
    }

    // Use the raylib-d script to download the raylib library files.
    // We also have to use `spawnShell` here because raylib-d:install does not accept arguments.
    // TODO: Ask the raylib-d project to do something about that.
    auto canDownload = (args.length > 1) ? (args[1] != noLibsArg) : true;
    if (canDownload) {
        run("dub add raylib-d");
        writeln();
        writeln(`"Saying yes to happiness means learning to say no to the things and people that stress you out." - Thema Davis`);
        writeln();
        auto pid = spawnShell("dub run raylib-d:install");
        wait(pid);
    }

    // Delete the old files.
    deleteFile(dubFile);
    deleteFile(dubyFile);
    deleteFile(gitignoreFile);
    deleteFile(appFile);

    // Create the new files.
    std.file.write(dubFile, defaultDubContent);
    std.file.write(gitignoreFile, defaultGitignoreContent);
    std.file.write(appFile, defaultAppContent);
    std.file.mkdir(assetsDir);
    std.file.mkdir(webDir);
    return 0;
}
