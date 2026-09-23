// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

module parin.backend.rl;

import parin.joka.math;
import parin.joka.memory;
import parin.joka.types;
import parin.types;

BackendState* _backendState;

// ---------- Config
version (WebAssembly) {
    enum defaultBackendResourcesCapacity = 256;
} else {
    enum defaultBackendResourcesCapacity = 2048;
}

enum defaultBackendMaxSurfaceCount = 4;
enum defaultBackendMaxSurfaceSide = 1024;
// ----------

struct BackendState {}

@trusted:

/// Updates the window every frame with the given function.
/// Returns when the given function returns true.
void updateWindow(alias loopFunc)() {}

@trusted nothrow:

void openWindow(int width, int height, IStr title, bool vsync, int fpsMax, int windowMinWidth, int windowMinHeight) {}

void closeWindow() {}

Maybe!Surface loadSurface(IStr path, IStr file = __FILE__, Sz line = __LINE__) {
    return Maybe!Surface();
}

Maybe!Surface loadSurface(const(ubyte)[] memory, IStr ext = ".png", IStr file = __FILE__, Sz line = __LINE__) {
    return Maybe!Surface();
}

Maybe!ResourceId loadTexture(IStr path) {
    return Maybe!ResourceId();
}

Maybe!ResourceId loadTexture(const(ubyte)[] memory, IStr ext = ".png") {
    return Maybe!ResourceId();
}

Maybe!ResourceId loadFont(IStr path, int size, int runeSpacing, int lineSpacing, IStr32 runes) {
    return Maybe!ResourceId();
}

Maybe!ResourceId loadFont(const(ubyte)[] memory, int size, int runeSpacing, int lineSpacing, IStr32 runes, IStr ext = ".ttf") {
    return Maybe!ResourceId();
}

Maybe!ResourceId loadFont(ResourceId texture, int tileWidth, int tileHeight) {
    return Maybe!ResourceId();
}

Maybe!ResourceId loadViewport(int width, int height, Rgba color, Blend blend) {
    return Maybe!ResourceId();
}

Maybe!ResourceId loadSound(IStr path, float volume, float pitch, bool canRepeat, float pitchVariance = 1.0f) {
    return Maybe!ResourceId();
}

@trusted nothrow @nogc:

bool isBackendNull() {
    return _backendState != null;
}

void freeAllTextures(bool canSkipFirst) {}

void freeAllFonts(bool canSkipFirst, bool canSkipSecond /* LOL */) {}

void freeAllSounds(bool canSkipFirst) {}

void freeAllViewports(bool canSkipFirst) {}

Sz textureCount() {
    return 0;
}

Sz fontCount() {
    return 0;
}

Sz soundCount() {
    return 0;
}

Sz viewportCount() {
    return 0;
}

pragma(inline, true)
bool resourceIsNull(ResourceId id) {
    return id.value == 0;
}

pragma(inline, true)
bool textureIsValid(ResourceId id) {
    return false;
}

Filter textureFilter(ResourceId id) {
    return Filter.init;
}

void textureSetFilter(ResourceId id, Filter value) {}

Wrap textureWrap(ResourceId id) {
    return Wrap.init;
}

void textureSetWrap(ResourceId id, Wrap value) {}

int textureWidth(ResourceId id) {
    return 0;
}

int textureHeight(ResourceId id) {
    return 0;
}

Vec2 textureSize(ResourceId id) {
    return Vec2();
}

void textureFree(ResourceId id) {}

pragma(inline, true)
bool fontIsValid(ResourceId id) {
    return false;
}

Filter fontFilter(ResourceId id) {
    return Filter.init;
}

void fontSetFilter(ResourceId id, Filter value) {}

Wrap fontWrap(ResourceId id) {
    return Wrap.init;
}

void fontSetWrap(ResourceId id, Wrap value) {}

int fontSize(ResourceId id) {
    return 0;
}

int fontRuneSpacing(ResourceId id) {
    return 0;
}

void fontSetRuneSpacing(ResourceId id, int value) {}

int fontLineSpacing(ResourceId id) {
    return 0;
}

void fontSetLineSpacing(ResourceId id, int value) {}

GlyphInfo fontGlyphInfo(ResourceId id, int rune) {
    return GlyphInfo();
}

void fontFree(ResourceId id) {}

pragma(inline, true)
bool soundIsValid(ResourceId id) {
    return false;
}

float soundVolume(ResourceId id) {
    return 0.0f;
}

void soundSetVolume(ResourceId id, float value) {}

float soundPan(ResourceId id) {
    return 0.0f;
}

void soundSetPan(ResourceId id, float value) {}

float soundPitch(ResourceId id) {
    return 0.0f;
}

void soundSetPitch(ResourceId id, float value, bool canUpdatePitchVarianceBase) {}

float soundPitchVariance(ResourceId id) {
    return 0.0f;
}

void soundSetPitchVariance(ResourceId id, float value) {}

float soundPitchVarianceBase(ResourceId id) {
    return 0.0f;
}

void soundSetPitchVarianceBase(ResourceId id, float value) {}

bool soundCanRepeat(ResourceId id) {
    return false;
}

void soundSetCanRepeat(ResourceId id, bool value) {}

bool soundIsActive(ResourceId id) {
    return false;
}

bool soundIsPaused(ResourceId id) {
    return false;
}

float soundTime(ResourceId id) {
    return 0.0f;
}

float soundDuration(ResourceId id) {
    return 0.0f;
}

float soundProgress(ResourceId id) {
    return 0.0f;
}

void soundFree(ResourceId id) {}

pragma(inline, true)
bool viewportIsValid(ResourceId id) {
    return false;
}

