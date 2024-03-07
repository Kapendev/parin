// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

module popka.game.engine;

/// The engine module functions as a lightweight 2D game engine,
/// designed to provide essential tools and functionalities for developing games with ease and efficiency.

import ray = popka.vendor.ray.raylib;
import raygl = popka.vendor.ray.rlgl;
import popka.core.basic;

enum {
    popkaDefaultFPS = 60,
    popkaDefaultBackgroundColor = Color(0x2A, 0x36, 0x3A),
    popkaFullscreenWaitTime = 0.125f,
    rayFontSpacing = Vec2(1.0f, 14.0f),
}

bool popkaState;
Color popkaBackgroundColor;

View popkaView;
float popkaViewWidth = 32.0f;
float popkaViewHeight = 32.0f;
bool popkaViewLockFlag;
bool popkaViewUnlockFlag;

Vec2 popkaFullscreenLastWindowSize;
float popkaFullscreenTime = 0.0f;
bool popkaFullscreenFlag;

struct Sprite {
    ray.Texture2D data;

    this(const(char)[] path) {
        load(path);
    }

    bool isEmpty() {
        return data.id == 0;
    }

    float width() {
        return data.width;
    }

    float height() {
        return data.height;
    }

    Vec2 size() {
        return Vec2(width, height);
    }

    Rect rect() {
        return Rect(size);
    }

    void load(const(char)[] path) {
        free();
        data = ray.LoadTexture(toStrz(path));
    }

    void free() {
        if (!isEmpty) {
            ray.UnloadTexture(data);
            data = ray.Texture2D();
        }
    }
}

struct Font {
    ray.Font data;

    this(const(char)[] path, uint size) {
        load(path, size);
    }

    bool isEmpty() {
        return data.texture.id == 0;
    }

    float size() {
        return data.baseSize;
    }

    void load(const(char)[] path, uint size) {
        free();
        data = ray.LoadFontEx(toStrz(path), size, null, 0);
    }

    void free() {
        if (data.texture.id != 0) {
            ray.UnloadFont(data);
            data = ray.Font();
        }
    }
}

struct View {
    ray.RenderTexture2D data;

    this(float width, float height) {
        load(width, height);
    }

    bool isEmpty() {
        return data.texture.id == 0;
    }

    float width() {
        return data.texture.width;
    }

    float height() {
        return data.texture.height;
    }

    Vec2 size() {
        return Vec2(width, height);
    }

    Rect rect() {
        return Rect(size);
    }

    void load(float width, float height) {
        free();
        data = ray.LoadRenderTexture(cast(int) width, cast(int) height);
    }

    void free() {
        if (!isEmpty) {
            ray.UnloadRenderTexture(data);
            data = ray.RenderTexture();
        }
    }
}

struct TileMap {
    Grid!short data;
    alias this = data;

    Vec2 cellSize() {
        return Vec2(cellWidth, cellHeight);
    }

    void cellSize(Vec2 value) {
        cellWidth = value.x;
        cellHeight = value.y;
    }

    Vec2 size() {
        return Vec2(width, height);
    }

