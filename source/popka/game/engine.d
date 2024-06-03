// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The engine module functions as a lightweight 2D game engine.

module popka.game.engine;

import ray = popka.vendor.ray;
import popka.core;

version (WebAssembly) {
    private {
        @trusted @nogc nothrow extern(C):

        void emscripten_set_main_loop(void* ptr, int fps, int loop);
    }
}

@trusted @nogc nothrow:

PopkaState popkaState;

enum defaultFPS = 60;
enum defaultBackgroundColor = toRGB(0x2A363A);
enum toggleFullscreenWaitTime = 0.135f;

enum Flip : ubyte {
    none,
    x,
    y,
    xy,
}

enum Filter : ubyte {
    nearest,
    linear,
}

enum Keyboard {
    a = ray.KEY_A,
    b = ray.KEY_B,
    c = ray.KEY_C,
    d = ray.KEY_D,
    e = ray.KEY_E,
    f = ray.KEY_F,
    g = ray.KEY_G,
    h = ray.KEY_H,
    i = ray.KEY_I,
    j = ray.KEY_J,
    k = ray.KEY_K,
    l = ray.KEY_L,
    m = ray.KEY_M,
    n = ray.KEY_N,
    o = ray.KEY_O,
    p = ray.KEY_P,
    q = ray.KEY_Q,
    r = ray.KEY_R,
    s = ray.KEY_S,
    t = ray.KEY_T,
    u = ray.KEY_U,
    v = ray.KEY_V,
    w = ray.KEY_W,
    x = ray.KEY_X,
    y = ray.KEY_Y,
    z = ray.KEY_Z,
    n0 = ray.KEY_ZERO,
    n1 = ray.KEY_ONE,
    n2 = ray.KEY_TWO,
    n3 = ray.KEY_THREE,
    n4 = ray.KEY_FOUR,
    n5 = ray.KEY_FIVE,
    n6 = ray.KEY_SIX,
    n7 = ray.KEY_SEVEN,
    n8 = ray.KEY_EIGHT,
    n9 = ray.KEY_NINE,
    nn0 = ray.KEY_KP_0,
    nn1 = ray.KEY_KP_1,
    nn2 = ray.KEY_KP_2,
    nn3 = ray.KEY_KP_3,
    nn4 = ray.KEY_KP_4,
    nn5 = ray.KEY_KP_5,
    nn6 = ray.KEY_KP_6,
    nn7 = ray.KEY_KP_7,
    nn8 = ray.KEY_KP_8,
    nn9 = ray.KEY_KP_9,
    f1 = ray.KEY_F1,
    f2 = ray.KEY_F2,
    f3 = ray.KEY_F3,
    f4 = ray.KEY_F4,
    f5 = ray.KEY_F5,
    f6 = ray.KEY_F6,
    f7 = ray.KEY_F7,
    f8 = ray.KEY_F8,
    f9 = ray.KEY_F9,
    f10 = ray.KEY_F10,
    f11 = ray.KEY_F11,
    f12 = ray.KEY_F12,
    left = ray.KEY_LEFT,
    right = ray.KEY_RIGHT,
    up = ray.KEY_UP,
    down = ray.KEY_DOWN,
    esc = ray.KEY_ESCAPE,
    enter = ray.KEY_ENTER,
    tab = ray.KEY_TAB,
    space = ray.KEY_SPACE,
    backspace = ray.KEY_BACKSPACE,
    shift = ray.KEY_LEFT_SHIFT,
    ctrl = ray.KEY_LEFT_CONTROL,
    alt = ray.KEY_LEFT_ALT,
    win = ray.KEY_LEFT_SUPER,
}

enum Mouse {
    left = ray.MOUSE_BUTTON_LEFT,
    right = ray.MOUSE_BUTTON_RIGHT,
    middle = ray.MOUSE_BUTTON_MIDDLE,
}

enum Gamepad {
    left = ray.GAMEPAD_BUTTON_LEFT_FACE_LEFT,
    right = ray.GAMEPAD_BUTTON_LEFT_FACE_RIGHT,
    up = ray.GAMEPAD_BUTTON_LEFT_FACE_UP,
    down = ray.GAMEPAD_BUTTON_LEFT_FACE_DOWN,
    y = ray.GAMEPAD_BUTTON_RIGHT_FACE_UP,
    x = ray.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT,
    a = ray.GAMEPAD_BUTTON_RIGHT_FACE_DOWN,
    b = ray.GAMEPAD_BUTTON_RIGHT_FACE_LEFT,
    lt = ray.GAMEPAD_BUTTON_LEFT_TRIGGER_2,
    lb = ray.GAMEPAD_BUTTON_LEFT_TRIGGER_1,
    lsb = ray.GAMEPAD_BUTTON_LEFT_THUMB,
    rt = ray.GAMEPAD_BUTTON_RIGHT_TRIGGER_2,
    rb = ray.GAMEPAD_BUTTON_RIGHT_TRIGGER_1,
    rsb = ray.GAMEPAD_BUTTON_RIGHT_THUMB,
    back = ray.GAMEPAD_BUTTON_MIDDLE_LEFT,
    start = ray.GAMEPAD_BUTTON_MIDDLE_RIGHT,
    middle = ray.GAMEPAD_BUTTON_MIDDLE,
}

