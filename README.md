# Parin

A delightfully simple 2D game engine for the [D programming language](https://dlang.org/).
It's easy to set up, hackable, and comes with the essentials built in.

*Some games made with Parin:*

| Worms Within | A Short Metamorphosis |
| :----------: | :-------------------: |
| [![Worms Within](https://img.itch.zone/aW1hZ2UvMzU4OTk2OC8yMTM5MTYyMC5wbmc=/original/fWBA1L.png)](https://kapendev.itch.io/worms-within) | [![A Short Metamorphosis](https://img.itch.zone/aW1hZ2UvMjYzNzg0Ni8xNTcxOTU0Ny5wbmc=/original/JxyUQe.png)](https://kapendev.itch.io/a-short-metamorphosis) |

## Why Parin

Parin sits somewhere between a small library like [raylib](https://www.raylib.com/) and a big engine like [Godot](https://godotengine.org/).
It offers more direction than small libraries, but far less overhead than big engines.
Its main ideas are:

- **Code-driven design**: No engine-mandated architecture, so code can be structured however fits the game.
- **Flexible abstraction**: Garbage collection is available for convenience, with the option to drop to manual management or avoid it entirely when needed.
- **Modular foundation**: Most of Parin is built on [Joka](https://github.com/Kapendev/joka), a portable utility library that can be used on its own (see this [raylib example](https://kapendev.itch.io/k-merge-with-me)).

## Major Features

- Pixel-perfect physics engine
- Flexible dialogue system
- Atlas-based animation library
- Efficient tile map structures
- Simple UI library (WIP)
- Includes extras like microui and memory allocators
- Support for Windows, Linux, Web, and macOS

## Quick Start

This section shows how to install Parin using [DUB](https://dub.pm/).
Create a new folder and run the following commands inside it:

```sh
dub init -t parin
dub run
```

If everything is set up correctly, a window will appear showing a simple message.

Available starting templates:

```sh
dub init -t parin -- basic
dub init -t parin -- entity
```

### Install Without DUB

Create a new folder and run the following commands inside it:

1. Prepare the folder:

    ```sh
    git clone --depth 1 https://github.com/Kapendev/parin parin_package
    ./parin_package/scripts/prepare
    # Or: .\parin_package\scripts\prepare.bat
    ```

2. Run the project:

    ```sh
    ./parin_package/scripts/run
    # Or: .\parin_package\scripts\run.bat
    # Or: ./parin_package/scripts/run ldc2 macos
    # Or: ./parin_package/scripts/run opend
    ```

### Required Libraries on Linux

Some libraries for sound, graphics, and input handling are required before using Parin on Linux. Below are installation commands for some Linux distributions.

Ubuntu:

```sh
sudo apt install libasound2-dev libx11-dev libxrandr-dev libxi-dev libgl1-mesa-dev libglu1-mesa-dev libxcursor-dev libxinerama-dev libwayland-dev libxkbcommon-dev
```

Fedora:

```sh
sudo dnf install alsa-lib-devel mesa-libGL-devel libX11-devel libXrandr-devel libXi-devel libXcursor-devel libXinerama-devel libatomic
```

Arch:

```sh
sudo pacman -S alsa-lib mesa libx11 libxrandr libxi libxcursor libxinerama
```

Void:

```sh
sudo xbps-install make alsa-lib-devel libglvnd-devel libX11-devel libXrandr-devel libXi-devel libXcursor-devel libXinerama-devel mesa MesaLib-devel
```

## Documentation

Start with the [examples](examples/) folder or the [cheatsheet](CHEATSHEET.md) for a quick overview.
For more details, see the [tour page](TOUR.md).
The [DDOX](https://github.com/dlang/ddox) documentation engine can also be used locally to create an overview with:

```sh
git clone --depth=1 https://github.com/Kapendev/parin parin_package
cd parin_package
dub run -b ddox
```

Articles:

- Latest: [I Stopped Fighting My Tools](https://blog.dlang.org/2026/05/29/i-stopped-fighting-my-tools-and-built-a-game-engine-in-d/)
- More: [dev.to/kapendev](https://dev.to/kapendev)
- Archive: [parin/archive](archive/)

## Web Builds

Parin includes a build script for the web in the [packages](packages/) folder.
Building for the web requires [LDC](https://github.com/ldc-developers/ldc/releases) and [Emscripten](https://emscripten.org/) (version `4.0.23` is recommended).
While installing LDC, unpack `ldc2-X.Y.Z-addon-emscripten.tar.xz` from the same [releases page](https://github.com/ldc-developers/ldc/releases) into the LDC installation folder.

Running the script with DUB:

```sh
dub run parin:web
```

Without DUB:

```sh
./parin_package/scripts/web
# Or: .\parin_package\scripts\web.bat
```

API:

```
Usage:
  dub run parin:web -- [flags]
Flags:
  -betterc  Use the `-betterC` flag.
  -release  Use the `-release` flag.
  -build    Avoid emrun after a successful build.
```

### Uploading Web Builds to itch.io

1. Open the web folder.
2. Select the `index.*` files and add them to a ZIP file.
3. Go to itch.io and create a new project.
4. Under "Kind of project", choose "HTML."
5. Upload the ZIP file and enable the option "This file will be played in the browser."

## Ideas

If you notice anything missing, feel free to open an [issue](https://github.com/Kapendev/parin/issues)!
You can also share things in the [GitHub discussions](https://github.com/Kapendev/parin/discussions).
Most ideas are welcome, except hot reloading.

Small extras that don't belong in the core can live in the [addons](addons/) folder as single-file D libraries.
Open a PR and add the file there.

## Frequently Asked Questions

### Is there a list of games made with Parin?

Yes. Check the [projects](PROJECTS.md) page.

### Does Parin have a scene or entity system?

No. However, there are examples of how to build them using the `Union` type in the examples folder:

- [Entity system](examples/basics/_018_entity.d)
- [State (Scene) system](examples/basics/_019_state.d)
- [Project template](examples/basics/_020_entity_template.d)

### Does Parin have a scripting language?

No. The following projects might be useful:

- [wren-port](https://github.com/AuburnSounds/wren-port): A port of the Wren programming language to D.
- [arsd.script](https://arsd-official.dpldocs.info/arsd.script.html): The language is based on a hybrid of D and Javascript.
- [bindbc-lua](https://github.com/BindBC/bindbc-lua): Static & dynamic D bindings to the C API of Lua.

### Any other helpful libraries that I can use?

- [arsd.ini](https://github.com/adamdruppe/arsd/blob/master/ini.d): INI configuration file support.
- [newsdlang](https://codeberg.org/ZILtoid1991/newsdlang): SDLang/XDL configuration file support.
- [dex-cf](https://codeberg.org/configuration-file/d): CF (Configuration File) support.
- [dtiled](https://github.com/rcorre/dtiled): D language parser for Tiled map files.
- [text-mode](https://github.com/AuburnSounds/text-mode): Virtual text mode with 8x8 Unicode font and markup language.
- [Gamut](https://github.com/AuburnSounds/gamut): Image encoding and decoding library.
- [gameserver](https://github.com/schveiguy/gameserver): Simple game server for toying with online games.

### Recommended tools?

- Editor: [Zed](https://zed.dev/), [Pulsar](https://pulsar-edit.dev/)
- Art: [Pixelorama](https://orama-interactive.itch.io/pixelorama), [GIMP](https://www.gimp.org/)
- Levels: [Tiled](https://www.mapeditor.org/)
- Sounds: [Bfxr](https://www.bfxr.net/), [Jfxr](https://jfxr.frozenfractal.com/)
- Music: [MilkyTracker](https://milkytracker.org/)

### How can I load an asset outside of the assets folder?

Call `setIsUsingAssetsPath(false)` to disable the default behavior.
Or `setAssetsPath(assetsPath.pathDirName)` to load from the executable's folder.

### How do I use the `Vec2` type?

The `Vec2` type is provided by the [Joka](https://github.com/Kapendev/joka) library, which Parin depends on.
An [example](https://github.com/Kapendev/joka/blob/main/examples/_002_math.d) using this type can be found in the Joka repository.
It's a good idea to learn how Joka works in general.

### How can I hot reload assets or code?

Hot reloading is not supported out of the box because I (Kapendev) don't care about that feature.
The [arsd](https://github.com/adamdruppe/arsd) libraries may help.

### Are the Parin assets free to use?

Yes. Be sure to check the associated [README](assets/README.md) for any licensing notes.

### Is Parin a raylib wrapper?

No. Raylib is one of its backends.
A custom backend is being worked on, but it's still experimental.
Contributions are welcome.

### Can I use Parin for HD games?

Yes.
