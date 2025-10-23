# 📋 Parin Cheatsheet (WIP)

This guide highlights the **most commonly used parts** of each module — it's not meant to be full documentation.
If you notice anything missing or want to contribute, feel free to open an [issue](https://github.com/Kapendev/parin/issues)!

## 📦 `parin.engine`

### Basic

```d
// Time-related functions
bool vsync();
void setVsync(bool value);
int fps();
int fpsMax();
void setFpsMax(int value);
float deltaTime();
double elapsedTime();
long elapsedTickCount();

// Screen-related functions
int screenWidth();
int screenHeight();
Vec2 screenSize();

// Window-related functions
int windowWidth();
int windowHeight();
Vec2 windowSize();
bool isWindowResized();
void setWindowMinSize(int width, int height);
void setWindowMaxSize(int width, int height);
Fault setWindowIconFromFiles(IStr path);
void setBackgroundColor(Rgba value);
void setBorderColor(Rgba value);
bool isFullscreen();
void setIsFullscreen(bool value);
void toggleIsFullscreen();
bool isCursorVisible();
void setIsCursorVisible(bool value);
void toggleIsCursorVisible();

// Resolution-related functions
int resolutionWidth();
int resolutionHeight();
Vec2 resolution();
void lockResolution(int width, int height);
void unlockResolution();
void toggleResolution(int width, int height);

// Drawing-related functions
bool isPixelSnapped();
void setIsPixelSnapped(bool value);
bool isPixelPerfect();
void setIsPixelPerfect(bool value);
bool isEmptyTextureVisible();
void setIsEmptyTextureVisible(bool value);
bool isEmptyFontVisible();
void setIsEmptyFontVisible(bool value);
Filter defaultFilter();
void setDefaultFilter(Filter value);
Wrap defaultWrap();
void setDefaultWrap(Wrap value);
TextureId defaultTexture();
void setDefaultTexture(TextureId value);
FontId defaultFont();
void setDefaultFont(FontId value);

// Randomness-related functions
int randi();
float randf();
void randomize();
void setRandomSeed(int value);

// Frame allocator functions
void* frameMalloc(Sz size, Sz alignment);
void* frameRealloc(void* ptr, Sz oldSize, Sz newSize, Sz alignment);
T* frameMakeBlank(T)();
T* frameMake(T)(const(T) value = T.init);
T[] frameMakeSliceBlank(T)(Sz length);
T[] frameMakeSlice(T)(Sz length, const(T) value = T.init);

// Debug-related functions
bool isLoggingLoadSaveFaults();
void setIsLoggingLoadSaveFaults(bool value);
bool isLoggingMemoryTrackingInfo();
void setIsLoggingMemoryTrackingInfo(bool value, IStr filter = "");
bool isDebugMode();
void setIsDebugMode(bool value);
void toggleIsDebugMode();
void setDebugModeKey(Keyboard value);

// Scheduling-related functions
TaskId every(float interval, EngineUpdateFunc func, int count = -1, bool canCallNow = false);
void cancel(TaskId id);

// Path-related functions
bool isUsingAssetsPath();
void setIsUsingAssetsPath(bool value);
IStr assetsPath();
IStr toAssetsPath(IStr path);
void setAssetsPath(IStr path);

// Resource-related functions
Texture toTexture(const(ubyte)[] from, IStr ext = ".png");
Font toFont(const(ubyte)[] from, int size, int runeSpacing = -1, int lineSpacing = -1, IStr32 runes = null, IStr ext = ".ttf");
Font toFontAscii(Texture from, int tileWidth, int tileHeight);
TextureId toTextureId(Texture from);
FontId toFontId(Font from);
SoundId toSoundId(Sound from);

// Other
Flip oppositeFlip(Flip flip, Flip fallback);
Vec2 measureTextSize(FontId font, IStr text, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());
IStr[] envArgs();
IStr[] droppedFilePaths();
void openUrl(IStr url = "https://github.com/Kapendev/parin");
```

### Input

```d
bool isDown(char key);
bool isDown(Keyboard key);
bool isDown(Mouse key);
bool isDown(Gamepad key, int id = 0);

bool isPressed(char key);
bool isPressed(Keyboard key);
bool isPressed(Mouse key);
bool isPressed(Gamepad key, int id = 0);

bool isReleased(char key);
bool isReleased(Keyboard key);
bool isReleased(Mouse key);
bool isReleased(Gamepad key, int id = 0);

Vec2 wasd();
Vec2 wasdPressed();
Vec2 wasdReleased();

Vec2 mouse();
Vec2 deltaMouse();
float deltaWheel();

Keyboard dequeuePressedKey();
dchar dequeuePressedRune();
```

### Drawing

```d
void drawRect(Rect area, Rgba color = white);
void drawHollowRect(Rect area, float thickness, Rgba color = white);
void drawCirc(Circ area, Rgba color = white);
void drawHollowCirc(Circ area, float thickness, Rgba color = white);
void drawVec2(Vec2 point, float size, Rgba color = white);
void drawLine(Line area, float size, Rgba color = white);

void drawTexture(TextureId texture, Vec2 position, DrawOptions options = DrawOptions());
void drawTextureArea(TextureId texture, Rect area, Vec2 position, DrawOptions options = DrawOptions());
void drawTextureArea(Rect area, Vec2 position, DrawOptions options = DrawOptions());
void drawTextureSlice(TextureId texture, Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions());
void drawTextureSlice(Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions());

void drawRune(FontId font, dchar rune, Vec2 position, DrawOptions options = DrawOptions());
void drawRune(dchar rune, Vec2 position, DrawOptions options = DrawOptions());
Vec2 drawText(FontId font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());
Vec2 drawText(IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());

void drawViewport(ref Viewport viewport, Vec2 position, DrawOptions options = DrawOptions());
void drawViewportArea(ref Viewport viewport, Rect area, Vec2 position, DrawOptions options = DrawOptions());

void drawDebugEngineInfo(Vec2 screenPoint, Camera camera = Camera(), DrawOptions options = DrawOptions(), bool isLogging = false);
void drawDebugTileInfo(int tileWidth, int tileHeight, Vec2 screenPoint, Camera camera = Camera(), DrawOptions options = DrawOptions(), bool isLogging = false);

void dprintfln(A...)(IStr fmtStr, A args);
void dprintln(A...)(A args);
IStr dprintBuffer();
void setDprintPosition(Vec2 value);
void setDprintOptions(DrawOptions value);
void setDprintLineCountLimit(Sz value);
void setDprintVisibility(bool value);
void toggleDprintVisibility();
void clearDprintBuffer();
```

### Sound

```d
void playSound(SoundId sound);
void stopSound(SoundId sound);
void pauseSound(SoundId sound);
void resumeSound(SoundId sound);
void startSound(SoundId sound);
void toggleSoundIsActive(SoundId sound);
void toggleSoundIsPaused(SoundId sound);

float masterVolume();
void setMasterVolume(float value);
```

### Loading & Saving

```d
TextureId loadTexture(IStr path);
FontId loadFont(IStr path, int size, int runeSpacing = -1, int lineSpacing = -1, IStr32 runes = null);
FontId loadFontFromTexture(IStr path, int tileWidth, int tileHeight);
SoundId loadSound(IStr path, float volume, float pitch, bool canRepeat = false, float pitchVariance = 1.0f);
Fault lastLoadFault();

Maybe!IStr loadTempText(IStr path);
Maybe!LStr loadRawText(IStr path);
Fault loadRawTextIntoBuffer(L = LStr)(IStr path, ref L listBuffer);
Fault saveText(IStr path, IStr text);

BStr prepareTempText();
```

### Data Structures

```d
struct Margin {
    int left;
    int top;
    int right;
    int bottom;

    this(int left, int top, int right, int bottom);
    this(int left);
}

struct DrawOptions {
    Vec2 origin;
    Vec2 scale;
    float rotation;
    Rgba color;
    Hook hook;
    Flip flip;

    this(float rotation, Hook hook = Hook.topLeft);
    this(Vec2 scale, Hook hook = Hook.topLeft);
    this(Rgba color, Hook hook = Hook.topLeft);
    this(Flip flip, Hook hook = Hook.topLeft);
    this(Hook hook);
}

struct TextOptions {
    float visibilityRatio;
    int alignmentWidth;
    ushort visibilityCount;
    Alignment alignment;
    bool isRightToLeft;

    this(float visibilityRatio);
    this(Alignment alignment, int alignmentWidth = 0);
}

struct TextureId {
    GenIndex data;

    int width();
    int height();
    Vec2 size();
    void setFilter(Filter value);
    void setWrap(Wrap value);
    bool isValid();
    TextureId validate(IStr message = defaultEngineValidateErrorMessage);
    ref Texture get();
    Texture getOr();
    void free();
}

struct FontId {
    GenIndex data;

    int runeSpacing();
    int lineSpacing();
    int size();
    void setFilter(Filter value);
    void setWrap(Wrap value);
    bool isValid();
    FontId validate(IStr message = defaultEngineValidateErrorMessage);
    ref Font get();
    Font getOr();
    void free();
}

struct SoundId {
    GenIndex data;

    float pitchVariance();
    void setPitchVariance(float value);
    float pitchVarianceBase();
    void setPitchVarianceBase(float value);
    bool canRepeat();
    bool isActive();
    bool isPaused();
    float time();
    float duration();
    float progress();
    void setVolume(float value);
    void setPitch(float value);
    void setPan(float value);
    void setCanRepeat(bool value);
    bool isValid();
    SoundId validate(IStr message = defaultEngineValidateErrorMessage);
    ref Sound get();
    Sound getOr();
    void free();
}

struct Camera {
    Vec2 position;
    Vec2 offset;
    float rotation;
    float scale;
    bool isCentered;
    bool isAttached;

    this(Vec2 position, bool isCentered = false);
    this(float x, float y, bool isCentered = false);
    ref float x();
    ref float y();
    Vec2 sum();
    Hook hook();
    Vec2 origin();
    Vec2 origin(ref Viewport viewport);
    Rect area();
    Rect area(ref Viewport viewport);
    Vec2 topLeftPoint();
    Vec2 topPoint();
    Vec2 topRightPoint();
    Vec2 leftPoint();
    Vec2 centerPoint();
    Vec2 rightPoint();
    Vec2 bottomLeftPoint();
    Vec2 bottomPoint();
    Vec2 bottomRightPoint();
    void followPosition(Vec2 target, float speed);
    void followPositionWithSlowdown(Vec2 target, float slowdown);
    void followScale(float target, float speed);
    void followScaleWithSlowdown(float target, float slowdown);
    void attach();
    void detach();
}

struct Viewport {
    rl.RenderTexture2D data;
    Rgba color;
    Blend blend;
    bool isAttached;

    this(Rgba color, Blend blend = Blend.alpha);
    bool isEmpty();
    int width();
    int height();
    Vec2 size();
    void resize(int newWidth, int newHeight);
    void attach();
    void detach();
    void setFilter(Filter value);
    void setWrap(Wrap value);
    void free();
}
```

### Constants

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
enum Keyboard : ushort {
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
enum Mouse : ushort {
    none,   /// Not a button.
    left,   /// The left mouse button.
    right,  /// The right mouse button.
    middle, /// The middle mouse button.
}

/// A limited set of gamepad buttons.
enum Gamepad : ushort {
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
```

## 📦 `parin.timer`

### Data Structures

```d
struct Timer {
    float duration;
    float pauseTime;
    float startTime;
    float stopTimeElapsedTimeBuffer;
    bool canRepeat;

    this(float duration, bool canRepeat = false);
    bool isPaused();
    bool isActive();
    bool hasStarted();
    bool hasStopped();
    void start(float newDuration = -1.0f);
    void stop();
    void toggleIsActive();
    void pause();
    void resume();
    void toggleIsPaused();
    float time();
    float timeLeft();
    void setTime(float newTime);
}
```

## 📦 `parin.palettes`

### Constants

```d
enum Wisp2 : Rgba {
    black,
    white,
}

enum Gb4 : Rgba {
    black,
    darkGray,
    lightGray,
    white,
}

enum Nes8 : Rgba {
    black,
    brown,
    purple,
    red,
    green,
    blue,
    yellow,
    white,
}

enum Pico8 : Rgba {
    black,
    navy,
    maroon,
    darkGreen,
    brown,
    darkGray,
    lightGray,
    white,
    red,
    orange,
    yellow,
    lightGreen,
    blue,
    purple,
    pink,
    peach,
}
```