struct PopkaState {
    Color backgroundColor = defaultBackgroundColor;
    float timeRate = 1.0f;
    bool isWindowOpen;
    bool isRunning;
    bool isDrawing;
    bool isFPSLocked;
    bool isCursorHidden;
    bool isPixelPerfect;

    Vec2 targetViewportSize;
    Viewport viewport;
    bool isLockResolutionQueued;
    bool isUnlockResolutionQueued;

    Vec2 lastWindowSize;
    float toggleFullscreenTimer = 0.0f;
    bool isToggleFullscreenQueued;
}

struct DrawOptions {
    Vec2 origin = Vec2(0.0f);
    Vec2 scale = Vec2(1.0f);
    float rotation = 0.0f;

    Color color = white;
    Hook hook = Hook.topLeft;
    Flip flip = Flip.none;
}

struct Sprite {
    ray.Texture2D data;

    @trusted @nogc nothrow:

    this(const(char)[] path) {
        load(path);
    }

    bool isEmpty() {
        return data.id <= 0;
    }

    Vec2 size() {
        return Vec2(data.width, data.height);
    }

    Rect area() {
        return Rect(size);
    }

    void changeFilter(Filter filter) {
        ray.SetTextureFilter(data, toRay(filter));
    }

    void load(const(char)[] path) {
        free();
        if (path.length != 0) {
            data = ray.LoadTexture(toStrz(path));
        }
    }

    void free() {
        if (!isEmpty) {
            ray.UnloadTexture(data);
            data = ray.Texture2D();
        }
    }
}

struct Viewport {
    ray.RenderTexture2D data;

    @trusted @nogc nothrow:

    this(Vec2 size) {
        load(size);
    }

    this(float width, float height) {
        this(Vec2(width, height));
    }

    bool isEmpty() {
        return data.texture.id <= 0;
    }

    Vec2 size() {
        return Vec2(data.texture.width, data.texture.height);
    }

    Rect area() {
        return Rect(size);
    }

    void changeFilter(Filter filter) {
        ray.SetTextureFilter(data.texture, toRay(filter));
    }

    void load(Vec2 size) {
        free();
        data = ray.LoadRenderTexture(cast(int) size.x, cast(int) size.y);
    }

    void free() {
        if (!isEmpty) {
            ray.UnloadRenderTexture(data);
            data = ray.RenderTexture();
        }
    }
}

struct Font {
    ray.Font data;
    Vec2 spacing;

    @trusted @nogc nothrow:

    this(const(char)[] path, uint size, const(dchar)[] runes = []) {
        load(path, size, runes);
    }

    bool isEmpty() {
        return data.texture.id <= 0;
    }

    float size() {
        return data.baseSize;
    }

    void changeFilter(Filter filter) {
        ray.SetTextureFilter(data.texture, toRay(filter));
    }

    void load(const(char)[] path, uint size, const(dchar)[] runes = []) {
        free();
        if (path.length != 0) {
            data = ray.LoadFontEx(toStrz(path), size, cast(int*) runes.ptr, cast(int) runes.length);
        }
    }

    void free() {
        if (!isEmpty) {
            ray.UnloadFont(data);
            data = ray.Font();
        }
    }
}

struct Sound {
    ray.Sound data;

    @trusted @nogc nothrow:

    this(const(char)[] path) {
        load(path);
    }

    bool isEmpty() {
        return data.stream.sampleRate == 0;
    }

    void play() {
        ray.PlaySound(data);
    }

    void stop() {
        ray.StopSound(data);
    }

    void pause() {
        ray.PauseSound(data);
    }

    void resume() {
        ray.ResumeSound(data);
    }

    void changeVolume(float level) {
        ray.SetSoundVolume(data, level);
    }

    void load(const(char)[] path) {
        free();
        if (path.length != 0) {
            data = ray.LoadSound(toStrz(path));
        }
    }

    void free() {
        if (!isEmpty) {
            ray.UnloadSound(data);
            data = ray.Sound();
        }
    }
}

struct Music {
    ray.Music data;

    @trusted @nogc nothrow:

    this(const(char)[] path) {
        load(path);
    }

    bool isEmpty() {
        return data.stream.sampleRate == 0;
    }

    void play() {
        ray.PlayMusicStream(data);
    }

    void stop() {
        ray.StopMusicStream(data);
    }

    void pause() {
        ray.PauseMusicStream(data);
    }

    void resume() {
        ray.ResumeMusicStream(data);
    }

    void update() {
        ray.UpdateMusicStream(data);
    }

    void changeVolume(float level) {
        ray.SetMusicVolume(data, level);
    }

    void load(const(char)[] path) {
        free();
        if (path.length != 0) {
            data = ray.LoadMusicStream(toStrz(path));
        }
    }

