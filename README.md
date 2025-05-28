<div style="text-align: center;">
<h1>🦆 Parin</h1>
<p>A delightfully simple 2D game engine for the D programming language. Parin is designed to make game development fun — it's easy to set up and lets you jump right into making things.</p>
<div style="display: flex; justify-content: center; gap: 11px;">
    <div style="text-align: center;">
        <p><strong>Worms Within</strong><br>A bite-sized escape room game.</p>
        <a href="https://kapendev.itch.io/worms-within"><img alt="Game 1" width="320px" src="https://img.itch.zone/aW1hZ2UvMzU4OTk2OC8yMTM5MTYyMC5wbmc=/original/fWBA1L.png"></a>
    </div>
    <div style="text-align: center;">
        <p><strong>A Short Metamorphosis</strong><br>A visual novel about looking at an egg.</p>
        <a href="https://kapendev.itch.io/a-short-metamorphosis"><img alt="Game 2" width="320px" src="https://img.itch.zone/aW1hZ2UvMjYzNzg0Ni8xNTcxOTU0NC5wbmc=/original/lH162J.png"></a>
    </div>
</div>
<br>
<p>A list of projects made with Parin is available in the <a href="https://kapendev.github.io/parin-website/pages/projects.html">projects page</a>.</p>
</div>

## Major Features

* Efficient tile map structures
* Flexible dialogue system
* Intuitive immediate mode UI
* Atlas-based animation library
* Pixel-perfect physics engine
* Cross-language support for the core library
* Cross-platform (Windows, Linux, macOS, Web)

## Hello World Example

```d
import parin;

// Called once when the game starts.
void ready() {
    lockResolution(320, 180);
}

// Called every frame while the game is running.
bool update(float dt) {
    drawDebugText("Hello world!", Vec2(8));
    return false;
}

// Called once when the game ends.
void finish() { }

mixin runGame!(ready, update, finish);
```

## Quick Start

This guide shows how to install Parin and its dependencies using [DUB](https://dub.pm/).
Create a new folder and run inside the following commands:

```cmd
dub init -n
dub run parin:setup -- -y
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

## Ideas

If you notice anything missing or would like to contribute, feel free to create an [issue](https://github.com/Kapendev/parin/issues)!
Most ideas are welcome, except ECS.
