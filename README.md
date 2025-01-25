# Parin

A delightfully simple and lightweight 2D game engine for the D programming language,
offering a solid foundation for creating 2D games.

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

* Intuitive immediate mode UI
* Flexible dialogue system with a stack-oriented scripting language
* Atlas-based animation library
* ...and more!

## Supported Platforms

* PC: Windows, Linux, Mac
* WebAssembly

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

Start with the [examples](https://github.com/Kapendev/parin/tree/main/examples) folder for a quick overview.
For more details, check the [tour](https://kapendev.github.io/parin-website/pages/tour.html) page.