    void free() {
        if (!isEmpty) {
            ray.UnloadMusicStream(data);
            data = ray.Music();
        }
    }
}

struct Camera {
    Vec2 position;
    float rotation = 0.0f;
    float scale = 1.0f;

    Hook hook;
    bool isAttached;

    @trusted @nogc nothrow:

    this(Vec2 position) {
        this.position = position;
    }

    this(float x, float y) {
        this(Vec2(x, y));
    }

    Vec2 size() {
        return resolution;
    }

    Vec2 origin() {
        return Rect(size).origin(hook);
    }

    Rect area() {
        return Rect(position - origin, size);
    }

    Vec2 point(Hook hook) {
        return area.point(hook);
    }

    void attach() {
        if (!isAttached) {
            isAttached = true;
            auto temp = toRay(this);
            if (isPixelPerfect) {
                temp.target.x = floor(temp.target.x);
                temp.target.y = floor(temp.target.y);
                temp.offset.x = floor(temp.offset.x);
                temp.offset.y = floor(temp.offset.y);
            }
            ray.BeginMode2D(temp);
        }
    }

    void detach() {
        if (isAttached) {
            isAttached = false;
            ray.EndMode2D();
        }
    }

    void followPosition(Vec2 target, float slowdown = 0.15f) {
        if (slowdown <= 0.0f) {
            position = target;
        } else {
            position = position.moveTo(target, Vec2(deltaTime), slowdown);
        }
    }

    void followScale(float target, float slowdown = 0.15f) {
        if (slowdown <= 0.0f) {
            scale = target;
        } else {
            scale = scale.moveTo(target, deltaTime, slowdown);
        }
    }
}

struct TileMap {
    Grid!short data;
    Vec2 tileSize = Vec2(16.0f);
    alias data this;

    @safe @nogc nothrow:

    this(const(char)[] path) {
        load(path);
    }

    Vec2 size() {
        return tileSize * Vec2(colCount, rowCount);
    }

    Rect area() {
        return Rect(size);
    }

    void load(const(char)[] path) {
        free();
        if (path.length == 0) {
            return;
        }

        auto file = readText(path);
        auto view = file.items;
        auto newRowCount = 0;
        auto newColCount = 0;

        while (view.length != 0) {
            auto line = view.skipLine();
            newRowCount += 1;
            newColCount = 0;
            while (line.length != 0) {
                auto value = line.skipValue(',');
                newColCount += 1;
            }
        }
        resize(newRowCount, newColCount);

        view = file.items;
        foreach (row; 0 .. newRowCount) {
            auto line = view.skipLine();
            foreach (col; 0 .. newColCount) {
                auto value = line.skipValue(',');
                auto conv = value.toSigned();
                if (conv.error) {
                    data[row, col] = cast(short) -1;
                } else {
                    data[row, col] = cast(short) conv.value;
                }
            }
        }
        file.free();
    }
}

Color toPopka(ray.Color from) {
    return Color(from.r, from.g, from.b, from.a);
}

Vec2 toPopka(ray.Vector2 from) {
    return Vec2(from.x, from.y);
}

Vec3 toPopka(ray.Vector3 from) {
    return Vec3(from.x, from.y, from.z);
}

Vec4 toPopka(ray.Vector4 from) {
    return Vec4(from.x, from.y, from.z, from.w);
}

Rect toPopka(ray.Rectangle from) {
    return Rect(from.x, from.y, from.width, from.height);
}

Sprite toPopka(ray.Texture2D from) {
    Sprite result;
    result.data = from;
    return result;
}

Font toPopka(ray.Font from) {
    Font result;
    result.data = from;
    return result;
}

Viewport toPopka(ray.RenderTexture2D from) {
    Viewport result;
    result.data = from;
    return result;
}

Camera toPopka(ray.Camera2D from) {
    Camera result;
    result.position = toPopka(from.target);
    result.rotation = from.rotation;
    result.scale = from.zoom;
    return result;
}

ray.Color toRay(Color from) {
    return ray.Color(from.r, from.g, from.b, from.a);
}

ray.Vector2 toRay(Vec2 from) {
    return ray.Vector2(from.x, from.y);
}

ray.Vector3 toRay(Vec3 from) {
    return ray.Vector3(from.x, from.y, from.z);
}

ray.Vector4 toRay(Vec4 from) {
    return ray.Vector4(from.x, from.y, from.z, from.w);
}

ray.Rectangle toRay(Rect from) {
    return ray.Rectangle(from.position.x, from.position.y, from.size.x, from.size.y);
}

ray.Texture2D toRay(Sprite from) {
    return from.data;
}

ray.Font toRay(Font from) {
    return from.data;
}

ray.RenderTexture2D toRay(Viewport from) {
    return from.data;
}

ray.Camera2D toRay(Camera from) {
    return ray.Camera2D(toRay(from.origin), toRay(from.position), from.rotation, from.scale);
}

