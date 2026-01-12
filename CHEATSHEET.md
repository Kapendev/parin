# 📋 Parin Cheatsheet (WIP)

This guide highlights the **most commonly used parts** of the `parin.types` and `parin.engine` modules — it's not meant to be full documentation.
If you notice anything missing or want to contribute, feel free to open an [issue](https://github.com/Kapendev/parin/issues)!

## Debug Mode

```d
/// Returns true if debug mode is active.
bool isDebugMode();
/// Returns true when entering debug mode this frame.
bool isEnteringDebugMode();
/// Returns true when exiting debug mode this frame.
bool isExitingDebugMode();
/// Sets whether debug mode should be active
void setIsDebugMode(bool value);
/// Toggles the debug mode on or off.
void toggleIsDebugMode();
/// Sets the key that toggles debug mode.
void setDebugModeKey(Keyboard value);
```

## Window

```d
/// Returns true if the window was resized.
bool isWindowResized();
/// Sets the minimum size of the window.
void setWindowMinSize(int width, int height);
/// Sets the maximum size of the window.
void setWindowMaxSize(int width, int height);
/// Returns the current background color (fill color) of the window.
Rgba windowBackgroundColor();
/// Sets the background color (fill color) of the window.
void setWindowBackgroundColor(Rgba value);
/// Returns the current color of the window borders shown when the aspect ratio is fixed.
Rgba windowBorderColor();
/// Sets the color of the window borders shown when the aspect ratio is fixed.
void setWindowBorderColor(Rgba value);
/// Sets the title of the window.
void setWindowTitle(IStr value);
/// Sets the window icon using an texture file (PNG).
Fault setWindowIconFromFiles(IStr path);

/// Returns the current screen width.
int screenWidth();
/// Returns the current screen height.
int screenHeight();
/// Returns the current screen size.
Vec2 screenSize();
/// Returns the current window width.
int windowWidth();
/// Returns the current window height.
int windowHeight();
/// Returns the current window size.
Vec2 windowSize();
/// Returns the current resolution width.
int resolutionWidth();
/// Returns the current resolution height.
int resolutionHeight();
/// Returns the current resolution.
Vec2 resolution();

/// Returns true if the resolution is locked.
bool isResolutionLocked();
/// Locks the resolution to the given width and height.
void lockResolution(int width, int height);
/// Unlocks the resolution.
void unlockResolution();
/// Toggles resolution lock using the specified width and height.
void toggleResolution(int width, int height);
/// Returns information about the engine viewport, including its size and position.
EngineViewportInfo engineViewportInfo();

/// Returns true if the application is in fullscreen mode.
bool isFullscreen();
/// Sets whether the application should be in fullscreen mode.
void setIsFullscreen(bool value);
/// Toggles fullscreen mode.
void toggleIsFullscreen();
/// Returns true if the cursor is visible.
bool isCursorVisible();
/// Sets whether the cursor should be visible.
void setIsCursorVisible(bool value);
/// Toggles cursor visibility.
void toggleIsCursorVisible();
```

## Time

```d
/// Returns the current frames per second (FPS).
int fps();
/// Returns the maximum frames per second (FPS).
int fpsMax();
/// Sets the maximum frames per second (FPS).
void setFpsMax(int value);
/// Returns the vertical synchronization (VSync) state.
bool vsync();
/// Sets the vertical synchronization (VSync) state.
void setVsync(bool value);
/// Returns the total elapsed time since the application started.
double elapsedTime();
/// Returns the total number of ticks since the application started.
ulong elapsedTicks();
/// Returns the time elapsed since the last frame.
float deltaTime();
```

## Randomness

```d
/// Returns a random integer between 0 and int.max (inclusive).
int randi();
/// Returns a random float between 0.0 and 1.0 (inclusive).
float randf();
/// Randomizes the seed of the random number generator.
void randomize();
/// Sets the random number generator seed to the given value.
void setRandomSeed(int value);
```

## Settings

```d
/// Returns the default filter mode used for textures, fonts and viewports.
Filter defaultFilter();
/// Sets the default filter mode used for textures, fonts and viewports.
void setDefaultFilter(Filter value);
/// Returns the default wrap mode used for textures, fonts and viewports.
Wrap defaultWrap();
/// Sets the default wrap mode used for textures, fonts and viewports.
void setDefaultWrap(Wrap value);
/// Returns the default texture used for null textures.
TextureId defaultTexture();
/// Sets the default texture used for null textures.
void setDefaultTexture(TextureId value);
/// Returns the default texture area size used for the ID version of `drawTextureArea`.
Vec2 defaultTextureAreaSize();
/// Sets the default texture area size used for the ID version of `drawTextureArea`.
void setDefaultTextureAreaSize(Vec2 size);
/// Returns the default font used for null fonts.
FontId defaultFont();
/// Sets the default font used for null fonts.
void setDefaultFont(FontId value);

/// Returns true if drawing is done when using a null texture.
bool isNullTextureVisible();
/// Sets whether drawing should be done when using a null texture.
void setIsNullTextureVisible(bool value);
/// Returns true if drawing is done when using a null font.
bool isNullFontVisible();
/// Sets whether drawing should be done when using a null font.
void setIsNullFontVisible(bool value);

/// Returns true if drawing is snapped to pixel coordinates.
bool isPixelSnapped();
/// Sets whether drawing should snap to pixel coordinates.
void setIsPixelSnapped(bool value);
/// Returns true if drawing is pixel-perfect.
bool isPixelPerfect();
/// Sets whether drawing should be pixel-perfect.
void setIsPixelPerfect(bool value);
```

## Helpers

```d
/// Returns the size of the text.
Vec2 measureTextSize(FontId font, IStr text, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());
/// Converts a scene point to a canvas point using the given camera and resolution.
Vec2 toCanvasPoint(Vec2 point, Camera camera);
/// Converts a canvas point to a scene point using the given camera and resolution.
Vec2 toScenePoint(Vec2 point, Camera camera);

/// Returns the arguments this application was started with.
IStr[] envArgs();
/// Returns the dropped paths from the current frame.
IStr[] droppedPaths();
/// Takes a screenshot and saves it to the given path.
void takeScreenshot(IStr path, bool isUsingLockedResolution = false, bool hasAlpha = false);
/// Takes a screenshot and creates a texture from it that can be used with the `getRequestedScreenshot` function.
void requestScreenshot(bool isUsingLockedResolution = false, bool hasAlpha = false);
/// Returns the texture created by the last screenshot request, if available (true).
bool getRequestedScreenshot(ref TextureId result, bool canFreeGivenTexture);
/// Opens a URL in the default web browser.
void openUrl(IStr url);

/// Returns the last fault from a load or save call.
Fault lastLoadOrSaveFault();
/// Helper for checking the result of a load or save call.
bool didLoadOrSaveSucceed(Fault fault, IStr message);

/// Frees all loaded textures.
void freeAllTextureIds();
/// Frees all loaded fonts.
void freeAllFontIds();
/// Frees all loaded sounds.
void freeAllSoundIds();
/// Frees all loaded viewports.
void freeAllViewportIds();
/// Frees all loaded textures, fonts, sounds, and viewports.
void freeAllResourceIds();
/// Clears all engine tasks.
void clearAllEngineTasks();

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
/// Allocates and initializes an array of type `T` with the given slice.
T[] frameMakeSlice(T)(const(T)[] values);
/// Resizes an array of type `T` with the given slice pointer and length.
T[] frameResizeSlice(T)(T* values, Sz oldLength, Sz newLength);
/// Allocates a temporary text buffer for this frame.
BStr prepareTempText(Sz capacity = defaultEngineLoadOrSaveTextCapacity);

/// Schedules a task to run every interval.
EngineTaskId every(UpdateFunc func, float interval, int count = -1, bool canCallNow = false);
/// Cancels a scheduled task by its ID.
void cancel(EngineTaskId id);
```

## Input

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

## Drawing

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
/// Begins a depth sort. Works only with textures.
void beginDepthSort(DepthSortMode mode = DepthSortMode.topDown);
/// Ends a depth sort. Works only with textures.
void endDepthSort();

/// Draws a rectangle with the specified area and color.
void drawRect(Rect area, Rgba color = white, float thickness = -1.0f);
/// Draws a point at the specified location with the given size and color.
void drawVec2(Vec2 point, Rgba color = white, float thickness = 9.0f);
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
/// Draws a portion of the default texture by ID at the given position with the specified draw options.
void drawTextureArea(int id, Vec2 position, DrawOptions options = DrawOptions());
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

/// Append a formatted line to the overlay text buffer.
void dprintfln(A...)(IStr fmtStr, A args);
/// Append a line to the overlay text buffer.
void dprintln(A...)(A args);
/// Returns the contents of the overlay text buffer.
IStr dprintBuffer();
/// Sets the font of the overlay text.
void setDprintFont(FontId value);
/// Sets the position of the overlay text.
void setDprintPosition(Vec2 value);
/// Sets the drawing options for the overlay text.
void setDprintOptions(DrawOptions value);
/// Sets the maximum number of overlay text lines.
void setDprintLineCountLimit(Sz value);
/// Sets the visibility state of the overlay text.
void setDprintVisibility(bool value);
/// Toggles the visibility state of the overlay text.
void toggleDprintVisibility();
/// Clears the overlay text.
void clearDprintBuffer();
/// Draws the overlay text now instead of at the end of the frame.
void drawDprintBuffer();

/// Draws debug engine information at the given position with the provided draw options.
void drawDebugEngineInfo(Vec2 screenPoint, Camera camera = Camera(), DrawOptions options = DrawOptions(), bool isLogging = false);
/// Draws debug tile information at the given position with the provided draw options.
void drawDebugTileInfo(int tileWidth, int tileHeight, Vec2 screenPoint, Camera camera = Camera(), DrawOptions options = DrawOptions(), bool isLogging = false);
```

## Sound

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

## Loading & Saving

```d
// They use the assets path unless the input starts with `/` or `\`, or `isUsingAssetsPath` is false.
// Path separators are also normalized to the platform's native format.

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
/// Saves an image taken from the given viewport.
Fault saveScreenshot(IStr path, ViewportId viewport, bool hasAlpha);
```

## Data Structures

```d
/// A texture identifier.
struct TextureId {
    /// Checks whether the resource is null (default value).
    bool isNull();
    /// Checks whether the resource is valid (loaded). Null is invalid.
    bool isValid();
    /// Returns this resource if valid, or asserts with the given message if not.
    TextureId validate(IStr message = defaultEngineValidateErrorMessage);
    /// Returns the filter mode.
    Filter filter();
    /// Sets the filter mode.
    void setFilter(Filter value);
    /// Returns the wrap mode.
    Wrap wrap();
    /// Sets the wrap mode.
    void setWrap(Wrap value);
    /// Returns the width in pixels.
    int width();
    /// Returns the height in pixels.
    int height();
    /// Returns the size in pixels.
    Vec2 size();
    /// Frees the resource and resets the identifier to null.
    void free();
}

/// A font identifier.
struct FontId {
    /// Checks whether the resource is null (default value).
    bool isNull();
    /// Checks whether the resource is valid (loaded). Null is invalid.
    bool isValid();
    /// Returns this resource if valid, or asserts with the given message if not.
    FontId validate(IStr message = defaultEngineValidateErrorMessage);
    /// Returns the filter mode.
    Filter filter();
    /// Sets the filter mode.
    void setFilter(Filter value);
    /// Returns the wrap mode.
    Wrap wrap();
    /// Sets the wrap mode.
    void setWrap(Wrap value);
    /// Returns the font size in pixels.
    int size();
    /// Returns the spacing between characters in pixels.
    int runeSpacing();
    /// Sets the spacing between characters in pixels.
    void setRuneSpacing(int value);
    /// Returns the spacing between lines in pixels.
    int lineSpacing();
    /// Sets the spacing between lines in pixels.
    void setLineSpacing(int value);
    /// Returns the glyph information for the given rune.
    GlyphInfo glyphInfo(int rune);
    /// Frees the resource and resets the identifier to null.
    void free();
}

/// A sound identifier.
struct SoundId {
    /// Checks whether the resource is null (default value).
    bool isNull();
    /// Checks whether the resource is valid (loaded). Null is invalid.
    bool isValid();
    /// Returns this resource if valid, or asserts with the given message if not.
    SoundId validate(IStr message = defaultEngineValidateErrorMessage);
    /// Returns the volume. The default value is 1.0 (normal level).
    float volume();
    /// Sets the volume. The default value is 1.0 (normal level).
    void setVolume(float value);
    /// Returns the pan. The default value is 0.5 (center).
    float pan();
    /// Sets the pan. The default value is 0.5 (center).
    void setPan(float value);
    /// Returns the pitch. The default value is 1.0 (base level).
    float pitch();
    /// Sets the pitch. The default value is 1.0 (base level).
    void setPitch(float value, bool canUpdatePitchVarianceBase = false);
    /// Returns the pitch variance. The default value is 1.0 (no variation).
    float pitchVariance();
    /// Sets the pitch variance. The default value is 1.0 (no variation).
    void setPitchVariance(float value);
    /// Returns the pitch variance base. The default value is 1.0 (base level).
    float pitchVarianceBase();
    /// Sets the pitch variance base. The default value is 1.0 (base level).
    void setPitchVarianceBase(float value);
    /// Returns true if the sound is set to repeat.
    bool canRepeat();
    /// Sets whether the sound should repeat.
    void setCanRepeat(bool value);
    /// Returns true if the sound is currently active (playing).
    bool isActive();
    /// Returns true if the sound is currently paused.
    bool isPaused();
    /// Returns the current playback time in seconds.
    float time();
    /// Returns the total duration in seconds.
    float duration();
    /// Returns the progress. The value is between 0.0 and 1.0 (inclusive).
    float progress();
    /// Frees the resource and resets the identifier to null.
    void free();
}

/// A viewport identifier.
struct ViewportId {
    /// Checks whether the resource is null (default value).
    bool isNull();
    /// Checks whether the resource is valid (loaded). Null is invalid.
    bool isValid();
    /// Returns this resource if valid, or asserts with the given message if not.
    ViewportId validate(IStr message = defaultEngineValidateErrorMessage);
    /// Returns the filter mode.
    Filter filter();
    /// Sets the filter mode.
    void setFilter(Filter value);
    /// Returns the wrap mode.
    Wrap wrap();
    /// Sets the wrap mode.
    void setWrap(Wrap value);
    /// Returns the blend mode.
    Blend blend();
    /// Sets the blend mode.
    void setBlend(Blend value);
    /// Returns the color in RGBA.
    Rgba color();
    /// Sets the color in RGBA.
    void setColor(Rgba value);
    /// Returns the width in pixels.
    int width();
    /// Returns the height in pixels.
    int height();
    /// Returns the size in pixels.
    Vec2 size();
    /// Returns true if the viewport has never been used (attached).
    bool isFirstUse();
    /// Returns true if the viewport is attached.
    bool isAttached();
    /// Resizes the viewport. Internally, this creates a new texture, so avoid calling it while the viewport is in use.
    void resize(int newWidth, int newHeight);
    /// Frees the resource and resets the identifier to null.
    void free();
}

/// A set of 4 integer margins.
struct Margin {
    /// The left side.
    int left;
    /// The top side.
    int top;
    /// The right side.
    int right;
    /// The bottom side.
    int bottom;

    this(int left, int top, int right, int bottom);
    this(int left);
}

/// Options for configuring drawing parameters.
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

    this(float rotation, Hook hook = Hook.topLeft);
    this(Vec2 scale, Hook hook = Hook.topLeft);
    this(Rgba color, Hook hook = Hook.topLeft);
    this(Flip flip, Hook hook = Hook.topLeft);
    this(Hook hook);
}

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

    this(float visibilityRatio);
    this(Alignment alignment, int alignmentWidth = 0);
}

