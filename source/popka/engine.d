// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The engine module functions as a lightweight 2D game engine.
module popka.engine;

import ray = popka.ray;

public import joka;
public import popka.types;
public import popka.utils;

@trusted @nogc nothrow:

/// Returns a random int between 0 and int.max (inclusive).
int randi() {
    return ray.GetRandomValue(0, int.max);
}

/// Returns a random float between 0.0f and 1.0f (inclusive).
float randf() {
    return ray.GetRandomValue(0, cast(int) float.max) / cast(float) cast(int) float.max;
}

/// Sets the seed for the random number generator to something specific.
void randomize(uint seed) {
    ray.SetRandomSeed(seed);
}

/// Randomizes the seed of the random number generator.
void randomize() {
    randomize(randi);
}

/// Converts a screen point to a world point based on the given camera.
Vec2 toWorldPoint(Vec2 point, Camera camera) {
    return toPopka(ray.GetScreenToWorld2D(toRay(point), toRay(camera)));
}

/// Converts a world point to a screen point based on the given camera.
Vec2 toScreenPoint(Vec2 point, Camera camera) {
    return toPopka(ray.GetWorldToScreen2D(toRay(point), toRay(camera)));
}

/// Returns the default raylib font. This font should not be freed.
Font rayFont() {
    auto result = toPopka(ray.GetFontDefault());
    result.runeSpacing = 1;
    result.lineSpacing = 14;
    return result;
}

/// Opens the game window with the given size and title.
/// This function does not work if the window is already open, because Popka only works with one window.
/// Usually you should avoid calling this function manually.
void openWindow(int width, int height, IStr title = "Popka") {
    if (ray.IsWindowReady) {
        return;
    }
    ray.SetConfigFlags(ray.FLAG_VSYNC_HINT | ray.FLAG_WINDOW_RESIZABLE);
    ray.SetTraceLogLevel(ray.LOG_ERROR);
    ray.InitWindow(width, height, title.toCStr().unwrapOr());
    ray.InitAudioDevice();
    ray.SetExitKey(ray.KEY_NULL);
    lockFPS(engineState.dfltFPS);
    engineState.backgroundColor = engineState.dfltBackgroundColor;
    engineState.lastWindowSize = Vec2(width, height);
}