int toRay(Filter filter) {
    final switch (filter) {
        case Filter.nearest: return ray.TEXTURE_FILTER_POINT;
        case Filter.linear: return ray.TEXTURE_FILTER_BILINEAR;
    }
}

Flip opposite(Flip flip, Flip fallback) {
    if (flip == fallback) {
        return Flip.none;
    } else {
        return fallback;
    }
}

int randi() {
    return ray.GetRandomValue(0, int.max);
}

float randf() {
    return ray.GetRandomValue(0, cast(int) float.max) / cast(float) cast(int) float.max;
}

void randomize(uint seed) {
    ray.SetRandomSeed(seed);
}

void randomize() {
    randomize(randi);
}

Vec2 toWorldPoint(Vec2 point, Camera camera) {
    return toPopka(ray.GetScreenToWorld2D(toRay(point), toRay(camera)));
}

Vec2 toScreenPoint(Vec2 point, Camera camera) {
    return toPopka(ray.GetWorldToScreen2D(toRay(point), toRay(camera)));
}

Font rayFont() {
    auto result = toPopka(ray.GetFontDefault());
    result.spacing = Vec2(1.0f, 14.0f);
    return result;
}

void openWindow(Vec2 size, const(char)[] title = "Popka", Color color = defaultBackgroundColor) {
    if (popkaState.isWindowOpen) {
        return;
    }
    ray.SetConfigFlags(ray.FLAG_VSYNC_HINT | ray.FLAG_WINDOW_RESIZABLE);
    ray.SetTraceLogLevel(ray.LOG_ERROR);
    ray.InitWindow(cast(int) size.x, cast(int) size.y, toStrz(title));
    ray.InitAudioDevice();
    ray.SetWindowMinSize(cast(int) (size.x * 0.25f), cast(int) (size.y * 0.25f));
    ray.SetExitKey(ray.KEY_NULL);
    lockFPS(defaultFPS);
    popkaState.isWindowOpen = true;
    popkaState.isRunning = true;
    popkaState.backgroundColor = color;
    popkaState.lastWindowSize = size;
}

void openWindow(float width, float height, const(char)[] title = "Popka", Color color = defaultBackgroundColor) {
    openWindow(Vec2(width, height), title, color);
}

void closeWindow() {
    popkaState.isWindowOpen = false;
}

bool isWindowOpen() {
    if (ray.WindowShouldClose() || !popkaState.isWindowOpen) {
        popkaState.isDrawing = false;
        return false;
    }

    if (!popkaState.isDrawing) {
        if (isResolutionLocked) {
            ray.BeginTextureMode(popkaState.viewport.data);
        } else {
            ray.BeginDrawing();
        }
        ray.ClearBackground(toRay(popkaState.backgroundColor));
    } else {
        // End drawing.
        if (isResolutionLocked) {
            auto minSize = popkaState.viewport.size;
            auto maxSize = windowSize;
            auto ratio = maxSize / minSize;
            auto minRatio = min(ratio.x, ratio.y);
            auto targetSize = minSize * Vec2(minRatio);
            auto targetPos = maxSize * Vec2(0.5f) - targetSize * Vec2(0.5f);
            ray.EndTextureMode();
            ray.BeginDrawing();
            ray.ClearBackground(ray.Color(0, 0, 0, 255));
            ray.DrawTexturePro(
                popkaState.viewport.data.texture,
                ray.Rectangle(0.0f, 0.0f, minSize.x, -minSize.y),
                ray.Rectangle(
                    ratio.x == minRatio ? targetPos.x : floor(targetPos.x),
                    ratio.y == minRatio ? targetPos.y : floor(targetPos.y),
                    ratio.x == minRatio ? targetSize.x : floor(targetSize.x),
                    ratio.y == minRatio ? targetSize.y : floor(targetSize.y),
                ),
                ray.Vector2(0.0f, 0.0f),
                0.0f,
                ray.Color(255, 255, 255, 255),
            );
            ray.EndDrawing();
        } else {
            ray.EndDrawing();
        }
        // The lockResolution and unlockResolution queue.
        if (popkaState.isLockResolutionQueued) {
            popkaState.viewport.load(popkaState.targetViewportSize);
            popkaState.isLockResolutionQueued = false;
        }
        if (popkaState.isUnlockResolutionQueued) {
            popkaState.viewport.free();
            popkaState.isUnlockResolutionQueued = false;
        }
        // Fullscreen code to fix a bug on KDE.
        if (popkaState.isToggleFullscreenQueued) {
            popkaState.toggleFullscreenTimer += deltaTime;
            if (popkaState.toggleFullscreenTimer >= toggleFullscreenWaitTime) {
                popkaState.toggleFullscreenTimer = 0.0f;
                auto screen = screenSize;
                auto window = popkaState.lastWindowSize;
                if (ray.IsWindowFullscreen()) {
                    ray.ToggleFullscreen();
                    ray.SetWindowSize(cast(int) window.x, cast(int) window.y);
                    ray.SetWindowPosition(cast(int) (screen.x * 0.5f - window.x * 0.5f), cast(int) (screen.y * 0.5f - window.y * 0.5f));
                } else {
                    ray.ToggleFullscreen();
                }
                popkaState.isToggleFullscreenQueued = false;
            }
        }
        // Begin drawing.
        if (isResolutionLocked) {
            ray.BeginTextureMode(popkaState.viewport.data);
        } else {
            ray.BeginDrawing();
        }
        ray.ClearBackground(toRay(popkaState.backgroundColor));
    }
    popkaState.isDrawing = true;
    return true;
}

