# 🦆 Parin

A delightfully simple 2D game engine for the [D programming language](https://dlang.org/).
Parin is designed to make game development fun — it's easy to set up and lets you jump right into making things.

<div align="center">
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
* Cross-platform (Windows, Linux, macOS, Web)
* Small C interface for cross-language use
* BetterC support

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

This guide shows how to install Parin using [DUB](https://dub.pm/).
Create a new folder and run inside the following commands:

```sh
dub init -n
dub run parin:setup
dub run
```

If everything is set up correctly, a window will appear showing the message "Hello world!".

### Required Libraries on Linux

Some libraries for sound, graphics, and input handling are required before using Parin on Linux. Below are installation commands for some Linux distributions.

#### Ubuntu

```sh
sudo apt install libasound2-dev libx11-dev libxrandr-dev libxi-dev libgl1-mesa-dev libglu1-mesa-dev libxcursor-dev libxinerama-dev libwayland-dev libxkbcommon-dev
```

#### Fedora

```sh
sudo dnf install alsa-lib-devel mesa-libGL-devel libX11-devel libXrandr-devel libXi-devel libXcursor-devel libXinerama-devel libatomic
```

#### Arch

```sh
sudo pacman -S alsa-lib mesa libx11 libxrandr libxi libxcursor libxinerama
```

## Documentation

Start with the [examples](examples/) folder or the [cheatsheet](CHEATSHEET.md) for a quick overview.
For more details, check the [tour page](TOUR.md).

## Ideas

If you notice anything missing or want to contribute, feel free to open an [issue](https://github.com/Kapendev/parin/issues)!
Most ideas are welcome, except ECS.

## Frequently Asked Questions

### How can I build without DUB?

Create a new folder and run inside the following commands:

#### Prepare folder

```sh
git clone --depth 1 https://github.com/Kapendev/parin parin_package
git clone --depth 1 https://github.com/Kapendev/joka joka_package
./parin_package/scripts/prepare
# Or: .\parin_package\scripts\prepare.bat
```

#### Compile & run

```sh
./parin_package/scripts/run
# Or: .\parin_package\scripts\run.bat
# Or: ./parin_package/scripts/run ldc2 macos
# Or: ./parin_package/scripts/run opend
```

### How do I make a web build?

Parin includes a build script for the web in the [packages](packages/) folder.
Building for the web also requires [Emscripten](https://emscripten.org/).
By default, Parin's web builds use the BetterC flag, meaning only projects compatible with BetterC can be compiled.

#### Running the script with DUB

```sh
dub run parin:web
```

#### Without DUB

```sh
./parin_package/scripts/web
# Or: .\parin_package\scripts\web.bat
```

Projects requiring the full D runtime can be built using the GC flag.
This flag also requires [OpenD](https://opendlang.org/index.html) and the latest version of Emscripten.
Note that exceptions are not supported and that some DUB related limitations apply like having to include all dependencies inside the source folder.
Before using the GC flag, make sure `opend install xpack-emscripten` has been run at least once.

#### Using the flag with DUB

```sh
dub run parin:web -- gc
```

#### Without DUB

```sh
./parin_package/scripts/web gc
# Or: .\parin_package\scripts\web.bat gc
```

Below are installation commands for Emscripten for some Linux distributions.

#### Ubuntu

```sh
sudo apt install emscripten
```

#### Fedora

```sh
sudo dnf install emscripten
```

#### Arch

```sh
yay -S emscripten
# Or: sudo pacman -S emscripten
```

### Is Parin a raylib wrapper?

No. Raylib is just the current backend.
A custom backend may be added in the future, but it's not a priority.

### What are Parin's priorities?

The goal is a smooth experience, similar to Godot or Unity.

### Where does `Vec2` come from?

`Vec2` is a type provided by the [Joka](https://github.com/Kapendev/joka) library, which Parin depends on.
An [example](https://github.com/Kapendev/joka/blob/main/examples/_002_math.d) using this type can be found in Joka.

### How can I load an asset outside of the assets folder?

Call `setIsUsingAssetsPath(false)` to disable the default behavior.
Or call `setAssetsPath(assetsPath.pathDirName)` to load assets from the executable's folder (e.g. `./exe ./file` instead of `./exe ./assets/file`).

### How can I hot reload assets?

Asset hot reloading is not supported out of the box.
The [arsd](https://github.com/adamdruppe/arsd) libraries may help.

### Are the Parin assets free to use?

Yes. Be sure to check the associated [README](assets/README.md) for any licensing notes.
