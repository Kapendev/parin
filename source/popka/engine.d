// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

// TODO: Needs docs!

/// The `engine` module functions as a lightweight 2D game engine.
module popka.engine;

import ray = popka.ray;

public import joka;
public import popka.types;

@safe @nogc nothrow:

private
ray.Camera2D _toRay(Camera camera) {
    return ray.Camera2D(
        Rect(resolution).origin(camera.isCentered ? Hook.center : Hook.topLeft).toRay(),
        camera.position.toRay(),
        camera.rotation,
        camera.scale,
    );
}

/// Returns a random integer between 0 and float.max (inclusive).
@trusted
int randi() {
    return ray.GetRandomValue(0, cast(int) float.max);
}

/// Returns a random floating point number between 0.0f and 1.0f (inclusive).
float randf() {
    return randi() / float.max;
}

/// Sets the seed for the random number generator to something specific.
@trusted
void randomize(int seed) {
    ray.SetRandomSeed(seed);
}

/// Randomizes the seed of the random number generator.
void randomize() {
    randomize(randi);
}

/// Converts a world point to a screen point based on the given camera.
@trusted
Vec2 toScreenPosition(Vec2 point, Camera camera) {
    return toPopka(ray.GetWorldToScreen2D(point.toRay(), camera._toRay()));
}

/// Converts a screen point to a world point based on the given camera.
@trusted
Vec2 toWorldPosition(Vec2 point, Camera camera) {
    return toPopka(ray.GetScreenToWorld2D(point.toRay(), camera._toRay()));
}

/// Returns the default font. This font should not be freed.
@trusted
Font dfltFont() {
    auto result = ray.GetFontDefault().toPopka();
    result.runeSpacing = 1;
    result.lineSpacing = 14;
    return result;
}

IStr assetsPath() {
    return engineState.assetsPath.items;
}

IStr toAssetsPath(IStr path) {
    return pathConcat(assetsPath, path).pathFormat();
}

/// Loads a text file from the assets folder and returns its contents as a list.
/// Can handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.
Result!LStr loadText(IStr path) {
    return readText(path.toAssetsPath());
}

/// Loads a text file from the assets folder and returns its contents as a slice.
/// The slice can be safely used until this function is called again.
/// Can handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.
Result!IStr loadTempText(IStr path) {
    auto fault = readTextIntoBuffer(path.toAssetsPath(), engineState.tempText);
    return Result!IStr(engineState.tempText.items, fault);
}

Result!TileMap loadTileMap(IStr path) {
    auto value = TileMap();
    auto fault = value.parse(loadTempText(path).unwrapOr());
    if (fault) {
        value.free();
    }
    return Result!TileMap(value, fault);
}

/// Loads an image file from the assets folder.
/// Can handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.
@trusted
Result!Texture loadTexture(IStr path) {
    auto value = ray.LoadTexture(path.toAssetsPath().toCStr().unwrapOr()).toPopka();
    return Result!Texture(value, value.isEmpty.toFault());
}

@trusted
Result!Viewport loadViewport(int width, int height) {
    auto value = ray.LoadRenderTexture(width, height).toPopka();
    return Result!Viewport(value, value.isEmpty.toFault());
}

@trusted
Result!Font loadFont(IStr path, uint size, const(dchar)[] runes = []) {
    auto value = ray.LoadFontEx(path.toAssetsPath.toCStr().unwrapOr(), size, cast(int*) runes.ptr, cast(int) runes.length).toPopka();
    return Result!Font(value, value.isEmpty.toFault());
}

/// Saves a text file to the assets folder.
/// Can handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.
Fault saveText(IStr path, IStr text) {
    return writeText(path.toAssetsPath(), text);
}