void updateWindow(alias loopFunc)() {
    static void __updateWindow() {
        // Begin drawing.
        if (isResolutionLocked) {
            ray.BeginTextureMode(popkaState.viewport.data);
        } else {
            ray.BeginDrawing();
        }
        ray.ClearBackground(toRay(popkaState.backgroundColor));

        // The main loop.
        loopFunc();

        // End drawing.
        if (isResolutionLocked) {
            auto minSize = popkaState.viewport.size;
            auto maxSize = windowSize;
            auto ratio = maxSize / minSize;
            auto minRatio = min(ratio.x, ratio.y);
            auto targetSize = minSize * Vec2(minRatio);
            auto targetPos = maxSize * Vec2(0.5f) - targetSize * Vec2(0.5f);
            ray.EndTextureMode();
            ray.BeginDrawing();
            ray.ClearBackground(ray.Color(0, 0, 0, 255));
            ray.DrawTexturePro(
                popkaState.viewport.data.texture,
                ray.Rectangle(0.0f, 0.0f, minSize.x, -minSize.y),
                ray.Rectangle(
                    ratio.x == minRatio ? targetPos.x : floor(targetPos.x),
                    ratio.y == minRatio ? targetPos.y : floor(targetPos.y),
                    ratio.x == minRatio ? targetSize.x : floor(targetSize.x),
                    ratio.y == minRatio ? targetSize.y : floor(targetSize.y),
                ),
                ray.Vector2(0.0f, 0.0f),
                0.0f,
                ray.Color(255, 255, 255, 255),
            );
            ray.EndDrawing();
        } else {
            ray.EndDrawing();
        }
        // The lockResolution and unlockResolution queue.
        if (popkaState.isLockResolutionQueued) {
            popkaState.viewport.load(popkaState.targetViewportSize);
            popkaState.isLockResolutionQueued = false;
        }
        if (popkaState.isUnlockResolutionQueued) {
            popkaState.viewport.free();
            popkaState.isUnlockResolutionQueued = false;
        }
        // Fullscreen code to fix a bug on KDE.
        if (popkaState.isToggleFullscreenQueued) {
            popkaState.toggleFullscreenTimer += deltaTime;
            if (popkaState.toggleFullscreenTimer >= toggleFullscreenWaitTime) {
                popkaState.toggleFullscreenTimer = 0.0f;
                auto screen = screenSize;
                auto window = popkaState.lastWindowSize;
                if (ray.IsWindowFullscreen()) {
                    ray.ToggleFullscreen();
                    ray.SetWindowSize(cast(int) window.x, cast(int) window.y);
                    ray.SetWindowPosition(cast(int) (screen.x * 0.5f - window.x * 0.5f), cast(int) (screen.y * 0.5f - window.y * 0.5f));
                } else {
                    ray.ToggleFullscreen();
                }
                popkaState.isToggleFullscreenQueued = false;
            }
        }
        popkaState.isDrawing = true;
    }

    version(WebAssembly) {
        emscripten_set_main_loop(&__updateWindow, 60, 1);
    } else {
        while (true) {
            if (ray.WindowShouldClose() || !popkaState.isWindowOpen) {
                popkaState.isDrawing = false;
                return;
            }
            popkaState.isDrawing = true;
            __updateWindow();
        }
    }
}

void freeWindow() {
    if (popkaState.isRunning) {
        popkaState.viewport.free();
        ray.CloseAudioDevice();
        ray.CloseWindow();
        popkaState = PopkaState.init;
    }
}

bool isFPSLocked() {
    return popkaState.isFPSLocked;
}

void lockFPS(uint target) {
    ray.SetTargetFPS(target);
    popkaState.isFPSLocked = true;
}

void unlockFPS() {
    ray.SetTargetFPS(0);
    popkaState.isFPSLocked = false;
}

bool isResolutionLocked() {
    return !popkaState.viewport.isEmpty;
}

void lockResolution(Vec2 size) {
    if (popkaState.isWindowOpen && !popkaState.isDrawing) {
        popkaState.viewport.load(size);
    } else {
        popkaState.targetViewportSize = size;
        popkaState.isLockResolutionQueued = true;
        popkaState.isUnlockResolutionQueued = false;
    }
}

void lockResolution(float width, float height) {
    lockResolution(Vec2(width, height));
}

void unlockResolution() {
    if (popkaState.isWindowOpen && !popkaState.isDrawing) {
        popkaState.viewport.free();
    } else {
        popkaState.isUnlockResolutionQueued = true;
        popkaState.isLockResolutionQueued = false;
    }
}

