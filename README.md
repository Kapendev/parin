# Parin

A delightfully simple and lightweight 2D game engine for the D programming language.

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

## Batteries Included

Parin is packed with powerful features to get you started quickly:

* Intuitive immediate mode UI
* Flexible dialogue system with a stack-oriented scripting language
* Atlas-based animation library
* Pixel-perfect physics engine
* ...and more!

## Cross-Platform

Parin lets you to build games for multiple platforms with ease:

* PC: Windows, Linux, Mac
* WebAssembly
* ...and more in the future!

## Open-Source

Parin is MIT-licensed and free to use forever.

## Projects Made With Parin

A list of projects made with Parin is available in the [projects](https://kapendev.github.io/parin-website/pages/projects.html) page.

## Installation

This guide shows how to install Parin and its dependencies using [DUB](https://dub.pm/).
Create a new folder and run inside the following commands:

```cmd
dub init -n
dub run parin:setup
dub run
```

If everything is set up correctly, a window will appear showing the message "Hello world!".

### Required Libraries on Linux

Some libraries for sound, graphics, and input handling are required before using Parin on Linux. Below are installation commands for some Linux distributions.

Ubuntu:

```cmd
sudo apt install libasound2-dev libx11-dev libxrandr-dev libxi-dev libgl1-mesa-dev libglu1-mesa-dev libxcursor-dev libxinerama-dev libwayland-dev libxkbcommon-dev
```

Fedora:

```cmd
sudo dnf install alsa-lib-devel mesa-libGL-devel libX11-devel libXrandr-devel libXi-devel libXcursor-devel libXinerama-devel libatomic
```

Arch:

```cmd
sudo pacman -S alsa-lib mesa libx11 libxrandr libxi libxcursor libxinerama
```

## Documentation

Start with the [examples](./examples/) folder or the [cheatsheet](https://kapendev.github.io/parin-website/pages/cheatsheet.html) for a quick overview.
For more details, check the [tour](https://kapendev.github.io/parin-website/pages/tour.html) page.

## Building Without DUB

Parin has the following dependencies:

* [Joka](https://github.com/Kapendev/joka)
* [raylib](https://github.com/raysan5/raylib)

To create a simple one-file game, run something like:

```cmd
dmd -i -Ijoka/source -Iparin/source -Jparin/assets -L-L. -L-lraylib app.d
```