/// Opens the game window with the given size and title.
/// This function does not work if the window is already open, because Popka only works with one window.
/// Usually you should avoid calling this function manually.
@trusted
void openWindow(int width, int height, IStr title = "Popka") {
    if (ray.IsWindowReady) {
        return;
    }
    ray.SetConfigFlags(ray.FLAG_VSYNC_HINT | ray.FLAG_WINDOW_RESIZABLE);
    ray.SetTraceLogLevel(ray.LOG_ERROR);
    ray.InitWindow(width, height, title.toCStr().unwrapOr());
    ray.InitAudioDevice();
    ray.SetExitKey(ray.KEY_NULL);
    lockFps(60);
    engineState.backgroundColor = gray2;
    engineState.fullscreenState.lastWindowSize = Vec2(width, height);
}

/// Updates the game window every frame with the specified loop function.
/// This function will return when the loop function returns true.
@trusted
void updateWindow(alias loopFunc)() {
    static bool __updateWindow() {
        // Begin drawing.
        if (isResolutionLocked) {
            ray.BeginTextureMode(engineState.viewport.toRay());
        } else {
            ray.BeginDrawing();
        }
        ray.ClearBackground(engineState.backgroundColor.toRay());

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
                engineState.viewport.toRay().texture,
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
        if (engineState.viewport.isLockResolutionQueued) {
            engineState.viewport.isLockResolutionQueued = false;
            // engineState.viewport.load(engineState.targetViewportSize); // TODO
        } else if (engineState.viewport.isUnlockResolutionQueued) {
            engineState.viewport.isUnlockResolutionQueued = false;
            // engineState.viewport.free(); // TODO
        }
        // Fullscreen code to fix a bug on KDE.
        if (engineState.fullscreenState.isToggleQueued) {
            engineState.fullscreenState.toggleTimer += deltaTime;
            if (engineState.fullscreenState.toggleTimer >= engineState.fullscreenState.toggleWaitTime) {
                engineState.fullscreenState.toggleTimer = 0.0f;
                auto screen = screenSize;
                auto window = engineState.fullscreenState.lastWindowSize;
                if (ray.IsWindowFullscreen()) {
                    ray.ToggleFullscreen();
                    ray.SetWindowSize(cast(int) window.x, cast(int) window.y);
                    ray.SetWindowPosition(cast(int) (screen.x * 0.5f - window.x * 0.5f), cast(int) (screen.y * 0.5f - window.y * 0.5f));
                } else {
                    ray.ToggleFullscreen();
                }
                engineState.fullscreenState.isToggleQueued = false;
            }
        }
        return result;
    }

    engineState.flags.isUpdating = true;
    version(WebAssembly) {
        static void __updateWindowWeb() {
            if (__updateWindow()) {
                engineState.flags.isUpdating = false;
                ray.emscripten_cancel_main_loop();
            }
        }
        ray.emscripten_set_main_loop(&__updateWindowWeb, 0, 1);
    } else {
        // NOTE: Maybe bad idea, but makes life of no-attribute people easier.
        auto __updateWindowScary = cast(bool function() @trusted @nogc nothrow) &__updateWindow;
        while (true) {
            if (ray.WindowShouldClose() || __updateWindowScary()) {
                engineState.flags.isUpdating = false;
                break;
            }
        }
    }
}

/// Closes the game window.
/// Usually you should avoid calling this function manually.
@trusted
void closeWindow() {
    if (!ray.IsWindowReady) {
        return;
    }
    
    engineState.tempText.free();
    engineState.assetsPath.free();
    engineState.viewport.free();

    ray.CloseAudioDevice();
    ray.CloseWindow();
    engineState = EngineState();
}

/// Returns true if the FPS of the game is locked.
bool isFpsLocked() {
    return engineState.flags.isFpsLocked;
}

/// Locks the FPS of the game to a specific value.
@trusted
void lockFps(int target) {
    engineState.flags.isFpsLocked = true;
    ray.SetTargetFPS(target);
}

/// Unlocks the FPS of the game.
@trusted
void unlockFps() {
    engineState.flags.isFpsLocked = false;
    ray.SetTargetFPS(0);
}

