# 🦆 Parin

A delightfully simple 2D game engine for the [D programming language](https://dlang.org/).
Parin is designed to make game development fast and fun — it's easy to set up, hackable, and comes with the essentials built in.

<div align="center">
<p>
    <strong>Worms Within</strong>
    <br>A bite-sized escape room game.
</p>
<a href="https://kapendev.itch.io/worms-within">
    <img alt="Game 1" width="480px" src="https://img.itch.zone/aW1hZ2UvMzU4OTk2OC8yMTM5MTYyMC5wbmc=/original/fWBA1L.png">
</a>
<br>
<br>
<p>
    <strong>A Short Metamorphosis</strong>
    <br>A cute visual novel about looking at an egg.
</p>
<a href="https://kapendev.itch.io/a-short-metamorphosis">
    <img alt="Game 1" width="480px" src="https://img.itch.zone/aW1hZ2UvMjYzNzg0Ni8xNTcxOTU0Ny5wbmc=/original/JxyUQe.png">
</a>

<br>
<br>
<p>A list of projects made with Parin is available in the <a href="https://kapendev.github.io/parin-website/pages/projects.html">projects page</a>.</p>
</div>

## Why Parin

- **Focused on games.** It is opinionated in ways that make common game-development tasks easier than in general-purpose engines.
- **Code-driven design.** There's no imposed architecture, allowing freedom on how a game is structured.
- **A guided workflow.** Parin assumes a few common patterns to smooth out the development experience.

Parin sits somewhere between a small engine like raylib or LÖVE and a big engine like Godot or Unity. It offers more direction than small ones, but far less overhead and "magic" than big ones.

## Major Features

- Focused 2D engine — not an everything engine
- Pixel-perfect physics engine
- Flexible dialogue system
- Atlas-based animation library
- Efficient tile map structures
- Intuitive immediate-mode UI
- Mixed memory model: manual control, GC, or both
- Built-in memory allocators: [tracking](https://github.com/Kapendev/parin/blob/main/TOUR.md#memory-tracking), [frame](https://github.com/Kapendev/parin/blob/main/TOUR.md#frame-allocator), and [arena](https://github.com/Kapendev/joka/blob/main/examples/_003_memory.d#L20)
- Includes extras like [microui](examples/integrations/microui.d)
- Cross-platform: Windows, Linux, Web, macOS

## Examples

### Hello World

```d
import parin;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    drawText("Hello world!", Vec2(8));
    return false;
}

void finish() {}

mixin runGame!(ready, update, finish);
```

### Simple Editor

```d
import parin;
import parin.addons.microui;

Game game;

struct Game {
    int width = 50;
    int height = 50;
    IVec2 point = IVec2(70, 50);
}

void ready() {
    readyUi(2);
}

bool update(float dt) {
    drawRect(Rect(game.point.x, game.point.y, game.width, game.height));
    beginUi();
    if (beginWindow("Edit", UiRect(500, 80, 350, 370))) {
        headerAndMembers(game, 125);
        endWindow();
    }
    endUi();
    return false;
}

mixin runGame!(ready, update, null);
```

## Quick Start

This guide shows how to install Parin using [DUB](https://dub.pm/).
Create a new folder and run inside the following commands:

```sh
dub init -t parin
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

#### Void

```sh
sudo xbps-install make alsa-lib-devel libglvnd-devel libX11-devel libXrandr-devel libXi-devel libXcursor-devel libXinerama-devel mesa MesaLib-devel
```

## Documentation

Start with the [examples](examples/) folder or the [cheatsheet](CHEATSHEET.md) for a quick overview.
For more details, see the [tour page](TOUR.md).
The [`parin.types`](source/parin/types.d) and [`parin.engine`](source/parin/engine.d) modules are easy to read and show what's available.

## Ideas

If you notice anything missing or want to contribute, feel free to open an [issue](https://github.com/Kapendev/parin/issues)!
You can also share things in the [GitHub discussions](https://github.com/Kapendev/parin/discussions).
Most ideas are welcome, except ECS.

## Devlogs

- Latest: [October 2025](https://dev.to/kapendev/parin-game-engine-devlog-october-2025-5dfi)
- More: [dev.to/kapendev](https://dev.to/kapendev)
- Archive: [parin/devlogs](devlogs/)

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
By default, Parin's web builds use the `betterC` flag, meaning only projects compatible with it can be compiled.

#### Running the script with DUB

```sh
dub run parin:web
```

#### Without DUB

```sh
./parin_package/scripts/web
# Or: .\parin_package\scripts\web.bat
```

Projects requiring the full D runtime can be built using the `gc` flag provided by the build script.
This flag also requires [OpenD](https://opendlang.org/index.html) and the latest version of Emscripten.
Note that exceptions are not supported and that some DUB related limitations apply like having to include all dependencies inside the source folder.
Make sure `opend install xpack-emscripten` has been run at least once before using it.

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

#### Projects Using raylib-d

Additionally, [raylib-d](https://github.com/schveiguy/raylib-d) projects are partially supported through the `rl` flag.
A small subset of raylib-d is included by Parin to make it possible to compile at least 2D games with minimal changes.
This flag can be combined with the `gc` flag if needed.
Make sure to add something like this in the dub.json file before using it:

```json
"configurations": [
    {
        "name": "default",
        "targetType": "executable"
    },
    {
        "name": "wasm",
        "targetType": "library",
        "targetName": "game_wasm",
        "dflags": ["-mtriple=wasm32-unknown-unknown-wasm", "-checkaction=halt", "-i", "--release", "-betterC"]
    }
]
```

#### Using the flag with DUB

```sh
dub run parin:web -- rl
```

#### Using rl and gc with DUB

```sh
dub run parin:web -- rl gc
```

For most projects, using both `rl` and `gc` should provide the best compatibility.

### How do I use `Vec2`?

`Vec2` is a type provided by the [Joka](https://github.com/Kapendev/joka) library, which Parin depends on.
An [example](https://github.com/Kapendev/joka/blob/main/examples/_002_math.d) using this type can be found in Joka.

### How can I load an asset outside of the assets folder?

Call `setIsUsingAssetsPath(false)` to disable the default behavior.
Or `setAssetsPath(assetsPath.pathDirName)` to load from the executable's folder.

### How can I hot reload assets?

Asset hot reloading is not supported out of the box.
The [arsd](https://github.com/adamdruppe/arsd) libraries may help.

### Does Parin have other UI libraries?

- [microui-d](examples/integrations/microui.d)
- [Fluid](examples/integrations/fluid.d)

### Are the Parin assets free to use?

Yes. Be sure to check the associated [README](assets/README.md) for any licensing notes.

### Is Parin a raylib wrapper?

No. Raylib is the current backend.
A custom backend may be added in the future, but it's not a priority.

### What are Parin's priorities?

The goal is a smooth experience, similar to Godot or Unity.
