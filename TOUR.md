# 🦉 Parin Tour (WIP)

This guide will go over **some of the features** of the engine and provide examples of how to use them.
If you notice anything missing or want to contribute, feel free to open an [issue](https://github.com/Kapendev/parin/issues)!

## Getting Started

This section shows how to install Parin using [DUB](https://dub.pm/).
To begin, make a new folder and run inside the following commands to create a new project:

```cmd
dub init -n
dub run parin:setup
```

If everything is set up correctly, there should be some new files inside the folder.
Three of them are particularly important:

* `source`: Contains the source code
* `assets`: Contains the game assets
* `web`: Used for exporting to the web

Additionally, an app.d file is inside the source folder that looks like this:

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

This code will create a window that displays the message "Hello world!".
Here is a breakdown of how it works:

1. The Ready Function

    ```d
    void ready() {
        lockResolution(320, 180);
    }
    ```

    This function is the starting point of the game.
    It is called once when the game starts and, in this example, locks the game resolution to 320x180.

2. The Update Function

    ```d
    bool update(float dt) {
        drawText("Hello world!", Vec2(8));
        return false;
    }
    ```

    This function is the main loop of the game.
    It is called every frame while the game is running and, in this example, draws the message "Hello world!" at position (8, 8).
    The `return false` statement at the end indicates that the game should continue running.
    If `true` were returned, then the game would stop running.

3. The Finish Function

    ```d
    void finish() {}
    ```

    This function is the ending point of the game.
    It is called once when the game ends and, in this example, does nothing.

4. The Mixin

    ```d
    mixin runGame!(ready, update, finish);
    ```

    This mixin sets up a main function that opens a window and calls the ready, update and finish functions.
    By default, the window has a size of 960x540.

In essence, a Parin game typically relies on three functions:

* A ready function.
* An update function.
* A finish function.

To run the game, use the following command:

```cmd
dub run
```

And that's it for the basics.
As a fun exercise, try changing the message to "DVD" and make it bounce inside the window.
The engine font has characters that have a size of 6x12.
An example of this can be found in the [examples](examples/basics/_003_dvd.d).

## Modules

Parin consists of the following modules:

* `parin.engine`: Core engine functionality
* `parin.map`: Tile map utilities
* `parin.palettes`: Predefined colors
* `parin.platformer`: Physics engine
* `parin.sprite`: Sprite utilities
* `parin.story`: Dialogue system
* `parin.timer`: Time utilities
* `parin.ui`: Immediate mode UI

The `parin.types` and `parin.engine` modules are the only mandatory module for creating a game.
All other modules are optional and can be included as needed.
The `import parin` statement in the example above is a convenience import that includes all modules.

## Input

Parin provides a set of input functions. These include:

```d
/// Returns the current mouse position on the window.
Vec2 mouse();
/// Returns the change in mouse position since the last frame.
Vec2 deltaMouse();
/// Returns the change in mouse wheel position since the last frame.
float deltaWheel();

/// Returns true if the specified character is currently pressed.
bool isDown(char key);
/// Returns true if the specified keyboard key is currently pressed.
bool isDown(Keyboard key);
/// Returns true if the specified mouse button is currently pressed.
bool isDown(Mouse key);
/// Returns true if the specified gamepad button is currently pressed.
bool isDown(Gamepad key, int id = 0);

/// Returns true if the specified character was pressed this frame.
bool isPressed(char key);
/// Returns true if the specified keyboard key was pressed this frame.
bool isPressed(Keyboard key);
/// Returns true if the specified mouse button was pressed this frame.
bool isPressed(Mouse key);
/// Returns true if the specified gamepad button was pressed this frame.
bool isPressed(Gamepad key, int id = 0);

/// Returns true if the specified character was released this frame.
bool isReleased(char key);
/// Returns true if the specified keyboard key was released this frame.
bool isReleased(Keyboard key);
/// Returns true if the specified mouse button was released this frame.
bool isReleased(Mouse key);
/// Returns true if the specified gamepad button was released this frame.
bool isReleased(Gamepad key, int id = 0);

/// Returns the direction from the WASD and arrow keys that are currently down.
Vec2 wasd();
/// Returns the direction from the WASD and arrow keys that were pressed this frame.
Vec2 wasdPressed();
/// Returns the direction from the WASD and arrow keys that were released this frame.
Vec2 wasdReleased();

/// Returns the next recently pressed keyboard key.
Keyboard dequeuePressedKey();
/// Returns the next recently pressed character.
dchar dequeuePressedRune();
```

Below are examples showing how to use these input functions to move text.

* Using the Mouse

    ```d
    bool update(float dt) {
        drawText("Text", mouse);
        return false;
    }
    ```

* Using the Arrow Keys

    ```d
    auto position = Vec2(8);

    bool update(float dt) {
        position.x += Keyboard.right.isDown - Keyboard.left.isDown;
        position.y += Keyboard.down.isDown - Keyboard.up.isDown;
        drawText("Text", position);
        return false;
    }
    ```

* Using the WASD Keys

    ```d
    auto position = Vec2(8);

    bool update(float dt) {
        position.x += 'd'.isDown - 'a'.isDown;
        position.y += 's'.isDown - 'w'.isDown;
        drawText("Text", position);
        return false;
    }
    ```

* Using the WASD or Arrow Keys

    ```d
    auto position = Vec2(8);

    bool update(float dt) {
        position += wasd;
        drawText("Text", position);
        return false;
    }
    ```

## Drawing

Parin provides a set of drawing functions. These include:

```d
/// Attaches the given camera and makes it active.
void attach(ref Camera camera, Rounding type = Rounding.none);
/// Attaches the given viewport and makes it active.
void attach(ViewportId viewport);
/// Detaches the currently active camera.
void detach(ref Camera camera);
/// Detaches the currently active viewport.
void detach(ViewportId viewport);
/// Begins a clipping region using the given area.
void beginClip(Rect area);
/// Ends the active clipping region.
void endClip();                                               

/// Draws a rectangle with the specified area and color.
void drawRect(Rect area, Rgba color = white, float thickness = -1.0f);
/// Draws a point at the specified location with the given size and color.
void drawVec2(Vec2 point, Rgba color = white, float thickness = 9.0f);
/// Draws a pixel at the specified location with the given color.
void drawPixel(IVec2 point, Rgba color = white);
/// Draws a circle with the specified area and color.
void drawCirc(Circ area, Rgba color = white, float thickness = -1.0f);
/// Draws a line with the specified area, thickness, and color.
void drawLine(Line area, Rgba color = white, float thickness = 9.0f);

/// Draws the texture at the given position with the specified draw options.
void drawTexture(TextureId texture, Vec2 position, DrawOptions options = DrawOptions());
/// Draws a portion of the specified texture at the given position with the specified draw options.
void drawTextureArea(TextureId texture, Rect area, Vec2 position, DrawOptions options = DrawOptions());
/// Draws a portion of the default texture at the given position with the specified draw options.
void drawTextureArea(Rect area, Vec2 position, DrawOptions options = DrawOptions());
/// Draws a 9-slice from the specified texture area at the given target area.
void drawTextureSlice(TextureId texture, Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions());
/// Draws a 9-slice from the default texture area at the given target area.
void drawTextureSlice(Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions());

/// Draws a portion of the specified viewport at the given position with the specified draw options.
void drawViewportArea(ViewportId viewport, Rect area, Vec2 position, DrawOptions options = DrawOptions());
/// Draws the viewport at the given position with the specified draw options.
void drawViewport(ViewportId viewport, Vec2 position, DrawOptions options = DrawOptions());

/// Draws a single character from the specified font at the given position with the specified draw options.
Vec2 drawRune(FontId font, dchar rune, Vec2 position, DrawOptions options = DrawOptions());
/// Draws a single character from the default font at the given position with the specified draw options.
Vec2 drawRune(dchar rune, Vec2 position, DrawOptions options = DrawOptions());
/// Draws the specified text with the given font at the given position using the provided draw options.
Vec2 drawText(FontId font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());
/// Draws text with the default font at the given position with the provided draw options.
Vec2 drawText(IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());

/// Adds a formatted line to the `dprint*` text.
void dprintfln(A...)(IStr fmtStr, A args);
/// Adds a line to the `dprint*` text.
void dprintln(A...)(A args);
/// Returns the contents of the `dprint*` buffer as an `IStr`.
IStr dprintBuffer();
/// Sets the position of `dprint*` text.
void setDprintPosition(Vec2 value);
/// Sets the drawing options for `dprint*` text.
void setDprintOptions(DrawOptions value);
/// Sets the maximum number of `dprint*` lines. Older lines are removed once this limit is reached. Use 0 for unlimited.
void setDprintLineCountLimit(Sz value);
/// Sets the visibility state of `dprint*` text.
void setDprintVisibility(bool value);
/// Toggles the visibility state of `dprint*` text.
void toggleDprintVisibility();
/// Clears all `dprint*` text.
void clearDprintBuffer();

/// Draws debug engine information at the given position with the provided draw options.
void drawDebugEngineInfo(Vec2 screenPoint, Camera camera = Camera(), DrawOptions options = DrawOptions(), bool isLogging = false);
/// Draws debug tile information at the given position with the provided draw options.
void drawDebugTileInfo(int tileWidth, int tileHeight, Vec2 screenPoint, Camera camera = Camera(), DrawOptions options = DrawOptions(), bool isLogging = false);
```

Functions such as `drawTextureArea(Rect area, ...)` that don't take a texture or font will use `defaultTexture` and `defaultFont` for drawing. To change the defaults, use the `setDefaultTexture` and `setDefaultFont` functions. To change the default filtering mode for textures, fonts or viewports, call `setDefaultFilter`.

### Draw Options

Draw options are used for configuring drawing parameters.

```d
struct DrawOptions {
    /// The origin point of the drawn object. This value can be used to force a specific origin.
    Vec2 origin = Vec2(0.0f);
    /// The scale of the drawn object.
    Vec2 scale = Vec2(1.0f);
    /// The rotation of the drawn object, in degrees.
    float rotation = 0.0f;
    /// The color of the drawn object, in RGBA.
    Rgba color = white;
    /// A value representing the origin point of the drawn object when origin is zero.
    Hook hook = Hook.topLeft;
    /// A value representing flipping orientations.
    Flip flip = Flip.none;
}
```

There is also an additional options type for text drawing.

```d
/// Options for configuring extra drawing parameters for text.
struct TextOptions {
    /// Controls the visibility ratio of the text when visibilityCount is zero, where 0.0 means fully hidden and 1.0 means fully visible.
    float visibilityRatio = 1.0f;
    /// The width of the aligned text. It is used as a hint and is not enforced.
    int alignmentWidth = 0;
    /// Controls the visibility count of the text. This value can be used to force a specific character count.
    ushort visibilityCount = 0;
    /// A value represeting alignment orientations.
    Alignment alignment = Alignment.left;
    /// Indicates whether the content of the text flows in a right-to-left direction.
    bool isRightToLeft = false;
}
```

* Changing the Origin and Scale

    ```d
    bool update(float dt) {
        auto options = DrawOptions(Hook.center);
        options.scale = Vec2(4 + sin(elapsedTime * 4));
        drawText("Text", resolution * Vec2(0.5), options);
        return false;
    }
    ```

* Changing the Origin and Visibility Ratio

    ```d
    bool update(float dt) {
        auto options = DrawOptions(Hook.center);
        auto extra = TextOptions(fmod(elapsedTime, 2.0));
        drawText("Hello.\nThis is some text.", resolution * Vec2(0.5), options, extra);
        return false;
    }
    ```

## Sprites & Tile Maps

Sprites and tile maps can be implemented in various ways.
To avoid enforcing a specific approach, Parin provides optional modules for these features, allowing users to include or omit them as needed.
Parin provides sprite utilities inside the `parin.sprite` module and map utilities inside the `parin.map` module.

## Sound

Parin provides a set of sound functions. These include:

```d
/// Plays the given sound. If the sound is already playing, this has no effect.
void playSound(SoundId sound);
/// Stops playback of the given sound.
void stopSound(SoundId sound);
/// Starts playback of the given sound from the beginning.
void startSound(SoundId sound);
/// Pauses playback of the given sound.
void pauseSound(SoundId sound);
/// Resumes playback of the given sound if it was paused.
void resumeSound(SoundId sound);
/// Toggles whether the sound is playing or stopped.
void toggleSoundIsActive(SoundId sound);
/// Toggles whether the sound is paused or resumed.
void toggleSoundIsPaused(SoundId sound);

/// Returns the current master volume level.
float masterVolume();
/// Sets the master volume level.
void setMasterVolume(float value);
```

Below are examples showing how to use these sound functions.

* Playing a Sound

    ```d
    SoundId sound;

    bool update(float dt) {
        if (Keyboard.space.isPressed) playSound(sound);
        return false;
    }
    ```

## Loading & Saving

Parin provides a set of loading and saving functions. These include:

```d
/// Loads a texture file (PNG) with default filter and wrap modes.
TextureId loadTexture(IStr path);
/// Loads a texture file (PNG) from memory with default filter and wrap modes.
TextureId loadTexture(const(ubyte)[] memory, IStr ext = ".png");

/// Loads a font file (TTF) with default filter and wrap modes.
FontId loadFont(IStr path, int size, int runeSpacing = -1, int lineSpacing = -1, IStr32 runes = "");
/// Loads a font file (TTF) from memory with default filter and wrap modes.
FontId loadFont(const(ubyte)[] memory, int size, int runeSpacing = -1, int lineSpacing = -1, IStr32 runes = "", IStr ext = ".ttf");
/// Loads a font file (TTF) from a texture with default filter and wrap modes.
FontId loadFont(TextureId texture, int tileWidth, int tileHeight);

/// Loads a sound file (WAV, OGG, MP3) with default playback settings.
SoundId loadSound(IStr path, float volume, float pitch, bool canRepeat, float pitchVariance = 1.0f);
/// Loads a viewport with default filter and wrap modes.
ViewportId loadViewport(int width, int height, Rgba color, Blend blend = Blend.alpha);

/// Loads a text file and returns the contents as a list.
LStr loadText(IStr path);
/// Loads a text file into a temporary buffer for the current frame.
IStr loadTempText(IStr path, Sz capacity = defaultEngineLoadOrSaveTextCapacity);
/// Loads a text file into the given buffer.
Fault loadTextIntoBuffer(L = LStr)(IStr path, ref L listBuffer);
/// Saves a text file with the given content.
Fault saveText(IStr path, IStr text);
```

They use the assets path unless the input starts with `/` or `\`, or `isUsingAssetsPath` is false.
Additionally, resources are separated into two groups. Managed and temporary.

### Managed Resources

Managed resources are managed by the engine, meaning they get updated every frame when necessary (e.g. sounds) and can be safely shared throughout the code. These resources use something known as [generational indices](https://lucassardois.medium.com/generational-indices-guide-8e3c5f7fd594).

### Temporary Resources

Temporary resources are only valid for the duration of the current frame.

## Embedding Assets

Assets can be embedded into the binary with D's `import` feature.
DUB projects already pass `-J=assets` to the compiler, so everything in the assets folder is available automatically. For example:

```d
auto atlas = TextureId();

void ready() {
    atlas = loadTexture(cast(ubyte[]) import("atlas.png"));
}
```

## Frame Allocator

The engine provides a frame allocator for temporary memory.
Allocations from it only live for the current frame and are automatically cleared at the end.
This is useful for short-lived data such as strings or small objects that only need to exist for one frame.

```d
/// Allocates raw memory from the frame arena.
void* frameMalloc(Sz size, Sz alignment);
/// Reallocates memory from the frame arena.
void* frameRealloc(void* ptr, Sz oldSize, Sz newSize, Sz alignment);
/// Allocates uninitialized memory for a single value of type `T`.
T* frameMakeBlank(T)();
/// Allocates and initializes a single value of type `T`.
T* frameMake(T)();
/// Allocates and initializes a single value of type `T`.
T* frameMake(T)(const(T) value);
/// Allocates uninitialized memory for an array of type `T` with the given length.
T[] frameMakeSliceBlank(T)(Sz length);
/// Allocates and initializes an array of type `T` with the given length.
T[] frameMakeSlice(T)(Sz length);
/// Allocates and initializes an array of type `T` with the given length.
T[] frameMakeSlice(T)(Sz length, const(T) value);
```

The engine uses this allocator internally for functions like `loadTempText` and `prepareTempText`.

## Memory Tracking

Parin includes a lightweight memory tracking system that can detect leaks or invalid frees in debug builds.
By default, leaks will be printed when the game ends only if they are detected.

```d
/// Returns true if memory tracking logs are enabled.
bool isLoggingMemoryTrackingInfo();
/// Enables or disables memory tracking logs.
void setIsLoggingMemoryTrackingInfo(bool value, IStr filter = "");
```

Example output:

```
Memory Leaks: 4 (total 699 bytes, 5 ignored)
  1 leak, 20 bytes, source/app.d:24
  1 leak, 53 bytes, source/app.d:31
  2 leak, 32 bytes, source/app.d:123
```

The leak summary can be filtered, showing only leaks with paths containing the filter string.
For example, `setIsLoggingMemoryTrackingInfo(true, "app.d")` shows only leaks with `"app.d"` in the path.
You can also ignore specific allocations with `ignoreLeak` like this:

```d
// struct Game { int hp; int mp; }
// Game* game;
game = jokaMake!Game().ignoreLeak();
```

This isn't strictly a Parin feature.
It comes from [Joka](https://github.com/Kapendev/joka), the library Parin uses for memory allocations.
Anything allocated through Joka is automatically tracked.
You can check whether memory tracking is active with `static if (isTrackingMemory)`, and if it is, you can inspect the current tracking state via `_memoryTrackingState`.
`_memoryTrackingState` is thread-local, so each thread has its own separate tracking state.

## Debug Mode

Parin has a debug mode that toggles with the **F3** key by default.

```d
/// Returns true if debug mode is active.
bool isDebugMode();
/// Sets whether debug mode should be active.
void setIsDebugMode(bool value);
/// Toggles the debug mode on or off.
void toggleIsDebugMode();
/// Sets the key that toggles debug mode.
void setDebugModeKey(Keyboard value);
```

Additionally, you can pass an `inspect` function to `runGame`. When debug mode is on, this function runs after `update` and can be used for debug tools. For example:

```d
// It assumes you are using: https://github.com/Kapendev/microui-d
void inspect() {
    if (beginWindow("Window", UiRect(200, 80, 350, 370))) {
        headerAndMembers(game, 125);
        endWindow();
    }
}
mixin runGame!(ready, update, finish, 960, 540, "Parin", inspect, beginUi, endUi);
```

The above code is part of a full example in the [examples](examples/integrations/microui.d).

## Scheduling

A simple scheduling system exists for running functions later or at intervals.
This is useful for timers and background tasks.
Scheduled functions run before `update`.

```d
/// Schedules a task to run every interval.
EngineTaskId every(UpdateFunc func, float interval, int count = -1, bool canCallNow = false);
/// Cancels a scheduled task by its ID.
void cancel(EngineTaskId id);
```

Example:

```d
import parin;

auto text = "GNU!";

bool updateText(float dt) {
    text ~= '!';
    return false;
}

void ready() {
    lockResolution(320, 180);
    every(1, &updateText);
}

bool update(float dt) {
    drawText(text, Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
```
