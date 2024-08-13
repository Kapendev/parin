# Popka

Popka is a lightweight and beginner-friendly 2D game engine for the D programming language.
It focuses on providing a simple foundation for building 2D games.

```d
import popka;

bool gameLoop() {
    drawDebugText("Hello world!");
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    updateWindow!gameLoop();
}

mixin callGameStart!(gameStart, 640, 360);
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

* [Joka](https://github.com/Kapendev/joka)
* [raylib](https://github.com/raysan5/raylib)

## Installation

This guide shows how to install Popka and its dependencies using DUB.
While DUB simplifies the process, Popka itself doesn't require DUB.

Create a new folder and run inside the following commands:

```bash
dub init -n
dub run popka:setup
```

The final line modifies the default app.d and dub.json files, downloads raylib, and creates the necessary folders for Popka to function properly. The following folders will be created:

* assets: This folder is used to store game assets.
* web: This folder is used for exporting to the web.

Once the installation is complete, run the following command:

```bash
dub run
```

If everything is set up correctly, a window will appear showing the message "Hello world!".
To avoid downloading raylib, pass `offline` to the script.

## Documentation

For an initial understanding, the [examples](examples) folder can be a good starting point.
For a more detailed overview, check the [TOUR.md](TOUR.md) file.

## Attributes and BetterC Support

This project offers support for some attributes (`@safe`, `@nogc`, `nothrow`) and aims for good compatibility with BetterC.
If you encounter errors with BetterC, try using the `-i` flag.

## Web Support

To export a game to the web, the game must be compatible with BetterC.
The [web](web) folder contains a helper script to assist with the web export process.

```bash
dub run popka:web
```

## raylib Bindings

Popka provides bindings for raylib that are compatible with BetterC and the web.

```d
import popka.ray;

int main() {
    const int screenWidth = 800;
    const int screenHeight = 450;
    InitWindow(screenWidth, screenHeight, "raylib [core] example - basic window");
    SetTargetFPS(60);
    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("Congrats! You created your first window!", 190, 200, 20, LIGHTGRAY);
        EndDrawing();
    }
    CloseWindow();
    return 0;
}
```

## Note

I add things to Popka when I need them.

## License

The project is released under the terms of the MIT License.
Please refer to the LICENSE file.
