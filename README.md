# 🍂 Popka

Popka is a lightweight and beginner-friendly 2D game engine for the D programming language.
It focuses on providing a simple and easy-to-understand foundation for building 2D games.
The game engine is currently under development and is not yet ready for use.

```d
/// A hello-world example.

import popka.basic;

void main() {
    openWindow(640, 480);
    lockResolution(320, 180);
    while (isWindowOpen) {
        drawDebugText("Hello world!");
    }
    freeWindow();
}
```

## Dependencies

To use Popka, you'll need the raylib library (version 5.0) installed on your system.
Installing raylib is easy, and the official raylib instructions will guide you through the process.

## Installation

This guide outlines the steps to install Popka using Git and the Dub package manager.
It is not recommended to use Dub for now.

1. **Clone the Popka repository:**

    Open a terminal and navigate to your source code folder.
    Then, execute the following command to clone the Popka repository:

    ```bash
    git clone https://github.com/Kapendev/popka.git
    ```

2. **Install raylib using Dub:**

    Navigate to the folder containing your dub.json file (usually the root folder of your project).
    Run the following command to install raylib using Dub:

    ```bash
    dub add raylib-d && dub run raylib-d:install && dub remove raylib-d
    ```

    After installation, remove the raylib-d dependency from your dub.json file.

3. **Compile example:**

    Once the installation is complete, you should be able to compile the provided example by running:

    ```bash
    dub run
    ```

## Examples

A comprehensive set of code examples showcasing various engine features can be found within the example folder.

## Documentation

This project uses the source code as its primary documentation.
For an initial understanding, the engine.d file inside the game folder can be a good starting point.
This file provides an overview of the system and can help you navigate the codebase.

## License

The project is released under the terms of the MIT License.
Please refer to the LICENSE file.
