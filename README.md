# 🍂 Popka

Popka is a lightweight and beginner-friendly 2D game engine for the D programming language.
It focuses on providing a simple and easy-to-understand foundation for building 2D games.
The game engine is currently under development and is not yet ready for use.

```d
/// A hello-world example.

import popka;

void main() {
    openWindow(640, 480);
    lockResolution(320, 180);
    while (isWindowOpen) {
        draw("Hello world!");
    }
    freeWindow();
}
```

## Games Made With Popka

* [A Short Metamorphosis](https://kapendev.itch.io/a-short-metamorphosis)

## Dependencies

To use Popka, you'll need the raylib library (version 5.0) installed on your system.
The official raylib instructions will guide you through the process.

## Project Layout

* core: A standard library designed specifically for game development. 
* vendor: A collection of third-party libraries.
* game: A set of tools for creating 2D games.
* examples: A collection of example projects.

## Documentation

This project uses the source code as its primary documentation for now.
For an initial understanding, the engine.d file inside the game folder can be a good starting point.

## License

The project is released under the terms of the MIT License.
Please refer to the LICENSE file.
