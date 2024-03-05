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

Popka requires the raylib library to be installed for full functionality.
Please install raylib following the official instructions before using this game engine.

## License

The project is released under the terms of the MIT License.
Please refer to the LICENSE file.