/// Returns true if the resolution of the game is locked.
bool isResolutionLocked() {
    return !engineState.viewport.isEmpty;
}

/// Locks the resolution of the game to a specific value.
@trusted
void lockResolution(int width, int height) {
    if (!engineState.flags.isUpdating) {
        engineState.viewport.data = loadViewport(width, height).unwrap();
    } else {
        engineState.viewport.targetWidth = width;
        engineState.viewport.targetHeight = height;
        engineState.viewport.isLockResolutionQueued = true;
        engineState.viewport.isUnlockResolutionQueued = false;
    }
}

/// Unlocks the resolution of the game.
void unlockResolution() {
    if (!engineState.flags.isUpdating) {
        engineState.viewport.free();
    } else {
        engineState.viewport.isUnlockResolutionQueued = true;
        engineState.viewport.isLockResolutionQueued = false;
    }
}

/// Returns true if the system cursor is hidden.
bool isCursorHidden() {
    return engineState.flags.isCursorHidden;
}

/// Hides the system cursor.
/// This function works only on desktop.
@trusted
void hideCursor() {
    engineState.flags.isCursorHidden = true;
    ray.HideCursor();
}

/// Shows the system cursor.
/// This function works only on desktop.
@trusted
void showCursor() {
    engineState.flags.isCursorHidden = false;
    ray.ShowCursor();
}

/// Returns true if the window is in fullscreen mode.
/// This function works only on desktop.
@trusted
bool isFullscreen() {
    return ray.IsWindowFullscreen();
}

/// Changes the state of the fullscreen mode of the window.
/// This function works only on desktop.
@trusted
void toggleFullscreen() {
    version(WebAssembly) {

    } else {
        if (!ray.IsWindowFullscreen()) {
            auto screen = screenSize;
            engineState.fullscreenState.lastWindowSize = windowSize;
            ray.SetWindowPosition(0, 0);
            ray.SetWindowSize(screenWidth, screenHeight);
        }
        engineState.fullscreenState.isToggleQueued = true;
    }
}

/// Returns true if the drawing is done in a pixel perfect way.
bool isPixelPerfect() {
    return engineState.flags.isPixelPerfect;
}

void togglePixelPerfect() {
    engineState.flags.isPixelPerfect = !engineState.flags.isPixelPerfect;
}

@trusted
int screenWidth() {
    return ray.GetMonitorWidth(ray.GetCurrentMonitor());
}

@trusted
int screenHeight() {
    return ray.GetMonitorHeight(ray.GetCurrentMonitor());
}

Vec2 screenSize() {
    return Vec2(screenWidth, screenHeight);
}

@trusted
int windowWidth() {
    return ray.GetScreenWidth();
}

@trusted
int windowHeight() {
    return ray.GetScreenHeight();
}

Vec2 windowSize() {
    if (isFullscreen) {
        return screenSize;
    } else {
        return Vec2(windowWidth, windowHeight);
    }
}

int resolutionWidth() {
    if (isResolutionLocked) {
        return engineState.viewport.width;
    } else {
        return windowWidth;
    }
}

int resolutionHeight() {
    if (isResolutionLocked) {
        return engineState.viewport.height;
    } else {
        return windowHeight;
    }
}

Vec2 resolution() {
    return Vec2(resolutionWidth, resolutionHeight);
}

@trusted
Vec2 mouseScreenPosition() {
    if (isResolutionLocked) {
        auto window = windowSize;
        auto minRatio = min(window.x / engineState.viewport.size.x, window.y / engineState.viewport.size.y);
        auto targetSize = engineState.viewport.size * Vec2(minRatio);
        // We use touch because it works on desktop, web and mobile.
        return Vec2(
            (ray.GetTouchX() - (window.x - targetSize.x) * 0.5f) / minRatio,
            (ray.GetTouchY() - (window.y - targetSize.y) * 0.5f) / minRatio,
        );
    } else {
        return Vec2(ray.GetTouchX(), ray.GetTouchY());
    }
}

