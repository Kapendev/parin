<div align="center">
<h1>🦆 Parin</h1>
A delightfully simple and lightweight 2D game engine for the D programming language. Parin is designed to make game development fun — it's easy to set up and lets you jump right into making things.
<br><br>
<img alt="Game 1" width="360px" src="https://img.itch.zone/aW1hZ2UvMzU4OTk2OC8yMTM5MTYyMC5wbmc=/original/fWBA1L.png">
<img alt="Game 2" width="360px" src="https://img.itch.zone/aW1hZ2UvMjYzNzg0Ni8xNTcxOTU0NC5wbmc=/original/lH162J.png">
<br><br>
A full list of projects made with Parin is available in the <a href="https://kapendev.github.io/parin-website/pages/projects.html">projects page</a>.
</div>

## Major Features

* Efficient tile map structures
* Flexible dialogue system
* Intuitive immediate mode UI
* Atlas-based animation library
* Pixel-perfect physics engine
* Cross-language support for the core library
* Cross-platform (Windows, Linux, macOS, Web)

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