/// A camera.
struct Camera {
    /// The position of the camera.
    Vec2 position;
    /// The offset of the view area of the camera.
    Vec2 offset;
    /// The rotation angle of the camera, in degrees.
    float rotation = 0.0f;
    /// The zoom level of the camera.
    float scale = 1.0f;
    /// Determines if the camera's origin is at the center instead of the top left.
    bool isCentered;
    /// Indicates whether the camera is currently in use.
    bool isAttached;

    this(Vec2 position, bool isCentered = false);
    this(float x, float y, bool isCentered = false);
}
```

## Constants

```d
/// Flipping orientations.
enum Flip : ubyte {
    none, /// No flipping.
    x,    /// Flipped along the X-axis.
    y,    /// Flipped along the Y-axis.
    xy,   /// Flipped along both X and Y axes.
}

/// Alignment orientations.
enum Alignment : ubyte {
    left,   /// Align to the left.
    center, /// Align to the center.
    right,  /// Align to the right.
}

/// Texture filtering modes.
enum Filter : ubyte {
    nearest, /// Nearest neighbor filtering (blocky).
    linear,  /// Bilinear filtering (smooth).
}

/// Texture wrapping modes.
enum Wrap : ubyte {
    clamp,  /// Clamps texture.
    repeat, /// Repeats texture.
}

