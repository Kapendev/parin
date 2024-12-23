# Parin

Parin is a lightweight and beginner-friendly 2D game engine for the D programming language.
It focuses on providing a simple foundation for building 2D games.

```d
import parin;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    drawDebugText("Hello world!", Vec2(8));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
```

## Supported Platforms

* PC: Windows, Linux, macOS
* Web

## Projects Made With Parin

A list of projects made with Parin is available in the [PROJECTS.md](PROJECTS.md) file.

## Installation

This guide shows how to install Parin and its dependencies using DUB.
While DUB simplifies the process, Parin itself doesn't require DUB.

Parin has the following dependencies:

* [Joka](https://github.com/Kapendev/joka): A simple nogc utility library.
* [raylib](https://github.com/raysan5/raylib): A simple graphics library.

### Installation Steps

Create a new folder and run inside the following commands:

```sh
dub init -n
dub run parin:setup
```

The final line modifies the default app.d and dub.json files, downloads raylib, and creates the necessary folders for Parin to function properly. The following folders will be created:

* assets: This folder is used to store assets.
* web: This folder is used for exporting to the web.

Once the installation is complete, run the following command:

```sh
dub run
```

If everything is set up correctly, a window will appear showing the message "Hello world!".

### Required Libraries on Linux

Some libraries for sound, graphics, and input handling are required before using Parin on Linux. Below are installation commands for some Linux distributions.

**Ubuntu:**

```sh
sudo apt install libasound2-dev libx11-dev libxrandr-dev libxi-dev libgl1-mesa-dev libglu1-mesa-dev libxcursor-dev libxinerama-dev libwayland-dev libxkbcommon-dev
```

**Fedora:**

```sh
sudo dnf install alsa-lib-devel mesa-libGL-devel libX11-devel libXrandr-devel libXi-devel libXcursor-devel libXinerama-devel libatomic
```

**Arch:**

```sh
sudo pacman -S alsa-lib mesa libx11 libxrandr libxi libxcursor libxinerama
```

## Documentation

For an initial understanding, the [examples](examples) folder can be a good starting point.
For a more detailed overview, check the [TOUR.md](TOUR.md) file.

## Web Support

To export to the web, the project must be compatible with BetterC.
The [web](web) folder contains a helper script to assist with the web export process and it can be used with DUB by running the following command:

```sh
dub run parin:web
```

## Alternative Game Development Libraries

While Parin provides a good game development experience in D, it might not fit everyone's needs.
Here are some other notable alternatives to consider:

* [raylib-d](https://github.com/schveiguy/raylib-d)
* [HipremeEngine](https://github.com/MrcSnm/HipremeEngine)
* [PixelPerfectEngine](https://github.com/ZILtoid1991/pixelperfectengine)
* [Godot-DLang](https://github.com/godot-dlang/godot-dlang)

## Note

I add things to Parin when I need them.
For an overview of what I like and don't like, check the [PREFERENCES.md](PREFERENCES.md) file.

Also, developers using Parin are called Parinists (a name suggested by AI).

## License

The project is released under the terms of the MIT License.
Please refer to the LICENSE file.