Vec2 mouseWorldPosition(Camera camera) {
    return mouseScreenPosition.toWorldPosition(camera);
}

@trusted
float mouseWheel() {
    return ray.GetMouseWheelMove();
}

@trusted
int fps() {
    return ray.GetFPS();
}

@trusted
float deltaTime() {
    return ray.GetFrameTime();
}

@trusted
Vec2 deltaMouse() {
    return toPopka(ray.GetMouseDelta());
}

@trusted
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

@trusted
bool isPressed(char key) {
    return ray.IsKeyPressed(toUpper(key));
}

@trusted
bool isPressed(Keyboard key) {
    return ray.IsKeyPressed(key);
}

@trusted
bool isPressed(Mouse key) {
    return ray.IsMouseButtonPressed(key);
}

@trusted
bool isPressed(Gamepad key, int id = 0) {
    return ray.IsGamepadButtonPressed(id, key);
}

@trusted
bool isDown(char key) {
    return ray.IsKeyDown(toUpper(key));
}

@trusted
bool isDown(Keyboard key) {
    return ray.IsKeyDown(key);
}

@trusted
bool isDown(Mouse key) {
    return ray.IsMouseButtonDown(key);
}

@trusted
bool isDown(Gamepad key, int id = 0) {
    return ray.IsGamepadButtonDown(id, key);
}

@trusted
bool isReleased(char key) {
    return ray.IsKeyReleased(toUpper(key));
}

@trusted
bool isReleased(Keyboard key) {
    return ray.IsKeyReleased(key);
}

@trusted
bool isReleased(Mouse key) {
    return ray.IsMouseButtonReleased(key);
}

@trusted
bool isReleased(Gamepad key, int id = 0) {
    return ray.IsGamepadButtonReleased(id, key);
}

Vec2 wasd() {
    auto result = Vec2();
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

@trusted
void drawRect(Rect area, Color color = white) {
    if (isPixelPerfect) {
        ray.DrawRectanglePro(area.floor().toRay(), ray.Vector2(0.0f, 0.0f), 0.0f, color.toRay());
    } else {
        ray.DrawRectanglePro(area.toRay(), ray.Vector2(0.0f, 0.0f), 0.0f, color.toRay());
    }
}

void drawVec2(Vec2 point, float size, Color color = white) {
    drawRect(Rect(point, size, size).centerArea, color);
}

@trusted
void drawCirc(Circ area, Color color = white) {
    if (isPixelPerfect) {
        ray.DrawCircleV(area.position.floor().toRay(), area.radius, color.toRay());
    } else {
        ray.DrawCircleV(area.position.toRay(), area.radius, color.toRay());
    }
}

@trusted
void drawLine(Line area, float size, Color color = white) {
    if (isPixelPerfect) {
        ray.DrawLineEx(area.a.floor().toRay(), area.b.floor().toRay(), size, color.toRay());
    } else {
        ray.DrawLineEx(area.a.toRay(), area.b.toRay(), size, color.toRay());
    }
}

@trusted
void drawTexture(Texture texture, Vec2 position, Rect area, DrawOptions options = DrawOptions()) {
    if (texture.isEmpty) {
        return;
    } else if (area.size.x <= 0.0f || area.size.y <= 0.0f) {
        return;
    }

    auto target = Rect(position, area.size * options.scale.abs());
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
        case Flip.x: area.size.x *= -1.0f; break;
        case Flip.y: area.size.y *= -1.0f; break;
        case Flip.xy: area.size *= Vec2(-1.0f); break;
    }

    auto origin = options.origin == Vec2() ? target.origin(options.hook) : options.origin;
    if (isPixelPerfect) {
        ray.DrawTexturePro(
            texture.data,
            area.floor().toRay(),
            target.floor().toRay(),
            origin.floor().toRay(),
            options.rotation,
            options.color.toRay(),
        );
    } else {
        ray.DrawTexturePro(
            texture.data,
            area.toRay(),
            target.toRay(),
            origin.toRay(),
            options.rotation,
            options.color.toRay(),
        );
    }
}