Filter viewportFilter(ResourceId id) {
    return Filter.init;
}

void viewportSetFilter(ResourceId id, Filter value) {}

Wrap viewportWrap(ResourceId id) {
    return Wrap.init;
}

void viewportSetWrap(ResourceId id, Wrap value) {}

Blend viewportBlend(ResourceId id) {
    return Blend();
}

void viewportSetBlend(ResourceId id, Blend value) {}

Rgba viewportColor(ResourceId id) {
    return Rgba();
}

void viewportSetColor(ResourceId id, Rgba value) {}

int viewportWidth(ResourceId id) {
    return 0;
}

int viewportHeight(ResourceId id) {
    return 0;
}

Vec2 viewportSize(ResourceId id) {
    return Vec2();
}

bool viewportIsFirstUse(ResourceId id) {
    return false;
}

bool viewportIsAttached(ResourceId id) {
    return false;
}

void viewportResize(ResourceId id, int newWidth, int newHeight) {}

void viewportFree(ResourceId id) {}

void beginDroppedPaths() {}

void endDroppedPaths() {}

IStr[] droppedPaths() {
    return [];
}

int screenWidth() {
    return 0;
}

int screenHeight() {
    return 0;
}

int windowWidth() {
    return 0;
}

int windowHeight() {
    return 0;
}

bool isFullscreen() {
    return false;
}

void setIsFullscreen(bool value) {}

void updateIsFullscreen() {}

bool isWindowCloseButtonPressed() {
    return false;
}

bool isWindowResized() {
    return false;
}

void setWindowMinSize(int width, int height) {}

void setWindowMaxSize(int width, int height) {}

void setWindowTitle(IStr value) {}

Fault setWindowIconFromFiles(IStr path) {
    return Fault.none;
}

Fault takeScreenshot(IStr path, ResourceId canvasViewportId, bool hasAlpha) {
    return Fault.none;
}

Maybe!ResourceId takeScreenshotAndUseAsTexture(ResourceId canvasViewportId, bool hasAlpha) {
    return Maybe!ResourceId();
}

void openUrl(IStr url) {}

int fps() {
    return 0;
}

int fpsMax() {
    return 0;
}

void setFpsMax(int value) {}

double elapsedTime() {
    return 0.0;
}

float deltaTime() {
    return 0.0f;
}

void setRandomSeed(int value) {}

void randomize() {}

int randi() {
    return 0;
}

float randf() {
    return 0.0f;
}

Vec2 toCanvasPoint(Vec2 point, Camera camera, Vec2 canvasSize) {
    return Vec2();
}

Vec2 toScenePoint(Vec2 point, Camera camera, Vec2 canvasSize) {
    return Vec2();
}

ulong elapsedTicks() {
    return 0;
}

bool vsync() {
    return false;
}

void setVsync(bool value) {}

void updateVsync() {}

bool isCursorVisible() {
    return false;
}

void setIsCursorVisible(bool value) {}

void pumpEvents() {}

bool isDown(char key) {
    return false;
}

bool isDown(Keyboard key) {
    return false;
}

bool isDown(Mouse key) {
    return false;
}

bool isDown(Gamepad key, int id = 0) {
    return false;
}

bool isPressed(char key) {
    return false;
}

bool isPressed(Keyboard key) {
    return false;
}

bool isPressed(Mouse key) {
    return false;
}

bool isPressed(Gamepad key, int id = 0) {
    return false;
}

bool isReleased(char key) {
    return false;
}

bool isReleased(Keyboard key) {
    return false;
}

bool isReleased(Mouse key) {
    return false;
}

bool isReleased(Gamepad key, int id = 0) {
    return false;
}

Vec2 mouse() {
    return Vec2();
}

Vec2 deltaMouse() {
    return Vec2();
}

float deltaWheel() {
    return 0.0f;
}

Keyboard dequeuePressedKey() {
    return Keyboard.init;
}

dchar dequeuePressedRune() {
    return dchar.init;
}

float masterVolume() {
    return 0.0f;
}

void setMasterVolume(float value) {}

void updateSoundPitchVariance(ResourceId id) {}

void activateSound(ResourceId id) {}

void deactivateSound(ResourceId id) {}

void playSound(ResourceId id) {}

void stopSound(ResourceId id) {}

void startSound(ResourceId id) {}

void pauseSound(ResourceId id) {}

void resumeSound(ResourceId id) {}

void updateSound(ResourceId id) {}

void beginDrawing() {}

void endDrawing() {}

void beginCamera(ref Camera camera, Vec2 canvasSize, Rounding type) {}

void endCamera(ref Camera camera) {}

void beginViewport(ResourceId id) {}

void endViewport(ResourceId id) {}

void beginBlend(Blend blend) {}

void endBlend() {}

void beginClip(Rect area) {}

void endClip() {}

void clearBackground(Rgba color) {}

void pushMatrix() {}

void matrixTranslate(float x, float y, float z) {}

void matrixRotate(float angle, float x, float y, float z) {}

void matrixScale(float x, float y, float z) {}

void popMatrix() {}

void drawRect(Rect area, Rgba color, float thickness) {}

void drawCirc(Circ area, Rgba color, float thickness) {}

void drawLine(Line area, Rgba color, float thickness) {}

void drawSurface(ref Surface surface, Rect area, Rect target, Vec2 origin, float rotation, Rgba color) {}

void drawTexture(ResourceId id, Rect area, Rect target, Vec2 origin, float rotation, Rgba color) {}

void drawViewport(ResourceId id, Rect area, Rect target, Vec2 origin, float rotation, Rgba color) {}

void drawRune(ResourceId id, int rune, Vec2 position, Rgba color) {}
