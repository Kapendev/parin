#!/bin/env rdmd

/// A helper script that automates the project setup.
/// This script is designed with the idea that you use DUB.

import std.format;
import std.path;
import std.stdio;
import std.file;
import std.process;

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
            "raylibdll"
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

void gameStart(string path) {
    openWindow(640, 360);
    lockResolution(320, 180);
    updateWindow!gameLoop();
    closeWindow();
}

mixin addGameStart!gameStart;
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

int main() {
    bool isDubProject = !check("./source/app.d", false);
    if (!isDubProject) {
        writeln("Error: This is not a DUB project.");
        return 1;
    }

    // Use the raylib-d script to download the raylib library files.
    // We also have to use `spawnShell` here because raylib-d:install does not accept arguments.
    // TODO: Ask the raylib-d project to do something about that.
    run("dub add raylib-d");
    writeln();
    writeln(`"Saying yes to happiness means learning to say no to the things and people that stress you out." - Thema Davis`);
    writeln();
    auto pid = spawnShell("dub run raylib-d:install");
    wait(pid);

    // Delete the old files.
    deleteFile("./dub.json");
    deleteFile("./dub.selections.json");
    deleteFile("./.gitignore");
    deleteFile("./source/app.d");

    // Create the new files.
    std.file.write("./dub.json", defaultDubContent);
    std.file.write("./.gitignore", defaultGitignoreContent);
    std.file.write("./source/app.d", defaultAppContent);
    if (check("./assets", false)) std.file.mkdir("./assets");
    if (check("./web", false)) std.file.mkdir("./web");
    return 0;
}