void drawTexture(Texture texture, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTexture(texture, position, Rect(texture.size), options);
}

void drawTile(Texture texture, Vec2 position, int tileID, Vec2 tileSize, DrawOptions options = DrawOptions()) {
    auto gridWidth = cast(int) (texture.size.x / tileSize.x);
    auto gridHeight = cast(int) (texture.size.y / tileSize.y);
    if (gridWidth == 0 || gridHeight == 0) {
        return;
    }
    auto row = tileID / gridWidth;
    auto col = tileID % gridWidth;
    auto area = Rect(col * tileSize.x, row * tileSize.y, tileSize.x, tileSize.y);
    drawTexture(texture, position, area, options);
}

void drawTileMap(Texture texture, Vec2 position, TileMap tileMap, Camera camera, DrawOptions options = DrawOptions()) {
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
            drawTile(texture, position + Vec2(col, row) * tileMap.tileSize * options.scale, tileMap[row, col], tileMap.tileSize, options);
        }
    }
}

@trusted
void drawRune(Font font, Vec2 position, dchar rune, DrawOptions options = DrawOptions()) {
    if (font.isEmpty) {
        return;
    }

    auto rect = toPopka(ray.GetGlyphAtlasRec(font.data, rune));
    auto origin = options.origin == Vec2() ? rect.origin(options.hook) : options.origin;
    ray.rlPushMatrix();
    if (isPixelPerfect) {
        ray.rlTranslatef(position.x.floor(), position.y.floor(), 0.0f);
    } else {
        ray.rlTranslatef(position.x, position.y, 0.0f);
    }
    ray.rlRotatef(options.rotation, 0.0f, 0.0f, 1.0f);
    ray.rlScalef(options.scale.x, options.scale.y, 1.0f);
    if (isPixelPerfect) {
        ray.rlTranslatef(-origin.x.floor(), -origin.y.floor(), 0.0f);
    } else {
        ray.rlTranslatef(-origin.x, -origin.y, 0.0f);
    }
    ray.DrawTextCodepoint(font.data, rune, ray.Vector2(0.0f, 0.0f), font.size, options.color.toRay());
    ray.rlPopMatrix();
}

@trusted
void drawText(Font font, Vec2 position, IStr text, DrawOptions options = DrawOptions()) {
    if (font.isEmpty || text.length == 0) {
        return;
    }

    // TODO: Make it work with negative scale values.
    auto origin = Rect(measureTextSize(font, text)).origin(options.hook);
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
                drawRune(font, Vec2(textOffsetX, textOffsetY), codepoint, runeOptions);
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

void drawDebugText(IStr text, Vec2 position = Vec2(8.0f), DrawOptions options = DrawOptions()) {
    drawText(dfltFont, position, text, options);
}

mixin template addGameStart(alias startFunc, int width, int height, IStr title = "Popka") {
    version (D_BetterC) {
        pragma(msg, "Popka is using the C main function.");
        extern(C)
        void main(int argc, immutable(char)** argv) {
            engineState.assetsPath.append(
                pathConcat(argv[0].toStr().pathDir, "assets")
            );
            engineState.tempText.reserve(8192);
            openWindow(width, height);
            startFunc();
            closeWindow();
        }
    } else {
        pragma(msg, "Popka is using the D main function.");
        void main(string[] args) {
            engineState.assetsPath.append(
                pathConcat(args[0].pathDir, "assets")
            );
            engineState.tempText.reserve(8192);
            openWindow(width, height);
            startFunc();
            closeWindow();
        }
    }
}
