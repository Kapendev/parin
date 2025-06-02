<div align="center">
<h1>🦆 Parin</h1>
<p>A delightfully simple 2D game engine for the <a href="https://dlang.org/">D programming language</a>. Parin is designed to make game development fun — it's easy to set up and lets you jump right into making things.</p>
<p><strong>Worms Within</strong><br>A bite-sized escape room game.</p>
<a href="https://kapendev.itch.io/worms-within"><img alt="Game 1" width="420px" src="https://img.itch.zone/aW1hZ2UvMzU4OTk2OC8yMTM5MTYyMC5wbmc=/original/fWBA1L.png"></a>
<br>
<br>
<p>A list of projects made with Parin is available in the <a href="https://kapendev.github.io/parin-website/pages/projects.html">projects page</a>.</p>
</div>

## Major Features

* Efficient tile map structures
* Flexible dialogue system
* Intuitive immediate mode UI
* Atlas-based animation library
* Pixel-perfect physics engine
* Cross-language support
* Cross-platform (Windows, Linux, macOS, Web)

## Hello World Example

```d
import parin;

// Called once when the game starts.
void ready() {
    lockResolution(320, 180);
}

// Called every frame while the game is running.
// If true is returned, then the game will stop running.
bool update(float dt) {
    drawDebugText("Hello world!", Vec2(8));
    return false;
}

// Called once when the game ends.
void finish() {}

// Creates a main function that calls the given functions.
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

**Ubuntu**:

```cmd
sudo apt install libasound2-dev libx11-dev libxrandr-dev libxi-dev libgl1-mesa-dev libglu1-mesa-dev libxcursor-dev libxinerama-dev libwayland-dev libxkbcommon-dev
```

**Fedora**:

```cmd
sudo dnf install alsa-lib-devel mesa-libGL-devel libX11-devel libXrandr-devel libXi-devel libXcursor-devel libXinerama-devel libatomic
```

**Arch**:

```cmd
sudo pacman -S alsa-lib mesa libx11 libxrandr libxi libxcursor libxinerama
```

## Documentation

Start with the [examples](./examples/) folder or the [cheatsheet](https://kapendev.github.io/parin-website/pages/cheatsheet.html) for a quick overview.
For more details, check the [tour page](https://kapendev.github.io/parin-website/pages/tour.html).

## Ideas

If you notice anything missing or would like to contribute, feel free to create an [issue](https://github.com/Kapendev/parin/issues)!
Most ideas are welcome, except ECS.

## Frequently Asked Questions

### How can I load an asset outside of the assets folder?

By default, assets are loaded from the assets folder.
To load from a different location, call `setIsUsingAssetsPath(false)` to disable this behavior.

### How can I hot reload assets?

Asset hot reloading is not supported out of the box.
The [arsd](https://github.com/adamdruppe/arsd) libraries may help, but with Parin alone, you can manually reload assets like this:

```d
bool update(float dt) {
    // Reload the texture whenever the 0 key is pressed.
    if ('0'.isPressed) {
        atlas.free();
        atlas = loadTexture("parin_atlas.png");
    }
    drawTexture(atlas, Vec2(8));
    return false;
}
```
