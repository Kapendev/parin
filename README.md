# Popka

Popka is a lightweight and beginner-friendly 2D game engine for the D programming language.
It focuses on providing a simple foundation for building 2D games.

```d
import popka;

void main() {
    openWindow(640, 360);
    lockResolution(320, 180);
    while (isWindowOpen) {
        draw("Hello world!");
    }
    freeWindow();
}
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

This guide shows how to install Popka and its dependency, raylib, using Dub.
While Dub simplifies the setup process, Popka itself doesn't require Dub.

1. **Install Popka and raylib**

    Navigate to the folder containing your dub.json file and run the following command:

    ```bash
    dub add popka raylib-d && dub run raylib-d:install
    ```

    Popka doesn't require raylib-d, but we include it as a dependency for its convenient raylib download script.

2. **Compile example**

    Once the installation is complete, you should be able to compile the provided hello-world example by running:

    ```bash
    dub run
    ```

    For more info about exporting to web, see [this](#web-support).

## Documentation

For an initial understanding, the [examples](source/popka/examples) folder and the [engine.d](source/popka/game/engine.d) file can be a good starting point.

## Project Layout

* [core](source/popka/core): A standard library designed specifically for game development. 
* [vendor](source/popka/vendor): A collection of third-party libraries.
* [game](source/popka/game): A set of tools for creating 2D games.
* [examples](source/popka/examples): A collection of example projects.

## Attributes and BetterC Support

This project offers support for some attributes (`@safe`, `@nogc`, `nothrow`) and aims for good compatibility with BetterC.

## Web Support

For exporting to web, your project needs to be compatible with BetterC and the code has to have a specific structure.
Games playable on both desktop and web typically follow this structure:

```d
import popka;

void gameLoop() {
    draw("I am part of the web.");
    if ('q'.isPressed) closeWindow();
}

void gameMain(const(char)[] path) {
    openWindow(640, 360);
    updateWindow!gameLoop();
    freeWindow();
}

mixin addGameMain!gameMain;
```

Here's a simple breakdown of the code:

* `mixin addGameMain!gameMain`:
    This mixin creates a main function that calls the given function. The given function must accept `const(char)[] path` to work properly.
* `updateWindow!gameLoop()`:
    This function calls the given function every frame until `closeWindow` is called.

The [web](web) folder contains a helper script to assist with the web export process.

## Note

I add things to Popka when I need them.

## License

The project is released under the terms of the MIT License.
Please refer to the LICENSE file.
