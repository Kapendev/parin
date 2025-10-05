# 🦆 Parin

A delightfully simple 2D game engine for the [D programming language](https://dlang.org/).
Parin is designed to make game development fun — it's easy to set up, hackable, and comes with the essentials built in.

<div align="center">
<p>
    <strong>Worms Within</strong>
    <br>A bite-sized escape room game.
</p>
<a href="https://kapendev.itch.io/worms-within">
    <img alt="Game 1" width="460px" src="https://img.itch.zone/aW1hZ2UvMzU4OTk2OC8yMTM5MTYyMC5wbmc=/original/fWBA1L.png">
</a>
<br>
<br>
<p>A list of projects made with Parin is available in the <a href="https://kapendev.github.io/parin-website/pages/projects.html">projects page</a>.</p>
</div>

> [!NOTE]
> 🚧 The `main` branch is currently unstable. Please check out a tagged commit.

## Major Features

* Focused 2D engine — not an everything engine
* Pixel-perfect physics engine
* Flexible dialogue system
* Atlas-based animation library
* Efficient tile map structures
* Intuitive immediate-mode UI
* Optional garbage collection (compile-time choice)
* Built-in memory allocators: [tracking](https://github.com/Kapendev/parin/blob/main/TOUR.md#memory-tracking), [frame](https://github.com/Kapendev/parin/blob/main/TOUR.md#frame-allocator), and [arena](https://github.com/Kapendev/joka/blob/main/examples/_003_memory.d#L20)
* Modular design — just `import parin.engine`
* Includes extras like [microui](examples/integrations/microui.d)
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
    drawText("Hello world!", Vec2(8));
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
For instructions on building without DUB, check the "[How can I build without DUB?](#how-can-i-build-without-dub)" section.

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
You can also share things in the [GitHub discussions](https://github.com/Kapendev/parin/discussions).
Most ideas are welcome, except ECS.

## Devlogs

- Latest: [September 2025](https://dev.to/kapendev/parin-game-engine-devlog-september-2025-517o)
- More: [dev.to/kapendev](https://dev.to/kapendev)

## Frequently Asked Questions

### How can I build without DUB?

Create a new folder and run inside the following commands:

#### Prepare folder

```sh
git clone --depth 1 https://github.com/Kapendev/parin parin_package
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

### Where does `Vec2` come from?

`Vec2` is a type provided by the [Joka](https://github.com/Kapendev/joka) library, which Parin depends on.
An [example](https://github.com/Kapendev/joka/blob/main/examples/_002_math.d) using this type can be found in Joka.

### How can I load an asset outside of the assets folder?

Call `setIsUsingAssetsPath(false)` to disable the default behavior.
Or `setAssetsPath(assetsPath.pathDirName)` to load from the executable's folder.

### How can I hot reload assets?

Asset hot reloading is not supported out of the box.
The [arsd](https://github.com/adamdruppe/arsd) libraries may help.

### Does Parin have other UI libraries?

* [microui-d](examples/integrations/microui.d)
* [Fluid](examples/integrations/fluid.d)

### Are the Parin assets free to use?

Yes. Be sure to check the associated [README](assets/README.md) for any licensing notes.

### Is Parin a raylib wrapper?

No. Raylib is the current backend.
A custom backend may be added in the future, but it's not a priority.

### What are Parin's priorities?

The goal is a smooth experience, similar to Godot or Unity.
