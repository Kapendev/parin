# Popka

Popka is a lightweight and beginner-friendly 2D game engine for the D programming language.
It focuses on providing a simple foundation for building 2D games.

```d
import popka;

bool gameLoop() {
    draw("Hello world!");
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    updateWindow!gameLoop();
}

mixin addGameStart!(gameStart, 640, 360);
```

> [!WARNING]  
> This is alpha software. Use it only if you are very cool.

## Supported Platforms

* Windows
* Linux
* MacOS
* Web

## Games Made With Popka

* [A Short Metamorphosis](https://kapendev.itch.io/a-short-metamorphosis)

## Dependencies

To use Popka, you'll need the raylib library (version 5.0) installed on your system.
The [official raylib instructions](https://github.com/raysan5/raylib/wiki) will guide you through the process.

## Installation

This guide shows how to install Popka and its dependency, raylib, using DUB.
While DUB simplifies the process, Popka itself doesn't require DUB.

Create a new folder and run inside the following commands:

```bash
dub init
dub add popka
dub run popka:setup
```

The last line will download raylib and create some folders necessary for Popka to function properly. The folders:

* assets: This folder is used to store game assets such as images, sounds and fonts.
* web: This folder is used for exporting to the web.

The last line also changes the default app.d file.
Once the installation is complete, you should be able to compile/run with:

```bash
dub run
```

You can pass `offline` to the script if you don't want to download raylib.
For more info about exporting to web, see [this](#web-support).

## Documentation

For an initial understanding, the [examples](examples) folder and the [engine.d](source/popka/game/engine.d) file can be a good starting point.

## Project Layout

* [core](source/popka/core): A standard library designed specifically for game development. 
* [vendor](source/popka/vendor): A collection of third-party libraries.
* [game](source/popka/game): A set of tools for creating 2D games.

## Attributes and BetterC Support

This project offers support for some attributes (`@safe`, `@nogc`, `nothrow`) and aims for good compatibility with BetterC.

## Web Support

For exporting to web, your project needs to be compatible with BetterC.
The [web](web) folder contains a helper script to assist with the web export process.
If you use DUB, you can run the script with:

```bash
dub run popka:web
```

## raylib Bindings

Popka provides bindings for raylib that are compatible with BetterC and the web.
Additionally, it provides helper functions to reduce some boilerplate code.
All the helper functions are inside the [raylibpp.d](source/popka/vendor/ray/raylibpp.d) file.

```d
import popka.vendor.ray;

bool rayLoop() {
    BeginDrawing();
    ClearBackground(RAYWHITE);
    DrawText("Congrats! You created your first window!", 190, 200, 20, LIGHTGRAY);
    EndDrawing();
    return false;
}

void rayStart(string path) {
    InitWindow(800, 450, "raylib");
    updateWindow!rayLoop();
    CloseWindow();
}

mixin addRayStart!rayStart;
```

## Note

I add things to Popka when I need them.

## License

The project is released under the terms of the MIT License.
Please refer to the LICENSE file.