/// Texture blending modes.
enum Blend : ubyte {
    alpha,      /// Standard alpha blending.
    additive,   /// Adds colors for light effects.
    multiplied, /// Multiplies colors for shadows.
    add,        /// Simply adds colors.
    sub,        /// Simply subtracts colors.
}

/// A limited set of keyboard keys.
enum Keyboard : ubyte {
    none,         /// Not a key.
    apostrophe,   /// The `'` key.
    comma,        /// The `,` key.
    minus,        /// The `-` key.
    period,       /// The `.` key.
    slash,        /// The `/` key.
    n0,           /// The 0 key.
    n1,           /// The 1 key.
    n2,           /// The 2 key.
    n3,           /// The 3 key.
    n4,           /// The 4 key.
    n5,           /// The 5 key.
    n6,           /// The 6 key.
    n7,           /// The 7 key.
    n8,           /// The 8 key.
    n9,           /// The 9 key.
    nn0,          /// The 0 key on the numpad.
    nn1,          /// The 1 key on the numpad.
    nn2,          /// The 2 key on the numpad.
    nn3,          /// The 3 key on the numpad.
    nn4,          /// The 4 key on the numpad.
    nn5,          /// The 5 key on the numpad.
    nn6,          /// The 6 key on the numpad.
    nn7,          /// The 7 key on the numpad.
    nn8,          /// The 8 key on the numpad.
    nn9,          /// The 9 key on the numpad.
    semicolon,    /// The `;` key.
    equal,        /// The `=` key.
    a,            /// The A key.
    b,            /// The B key.
    c,            /// The C key.
    d,            /// The D key.
    e,            /// The E key.
    f,            /// The F key.
    g,            /// The G key.
    h,            /// The H key.
    i,            /// The I key.
    j,            /// The J key.
    k,            /// The K key.
    l,            /// The L key.
    m,            /// The M key.
    n,            /// The N key.
    o,            /// The O key.
    p,            /// The P key.
    q,            /// The Q key.
    r,            /// The R key.
    s,            /// The S key.
    t,            /// The T key.
    u,            /// The U key.
    v,            /// The V key.
    w,            /// The W key.
    x,            /// The X key.
    y,            /// The Y key.
    z,            /// The Z key.
    bracketLeft,  /// The `[` key.
    bracketRight, /// The `]` key.
    backslash,    /// The `\` key.
    grave,        /// The `` ` `` key.
    space,        /// The space key.
    esc,          /// The escape key.
    enter,        /// The enter key.
    tab,          /// The tab key.
    backspace,    /// THe backspace key.
    insert,       /// The insert key.
    del,          /// The delete key.
    right,        /// The right arrow key.
    left,         /// The left arrow key.
    down,         /// The down arrow key.
    up,           /// The up arrow key.
    pageUp,       /// The page up key.
    pageDown,     /// The page down key.
    home,         /// The home key.
    end,          /// The end key.
    capsLock,     /// The caps lock key.
    scrollLock,   /// The scroll lock key.
    numLock,      /// The num lock key.
    printScreen,  /// The print screen key.
    pause,        /// The pause/break key.
    shift,        /// The left shift key.
    shiftRight,   /// The right shift key.
    ctrl,         /// The left control key.
    ctrlRight,    /// The right control key.
    alt,          /// The left alt key.
    altRight,     /// The right alt key.
    win,          /// The left windows/super/command key.
    winRight,     /// The right windows/super/command key.
    menu,         /// The menu key.
    f1,           /// The f1 key.
    f3,           /// The f3 key.
    f2,           /// The f2 key.
    f4,           /// The f4 key.
    f5,           /// The f5 key.
    f6,           /// The f6 key.
    f7,           /// The f7 key.
    f8,           /// The f8 key.
    f9,           /// The f9 key.
    f10,          /// The f10 key.
    f11,          /// The f11 key.
    f12,          /// The f12 key.
}

