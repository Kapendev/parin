# 📋 Parin Cheatsheet (WIP)

This guide highlights the **most commonly used parts** of each module — it's not meant to be full documentation.
If you notice anything missing or want to contribute, feel free to open an [issue](https://github.com/Kapendev/parin/issues)!

## 📦 `parin.engine`

### Basic

```d
bool vsync();
void setVsync(bool value);
int fps();
int fpsMax();
void setFpsMax(int value);
float deltaTime();
double elapsedTime();
long elapsedTickCount();

int screenWidth();
int screenHeight();
Vec2 screenSize();
int windowWidth();
int windowHeight();
Vec2 windowSize();
int resolutionWidth();
int resolutionHeight();
Vec2 resolution();

void setBackgroundColor(Rgba value);
void setBorderColor(Rgba value);
void lockResolution(int width, int height);
void unlockResolution();
void toggleResolution(int width, int height);
bool isWindowResized();
void setWindowMinSize(int width, int height);
void setWindowMaxSize(int width, int height);
Fault setWindowIconFromFiles(IStr path);

bool isPixelSnapped();
void setIsPixelSnapped(bool value);
bool isPixelPerfect();
void setIsPixelPerfect(bool value);
bool isFullscreen();
void setIsFullscreen(bool value);
void toggleIsFullscreen();
bool isCursorVisible();
void setIsCursorVisible(bool value);
void toggleIsCursorVisible();

bool isEmptyTextureVisible();
void setIsEmptyTextureVisible(bool value);
bool isEmptyFontVisible();
void setIsEmptyFontVisible(bool value);

bool isLoggingLoadSaveFaults();
void setIsLoggingLoadSaveFaults(bool value);
bool isLoggingMemoryTracking();
void setIsLoggingMemoryTrackingInfo(bool value, IStr filter = "");

bool isDebugMode();
void setIsDebugMode(bool value);
void toggleIsDebugMode();
void setDebugModeKey(Keyboard value);

TaskId every(float interval, EngineUpdateFunc func, int count = -1, bool canCallNow = false);
void cancel(TaskId id);

bool isUsingAssetsPath();
void setIsUsingAssetsPath(bool value);
IStr assetsPath();
IStr toAssetsPath(IStr path);
void setAssetsPath(IStr path);

Filter defaultFilter();
void setDefaultFilter(Filter value);
Wrap defaultWrap();
void setDefaultWrap(Wrap value);
TextureId defaultTexture();
void setDefaultTexture(TextureId value);
FontId defaultFont();
void setDefaultFont(FontId value);

Texture toTexture(const(ubyte)[] from, IStr ext = ".png");
Font toFont(const(ubyte)[] from, int size, int runeSpacing = -1, int lineSpacing = -1, IStr32 runes = null, IStr ext = ".ttf");
Font toFontAscii(Texture from, int tileWidth, int tileHeight);
TextureId toTextureId(Texture from);
FontId toFontId(Font from);
SoundId toSoundId(Sound from);

Flip oppositeFlip(Flip flip, Flip fallback);
Vec2 measureTextSize(FontId font, IStr text, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());
IStr[] envArgs();
IStr[] droppedFilePaths();
void openUrl(IStr url = "https://github.com/Kapendev/parin");

void* frameMalloc(Sz size, Sz alignment);
void* frameRealloc(void* ptr, Sz oldSize, Sz newSize, Sz alignment);
T* frameMakeBlank(T)();
T* frameMake(T)(const(T) value = T.init);
T[] frameMakeSliceBlank(T)(Sz length);
T[] frameMakeSlice(T)(Sz length, const(T) value = T.init);
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
void drawText(FontId font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());
void drawText(IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());

void drawViewport(Viewport viewport, Vec2 position, DrawOptions options = DrawOptions());
void drawViewportArea(Viewport viewport, Rect area, Vec2 position, DrawOptions options = DrawOptions());

void drawDebugEngineInfo(Vec2 screenPoint, Camera camera = Camera(), DrawOptions options = DrawOptions(), bool isLogging = false);
void drawDebugTileInfo(int tileWidth, int tileHeight, Vec2 screenPoint, Camera camera = Camera(), DrawOptions options = DrawOptions(), bool isLogging = false);
```

### Sound

```d
float masterVolume();
void setMasterVolume(float value);

void playSound(SoundId sound);
void stopSound(SoundId sound);
void pauseSound(SoundId sound);
void resumeSound(SoundId sound);
void startSound(SoundId sound);
void toggleSoundIsActive(SoundId sound);
void toggleSoundIsPaused(SoundId sound);
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
Fault loadRawTextIntoBuffer(IStr path, ref LStr buffer);
Fault saveText(IStr path, IStr text);
```

### Randomness

```d
int randi();
float randf();
void randomize();
void setRandomSeed(int value);
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
    Vec2 origin(Viewport viewport = Viewport());
    Rect area(Viewport viewport = Viewport());
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
enum Flip : ubyte {
    none,
    x,
    y,
    xy,
}

enum Alignment : ubyte {
    left,
    center,
    right,
}

enum Filter : ubyte {
    nearest,
    linear,
}

enum Wrap : ubyte {
    clamp,
    repeat,
}

enum Blend : ubyte {
    alpha,
    additive,
    multiplied,
    add,
    sub,
}

enum Keyboard : ushort {
    none,
    apostrophe,
    comma,
    minus,
    period,
    slash,
    n0,
    n1,
    n2,
    n3,
    n4,
    n5,
    n6,
    n7,
    n8,
    n9,
    nn0,
    nn1,
    nn2,
    nn3,
    nn4,
    nn5,
    nn6,
    nn7,
    nn8,
    nn9,
    semicolon,
    equal,
    a,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,
    j,
    k,
    l,
    m,
    n,
    o,
    p,
    q,
    r,
    s,
    t,
    u,
    v,
    w,
    x,
    y,
    z,
    bracketLeft,
    bracketRight,
    backslash,
    grave,
    space,
    esc,
    enter,
    tab,
    backspace,
    insert,
    del,
    right,
    left,
    down,
    up,
    pageUp,
    pageDown,
    home,
    end,
    capsLock,
    scrollLock,
    numLock,
    printScreen,
    pause,
    shift,
    shiftRight,
    ctrl,
    ctrlRight,
    alt,
    altRight,
    win,
    winRight,
    menu,
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
}

enum Mouse : ushort {
    none,
    left,
    right,
    middle,
}

enum Gamepad : ushort {
    none,
    left,
    right,
    up,
    down,
    y,
    x,
    a,
    b,
    lt,
    lb,
    lsb,
    rt,
    rb,
    rsb,
    back,
    start,
    middle,
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