bool isCursorHidden() {
    return popkaState.isCursorHidden;
}

void hideCursor() {
    ray.HideCursor();
    popkaState.isCursorHidden = true;
}

void showCursor() {
    ray.ShowCursor();
    popkaState.isCursorHidden = false;
}

bool isFullscreen() {
    return ray.IsWindowFullscreen;
}

void toggleFullscreen() {
    if (!ray.IsWindowFullscreen()) {
        auto screen = screenSize;
        popkaState.lastWindowSize = windowSize;
        ray.SetWindowPosition(0, 0);
        ray.SetWindowSize(cast(int) screen.x, cast(int) screen.y);
    }
    popkaState.isToggleFullscreenQueued = true;
}

bool isPixelPerfect() {
    return popkaState.isPixelPerfect;
}

void togglePixelPerfect() {
    popkaState.isPixelPerfect = !popkaState.isPixelPerfect;
}

Vec2 screenSize() {
    auto id = ray.GetCurrentMonitor();
    return Vec2(ray.GetMonitorWidth(id), ray.GetMonitorHeight(id));
}

Vec2 windowSize() {
    if (isFullscreen) {
        return screenSize;
    } else {
        return Vec2(ray.GetScreenWidth(), ray.GetScreenHeight());
    }
}

Vec2 resolution() {
    if (isResolutionLocked) {
        return popkaState.viewport.size;
    } else {
        return windowSize;
    }
}

Vec2 mouseScreenPosition() {
    if (isResolutionLocked) {
        auto window = windowSize;
        auto minRatio = min(window.x / popkaState.viewport.size.x, window.y / popkaState.viewport.size.y);
        auto targetSize = popkaState.viewport.size * Vec2(minRatio);
        return Vec2(
            (ray.GetMouseX() - (window.x - targetSize.x) * 0.5f) / minRatio,
            (ray.GetMouseY() - (window.y - targetSize.y) * 0.5f) / minRatio,
        );
    } else {
        return Vec2(ray.GetMouseX(), ray.GetMouseY());
    }
}

Vec2 mouseWorldPosition(Camera camera) {
    return mouseScreenPosition.toWorldPoint(camera);
}

float mouseWheel() {
    return ray.GetMouseWheelMove();
}

int fps() {
    return ray.GetFPS();
}

float deltaTime() {
    return ray.GetFrameTime() * popkaState.timeRate;
}

Vec2 deltaMousePosition() {
    return toPopka(ray.GetMouseDelta());
}

float timeRate() {
    return popkaState.timeRate;
}

Color backgroundColor() {
    return popkaState.backgroundColor;
}

void changeTimeRate(float rate) {
    popkaState.timeRate = rate;
}

void changeBackgroundColor(Color color) {
    popkaState.backgroundColor = color;
}

void changeShapeSprite(Sprite sprite, Rect area = Rect(1.0f, 1.0f)) {
    ray.SetShapesTexture(sprite.data, toRay(area));
}

Vec2 measureTextSize(Font font, const(char)[] text, DrawOptions options = DrawOptions()) {
    if (font.isEmpty || text.length == 0) {
        return Vec2();
    }
    auto result = Vec2();
    auto tempByteCounter = 0; // Used to count longer text line num chars.
    auto byteCounter = 0;
    auto textWidth = 0.0f;
    auto tempTextWidth = 0.0f; // Used to count longer text line width.
    auto textHeight = font.size;

    auto letter = 0; // Current character.
    auto index = 0; // Index position in sprite font.
    auto i = 0;
    while (i < text.length) {
        byteCounter += 1;

        auto next = 0;
        letter = ray.GetCodepointNext(&text[i], &next);
        index = ray.GetGlyphIndex(font.data, letter);
        i += next;
        if (letter != '\n') {
            if (font.data.glyphs[index].advanceX != 0) {
                textWidth += font.data.glyphs[index].advanceX;
            } else {
                textWidth += font.data.recs[index].width + font.data.glyphs[index].offsetX;
            }
        } else {
            if (tempTextWidth < textWidth) {
                tempTextWidth = textWidth;
            }
            byteCounter = 0;
            textWidth = 0;
            textHeight += font.spacing.y;
        }
        if (tempByteCounter < byteCounter) {
            tempByteCounter = byteCounter;
        }
    }
    if (tempTextWidth < textWidth) {
        tempTextWidth = textWidth;
    }
    result.x = floor(tempTextWidth * options.scale.x + ((tempByteCounter - 1) * font.spacing.x * options.scale.x));
    result.y = floor(textHeight * options.scale.y);
    return result;
}

Rect measureTextArea(Font font, const(char)[] text, Vec2 position, DrawOptions options = DrawOptions()) {
    return Rect(position, measureTextSize(font, text, options)).area(options.hook);
}

Rect measureTextArea(Font font, const(char)[] text, DrawOptions options = DrawOptions()) {
    return Rect(Vec2(), measureTextSize(font, text, options)).area(options.hook);
}