/// A limited set of mouse keys.
enum Mouse : ubyte {
    none,   /// Not a button.
    left,   /// The left mouse button.
    right,  /// The right mouse button.
    middle, /// The middle mouse button.
}

/// A limited set of gamepad buttons.
enum Gamepad : ubyte {
    none,   /// Not a button.
    left,   /// The left button.
    right,  /// The right button.
    up,     /// The up button.
    down,   /// The down button.
    y,      /// The Xbox y, PlayStation triangle and Nintendo x button.
    x,      /// The Xbox x, PlayStation square and Nintendo y button.
    a,      /// The Xbox a, PlayStation cross and Nintendo b button.
    b,      /// The Xbox b, PlayStation circle and Nintendo a button.
    lt,     /// The left trigger button.
    lb,     /// The left bumper button.
    lsb,    /// The left stick button.
    rt,     /// The right trigger button.
    rb,     /// The right bumper button.
    rsb,    /// The right stick button.
    back,   /// The back button.
    start,  /// The start button.
    middle, /// The middle button.
}

/// Depth sorting modes.
enum DepthSortMode : ubyte {
    topDown,        /// Sorts with: Layer + Y + Call Order
    topDownFast,    /// Sorts with: Layer + Y
    topDownFastest, /// Sorts with: Y
    layered,        /// Sorts with: Layer + Call Order
}
```