/// Updates the game window every frame with the specified loop function.
/// This function will return when the loop function returns true.
void updateWindow(alias loopFunc)() {
    static bool __updateWindow() {
        // Begin drawing.
        if (isResolutionLocked) {
            ray.BeginTextureMode(engineState.viewport.data);
        } else {
            ray.BeginDrawing();
        }
        ray.ClearBackground(toRay(engineState.backgroundColor));

        // The main loop.
        auto result = loopFunc();

        // End drawing.
        if (isResolutionLocked) {
            auto minSize = engineState.viewport.size;
            auto maxSize = windowSize;
            auto ratio = maxSize / minSize;
            auto minRatio = min(ratio.x, ratio.y);
            auto targetSize = minSize * Vec2(minRatio);
            auto targetPos = maxSize * Vec2(0.5f) - targetSize * Vec2(0.5f);
            ray.EndTextureMode();
            ray.BeginDrawing();
            ray.ClearBackground(ray.Color(0, 0, 0, 255));
            ray.DrawTexturePro(
                engineState.viewport.data.texture,
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
        if (engineState.isLockResolutionQueued) {
            engineState.isLockResolutionQueued = false;
            // engineState.viewport.load(engineState.targetViewportSize); // TODO
        } else if (engineState.isUnlockResolutionQueued) {
            engineState.isUnlockResolutionQueued = false;
            // engineState.viewport.free(); // TODO
        }
        // Fullscreen code to fix a bug on KDE.
        if (engineState.isToggleFullscreenQueued) {
            engineState.toggleFullscreenTimer += deltaTime;
            if (engineState.toggleFullscreenTimer >= engineState.dfltFullscreenWaitTime) {
                engineState.toggleFullscreenTimer = 0.0f;
                auto screen = screenSize;
                auto window = engineState.lastWindowSize;
                if (ray.IsWindowFullscreen()) {
                    ray.ToggleFullscreen();
                    ray.SetWindowSize(cast(int) window.x, cast(int) window.y);
                    ray.SetWindowPosition(cast(int) (screen.x * 0.5f - window.x * 0.5f), cast(int) (screen.y * 0.5f - window.y * 0.5f));
                } else {
                    ray.ToggleFullscreen();
                }
                engineState.isToggleFullscreenQueued = false;
            }
        }
        return result;
    }

    engineState.flags.isUpdating = true;
    version(WebAssembly) {
        static void __updateWindow2() {
            if (__updateWindow()) {
                engineState.flags.isUpdating = false;
                ray.emscripten_cancel_main_loop();
            }
        }
        ray.emscripten_set_main_loop(&__updateWindow2, 0, 1);
    } else {
        // NOTE: Maybe bad idea, but makes life of no-attribute people easier.
        auto __updateWindowScaryEdition = cast(bool function() @trusted @nogc nothrow) &__updateWindow;
        while (true) {
            if (ray.WindowShouldClose() || __updateWindowScaryEdition()) {
                engineState.flags.isUpdating = false;
                break;
            }
        }
    }
}

/// Closes the game window.
/// Usually you should avoid calling this function manually.
void closeWindow() {
    if (!ray.IsWindowReady) {
        return;
    }
    
    engineState.assetsPath.free();
    engineState.tempText.free();
    // engineState.viewport.free(); // TODO: free the viewport.
    
    ray.CloseAudioDevice();
    ray.CloseWindow();
    
    engineState = EngineState.init;
}

/// Returns true if the FPS of the game is locked.
bool isFpsLocked() {
    return engineState.flags.isFpsLocked;
}

/// Locks the FPS of the game to a specific value.
void lockFPS(uint target) {
    ray.SetTargetFPS(target);
    engineState.flags.isFpsLocked = true;
}

/// Unlocks the FPS of the game.
void unlockFPS() {
    ray.SetTargetFPS(0);
    engineState.flags.isFpsLocked = false;
}

/// Returns true if the resolution of the game is locked.
bool isResolutionLocked() {
    return !engineState.viewport.isEmpty;
}

/// Locks the resolution of the game to a specific value.
void lockResolution(Vec2 size) {
    if (!engineState.flags.isUpdating) {
        // engineState.viewport.load(size); // TODO: Add loading.
    } else {
        engineState.targetViewportSize = size;
        engineState.isLockResolutionQueued = true;
        engineState.isUnlockResolutionQueued = false;
    }
}

/// Locks the resolution of the game to a specific value.
void lockResolution(float width, float height) {
    lockResolution(Vec2(width, height));
}

/// Unlocks the resolution of the game.
void unlockResolution() {
    if (!engineState.flags.isUpdating) {
        // engineState.viewport.free(); // TODO: Add free.
    } else {
        engineState.isUnlockResolutionQueued = true;
        engineState.isLockResolutionQueued = false;
    }
}

/// Returns true if the system cursor is hidden.
bool isCursorHidden() {
    return engineState.flags.isCursorHidden;
}

/// Hides the system cursor.
/// This function works only on desktop.
void hideCursor() {
    ray.HideCursor();
    engineState.flags.isCursorHidden = true;
}

/// Shows the system cursor.
/// This function works only on desktop.
void showCursor() {
    ray.ShowCursor();
    engineState.flags.isCursorHidden = false;
}

/// Returns the assets folder path.
IStr assetsPath() {
    return engineState.assetsPath.items;
}

/// Returns true if the window is in fullscreen mode.
/// This function works only on desktop.
bool isFullscreen() {
    return ray.IsWindowFullscreen;
}

/// Changes the state of the fullscreen mode of the window.
/// This function works only on desktop.
void toggleFullscreen() {
    version(WebAssembly) {

    } else {
        if (!ray.IsWindowFullscreen()) {
            auto screen = screenSize;
            engineState.lastWindowSize = windowSize;
            ray.SetWindowPosition(0, 0);
            ray.SetWindowSize(cast(int) screen.x, cast(int) screen.y);
        }
        engineState.isToggleFullscreenQueued = true;
    }
}

/// Returns true if the drawing is done in a pixel perfect way.
bool isPixelPerfect() {
    return engineState.flags.isPixelPerfect;
}

void togglePixelPerfect() {
    engineState.flags.isPixelPerfect = !engineState.flags.isPixelPerfect;
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
        return engineState.viewport.size;
    } else {
        return windowSize;
    }
}

Vec2 mouseScreenPosition() {
    if (isResolutionLocked) {
        auto window = windowSize;
        auto minRatio = min(window.x / engineState.viewport.size.x, window.y / engineState.viewport.size.y);
        auto targetSize = engineState.viewport.size * Vec2(minRatio);
        // We use touch because it works on desktop, web and phones.
        return Vec2(
            (ray.GetTouchX() - (window.x - targetSize.x) * 0.5f) / minRatio,
            (ray.GetTouchY() - (window.y - targetSize.y) * 0.5f) / minRatio,
        );
    } else {
        return Vec2(ray.GetTouchX(), ray.GetTouchY());
    }
}

Vec2 mouseWorldPosition(Camera camera) {
    return mouseScreenPosition.toWorldPoint(camera);
}

int fps() {
    return ray.GetFPS();
}

float deltaTime() {
    return ray.GetFrameTime();
}

float deltaMouseWheel() {
    return ray.GetMouseWheelMove();
}

Vec2 deltaMousePosition() {
    return toPopka(ray.GetMouseDelta());
}

Color backgroundColor() {
    return engineState.backgroundColor;
}

void changeBackgroundColor(Color color) {
    engineState.backgroundColor = color;
}

void changeShapeTexture(Texture texture, Rect area) {
    ray.SetShapesTexture(texture.data, toRay(area));
}

Vec2 measureTextSize(Font font, IStr text, DrawOptions options = DrawOptions()) {
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
    auto index = 0; // Index position in texture font.
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
            textHeight += font.lineSpacing;
        }
        if (tempByteCounter < byteCounter) {
            tempByteCounter = byteCounter;
        }
    }
    if (tempTextWidth < textWidth) {
        tempTextWidth = textWidth;
    }
    result.x = floor(tempTextWidth * options.scale.x + ((tempByteCounter - 1) * font.runeSpacing * options.scale.x));
    result.y = floor(textHeight * options.scale.y);
    return result;
}