bool isPressed(char key) {
    return ray.IsKeyPressed(toUpper(key));
}

bool isPressed(Keyboard key) {
    return ray.IsKeyPressed(key);
}

bool isPressed(Mouse key) {
    return ray.IsMouseButtonPressed(key);
}

bool isPressed(Gamepad key, uint id = 0) {
    return ray.IsGamepadButtonPressed(id, key);
}

bool isDown(char key) {
    return ray.IsKeyDown(toUpper(key));
}

bool isDown(Keyboard key) {
    return ray.IsKeyDown(key);
}

bool isDown(Mouse key) {
    return ray.IsMouseButtonDown(key);
}

bool isDown(Gamepad key, uint id = 0) {
    return ray.IsGamepadButtonDown(id, key);
}

bool isReleased(char key) {
    return ray.IsKeyReleased(toUpper(key));
}

bool isReleased(Keyboard key) {
    return ray.IsKeyReleased(key);
}

bool isReleased(Mouse key) {
    return ray.IsMouseButtonReleased(key);
}

bool isReleased(Gamepad key, uint id = 0) {
    return ray.IsGamepadButtonReleased(id, key);
}

Vec2 wasd() {
    Vec2 result;
    if (Keyboard.a.isDown || Keyboard.left.isDown) {
        result.x = -1.0f;
    }
    if (Keyboard.d.isDown || Keyboard.right.isDown) {
        result.x = 1.0f;
    }
    if (Keyboard.w.isDown || Keyboard.up.isDown) {
        result.y = -1.0f;
    }
    if (Keyboard.s.isDown || Keyboard.down.isDown) {
        result.y = 1.0f;
    }
    return result;
}

void draw(Rect rect, Color color = white) {
    if (isPixelPerfect) {
        ray.DrawRectanglePro(toRay(rect.floor()), ray.Vector2(0.0f, 0.0f), 0.0f, toRay(color));
    } else {
        ray.DrawRectanglePro(toRay(rect), ray.Vector2(0.0f, 0.0f), 0.0f, toRay(color));
    }
}

void draw(Circ circ, Color color = white) {
    ray.DrawCircleV(toRay(circ.position), circ.radius, toRay(color));
}

void draw(Sprite sprite, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    if (sprite.isEmpty) {
        return;
    }

    auto target = Rect();
    auto source = Rect();
    if (area.size.x <= 0.0f || area.size.y <= 0.0f) {
        target = Rect(position, sprite.size * options.scale.abs());
        source = Rect(sprite.size);
    } else {
        target = Rect(position, area.size * options.scale.abs());
        source = area;
    }

    auto flip = options.flip;
    if (options.scale.x < 0.0f && options.scale.y < 0.0f) {
        flip = opposite(flip, Flip.xy);
    } else if (options.scale.x < 0.0f) {
        flip = opposite(flip, Flip.x);
    } else if (options.scale.y < 0.0f) {
        flip = opposite(flip, Flip.y);
    }
    final switch (flip) {
        case Flip.none: break;
        case Flip.x: source.size.x *= -1.0f; break;
        case Flip.y: source.size.y *= -1.0f; break;
        case Flip.xy: source.size *= Vec2(-1.0f); break;
    }

    auto origin = options.origin == Vec2() ? target.origin(options.hook) : options.origin;
    if (isPixelPerfect) {
        ray.DrawTexturePro(
            sprite.data,
            toRay(source.floor()),
            toRay(target.floor()),
            toRay(origin.floor()),
            options.rotation,
            toRay(options.color),
        );
    } else {
        ray.DrawTexturePro(
            sprite.data,
            toRay(source),
            toRay(target),
            toRay(origin),
            options.rotation,
            toRay(options.color),
        );
    }
}

void draw(Sprite sprite, Vec2 position, DrawOptions options = DrawOptions()) {
    draw(sprite, Rect(), position, options);
}

void draw(Sprite sprite, Vec2 tileSize, uint tileID, Vec2 position, DrawOptions options = DrawOptions()) {
    auto gridWidth = cast(uint) (sprite.size.x / tileSize.x);
    auto gridHeight = cast(uint) (sprite.size.y / tileSize.y);
    if (gridWidth == 0 || gridHeight == 0) {
        return;
    }
    auto row = tileID / gridWidth;
    auto col = tileID % gridWidth;
    auto area = Rect(col * tileSize.x, row * tileSize.y, tileSize.x, tileSize.y);
    draw(sprite, area, position, options);
}

void draw(Sprite sprite, Vec2 tileSize, uint tileCount, float tileSpacing, Vec2 position, DrawOptions options = DrawOptions()) {
    foreach_reverse(i; 0 .. tileCount) {
        draw(sprite, tileSize, i, Vec2(position.x, position.y + i * tileSpacing * options.scale.y), options);
    }
}

