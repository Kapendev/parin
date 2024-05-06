# Popka

Popka is a lightweight and beginner-friendly 2D game engine for the D programming language.
It focuses on providing a simple foundation for building 2D games.

```d
/// A hello-world example.

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

## Games Made With Popka

* [A Short Metamorphosis](https://kapendev.itch.io/a-short-metamorphosis)

## Dependencies

To use Popka, you'll need the raylib library (version 5.0) installed on your system.
The official raylib instructions will guide you through the process.

## Documentation

For an initial understanding, the [examples](examples) folder and the [engine.d](game/engine.d) file can be a good starting point.

## Project Layout

* [core](core): A standard library designed specifically for game development. 
* [vendor](vendor): A collection of third-party libraries.
* [game](game): A set of tools for creating 2D games.
* [examples](examples): A collection of example projects.

## License

The project is released under the terms of the MIT License.
Please refer to the LICENSE file.