Rect measureTextArea(Font font, IStr text, Vec2 position, DrawOptions options = DrawOptions()) {
    return Rect(position, measureTextSize(font, text, options)).area(options.hook);
}

Rect measureTextArea(Font font, IStr text, DrawOptions options = DrawOptions()) {
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

void draw(Rect area, Color color = white) {
    if (isPixelPerfect) {
        ray.DrawRectanglePro(toRay(area.floor()), ray.Vector2(0.0f, 0.0f), 0.0f, toRay(color));
    } else {
        ray.DrawRectanglePro(toRay(area), ray.Vector2(0.0f, 0.0f), 0.0f, toRay(color));
    }
}

void draw(Circ area, Color color = white) {
    if (isPixelPerfect) {
        ray.DrawCircleV(toRay(area.position.floor()), area.radius, toRay(color));
    } else {
        ray.DrawCircleV(toRay(area.position), area.radius, toRay(color));
    }
}

void draw(Line area, float size, Color color = white) {
    if (isPixelPerfect) {
        ray.DrawLineEx(toRay(area.a.floor()), toRay(area.b.floor()), size, toRay(color));
    } else {
        ray.DrawLineEx(toRay(area.a), toRay(area.b), size, toRay(color));
    }
}

void draw(Vec2 point, float size, Color color = white) {
    draw(Rect(point, size, size).centerArea, color);
}

void draw(Texture texture, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    if (texture.isEmpty) {
        return;
    }

    auto target = Rect();
    auto source = Rect();
    if (area.size.x <= 0.0f || area.size.y <= 0.0f) {
        target = Rect(position, texture.size * options.scale.abs());
        source = Rect(texture.size);
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
            texture.data,
            toRay(source.floor()),
            toRay(target.floor()),
            toRay(origin.floor()),
            options.rotation,
            toRay(options.color),
        );
    } else {
        ray.DrawTexturePro(
            texture.data,
            toRay(source),
            toRay(target),
            toRay(origin),
            options.rotation,
            toRay(options.color),
        );
    }
}