void draw(Sprite sprite, TileMap tileMap, Camera camera, Vec2 position, DrawOptions options = DrawOptions()) {
    enum extraTileCount = 4;

    auto topLeft = camera.point(Hook.topLeft);
    auto bottomRight = camera.point(Hook.bottomRight);
    auto col1 = 0;
    auto col2 = 0;
    auto row1 = 0;
    auto row2 = 0;

    if (camera.isAttached) {
        col1 = cast(int) floor(clamp((topLeft.x - position.x) / tileMap.tileSize.x - extraTileCount, 0, tileMap.colCount));
        col2 = cast(int) floor(clamp((bottomRight.x - position.x) / tileMap.tileSize.x + extraTileCount, 0, tileMap.colCount));
        row1 = cast(int) floor(clamp((topLeft.y - position.y) / tileMap.tileSize.y - extraTileCount, 0, tileMap.rowCount));
        row2 = cast(int) floor(clamp((bottomRight.y - position.y) / tileMap.tileSize.y + extraTileCount, 0, tileMap.rowCount));
    } else {
        col1 = 0;
        col2 = cast(int) tileMap.colCount;
        row1 = 0;
        row2 = cast(int) tileMap.rowCount;
    }
    foreach (row; row1 .. row2) {
        foreach (col; col1 .. col2) {
            if (tileMap[row, col] == -1) {
                continue;
            }
            draw(sprite, tileMap.tileSize, tileMap[row, col], position + Vec2(col, row) * tileMap.tileSize, options);
        }
    }
}

void draw(Font font, dchar rune, Vec2 position, DrawOptions options = DrawOptions()) {
    if (font.isEmpty) {
        return;
    }

    auto rect = toPopka(ray.GetGlyphAtlasRec(font.data, rune));
    auto origin = options.origin == Vec2() ? rect.origin(options.hook) : options.origin;
    
    // NOTE: Maybe new way of drawing a character.
    // draw(toPopka(font.data.texture), rect, position + Vec2(0.0f, font.size - rect.size.y), options);

    // NOTE: Old way of drawing a character.
    ray.rlPushMatrix();
    if (isPixelPerfect) {
        ray.rlTranslatef(floor(position.x), floor(position.y), 0.0f);
    } else {
        ray.rlTranslatef(position.x, position.y, 0.0f);
    }
    ray.rlRotatef(options.rotation, 0.0f, 0.0f, 1.0f);
    ray.rlScalef(options.scale.x, options.scale.y, 1.0f);
    if (isPixelPerfect) {
        ray.rlTranslatef(floor(-origin.x), floor(-origin.y), 0.0f);
    } else {
        ray.rlTranslatef(-origin.x, -origin.y, 0.0f);
    }
    ray.DrawTextCodepoint(font.data, rune, ray.Vector2(0.0f, 0.0f), font.size, toRay(options.color));
    ray.rlPopMatrix();
}

// TODO: Make it work with negative scale values.
void draw(Font font, const(char)[] text, Vec2 position, DrawOptions options = DrawOptions()) {
    if (font.isEmpty || text.length == 0) {
        return;
    }
    auto rect = measureTextArea(font, text);
    auto origin = rect.origin(options.hook);
    ray.rlPushMatrix();
    if (isPixelPerfect) {
        ray.rlTranslatef(floor(position.x), floor(position.y), 0.0f);
    } else {
        ray.rlTranslatef(position.x, position.y, 0.0f);
    }
    ray.rlRotatef(options.rotation, 0.0f, 0.0f, 1.0f);
    ray.rlScalef(options.scale.x, options.scale.y, 1.0f);
    if (isPixelPerfect) {
        ray.rlTranslatef(floor(-origin.x), floor(-origin.y), 0.0f);
    } else {
        ray.rlTranslatef(-origin.x, -origin.y, 0.0f);
    }
    auto textOffsetY = 0.0f; // Offset between lines (on linebreak '\n').
    auto textOffsetX = 0.0f; // Offset X to next character to draw.
    auto i = 0;
    while (i < text.length) {
        // Get next codepoint from byte string and glyph index in font.
        auto codepointByteCount = 0;
        auto codepoint = ray.GetCodepointNext(&text[i], &codepointByteCount);
        auto index = ray.GetGlyphIndex(font.data, codepoint);
        if (codepoint == '\n') {
            textOffsetY += font.spacing.y;
            textOffsetX = 0.0f;
        } else {
            if (codepoint != ' ' && codepoint != '\t') {
                auto runeOptions = DrawOptions();
                runeOptions.color = options.color;
                draw(font, codepoint, Vec2(textOffsetX, textOffsetY), runeOptions);
            }
            if (font.data.glyphs[index].advanceX == 0) {
                textOffsetX += font.data.recs[index].width + font.spacing.x;
            } else {
                textOffsetX += font.data.glyphs[index].advanceX + font.spacing.x;
            }
        }
        // Move text bytes counter to next codepoint.
        i += codepointByteCount;
    }
    ray.rlPopMatrix();
}

void draw(const(char)[] text, Vec2 position = Vec2(8.0f, 8.0f)) {
    auto options = DrawOptions();
    options.color = gray2;
    draw(rayFont, text, position, options);
}