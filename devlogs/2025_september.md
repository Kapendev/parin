# Parin Game Engine Devlog – September 2025

*Welcome to the September 2025 devlog for [Parin](https://github.com/Kapendev/parin).*

## 🎨 New Palettes

This month, 8 predefined color palettes were added. Two are inspired by the Game Boy and NES, while others bring in Linux nerd stuff like Gruvbox.

```d
HexPalette!4 gb4 = [ .. ];
HexPalette!8 nes8 = [ .. ];
HexPalette!16 gruvboxDark = [ .. ];
HexPalette!16 gruvboxLight = [ .. ];
HexPalette!16 oneDark = [ .. ];
HexPalette!16 oneLight = [ .. ];
HexPalette!16 solarizedDark = [ .. ];
HexPalette!16 solarizedLight = [ .. ];
```

On top of that, there is now a helper function to parse palettes from a CSV file called `csvRowToPalette`. Monkeyyy is happy.

## ⚡ Drawing Go Brrr

A version called `ParinSkipDrawChecks` was added for situations where speed matters more than safety. Invalid draw values will crash your game, so use it only if you know what you are doing.

This version also disables debug shapes when attempting to draw empty (not loaded) resources. If you are not familiar with debug shapes, here's how they look:

**With loaded resources**

![Game Yes](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/r4525duhj6ogu4hjltpb.png)

**Without loaded resources**

![Game No](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/1x2dw7jvbj9dxboj218q.png)

You can find the game [here](https://kapendev.itch.io/runani).

## 🗂️ Frame Allocator & Better Containers

The engine now provides a frame allocator for temporary memory. Allocations from it only live for the current frame and are automatically cleared at the end. This is useful for scratch data like strings or small objects created every frame without worrying about freeing them.

```d
void* frameMalloc(Sz size, Sz alignment);
void* frameRealloc(void* ptr, Sz oldSize, Sz newSize, Sz alignment);
T* frameMakeBlank(T)();
T* frameMake(T)(const(T) value = T.init);
T[] frameMakeSliceBlank(T)(Sz length);
T[] frameMakeSlice(T)(Sz length, const(T) value = T.init);
```

The engine already uses this allocator internally for functions like `loadTempText` and `prepareTempText`. Alongside this, the built-in containers got more generic in terms of allocation strategy. Previously, they only supported heap allocation. Now they can also be stack-allocated or backed by external memory.

One practical example is tile map layers in the map module, which now use fixed-sized containers:

```d
// Fixed-sized container.
alias TileMapLayerData = FixedList!(short, maxTileMapLayerCapacity);
// Fixed-sized container.
alias TileMapLayer = Grid!(TileMapLayerData.Item, TileMapLayerData);
// Dynamic container.
alias TileMapLayers = List!TileMapLayer;
```

## 🧩 Memory Tracking

Parin got a lightweight memory tracking system that can detect leaks or invalid frees in debug builds. By default, leaks will be printed at shutdown only if they are detected.

```d
bool isLoggingMemoryTrackingInfo();
void setIsLoggingMemoryTrackingInfo(bool value, IStr filter = "");
```

Example output:

```
Memory Leaks: 4 (total 699 bytes, 5 ignored)
  1 leak, 20 bytes, source/app.d:24
  1 leak, 53 bytes, source/app.d:31
  2 leak, 32 bytes, source/app.d:123
```

This isn't strictly a Parin feature. It comes from [Joka](https://github.com/Kapendev/joka), the library Parin uses for memory allocations. Anything allocated through Joka is automatically tracked. You can check whether memory tracking is active with `static if (isTrackingMemory)`, and if it is, you can inspect the current tracking state via `_memoryTrackingState`.

`_memoryTrackingState` is thread-local, so each thread has its own separate tracking state. When you look at the state or summary, remember that it's primarily a debug tool. In general, this information is normal in debug builds and doesn't indicate an error.

Some leaks can be ignored with the `ignoreLeak` function like this:

```d
// struct Game { int hp; int mp; }
// Game* game;
game = jokaMake!Game().ignoreLeak();
```

This feature might seem simple, but it can provide valuable insight into what's happening with memory. For example, it helped me cut the number of heap allocations in one part of the engine from 19 down to 9.

## 📦 Extras Collection

A new extras collection of optional libraries was added. At the moment, it only includes [microui](https://github.com/Kapendev/parin/blob/main/examples/integrations/microui.d), but more may be added over time. This is mostly a batteries included thing and lets internal Parin code use libraries without any dependencies that need to be downloaded.

## 🎚️ Easing

Two new structs were added:

* `Tween`: Eases between two float values
* `SmoothToggle`: Handles smooth transitions between two states, usually on/off.

Here is a basic example that creates a basic transition effect with the `SmoothToggle` type:

```d
auto color = cyan;
auto state = SmoothToggle();

bool update(float dt) {
    if ('q'.isPressed) state.toggle();
    auto value = smoothstep(-resolutionHeight, resolutionHeight, state.update(dt));
    if (state.isAtEnd) {
        state.toggleSnap();
        color.r = cast(ubyte) (randi % 255);
        color.g = cast(ubyte) (randi % 255);
        color.b = cast(ubyte) (randi % 255);
    };
    drawRect(Rect(0, value, resolution), color);
    return false;
}
```

Both are designed to be small in size, so they can be easily iterated in an animation array, for example. `Tween` is 20 bytes and `SmoothToggle` is 8 bytes. `Tween` also supports vectors through the types `Tween2`, `Tween3` and `Tween4`.

## 🖨️ Faster Formatting & Printing Improvements

Projects should compile faster thanks to a simpler `fmt` implementation. The `fmt` template, used for string formatting, is now just 8 lines of code and delegates all the work to a non-template function called `fmtIntoBufferWithStrs`.

A new struct called `Sep` was also added as a handy separator marker for printing functions. For example:

```d
// Will print: "1 2 3 Go!"
println(Sep(" "), 1, 2, 3, "Go!");
```

This allows you to easily control separators when printing, which is great for quick debugging.

## 🐇 Bunnymark

It's not a classic "bunnymark." More like "wormmark." I put together a quick test to see how well the current physics system works, and the results seem fine. The test runs with 30,000 worms, and each one is a physics object moving around the room. It's close to 60 FPS on a **Ryzen 3 2200G** with **16 GB of memory**.

![Game Screenshot](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/0dso31dp4px00gti3mvy.png)

You can find the code for the game [here](https://github.com/Kapendev/worms). Just change the `appendWorm` function.

## 📍 Fin

That's mostly it. If you try Parin out, let me know what you think in the [GitHub discussions](https://github.com/Kapendev/parin/discussions).
