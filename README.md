# 🍂 Popka

Popka is a lightweight and beginner-friendly 2D game engine for the D programming language.
It focuses on providing a simple and easy-to-understand foundation for building 2D games.
The game engine is currently under development and is not yet ready for use.

```d
import popka.basic;

void main() {
    openWindow(800, 600);
    while (isWindowOpen) {
        if (Keyboard.q.isPressed) {
            closeWindow();
        }
    }
    freeWindow();
}
```

## Dependencies

To use Popka, you'll need the raylib library (version 5.0) installed on your system.
Installing raylib is easy, and the official instructions will guide you through the process.

## Documentation

This project uses the source code as its primary documentation.
For an initial understanding, the engine.d file inside the game folder can be a good starting point.
This file provides an overview of the system and can help you navigate the codebase.

## License

The project is released under the terms of the MIT License.
Please refer to the LICENSE file.