void draw(Texture texture, Vec2 position, DrawOptions options = DrawOptions()) {
    draw(texture, Rect(), position, options);
}

void draw(Texture texture, Vec2 tileSize, int tileID, Vec2 position, DrawOptions options = DrawOptions()) {
    auto gridWidth = cast(int) (texture.size.x / tileSize.x);
    auto gridHeight = cast(int) (texture.size.y / tileSize.y);
    if (gridWidth == 0 || gridHeight == 0) {
        return;
    }
    auto row = tileID / gridWidth;
    auto col = tileID % gridWidth;
    auto area = Rect(col * tileSize.x, row * tileSize.y, tileSize.x, tileSize.y);
    draw(texture, area, position, options);
}

void draw(Texture texture, TileMap tileMap, Camera camera, Vec2 position, DrawOptions options = DrawOptions()) {
    enum extraTileCount = 4;

    auto cameraArea = Rect(camera.position, resolution).area(camera.hook);
    auto topLeft = cameraArea.point(Hook.topLeft);
    auto bottomRight = cameraArea.point(Hook.bottomRight);
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
            draw(texture, tileMap.tileSize, tileMap[row, col], position + Vec2(col, row) * tileMap.tileSize * options.scale, options);
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
void draw(Font font, IStr text, Vec2 position, DrawOptions options = DrawOptions()) {
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
            textOffsetY += font.lineSpacing;
            textOffsetX = 0.0f;
        } else {
            if (codepoint != ' ' && codepoint != '\t') {
                auto runeOptions = DrawOptions();
                runeOptions.color = options.color;
                draw(font, codepoint, Vec2(textOffsetX, textOffsetY), runeOptions);
            }
            if (font.data.glyphs[index].advanceX == 0) {
                textOffsetX += font.data.recs[index].width + font.runeSpacing;
            } else {
                textOffsetX += font.data.glyphs[index].advanceX + font.runeSpacing;
            }
        }
        // Move text bytes counter to next codepoint.
        i += codepointByteCount;
    }
    ray.rlPopMatrix();
}

void draw(IStr text, Vec2 position = Vec2(8.0f), DrawOptions options = DrawOptions()) {
    draw(rayFont, text, position, options);
}

mixin template addGameStart(alias startFunc, int width, int height, IStr title = "Popka") {
    version (D_BetterC) {
        extern(C)
        void main(int argc, immutable(char)** argv) {
            debug {
                println("Popka is using the C main function.");
            }

            engineState.assetsPath.append(
                pathConcat(argv[0].toStr().pathDir, "assets")
            );
            engineState.tempText.reserve(dfltTempTextCapacity);

            openWindow(width, height);
            startFunc();
            closeWindow();
        }
    } else {
        void main(string[] args) {
            debug {
                println("Popka is using the D main function.");
            }

            engineState.assetsPath.append(
                pathConcat(args[0].pathDir, "assets")
            );
            engineState.tempText.reserve(engineState.dfltTempTextCapacity);

            openWindow(width, height);
            startFunc();
            closeWindow();
        }
    }
}
