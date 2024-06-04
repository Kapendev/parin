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
> Popka is alpha software. Use it only if you are very cool.

## Supported Platforms

* Windows
* Linux
* MacOS
* Web

## Games Made With Popka

* [A Short Metamorphosis](https://kapendev.itch.io/a-short-metamorphosis)

## Dependencies

To use Popka, you'll need the raylib library (version 5.0) installed on your system.
The official raylib instructions will guide you through the process.

## Installation

This guide outlines the steps to install Popka and raylib using Dub.

1. **Install Popka and raylib**

    Navigate to the folder containing your dub.json file and run the following command:

    ```bash
    dub add popka raylib-d && dub run raylib-d:install
    ```

2. **Compile example**

    Once the installation is complete, you should be able to compile the provided hello-world example by running:

    ```bash
    dub run
    ```

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

For exporting to web, your project needs to be compatible with BetterC.
The [web](web) folder contains helper scripts to assist with the web export process on Linux.

## Note

I add things to Popka when I need them.

## License

The project is released under the terms of the MIT License.
Please refer to the LICENSE file.