    void load(const(char)[] path) {
        free();

        auto file = readText(path);
        const(char)[] view = file.items;
        while (view.length != 0) {
            auto line = view.skipLine();
            rowCount += 1;
            colCount = 0;
            while (line.length != 0) {
                auto value = line.skipValue();
                colCount += 1;
            }
        }
        resize(rowCount, colCount);

        view = file.items;
        foreach (row; 0 .. rowCount) {
            auto line = view.skipLine();
            foreach (col; 0 .. colCount) {
                auto value = line.skipValue();
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

struct Camera {
    Vec2 position;
    float rotation = 0.0f;
    float scale = 1.0f;
    Hook hook;
    bool isAttached;

    this(Vec2 position) {
        this.position = position;
    }

    float width() {
        return resolution.x * scale;
    }

    float height() {
        return resolution.y * scale;
    }

    Vec2 size() {
        return Vec2(width, height);
    }

    Vec2 origin() {
        return Rect(size).origin(hook);
    }

    Rect rect() {
        return Rect(position - origin, size);
    }

    Vec2 point(Hook hook) {
        return rect.point(hook);
    }

    void attach() {
        if (!isAttached) {
            isAttached = true;
            auto temp = toRay(this);
            temp.target.x = floor(temp.target.x);
            temp.target.y = floor(temp.target.y);
            temp.offset.x = floor(temp.offset.x);
            temp.offset.y = floor(temp.offset.y);
            ray.BeginMode2D(temp);
        }
    }

    void detach() {
        if (isAttached) {
            isAttached = false;
            ray.EndMode2D();
        }
    }

    void follow(Vec2 target, float slowdown = 0.14f) {
        if (slowdown <= 0.0f) {
            position = target;
        } else {
            position = position.moveTo(target, Vec2(deltaTime), slowdown);
        }
    }
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
    n00 = ray.KEY_KP_0,
    n11 = ray.KEY_KP_1,
    n22 = ray.KEY_KP_2,
    n33 = ray.KEY_KP_3,
    n44 = ray.KEY_KP_4,
    n55 = ray.KEY_KP_5,
    n66 = ray.KEY_KP_6,
    n77 = ray.KEY_KP_7,
    n88 = ray.KEY_KP_8,
    n99 = ray.KEY_KP_9,
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
    lb = ray.GAMEPAD_BUTTON_LEFT_TRIGGER_1,
    lt = ray.GAMEPAD_BUTTON_LEFT_TRIGGER_2,
    lsb = ray.GAMEPAD_BUTTON_LEFT_THUMB,
    rb = ray.GAMEPAD_BUTTON_RIGHT_TRIGGER_1,
    rt = ray.GAMEPAD_BUTTON_RIGHT_TRIGGER_2,
    rsb = ray.GAMEPAD_BUTTON_RIGHT_THUMB,
    back = ray.GAMEPAD_BUTTON_MIDDLE_LEFT,
    start = ray.GAMEPAD_BUTTON_MIDDLE_RIGHT,
    center = ray.GAMEPAD_BUTTON_MIDDLE,
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

View toPopka(ray.RenderTexture2D from) {
    View result;
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

ray.RenderTexture2D toRay(View from) {
    return from.data;
}

ray.Camera2D toRay(Camera from) {
    return ray.Camera2D(toRay(from.origin), toRay(from.position), from.rotation, from.scale);
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

void openWindow(float width, float height, const(char)[] title = "Popka", Color color = popkaDefaultBackgroundColor) {
    ray.SetConfigFlags(ray.FLAG_VSYNC_HINT | ray.FLAG_WINDOW_RESIZABLE);
    ray.SetTraceLogLevel(ray.LOG_ERROR);
    ray.InitWindow(cast(int) width, cast(int) height, toStrz(title));
    ray.SetWindowMinSize(cast(int) (width * 0.25f), cast(int) (height * 0.25f));
    ray.SetExitKey(ray.KEY_NULL);
    ray.SetTargetFPS(popkaDefaultFPS);
    popkaState = true;
    popkaBackgroundColor = color;
    popkaFullscreenLastWindowSize = Vec2(width, height);
}

void closeWindow() {
    popkaState = false;
}

void freeWindow() {
    popkaView.free();
    ray.CloseWindow();
}

bool isWindowOpen() {
    static auto isFirstCall = true;

    auto result = !(ray.WindowShouldClose() || !popkaState);
    if (result) {
        if (isFirstCall) {
            // Begin drawing.
            if (isResolutionLocked) {
                ray.BeginTextureMode(popkaView.data);
            } else {
                ray.BeginDrawing();
            }
            ray.ClearBackground(toRay(popkaBackgroundColor));
            isFirstCall = false;
        } else {
            // End drawing.
            if (isResolutionLocked) {
                auto minSize = popkaView.size;
                auto maxSize = windowSize;
                auto ratio = maxSize / minSize;
                auto minRatio = min(ratio.x, ratio.y);
                auto targetSize = minSize * Vec2(minRatio);
                auto targetPos = maxSize * Vec2(0.5f) - targetSize * Vec2(0.5f);
                ray.EndTextureMode();
                ray.BeginDrawing();
                ray.ClearBackground(ray.BLACK);
                ray.DrawTexturePro(
                    popkaView.data.texture,
                    ray.Rectangle(0.0f, 0.0f, minSize.x, -minSize.y),
                    ray.Rectangle(
                        ratio.x == minRatio ? targetPos.x : targetPos.x.floor,
                        ratio.y == minRatio ? targetPos.y : targetPos.y.floor,
                        ratio.x == minRatio ? targetSize.x : targetSize.x.floor,
                        ratio.y == minRatio ? targetSize.y : targetSize.y.floor,
                    ),
                    ray.Vector2(0.0f, 0.0f),
                    0.0f,
                    ray.WHITE,
                );
                ray.EndDrawing();
            } else {
                ray.EndDrawing();
            }
            // Check if the resolution was locked or unlocked.
            if (popkaViewLockFlag) {
                popkaView.load(popkaViewWidth, popkaViewHeight);
                popkaViewLockFlag = false;
            }
            if (popkaViewUnlockFlag) {
                popkaView.free();
                popkaViewUnlockFlag = false;
            }
            // Begin drawing.
            if (isResolutionLocked) {
                ray.BeginTextureMode(popkaView.data);
            } else {
                ray.BeginDrawing();
            }
            ray.ClearBackground(toRay(popkaBackgroundColor));
            // Fullscreen code to fix a bug on KDE.
            if (popkaFullscreenFlag) {
                popkaFullscreenTime += deltaTime;
                if (popkaFullscreenTime >= popkaFullscreenWaitTime) {
                    popkaFullscreenTime = 0.0f;
                    popkaFullscreenFlag = false;
                    ray.ToggleFullscreen();
                    if (!isFullscreen) {
                        windowSize(popkaFullscreenLastWindowSize);
                    }
                }
            }
        }
    }
    return result;
}

void lockFPS(uint target) {
    ray.SetTargetFPS(target);
}

void unlockFPS() {
    ray.SetTargetFPS(0);
}

bool isResolutionLocked() {
    return !popkaView.isEmpty;
}

void lockResolution(float width, float height) {
    popkaViewWidth = width;
    popkaViewHeight = height;
    popkaViewLockFlag = true;
}

void unlockResolution() {
    popkaViewUnlockFlag = true;
}

bool isFullscreen() {
    return ray.IsWindowFullscreen;
}

void toggleFullscreen() {
    if (!popkaFullscreenFlag) {
        popkaFullscreenFlag = true;
        if (!isFullscreen) {
            popkaFullscreenLastWindowSize = windowSize;
            windowSize(screenSize);
        }
    }
}

Vec2 screenSize(uint id) {
    return Vec2(ray.GetMonitorWidth(id), ray.GetMonitorHeight(id));
}

Vec2 screenSize() {
    return screenSize(ray.GetCurrentMonitor());
}

Vec2 windowSize() {
    if (isFullscreen) {
        return screenSize;
    } else {
        return Vec2(ray.GetScreenWidth(), ray.GetScreenHeight());
    }
}

void windowSize(Vec2 size) {
    auto screen = screenSize;
    ray.SetWindowSize(cast(int) size.x, cast(int) size.y);
    ray.SetWindowPosition(cast(int) (screen.x * 0.5f - size.x * 0.5f), cast(int) (screen.y * 0.5f - size.y * 0.5f));
}

Vec2 resolution() {
    if (isResolutionLocked) {
        return popkaView.size;
    } else {
        return windowSize;
    }
}

int fps() {
    return ray.GetFPS();
}

float deltaTime() {
    return ray.GetFrameTime();
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

bool isDown(Keyboard key) {
    return ray.IsKeyDown(key);
}

bool isDown(Mouse key) {
    return ray.IsMouseButtonDown(key);
}

bool isDown(Gamepad key, uint id = 0) {
    return ray.IsGamepadButtonDown(id, key);
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

Font rayFont() {
    return toPopka(ray.GetFontDefault());
}

void drawRect(Rect rect, Color color = white) {
    ray.DrawRectanglePro(toRay(rect.floor()), ray.Vector2(0.0f, 0.0f), 0.0f, toRay(color));
}

void drawSprite(Sprite sprite, Rect region, Vec2 position = Vec2(), float rotation = 0.0f, Vec2 scale = Vec2(1.0f), Color color = white, Hook hook = Hook.topLeft, Flip flip = Flip.none) {
    if (sprite.isEmpty) {
        return;
    }
    auto target = Rect(position, region.size * scale);
    auto source = region;
    if (region.size.x <= 0.0f || region.size.y <= 0.0f) {
        target = Rect(position, sprite.size * scale);
        source = Rect(sprite.size);
    } else {
        target = Rect(position, region.size * scale);
        source = region;
    }
    final switch (flip) {
        case Flip.none: break;
        case Flip.x: source.size.x *= -1.0f; break;
        case Flip.y: source.size.y *= -1.0f; break;
        case Flip.xy: source.size *= Vec2(-1.0f); break;
    }
    ray.DrawTexturePro(
        sprite.data,
        toRay(source.floor()),
        toRay(target.floor()),
        toRay(target.origin(hook).floor()),
        rotation,
        toRay(color),
    );
}

void drawTile(Sprite sprite, uint tileID, Vec2 cellSize, Vec2 position = Vec2(), float rotation = 0.0f, Vec2 scale = Vec2(1.0f), Color color = white, Hook hook = Hook.topLeft, Flip flip = Flip.none) {
    uint gridWidth = cast(uint) (sprite.width / cellSize.x).floor();
    uint gridHeight = cast(uint) (sprite.height / cellSize.y).floor();
    drawSprite(
        sprite,
        Rect((tileID % gridWidth) * cellSize.x, (tileID / gridHeight) * cellSize.y, cellSize.x, cellSize.y),
        position,
        rotation,
        scale,
        color,
        hook,
        flip,
    );
}

void drawTileMap(Sprite sprite, TileMap map, Camera camera, Vec2 position = Vec2(), float rotation = 0.0f, Vec2 scale = Vec2(1.0f), Color color = white, Hook hook = Hook.topLeft, Flip flip = Flip.none) {
    size_t col1, col2, row1, row2;
    if (camera.isAttached) {
        col1 = cast(size_t) clamp((camera.point(Hook.topLeft).x - position.x) / map.cellWidth - 4.0f, 0, map.colCount).floor();
        col2 = cast(size_t) clamp((camera.point(Hook.bottomRight).x - position.x) / map.cellWidth + 4.0f, 0, map.colCount).floor();
        row1 = cast(size_t) clamp((camera.point(Hook.topLeft).y - position.y) / map.cellHeight - 4.0f, 0, map.rowCount).floor();
        row2 = cast(size_t) clamp((camera.point(Hook.bottomRight).y - position.y) / map.cellHeight + 4.0f, 0, map.rowCount).floor();
    } else {
        col1 = 0;
        col2 = map.colCount;
        row1 = 0;
        row2 = map.rowCount;
    }
    foreach (row; row1 .. row2) {
        foreach (col; col1 .. col2) {
            if (map[row, col] == -1) {
                continue;
            }
            drawTile(
                sprite,
                map[row, col],
                map.cellSize,
                Vec2(position.x + col * map.cellSize.x, position.y + row * map.cellSize.y),
                rotation,
                scale,
                color,
                hook,
                flip,
            );
        }
    }
}

Vec2 measureText(Font font, Vec2 spacing, const(char)[] text, Vec2 scale = Vec2(1.0f)) {
    if (font.isEmpty || text.length == 0) {
        return Vec2();
    }
    auto result = Vec2();
    auto tempByteCounter = 0; // Used to count longer text line num chars.
    auto byteCounter = 0;
    auto textWidth = 0.0f;
    auto tempTextWidth = 0.0f; // Used to count longer text line width.
    auto textHeight = font.size;

    int letter = 0; // Current character.
    int index = 0; // Index position in sprite font.
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
            textHeight += spacing.y;
        }
        if (tempByteCounter < byteCounter) {
            tempByteCounter = byteCounter;
        }
    }
    if (tempTextWidth < textWidth) {
        tempTextWidth = textWidth;
    }
    result.x = floor(tempTextWidth * scale.x + ((tempByteCounter - 1) * spacing.x * scale.x));
    result.y = floor(textHeight * scale.y);
    return result;
}

void drawRune(Font font, dchar rune, Vec2 position = Vec2(), float rotation = 0.0f, Vec2 scale = Vec2(1.0f), Color color = white, Hook hook = Hook.topLeft) {
    if (font.isEmpty) {
        return;
    }
    auto origin = toPopka(ray.GetGlyphAtlasRec(font.data, rune)).origin(hook).floor();
    raygl.rlPushMatrix();
    raygl.rlTranslatef(floor(position.x), floor(position.y), 0.0f);
    raygl.rlRotatef(rotation, 0.0f, 0.0f, 1.0f);
    raygl.rlScalef (scale.x, scale.y, 1.0f);
    raygl.rlTranslatef(-origin.x, -origin.y, 0.0f);
    ray.DrawTextCodepoint(font.data, rune, ray.Vector2(0.0f, 0.0f), font.size, toRay(color));
    raygl.rlPopMatrix();
}

void drawText(Font font, Vec2 spacing, const(char)[] text, Vec2 position = Vec2(), float rotation = 0.0f, Vec2 scale = Vec2(1.0f), Color color = white, Hook hook = Hook.topLeft) {
    if (font.isEmpty || text.length == 0) {
        return;
    }
    auto origin = Rect(measureText(font, spacing, text, Vec2(1.0f))).origin(hook);
    raygl.rlPushMatrix();
    raygl.rlTranslatef(floor(position.x), floor(position.y), 0.0f);
    raygl.rlRotatef(rotation, 0.0f, 0.0f, 1.0f);
    raygl.rlScalef (scale.x, scale.y, 1.0f);
    raygl.rlTranslatef(-origin.x, -origin.y, 0.0f);
    auto textOffsetY = 0.0f; // Offset between lines (on linebreak '\n').
    auto textOffsetX = 0.0f; // Offset X to next character to draw.
    auto i = 0;
    while (i < text.length) {
        // Get next codepoint from byte string and glyph index in font.
        auto codepointByteCount = 0;
        auto codepoint = ray.GetCodepointNext(&text[i], &codepointByteCount);
        auto index = ray.GetGlyphIndex(font.data, codepoint);
        if (codepoint == '\n') {
            textOffsetY += spacing.y;
            textOffsetX = 0.0f;
        } else {
            if (codepoint != ' ' && codepoint != '\t') {
                drawRune(font, codepoint, Vec2(textOffsetX, textOffsetY), 0.0f, Vec2(1.0f), color);
            }
            if (font.data.glyphs[index].advanceX == 0) {
                textOffsetX += font.data.recs[index].width + spacing.x;
            } else {
                textOffsetX += font.data.glyphs[index].advanceX + spacing.x;
            }
        }
        // Move text bytes counter to next codepoint.
        i += codepointByteCount;
    }
    raygl.rlPopMatrix();
}

void drawDebugText(const(char)[] text, Vec2 position = Vec2(8.0f), float rotation = 0.0f, Vec2 scale = Vec2(2.0f), Color color = gray, Hook hook = Hook.topLeft) {
    drawText(rayFont, rayFontSpacing, text, position, rotation, scale, color, hook);
}

unittest {}
