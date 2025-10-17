// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

// TODO: Fix microui lol.
// TODO: Docs need changes because I also renamed things like: toScreenPoint -> toCanvasPoint
// TODO: Web script needs testing probably.
// TODO: Reorder functions to give them a more logical order. Do that after evetything works.
// TODO: Think about some names again.
// TODO: Maybe look at the function names in bk and engine again. Was thinking about ready vs _openWindow or updateWindow vs updateMainLoop...

/// The `engine` module functions as a lightweight 2D game engine.
module parin.engine;

version (ParinSkipDrawChecks) pragma(msg, "Parin: Skipping draw checks.");

import bk = parin.backend;

import parin.joka.ascii;
import parin.joka.io;
import parin.joka.memory;

public import parin.joka.containers;
public import parin.joka.math;
public import parin.joka.memory;
public import parin.joka.types;
public import parin.types;

__gshared EngineState* _engineState;

// ---------- Config
enum defaultEngineTitle           = "Parin";
enum defaultEngineWidth           = 960;
enum defaultEngineHeight          = 540;
enum defaultEngineVsync           = true;
enum defaultEngineFpsMax          = 60;
enum defaultEngineWindowMinWidth  = 320;
enum defaultEngineWindowMinHeight = 180;
enum defaultEngineWindowMinSize   = Vec2(defaultEngineWindowMinWidth, defaultEngineWindowMinHeight);
enum defaultEngineDebugModeKey    = Keyboard.f3;

enum defaultEngineFontRuneWidth  = 6;
enum defaultEngineFontRuneHeight = 12;

enum defaultEngineFlags =
    EngineFlag.isUsingAssetsPath |
    EngineFlag.isEmptyTextureVisible |
    EngineFlag.isEmptyFontVisible |
    EngineFlag.isLoggingLoadOrSaveFaults |
    EngineFlag.isLoggingMemoryTrackingInfo;

enum defaultEngineValidateErrorMessage   = "Resource is invalid or was never assigned.";
enum defaultEngineLoadErrorMessage       = "ERROR({}:{}): Could not load {} from \"{}\".";
enum defaultEngineSaveErrorMessage       = "ERROR({}:{}): Could not save {} from \"{}\".";
enum defaultEngineAssetsPathCapacity     = 8 * kilobyte;
enum defaultEngineEnvArgsCapacity        = 64;
enum defaultEngineLoadOrSaveTextCapacity = 14 * kilobyte;
enum defaultEngineEngineTasksCapacity    = 112;
enum defaultEngineArenaCapacity          = 4 * megabyte;

enum defaultEngineDprintCapacity       = 8 * kilobyte;
enum defaultEngineDprintPosition       = Vec2(8, 6);
enum defaultEngineDprintLineCountLimit = 14;

enum defaultEngineDebugColor1 = white.alpha(120);
enum defaultEngineDebugColor2 = black.alpha(170);
// ----------

@trusted:

/// The engine font.
enum engineFont = FontId(ResourceId(1));
/// The engine viewport.
enum engineViewport = ViewportId(ResourceId(1));

/// A container holding scheduled tasks.
alias EngineTasks = GenList!(
    Task,
    SparseList!(Task, FixedList!(SparseListItem!Task, defaultEngineEngineTasksCapacity)),
    FixedList!(Gen, defaultEngineEngineTasksCapacity)
);

/// An identifier for a scheduled engine task.
alias EngineTaskId = GenIndex;
/// The type of the internal engine flags.
alias EngineFlags = uint;

///  The internal engine flags.
enum EngineFlag : EngineFlags {
    none                        = 0x000000,
    isUpdating                  = 0x000001,
    isUsingAssetsPath           = 0x000002,
    isPixelSnapped              = 0x000004,
    isPixelPerfect              = 0x000008,
    isEmptyTextureVisible       = 0x000010,
    isEmptyFontVisible          = 0x000020,
    isLoggingLoadOrSaveFaults   = 0x000040,
    isLoggingMemoryTrackingInfo = 0x000080,
    isDebugMode                 = 0x000100,
}

/// Information about the engine viewport, including its area.
struct EngineViewportInfo {
    Rect area;      /// The area covered by the viewport.
    Vec2 minSize;   /// The minimum size that the viewport can be.
    Vec2 maxSize;   /// The maximum size that the viewport can be.
    float minRatio; /// The minimum ratio between minSize and maxSize.
}

/// The engine viewport.
struct EngineViewport {
    ViewportId data; /// The viewport data.
    int lockWidth;   /// The target lock width.
    int lockHeight;  /// The target lock height.
    bool isChanging; /// The flag that triggers the new lock state.
    bool isLocking;  /// The flag that tells what the new lock state is.
}

/// The engine state.
struct EngineState {
    EngineFlags flags = defaultEngineFlags;
    UpdateFunc updateFunc;
    CallFunc debugModeFunc;
    CallFunc debugModeBeginFunc;
    CallFunc debugModeEndFunc;
    Keyboard debugModeKey = defaultEngineDebugModeKey;

    EngineViewportInfo viewportInfoBuffer;
    Vec2 mouseBuffer;
    Vec2 wasdBuffer;
    Vec2 wasdPressedBuffer;
    Vec2 wasdReleasedBuffer;

    Rgba borderColor = black;
    Filter defaultFilter;
    Wrap defaultWrap;
    FontId defaultFont = engineFont;
    TextureId defaultTexture;
    Camera userCamera;
    ViewportId userViewport;
    Fault lastLoadOrSaveFault;
    IStr memoryTrackingInfoFilter;
    FStr!defaultEngineAssetsPathCapacity assetsPath;
    FixedList!(IStr, defaultEngineEnvArgsCapacity) envArgsBuffer;
    EngineTasks tasks;

    FStr!defaultEngineDprintCapacity dprintBuffer;
    Vec2 dprintPosition = defaultEngineDprintPosition;
    DrawOptions dprintOptions;
    Sz dprintLineCount;
    Sz dprintLineCountLimit = defaultEngineDprintLineCountLimit;
    bool dprintIsVisible = true;

    EngineViewport viewport;
    GrowingArena arena;
}

/// A texture identifier.
struct TextureId {
    ResourceId data;

    @safe nothrow @nogc:

    /// Checks if the texture is null (default value).
    bool isNull() {
        return bk.resourceIsNull(data);
    }

    /// Checks if the texture is valid (loaded). Null is invalid.
    bool isValid() {
        return bk.textureIsValid(data);
    }

    /// Checks if the texture is valid (loaded) and asserts if it is not.
    TextureId validate(IStr message = defaultEngineValidateErrorMessage) {
        return isValid ? this : assert(0, message);
    }

    /// Returns the width of the texture.
    int width() {
        return bk.textureWidth(data);
    }

    /// Returns the height of the texture.
    int height() {
        return bk.textureHeight(data);
    }

    /// Returns the size of the texture.
    Vec2 size() {
        return bk.textureSize(data);
    }

    /// Sets the filter mode of the texture.
    void setFilter(Filter value) {
        bk.textureSetFilter(data, value);
    }

    /// Sets the wrap mode of the texture.
    void setWrap(Wrap value) {
        bk.textureSetWrap(data, value);
    }

    /// Frees the loaded texture.
    void free() {
        bk.textureFree(data);
        data = ResourceId();
    }
}

/// A font identifier.
struct FontId {
    ResourceId data;

    @safe nothrow @nogc:

    /// Checks if the font is null (default value).
    bool isNull() {
        return bk.resourceIsNull(data);
    }

    /// Checks if the font is valid (loaded). Null is invalid.
    bool isValid() {
        return bk.fontIsValid(data);
    }

    /// Checks if the font is valid (loaded) and asserts if it is not.
    FontId validate(IStr message = defaultEngineValidateErrorMessage) {
        return isValid ? this : assert(0, message);
    }

    /// Returns the size of the font.
    int size() {
        return bk.fontSize(data);
    }

    /// Sets the filter mode of the font.
    void setFilter(Filter value) {
        bk.fontSetFilter(data, value);
    }

    /// Sets the wrap mode of the font.
    void setWrap(Wrap value) {
        bk.fontSetWrap(data, value);
    }

    /// Returns the spacing between individual characters.
    int runeSpacing() {
        return bk.fontRuneSpacing(data);
    }

    void setRuneSpacing(int value) {
        return bk.fontSetRuneSpacing(data, value);
    }

     /// Returns the spacing between lines of text.
    int lineSpacing() {
        return bk.fontLineSpacing(data);
    }

    void setLineSpacing(int value) {
        return bk.fontSetRuneSpacing(data, value);
    }

    GlyphInfo glyphInfo(int rune) {
        return bk.fontGlyphInfo(data, rune);
    }

    /// Frees the loaded font.
    void free() {
        if (this != engineFont) bk.fontFree(data);
        data = ResourceId();
    }
}

/// A sound identifier.
struct SoundId {
    ResourceId data;

    @safe nothrow @nogc:

    /// Checks if the font is null (default value).
    bool isNull() {
        return bk.resourceIsNull(data);
    }

    /// Checks if the font is valid (loaded). Null is invalid.
    bool isValid() {
        return bk.soundIsValid(data);
    }

    /// Checks if the font is valid (loaded) and asserts if it is not.
    SoundId validate(IStr message = defaultEngineValidateErrorMessage) {
        return isValid ? this : assert(0, message);
    }

    float volume() {
        return bk.soundVolume(data);
    }

    void setVolume(float value) {
        bk.soundSetVolume(data, value);
    }

    float pan() {
        return bk.soundPan(data);
    }

    void setPan(float value) {
        bk.soundSetPan(data, value);
    }

    float pitch() {
        return bk.soundPitch(data);
    }

    void setPitch(float value, bool canUpdatePitchVarianceBase = false) {
        bk.soundSetPitch(data, value, canUpdatePitchVarianceBase);
    }

    /// Returns the pitch variance of the sound associated with the resource identifier.
    float pitchVariance() {
        return bk.soundPitchVariance(data);
    }

    /// Sets the pitch variance for the sound associated with the resource identifier. One is the default value.
    void setPitchVariance(float value) {
        bk.soundSetPitchVariance(data, value);
    }

    /// Sets the pitch variance base for the sound associated with the resource identifier. One is the default value.
    void pitchVarianceBase() {
        bk.soundPitchVarianceBase(data);
    }

    /// Sets the pitch variance base for the sound associated with the resource identifier. One is the default value.
    void setPitchVarianceBase(float value) {
        bk.soundSetPitchVarianceBase(data, value);
    }

    /// Returns true if the sound associated with the resource identifier can repeat.
    bool canRepeat() {
        return bk.soundCanRepeat(data);
    }

    void setCanRepeat(bool value) {
        bk.soundSetCanRepeat(data, value);
    }

    /// Returns true if the sound associated with the resource identifier is playing.
    bool isActive() {
        return bk.soundIsActive(data);
    }

    /// Returns true if the sound associated with the resource identifier is paused.
    bool isPaused() {
        return bk.soundIsPaused(data);
    }

    /// Returns the current playback time of the sound associated with the resource identifier.
    float time() {
        return bk.soundTime(data);
    }

    /// Returns the total duration of the sound associated with the resource identifier.
    float duration() {
        return bk.soundDuration(data);
    }

    /// Returns the progress of the sound associated with the resource identifier.
    float progress() {
        return bk.soundProgress(data);
    }

    /// Frees the resource associated with the identifier.
    void free() {
        bk.soundFree(data);
        data = ResourceId();
    }
}

/// A viewing area for rendering.
struct ViewportId {
    ResourceId data;

    @safe nothrow @nogc:

    /// Checks if the font is null (default value).
    bool isNull() {
        return bk.resourceIsNull(data);
    }

    /// Checks if the font is valid (loaded). Null is invalid.
    bool isValid() {
        return bk.viewportIsValid(data);
    }

    /// Checks if the font is valid (loaded) and asserts if it is not.
    ViewportId validate(IStr message = defaultEngineValidateErrorMessage) {
        return isValid ? this : assert(0, message);
    }

    /// Returns the width of the viewport.
    int width() {
        return bk.viewportWidth(data);
    }

    /// Returns the height of the viewport.
    int height() {
        return bk.viewportHeight(data);
    }

    /// Returns the size of the viewport.
    Vec2 size() {
        return bk.viewportSize(data);
    }

    /// Resizes the viewport to the given width and height.
    /// Internally, this allocates a new render texture, so avoid calling it while the viewport is in use.
    void resize(int newWidth, int newHeight) {
        bk.viewportResize(data, newWidth, newHeight);
    }

    /// Sets the filter mode of the viewport.
    void setFilter(Filter value) {
        bk.viewportSetFilter(data, value);
    }

    /// Sets the wrap mode of the viewport.
    void setWrap(Wrap value) {
        bk.viewportSetWrap(data, value);
    }

    bool isAttached() {
        return bk.viewportIsAttached(data);
    }

    Rgba color() {
        return bk.viewportColor(data);
    }

    void setColor(Rgba value) {
        bk.viewportSetColor(data, value);
    }

    Blend blend() {
        return bk.viewportBlend(data);
    }

    /// Frees the loaded viewport.
    void free() {
        if (this != engineViewport) bk.viewportFree(data);
        data = ResourceId();
    }
}

/// Attaches the viewport, making it active.
// NOTE: The engine viewport should not use this function.
void attach(ViewportId viewport) {
    if (viewport.size.isZero) return;
    if (_engineState.userViewport.isAttached) assert(0, "Cannot attach viewport because another viewport is already attached.");
    if (isResolutionLocked) bk.endViewport(_engineState.viewport.data.data);
    bk.beginViewport(viewport.data);
    bk.clearBackground(viewport.color);
    bk.beginBlend(viewport.blend);
    _engineState.userViewport = viewport;
}

/// Detaches the viewport, making it inactive.
// NOTE: The engine viewport should not use this function.
void detach(ViewportId viewport) {
    if (viewport.size.isZero) return;
    if (!_engineState.userViewport.isAttached) assert(0, "Cannot detach viewport because it is not the attached viewport.");
    bk.endBlend();
    bk.endViewport(viewport.data);
    _engineState.userViewport = ViewportId();
    if (isResolutionLocked) bk.beginViewport(_engineState.viewport.data.data);
}

/// Attaches the camera, making it active.
void attach(ref Camera camera, Rounding type = Rounding.none) {
    if (_engineState.userCamera.isAttached) assert(0, "Cannot attach camera because another camera is already attached.");
    bk.beginCamera(camera, resolution, isPixelSnapped ? Rounding.floor : type);
    _engineState.userCamera = camera;
}

/// Detaches the camera, making it inactive.
void detach(ref Camera camera) {
    if (!camera.isAttached) assert(0, "Cannot detach camera because it is not the attached camera.");
    bk.endCamera(camera);
    _engineState.userCamera = Camera();
}

void beginClip(Rect area) {
    bk.beginClip(area);
}

void endClip() {
    bk.endClip();
}

/// Opens a window with the specified size and title.
/// You should avoid calling this function manually.
void _openWindow(int width, int height, const(IStr)[] args, IStr title = "Parin") {
    enum monogramPath = "parin_monogram.png";

    bk.readyBackend(width, height, title, defaultEngineVsync, defaultEngineFpsMax, defaultEngineWindowMinWidth, defaultEngineWindowMinHeight);
    _engineState = jokaMake!EngineState();
    _engineState.tasks.push(Task());
    _engineState.arena.ready(defaultEngineArenaCapacity);
    _engineState.viewport.data = loadViewport(0, 0, gray);
    // TODO: will have to remove the id thing and also change the toTexure names to load maybe.
    loadTexture(cast(const(ubyte)[]) import(monogramPath)).loadFont(defaultEngineFontRuneWidth, defaultEngineFontRuneHeight);
    if (args.length) {
        foreach (arg; args) _engineState.envArgsBuffer.append(arg);
        _engineState.assetsPath.append(pathConcat(args[0].pathDirName, "assets"));
    }
}

/// Opens a window with the specified size and title, using C strings.
/// You should avoid calling this function manually.
void _openWindowC(int width, int height, int argc, ICStr* argv, ICStr title = "Parin") {
    _openWindow(width, height, null, title.cStrToStr());
    if (argc) {
        foreach (i; 0 .. argc) _engineState.envArgsBuffer.append(argv[i].cStrToStr());
        _engineState.assetsPath.append(pathConcat(_engineState.envArgsBuffer[0].pathDirName, "assets"));
    }
}

/// Use by the `updateWindow` function.
/// You should avoid calling this function manually.
bool _updateWindowLoop() {
    // Update buffers and resources.
    bk.pumpEvents();
    _updateViewportInfoBuffer();
    _updateEngineMouseBuffer(bk.mouse);
    _updateEngineWasdBuffer();

    // Begin drawing.
    auto loopVsync = vsync;
    if (isResolutionLocked) {
        bk.beginViewport(_engineState.viewport.data.data);
    } else {
        bk.beginDrawing();
    }
    bk.clearBackground(_engineState.viewport.data.color);

    // Update and draw the game.
    bk.beginDroppedPaths();
    _engineState.arena.clear();
    auto dt = deltaTime;
    foreach (id; _engineState.tasks.ids) {
        if (_engineState.tasks[id].update(dt)) cancel(id);
    }
    auto result = _engineState.updateFunc(dt);
    if (_engineState.dprintIsVisible) {
        drawText(_engineState.dprintBuffer.items, _engineState.dprintPosition, _engineState.dprintOptions);
    }
    if (_engineState.debugModeKey.isPressed) toggleIsDebugMode();
    if (isDebugMode) {
        if (_engineState.debugModeBeginFunc) _engineState.debugModeBeginFunc();
        if (_engineState.debugModeFunc) _engineState.debugModeFunc();
        if (_engineState.debugModeEndFunc) _engineState.debugModeEndFunc();
    }
    bk.endDroppedPaths();

    // End drawing.
    if (isResolutionLocked) {
        auto info = engineViewportInfo;
        bk.endViewport(_engineState.viewport.data.data);
        bk.beginDrawing();
        bk.clearBackground(_engineState.borderColor);
        bk.drawViewport(_engineState.viewport.data.data, Rect(info.minSize.x, -info.minSize.y), info.area, Vec2(), 0.0f, white);
        bk.endDrawing();
    } else {
        bk.endDrawing();
    }

    // Viewport code.
    if (_engineState.viewport.isChanging) {
        if (_engineState.viewport.isLocking) {
            _engineState.viewport.data.resize(_engineState.viewport.lockWidth, _engineState.viewport.lockHeight);
        } else {
            _engineState.viewport.data.resize(0, 0);
        }
        _engineState.viewport.isChanging = false;
    }
    return result;
}

/// Updates the window every frame with the given function.
/// This function will return when the given function returns true.
/// You should avoid calling this function manually.
void _updateWindow(UpdateFunc updateFunc, CallFunc debugModeFunc = null, CallFunc debugModeBeginFunc = null, CallFunc debugModeEndFunc = null) {
    _engineState.updateFunc = updateFunc;
    _engineState.debugModeFunc = debugModeFunc;
    _engineState.debugModeBeginFunc = debugModeBeginFunc;
    _engineState.debugModeEndFunc = debugModeEndFunc;

    _engineState.flags |= EngineFlag.isUpdating;
    bk.runMainLoop!(_updateWindowLoop);
    _engineState.flags &= ~EngineFlag.isUpdating;
}

/// Closes the window.
/// You should avoid calling this function manually.
void _closeWindow() {
    // NOTE: I assume `filter` is a static string or managed by the user.
    auto filter = _engineState.memoryTrackingInfoFilter;
    auto isLogging = isLoggingMemoryTrackingInfo;

    bk.freeBackend();
    _engineState.arena.free();
    jokaFree(_engineState);
    _engineState = null;

    static if (isTrackingMemory) {
        if (isLogging) printMemoryTrackingInfo(filter);
    }
}

/// Mixes in a game loop template with specified functions for initialization, update, and cleanup, and sets window size and title.
mixin template runGame(
    alias readyFunc,
    alias updateFunc,
    alias finishFunc,
    int width = defaultEngineWidth,
    int height = defaultEngineHeight,
    IStr title = defaultEngineTitle,
    alias debugModeFunc = null,
    alias debugModeBeginFunc = null,
    alias debugModeEndFunc = null
) {
    int _runGame() {
        import _pr = parin.engine;
        static if (__traits(isStaticFunction, debugModeFunc)) enum debugMode1 = &debugModeFunc;
        else enum debugMode1 = null;
        static if (__traits(isStaticFunction, debugModeBeginFunc)) enum debugMode2 = &debugModeBeginFunc;
        else enum debugMode2 = null;
        static if (__traits(isStaticFunction, debugModeEndFunc)) enum debugMode3 = &debugModeEndFunc;
        else enum debugMode3 = null;

        static if (__traits(isStaticFunction, readyFunc)) readyFunc();
        static if (__traits(isStaticFunction, updateFunc)) _pr._updateWindow(&updateFunc, debugMode1, debugMode2, debugMode3);
        static if (__traits(isStaticFunction, finishFunc)) finishFunc();
        _pr._closeWindow();
        return 0;
    }

    version (D_BetterC) {
        extern(C)
        int main(int argc, const(char)** argv) {
            import _pr = parin.engine;
            _pr._openWindowC(width, height, argc, argv, title);
            return _runGame();
        }
    } else {
        int main(immutable(char)[][] args) {
            import _pr = parin.engine;
            _pr._openWindow(width, height, args, title);
            return _runGame();
        }
    }
}

/// Schedule a function (task) to run every interval, optionally limited by count.
EngineTaskId every(float interval, UpdateFunc func, int count = -1, bool canCallNow = false) {
    return _engineState.tasks.push(Task(interval, canCallNow ? interval : 0, func, cast(byte) count));
}

/// Cancel the scheduled task by its ID.
void cancel(EngineTaskId id) {
    if (id.value == 0) return;
    _engineState.tasks.remove(id);
}

@trusted nothrow:

/// Allocates raw memory from the frame arena.
void* frameMalloc(Sz size, Sz alignment) {
    return _engineState.arena.malloc(size, alignment);
}

/// Reallocates memory from the frame arena.
void* frameRealloc(void* ptr, Sz oldSize, Sz newSize, Sz alignment) {
    return _engineState.arena.realloc(ptr, oldSize, newSize, alignment);
}

/// Allocates uninitialized memory for a single value of type T from the frame arena.
T* frameMakeBlank(T)() {
    return _engineState.arena.makeBlank!T();
}

/// Allocates and initializes a single value of type T from the frame arena.
T* frameMake(T)(const(T) value = T.init) {
    return _engineState.arena.make!T(value);
}

/// Allocates uninitialized memory for an array of T with the given length.
T[] frameMakeSliceBlank(T)(Sz length) {
    return _engineState.arena.makeSliceBlank!T(length);
}

/// Allocates and initializes an array of T with the given length.
T[] frameMakeSlice(T)(Sz length, const(T) value = T.init) {
    return _engineState.arena.makeSlice!T(length, value);
}

/// Returns a temporary text container.
/// The resource remains valid for the duration of the current frame.
BStr prepareTempText() {
    return BStr(frameMakeSliceBlank!char(defaultEngineLoadOrSaveTextCapacity));
}

/// Loads a text file from the assets folder and saves the content into the given buffer.
/// Supports both forward slashes and backslashes in file paths.
Fault loadTextIntoBuffer(L = LStr)(IStr path, ref L listBuffer, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = readTextIntoBuffer(path.toAssetsPath(), listBuffer);
    didLoadOrSaveSucceed(result, fmt(defaultEngineLoadErrorMessage, file, line, "text", path.toAssetsPath()));
    return result;
}

/// Loads a text file from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
LStr loadText(IStr path, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = readText(path.toAssetsPath());
    if (didLoadOrSaveSucceed(result.fault, fmt(defaultEngineLoadErrorMessage, file, line, "text", path.toAssetsPath()))) return result.get();
    return LStr();
}

/// Loads a text file from the assets folder.
/// The resource remains valid for the duration of the current frame.
/// Supports both forward slashes and backslashes in file paths.
IStr loadTempText(IStr path, IStr file = __FILE__, Sz line = __LINE__) {
    auto tempText = BStr(frameMakeSliceBlank!char(defaultEngineLoadOrSaveTextCapacity));
    loadTextIntoBuffer(path, tempText, file, line);
    return tempText.items;
}

/// Loads a texture file (PNG) from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
TextureId loadTexture(IStr path, IStr file = __FILE__, Sz line = __LINE__) {
    auto trap = Fault.none;
    auto data = bk.loadTexture(toAssetsPath(path)).get(trap);
    if (didLoadOrSaveSucceed(trap, fmt(defaultEngineLoadErrorMessage, file, line, "texture", path.toAssetsPath()))) {
        bk.textureSetFilter(data, _engineState.defaultFilter);
        bk.textureSetWrap(data, _engineState.defaultWrap);
        return TextureId(data);
    }
    return TextureId();
}

/// Loads a texture file (PNG) from the given bytes.
TextureId loadTexture(const(ubyte)[] memory, IStr ext = ".png", IStr file = __FILE__, Sz line = __LINE__) {
    auto trap = Fault.none;
    auto data = bk.loadTexture(memory, ext).get(trap);
    if (didLoadOrSaveSucceed(trap, fmt(defaultEngineLoadErrorMessage, file, line, "texture", "[MEMORY]"))) {
        bk.textureSetFilter(data, _engineState.defaultFilter);
        bk.textureSetWrap(data, _engineState.defaultWrap);
        return TextureId(data);
    }
    return TextureId();
}

FontId loadFont(IStr path, int size, int runeSpacing = -1, int lineSpacing = -1, IStr32 runes = "", IStr file = __FILE__, Sz line = __LINE__) {
    auto trap = Fault.none;
    auto data = bk.loadFont(toAssetsPath(path), size, runeSpacing, lineSpacing, runes).get(trap);
    if (didLoadOrSaveSucceed(trap, fmt(defaultEngineLoadErrorMessage, file, line, "font", path.toAssetsPath()))) {
        bk.fontSetFilter(data, _engineState.defaultFilter);
        bk.fontSetWrap(data, _engineState.defaultWrap);
        return FontId(data);
    }
    return FontId();
}

/// Converts bytes into a font. Returns an empty font on error.
FontId loadFont(const(ubyte)[] memory, int size, int runeSpacing = -1, int lineSpacing = -1, IStr32 runes = "", IStr ext = ".ttf", IStr file = __FILE__, Sz line = __LINE__) {
    auto trap = Fault.none;
    auto data = bk.loadFont(memory, size, runeSpacing, lineSpacing, runes, ext).get(trap);
    if (didLoadOrSaveSucceed(trap, fmt(defaultEngineLoadErrorMessage, file, line, "font", "[MEMORY]"))) {
        bk.fontSetFilter(data, _engineState.defaultFilter);
        bk.fontSetWrap(data, _engineState.defaultWrap);
        return FontId(data);
    }
    return FontId();
}

FontId loadFont(TextureId texture, int tileWidth, int tileHeight, IStr file = __FILE__, Sz line = __LINE__) {
    auto trap = Fault.none;
    auto data = bk.loadFont(texture.data, tileWidth, tileHeight).get(trap);
    if (didLoadOrSaveSucceed(trap, fmt(defaultEngineLoadErrorMessage, file, line, "font", "[TEXTURE]"))) {
        bk.fontSetFilter(data, _engineState.defaultFilter);
        bk.fontSetWrap(data, _engineState.defaultWrap);
        return FontId(data);
    }
    return FontId();
}

/// Loads a sound file (WAV, OGG, MP3) from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
SoundId loadSound(IStr path, float volume, float pitch, bool canRepeat, float pitchVariance = 1.0f, IStr file = __FILE__, Sz line = __LINE__) {
    auto trap = Fault.none;
    auto data = bk.loadSound(toAssetsPath(path), volume, pitch, canRepeat, pitchVariance).get(trap);
    if (didLoadOrSaveSucceed(trap, fmt(defaultEngineLoadErrorMessage, file, line, "sound", path.toAssetsPath()))) {
        return SoundId(data);
    }
    return SoundId();
}

ViewportId loadViewport(int width, int height, Rgba color, Blend blend = Blend.alpha, IStr file = __FILE__, Sz line = __LINE__) {
    auto trap = Fault.none;
    auto data = bk.loadViewport(width, height, color, blend).get(trap);
    if (didLoadOrSaveSucceed(trap, fmt(defaultEngineLoadErrorMessage, file, line, "viewport", "[MEMORY]"))) {
        bk.viewportSetFilter(data, _engineState.defaultFilter);
        bk.viewportSetWrap(data, _engineState.defaultWrap);
        return ViewportId(data);
    }
    return ViewportId();
}

/// Saves a text file to the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Fault saveText(IStr path, IStr text, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = writeText(path.toAssetsPath(), text);
    if (isLoggingLoadOrSaveFaults && result) printfln!(StdStream.error)(defaultEngineSaveErrorMessage, file, line, "text", path.toAssetsPath());
    return result;
}

/// Returns the fault from the last load or save call.
Fault lastLoadOrSaveFault() {
    return _engineState.lastLoadOrSaveFault;
}

/// Sets the path of the assets folder.
void setAssetsPath(IStr path) {
    _engineState.assetsPath.clear();
    _engineState.assetsPath.append(path);
}

@trusted nothrow @nogc:

// TODO: Replace that with something in Joka. I was too lazy to write it myself.
// Get next codepoint in a byte sequence and bytes processed
// Sorry monky, but it's temp code that I copy-pasted from raylib.
private int TEMP_REPLACE_ME_GetCodepointNext(const(char)* text, int* codepointSize) {
    const(char)* ptr = text;
    int codepoint = 0x3f;       // Codepoint (defaults to '?')
    *codepointSize = 1;

    // Get current codepoint and bytes processed
    if (0xf0 == (0xf8 & ptr[0]))
    {
        // 4 byte UTF-8 codepoint
        if (((ptr[1] & 0xC0) ^ 0x80) || ((ptr[2] & 0xC0) ^ 0x80) || ((ptr[3] & 0xC0) ^ 0x80)) { return codepoint; } // 10xxxxxx checks
        codepoint = ((0x07 & ptr[0]) << 18) | ((0x3f & ptr[1]) << 12) | ((0x3f & ptr[2]) << 6) | (0x3f & ptr[3]);
        *codepointSize = 4;
    }
    else if (0xe0 == (0xf0 & ptr[0]))
    {
        // 3 byte UTF-8 codepoint */
        if (((ptr[1] & 0xC0) ^ 0x80) || ((ptr[2] & 0xC0) ^ 0x80)) { return codepoint; } // 10xxxxxx checks
        codepoint = ((0x0f & ptr[0]) << 12) | ((0x3f & ptr[1]) << 6) | (0x3f & ptr[2]);
        *codepointSize = 3;
    }
    else if (0xc0 == (0xe0 & ptr[0]))
    {
        // 2 byte UTF-8 codepoint
        if ((ptr[1] & 0xC0) ^ 0x80) { return codepoint; } // 10xxxxxx checks
        codepoint = ((0x1f & ptr[0]) << 6) | (0x3f & ptr[1]);
        *codepointSize = 2;
    }
    else if (0x00 == (0x80 & ptr[0]))
    {
        // 1 byte UTF-8 codepoint
        codepoint = ptr[0];
        *codepointSize = 1;
    }

    return codepoint;
}

// TODO: Replace that with something in Joka. I was too lazy to write it myself.
// Get previous codepoint in a byte sequence and bytes processed
private int TEMP_REPLACE_ME_GetCodepointPrevious(const(char)* text, int* codepointSize) {
    const(char)* ptr = text;
    int codepoint = 0x3f;       // Codepoint (defaults to '?')
    int cpSize = 0;
    *codepointSize = 0;

    // Move to previous codepoint
    do ptr--;
    while (((0x80 & ptr[0]) != 0) && ((0xc0 & ptr[0]) ==  0x80));

    codepoint = TEMP_REPLACE_ME_GetCodepointNext(ptr, &cpSize);

    if (codepoint != 0) *codepointSize = cpSize;

    return codepoint;
}

bool didLoadOrSaveSucceed(Fault fault, IStr message) {
    if (fault) {
        _engineState.lastLoadOrSaveFault = fault;
        if (isLoggingLoadOrSaveFaults) println!(StdStream.error)(message);
        return false;
    }
    return true;
}

void _updateViewportInfoBuffer() {
    auto info = &_engineState.viewportInfoBuffer;
    if (isResolutionLocked) {
        info.minSize = resolution;
        info.maxSize = windowSize;
        auto ratio = info.maxSize / info.minSize;
        info.minRatio = min(ratio.x, ratio.y);
        if (isPixelPerfect) {
            auto roundMinRatio = info.minRatio.round();
            auto floorMinRation = info.minRatio.floor();
            info.minRatio = info.minRatio.fequals(roundMinRatio, 0.015f) ? roundMinRatio : floorMinRation;
        }
        auto targetSize = info.minSize * Vec2(info.minRatio);
        auto targetPosition = info.maxSize * Vec2(0.5f) - targetSize * Vec2(0.5f);
        info.area = Rect(
            targetPosition.floor(),
            ratio.x == info.minRatio ? targetSize.x : floor(targetSize.x),
            ratio.y == info.minRatio ? targetSize.y : floor(targetSize.y),
        );
    } else {
        info.minSize = windowSize;
        info.maxSize = info.minSize;
        info.minRatio = 1.0f;
        info.area = Rect(info.minSize);
    }
}

void _updateEngineMouseBuffer(Vec2 value) {
    auto info = &_engineState.viewportInfoBuffer;
    if (isResolutionLocked) {
        _engineState.mouseBuffer = Vec2(
            floor((value.x - (info.maxSize.x - info.area.size.x) * 0.5f) / info.minRatio),
            floor((value.y - (info.maxSize.y - info.area.size.y) * 0.5f) / info.minRatio),
        );
    } else {
        _engineState.mouseBuffer = value;
    }
}

void _updateEngineWasdBuffer() {
    with (Keyboard) {
        _engineState.wasdBuffer = Vec2(
            (d.isDown || right.isDown) - (a.isDown || left.isDown),
            (s.isDown || down.isDown) - (w.isDown || up.isDown),
        );
        _engineState.wasdPressedBuffer = Vec2(
            (d.isPressed || right.isPressed) - (a.isPressed || left.isPressed),
            (s.isPressed || down.isPressed) - (w.isPressed || up.isPressed),
        );
        _engineState.wasdReleasedBuffer = Vec2(
            (d.isReleased || right.isReleased) - (a.isReleased || left.isReleased),
            (s.isReleased || down.isReleased) - (w.isReleased || up.isReleased),
        );
    }
}

/// Returns the arguments that this application was started with.
IStr[] envArgs() {
    return _engineState.envArgsBuffer.items;
}

/// Sets the seed of the random number generator to the given value.
void setRandomSeed(int value) {
    bk.setRandomSeed(value);
}

/// Randomizes the seed of the random number generator.
void randomize() {
    bk.randomize();
}

/// Returns a random integer between 0 and int.max (inclusive).
int randi() {
    return bk.randi;
}

/// Returns a random floating point number between 0.0 and 1.0 (inclusive).
float randf() {
    return bk.randf;
}

/// Converts a scene point to a canvas point based on the given camera.
Vec2 toCanvasPoint(Vec2 position, Camera camera) {
    return bk.toCanvasPoint(position, camera, resolution);
}

/// Converts a scene point to a canvas point based on the given camera.
Vec2 toCanvasPoint(Vec2 position, Camera camera, Vec2 canvasSize) {
    return bk.toCanvasPoint(position, camera, canvasSize);
}

/// Converts a canvas point to a scene point based on the given camera.
Vec2 toScenePoint(Vec2 position, Camera camera) {
    return bk.toScenePoint(position, camera, resolution);
}

/// Converts a canvas point to a scene point based on the given camera.
Vec2 toScenePoint(Vec2 position, Camera camera, Vec2 canvasSize) {
    return bk.toScenePoint(position, camera, canvasSize);
}

/// Returns the path of the assets folder.
IStr assetsPath() {
    return _engineState.assetsPath.items;
}

/// Converts a path to a path within the assets folder.
IStr toAssetsPath(IStr path) {
    if (path.startsWith(pathSep) || !isUsingAssetsPath) return path;
    return pathConcat(assetsPath, path).pathFormat();
}

/// Returns the dropped paths of the current frame.
IStr[] droppedPaths() {
    return bk.droppedPaths;
}

void freeAllTextureIds() {
    bk.freeAllTextures(false);
}

void freeAllFontIds() {
    bk.freeAllFonts(true);
}

void freeAllSoundIds() {
    bk.freeAllSounds(false);
}

void freeAllViewportIds() {
    bk.freeAllViewports(true);
}

/// Frees all engine resources.
void freeAllResourceIds() {
    freeAllTextureIds();
    freeAllFontIds();
    freeAllSoundIds();
    freeAllViewportIds();
}

/// Opens a URL in the default web browser (if available).
/// Redirect to Parin's GitHub when no URL is provided.
void openUrl(IStr url = "https://github.com/Kapendev/parin") {
    bk.openUrl(url);
}

/// Returns true if the assets path is currently in use when loading.
bool isUsingAssetsPath() {
    return cast(bool) (_engineState.flags & EngineFlag.isUsingAssetsPath);
}

/// Sets whether the assets path should be in use when loading.
void setIsUsingAssetsPath(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isUsingAssetsPath
        : _engineState.flags & ~EngineFlag.isUsingAssetsPath;
}

/// Returns true if the drawing is snapped to pixel coordinates.
bool isPixelSnapped() {
    return cast(bool) (_engineState.flags & EngineFlag.isPixelSnapped);
}

/// Sets whether drawing should be snapped to pixel coordinates.
void setIsPixelSnapped(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isPixelSnapped
        : _engineState.flags & ~EngineFlag.isPixelSnapped;
}

/// Returns true if the drawing is done in a pixel perfect way.
bool isPixelPerfect() {
    return cast(bool) (_engineState.flags & EngineFlag.isPixelPerfect);
}

/// Sets whether drawing should be done in a pixel-perfect way.
void setIsPixelPerfect(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isPixelPerfect
        : _engineState.flags & ~EngineFlag.isPixelPerfect;
}

/// Returns true if drawing is done when an empty texture is used.
bool isEmptyTextureVisible() {
    return cast(bool) (_engineState.flags & EngineFlag.isEmptyTextureVisible);
}

/// Sets whether drawing should be done when an empty texture is used.
void setIsEmptyTextureVisible(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isEmptyTextureVisible
        : _engineState.flags & ~EngineFlag.isEmptyTextureVisible;
}

/// Returns true if drawing is done when an empty font is used.
bool isEmptyFontVisible() {
    return cast(bool) (_engineState.flags & EngineFlag.isEmptyFontVisible);
}

/// Sets whether drawing should be done when an empty font is used.
void setIsEmptyFontVisible(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isEmptyFontVisible
        : _engineState.flags & ~EngineFlag.isEmptyFontVisible;
}

/// Returns true if loading or saving should log on fault.
bool isLoggingLoadOrSaveFaults() {
    return cast(bool) (_engineState.flags & EngineFlag.isLoggingLoadOrSaveFaults);
}

/// Sets whether loading or saving should log on fault.
void setIsLoggingLoadOrSaveFaults(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isLoggingLoadOrSaveFaults
        : _engineState.flags & ~EngineFlag.isLoggingLoadOrSaveFaults;
}

/// Returns true if memory tracking logs are enabled.
bool isLoggingMemoryTrackingInfo() {
    return cast(bool) (_engineState.flags & EngineFlag.isLoggingMemoryTrackingInfo);
}

/// Enables or disables memory tracking logs.
void setIsLoggingMemoryTrackingInfo(bool value, IStr filter = "") {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isLoggingMemoryTrackingInfo
        : _engineState.flags & ~EngineFlag.isLoggingMemoryTrackingInfo;
    _engineState.memoryTrackingInfoFilter = filter;
}

/// Returns true if debug mode is active.
bool isDebugMode() {
    return cast(bool) (_engineState.flags & EngineFlag.isDebugMode);
}

/// Sets whether debug mode should be active.
void setIsDebugMode(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isDebugMode
        : _engineState.flags & ~EngineFlag.isDebugMode;
}

/// Toggles the debug mode on or off.
void toggleIsDebugMode() {
    setIsDebugMode(!isDebugMode);
}

/// Sets the key that will toggle the debug mode on or off.
void setDebugModeKey(Keyboard value) {
    _engineState.debugModeKey = value;
}

/// Returns true if the application is currently in fullscreen mode.
// NOTE: There is a conflict between the flag and real-window-state, which could potentially cause issues for some users.
bool isFullscreen() {
    return bk.isFullscreen;
}

/// Sets whether the application should be in fullscreen mode.
// NOTE: This function introduces a slight delay to prevent some bugs observed on Linux. See the `updateWindow` function.
void setIsFullscreen(bool value) {
    bk.setIsFullscreen(value);
}

/// Toggles the fullscreen mode on or off.
void toggleIsFullscreen() {
    setIsFullscreen(!isFullscreen);
}

/// Returns true if the cursor is currently visible.
bool isCursorVisible() {
    return bk.isCursorVisible;
}

/// Sets whether the cursor should be visible or hidden.
void setIsCursorVisible(bool value) {
    bk.setIsCursorVisible(value);
}

/// Toggles the visibility of the cursor.
void toggleIsCursorVisible() {
    setIsCursorVisible(!isCursorVisible);
}

/// Returns true if the windows was resized.
bool isWindowResized() {
    return bk.isWindowResized;
}

/// Sets the background color to the specified value.
void setBackgroundColor(Rgba value) {
    _engineState.viewport.data.setColor(value);
}

/// Sets the border color to the specified value.
void setBorderColor(Rgba value) {
    _engineState.borderColor = value;
}

/// Sets the minimum size of the window to the specified value.
void setWindowMinSize(int width, int height) {
    bk.setWindowMinSize(width, height);
}

/// Sets the maximum size of the window to the specified value.
// TODO: DO we care about these values? think about if there shoudl be a way to retrn tgem
void setWindowMaxSize(int width, int height) {
    bk.setWindowMaxSize(width, height);
}

/// Sets the window icon to the specified image that will be loaded from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Fault setWindowIconFromFiles(IStr path) {
    return bk.setWindowIconFromFiles(path.toAssetsPath());
}

/// Returns information about the engine viewport, including its area.
EngineViewportInfo engineViewportInfo() {
    return _engineState.viewportInfoBuffer;
}

/// Returns the default filter mode.
Filter defaultFilter() {
    return _engineState.defaultFilter;
}

/// Sets the default filter mode to the specified value.
void setDefaultFilter(Filter value) {
    _engineState.defaultFilter = value;
}

/// Returns the default wrap mode.
Wrap defaultWrap() {
    return _engineState.defaultWrap;
}

/// Sets the default wrap mode to the specified value.
void setDefaultWrap(Wrap value) {
    _engineState.defaultWrap = value;
}

/// Returns the default texture.
TextureId defaultTexture() {
    return _engineState.defaultTexture;
}

/// Sets the default texture to the specified value.
void setDefaultTexture(TextureId value) {
    _engineState.defaultTexture = value;
}

/// Returns the default font.
FontId defaultFont() {
    return _engineState.defaultFont;
}

/// Sets the default font to the specified value.
void setDefaultFont(FontId value) {
    _engineState.defaultFont = value;
}

/// Returns the current master volume level.
float masterVolume() {
    return bk.masterVolume;
}

/// Sets the master volume level to the specified value.
void setMasterVolume(float value) {
    bk.setMasterVolume(value);
}

/// Returns true if the resolution is locked and cannot be changed.
bool isResolutionLocked() {
    return !_engineState.viewport.data.size.isZero;
}

/// Locks the resolution to the specified width and height.
void lockResolution(int width, int height) {
    _engineState.viewport.lockWidth = width;
    _engineState.viewport.lockHeight = height;
    if (_engineState.flags & EngineFlag.isUpdating) {
        _engineState.viewport.isChanging = true;
        _engineState.viewport.isLocking = true;
    } else {
        _engineState.viewport.data.resize(width, height);
    }
}

/// Unlocks the resolution, allowing it to be changed.
void unlockResolution() {
    if (_engineState.flags & EngineFlag.isUpdating) {
        _engineState.viewport.isChanging = true;
        _engineState.viewport.isLocking = false;
    } else {
        _engineState.viewport.data.resize(0, 0);
    }
}

/// Toggles between the current resolution and the specified width and height.
void toggleResolution(int width, int height) {
    if (isResolutionLocked) unlockResolution();
    else lockResolution(width, height);
}

/// Returns the current screen width.
int screenWidth() {
    return bk.screenWidth;
}

/// Returns the current screen height.
int screenHeight() {
    return bk.screenHeight;
}

/// Returns the current screen size.
Vec2 screenSize() {
    return Vec2(bk.screenWidth, bk.screenHeight);
}

/// Returns the current window width.
int windowWidth() {
    return bk.windowWidth;
}

/// Returns the current window height.
int windowHeight() {
    return bk.windowHeight;
}

/// Returns the current window size.
Vec2 windowSize() {
    return Vec2(bk.windowWidth, bk.windowHeight);
}

/// Returns the current resolution width.
int resolutionWidth() {
    return isResolutionLocked ? _engineState.viewport.data.width : windowWidth;
}

/// Returns the current resolution height.
int resolutionHeight() {
    return isResolutionLocked ? _engineState.viewport.data.height : windowHeight;
}

/// Returns the current resolution size.
Vec2 resolution() {
    return Vec2(resolutionWidth, resolutionHeight);
}

/// Returns the vertical synchronization state (VSync).
bool vsync() {
    return bk.vsync;
}

/// Sets the vertical synchronization state (VSync).
void setVsync(bool value) {
    bk.setVsync(value);
}

/// Returns the current frames per second (FPS).
int fps() {
    return bk.fps;
}

/// Returns the maximum frames per second (FPS).
int fpsMax() {
    return bk.fpsMax;
}

/// Sets the maximum number of frames that can be rendered every second (FPS).
void setFpsMax(int value) {
    bk.setFpsMax(value);
}

/// Returns the total elapsed time since the application started.
double elapsedTime() {
    return bk.elapsedTime;
}

/// Returns the total number of ticks elapsed since the application started.
long elapsedTickCount() {
    return bk.elapsedTickCount;
}

/// Returns the time elapsed since the last frame.
float deltaTime() {
    return bk.deltaTime;
}

/// Returns the current position of the mouse on the screen.
Vec2 mouse() {
    return _engineState.mouseBuffer;
}

/// Returns the change in mouse position since the last frame.
Vec2 deltaMouse() {
    return bk.deltaMouse;
}

/// Returns the change in mouse wheel position since the last frame.
float deltaWheel() {
    return bk.deltaWheel;
}

/// Returns true if the specified key is currently pressed.
bool isDown(char key) => key ? bk.isDown(key) : false;
/// Returns true if the specified key is currently pressed.
bool isDown(Keyboard key) => key ? bk.isDown(key) : false;
/// Returns true if the specified key is currently pressed.
bool isDown(Mouse key) => key ? bk.isDown(key) : false;
/// Returns true if the specified key is currently pressed.
bool isDown(Gamepad key, int id = 0) => key ? bk.isDown(key, id) : false;

/// Returns true if the specified key was pressed.
bool isPressed(char key) => key ? bk.isPressed(key) : false;
/// Returns true if the specified key was pressed.
bool isPressed(Keyboard key) => key ? bk.isPressed(key) : false;
/// Returns true if the specified key was pressed.
bool isPressed(Mouse key) => key ? bk.isPressed(key) : false;
/// Returns true if the specified key was pressed.
bool isPressed(Gamepad key, int id = 0) => key ? bk.isPressed(key, id) : false;

/// Returns true if the specified key was released.
bool isReleased(char key) => key ? bk.isReleased(key) : false;
/// Returns true if the specified key was released.
bool isReleased(Keyboard key) => key ? bk.isReleased(key) : false;
/// Returns true if the specified key was released.
bool isReleased(Mouse key) => key ? bk.isReleased(key) : false;
/// Returns true if the specified key was released.
bool isReleased(Gamepad key, int id = 0) => key ? bk.isReleased(key, id) : false;

/// Returns the recently pressed keyboard key.
/// This function acts like a queue, meaning that multiple calls will return other recently pressed keys.
/// A none key is returned when the queue is empty.
Keyboard dequeuePressedKey() {
    return bk.dequeuePressedKey();
}

/// Returns the recently pressed character.
/// This function acts like a queue, meaning that multiple calls will return other recently pressed characters.
/// A none character is returned when the queue is empty.
dchar dequeuePressedRune() {
    return bk.dequeuePressedRune();
}

/// Returns the directional input based on the WASD and arrow keys when they are down.
/// The vector is not normalized.
Vec2 wasd() {
    return _engineState.wasdBuffer;
}

/// Returns the directional input based on the WASD and arrow keys when they are pressed.
/// The vector is not normalized.
Vec2 wasdPressed() {
    return _engineState.wasdPressedBuffer;
}

/// Returns the directional input based on the WASD and arrow keys when they are released.
/// The vector is not normalized.
Vec2 wasdReleased() {
    return _engineState.wasdReleasedBuffer;
}

/// Plays the specified sound.
void playSound(SoundId sound) {
    if (!sound.isValid) return;
    bk.playSound(sound.data);
}

/// Stops playback of the specified sound.
void stopSound(SoundId sound) {
    if (!sound.isValid) return;
    bk.stopSound(sound.data);
}

/// Resets and plays the specified sound.
void startSound(SoundId sound) {
    if (!sound.isValid) return;
    bk.startSound(sound.data);
}

/// Pauses playback of the specified sound.
void pauseSound(SoundId sound) {
    if (!sound.isValid) return;
    bk.pauseSound(sound.data);
}

/// Resumes playback of the specified paused sound.
void resumeSound(SoundId sound) {
    if (!sound.isValid) return;
    bk.resumeSound(sound.data);
}

/// Toggles the active state of the sound.
void toggleSoundIsActive(SoundId sound) {
    if (sound.isActive) stopSound(sound);
    else playSound(sound);
}

/// Toggles the paused state of the sound.
void toggleSoundIsPaused(SoundId sound) {
    if (sound.isPaused) resumeSound(sound);
    else pauseSound(sound);
}

/// Measures the size of the specified text when rendered with the given font and draw options.
Vec2 measureTextSize(FontId font, IStr text, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    version (ParinSkipDrawChecks) {
    } else {
        if (font.isNull) {
            if (isEmptyFontVisible) font = engineFont;
            else return Vec2();
        }
    }

    auto lineCodepointCount = 0;
    auto lineMaxCodepointCount = 0;
    auto textWidth = 0;
    auto textMaxWidth = 0;
    auto textHeight = font.size;
    auto textCodepointIndex = 0;
    while (textCodepointIndex < text.length) {
        lineCodepointCount += 1;
        auto codepointByteCount = 0;
        auto codepoint = TEMP_REPLACE_ME_GetCodepointNext(&text[textCodepointIndex], &codepointByteCount); // TODO: REPLACE WITH JOKA THING
        auto glyphInfo = font.glyphInfo(codepoint);
        if (codepoint != '\n') {
            if (glyphInfo.advanceX) {
                textWidth += glyphInfo.advanceX + font.runeSpacing;
            } else {
                textWidth += glyphInfo.rect.w + glyphInfo.offset.x + font.runeSpacing;
            }
        } else {
            if (textMaxWidth < textWidth) textMaxWidth = textWidth;
            lineCodepointCount = 0;
            textWidth = 0;
            textHeight += font.lineSpacing;
        }
        if (lineMaxCodepointCount < lineCodepointCount) lineMaxCodepointCount = lineCodepointCount;
        textCodepointIndex += codepointByteCount;
    }
    if (textMaxWidth < textWidth) textMaxWidth = textWidth;
    if (textMaxWidth < extra.alignmentWidth) textMaxWidth = extra.alignmentWidth;
    return Vec2(textMaxWidth * options.scale.x, textHeight * options.scale.y).floor();
}

/// Draws a rectangle with the specified area and color.
void drawRect(Rect area, Rgba color = white, float thickness = -1.0f) {
    bk.drawRect(isPixelSnapped ? area.floor() : area, color, thickness);
}

/// Draws a point at the specified location with the given size and color.
void drawVec2(Vec2 point, Rgba color = white, float thickness = 9.0f) {
    drawRect(Rect(point, thickness, thickness).centerArea, color);
}

/// Draws a circle with the specified area and color.
void drawCirc(Circ area, Rgba color = white, float thickness = -1.0f) {
    bk.drawCirc(isPixelSnapped ? area.floor() : area, color, thickness);
}

/// Draws a line with the specified area, thickness, and color.
void drawLine(Line area, Rgba color = white, float thickness = 9.0f) {
    bk.drawLine(isPixelSnapped ? area.floor() : area, color, thickness);
}

/// Draws a portion of the specified texture at the given position with the specified draw options.
void drawTextureArea(TextureId texture, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    version (ParinSkipDrawChecks) {
    } else {
        if (texture.isNull) {
            if (isEmptyTextureVisible) {
                auto rect = Rect(position, (!area.hasSize ? Vec2(64) : area.size) * options.scale).area(options.hook);
                drawRect(rect, defaultEngineDebugColor1);
                drawRect(rect, defaultEngineDebugColor2, 1);
            }
            return;
        }
    }

    auto target = Rect(position, area.size * options.scale);
    auto origin = options.origin.isZero ? target.origin(options.hook) : options.origin;
    final switch (options.flip) {
        case Flip.none: break;
        case Flip.x: area.size.x *= -1.0f; break;
        case Flip.y: area.size.y *= -1.0f; break;
        case Flip.xy: area.size *= Vec2(-1.0f); break;
    }
    if (isPixelSnapped) {
        bk.drawTexture(
            texture.data,
            area.floor(),
            target.floor(),
            origin.floor(),
            options.rotation,
            options.color,
        );
    } else {
        bk.drawTexture(
            texture.data,
            area,
            target,
            origin,
            options.rotation,
            options.color,
        );
    }
}

/// Draws a portion of the default texture at the given position with the specified draw options.
/// Use the `setDefaultTexture` function before using this function.
void drawTextureArea(Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTextureArea(_engineState.defaultTexture, area, position, options);
}

/// Draws the texture at the given position with the specified draw options.
void drawTexture(TextureId texture, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTextureArea(texture, Rect(texture.size), position, options);
}

/// Draws a 9-slice from the specified texture area at the given target area.
void drawTextureSlice(TextureId texture, Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions()) {
    version (ParinSkipDrawChecks) {
    } else {
        if (texture.isNull) {
            if (isEmptyTextureVisible) {
                drawRect(target, defaultEngineDebugColor1);
                drawRect(target, defaultEngineDebugColor2, 1);
            }
            return;
        }
    }

    // NOTE: New rule for options. Functions are allowed to ignore values. Should they handle bad values? Ehhh.
    auto tempOptions = options;
    foreach (part; computeSliceParts(area.floor().toIRect(), target.floor().toIRect(), margin)) {
        if (canRepeat && part.canTile) {
            tempOptions.scale = Vec2(1);
            foreach (y; 0 .. part.tileCount.y) { foreach (x; 0 .. part.tileCount.x) {
                auto sourceW = (x != part.tileCount.x - 1) ? part.source.w : max(0, part.target.w - x * part.source.w);
                auto sourceH = (y != part.tileCount.y - 1) ? part.source.h : max(0, part.target.h - y * part.source.h);
                drawTextureArea(
                    texture,
                    Rect(part.source.x, part.source.y, sourceW, sourceH),
                    Vec2(part.target.x + x * part.source.w, part.target.y + y * part.source.h),
                    tempOptions,
                );
            }}
        } else {
            tempOptions.scale = Vec2(
                part.target.w / cast(float) part.source.w,
                part.target.h / cast(float) part.source.h,
            );
            drawTextureArea(
                texture,
                Rect(part.source.x, part.source.y, part.source.w, part.source.h),
                Vec2(part.target.x, part.target.y),
                tempOptions,
            );
        }
    }
}

/// Draws a 9-slice from the default texture area at the given target area.
/// Use the `setDefaultTexture` function before using this function.
void drawTextureSlice(Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions()) {
    drawTextureSlice(_engineState.defaultTexture, area, target, margin, canRepeat, options);
}

/// Draws a portion of the specified viewport at the given position with the specified draw options.
void drawViewportArea(ViewportId viewport, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    version (ParinSkipDrawChecks) {
    } else {
        if (!viewport.isValid) {
            if (isEmptyTextureVisible) {
                auto rect = Rect(position, (!area.hasSize ? Vec2(64) : area.size) * options.scale).area(options.hook);
                drawRect(rect, defaultEngineDebugColor1);
                drawRect(rect, defaultEngineDebugColor2, 1);
            }
            return;
        }
    }

    // NOTE: JUST COPY PASTED THE TEXUTYRE CODE, but changed how the flip works.
    auto target = Rect(position, area.size * options.scale);
    auto origin = options.origin.isZero ? target.origin(options.hook) : options.origin;
    final switch (options.flip) {
        case Flip.none: area.size.y *= -1.0f; break;
        case Flip.x: area.size *= Vec2(-1.0f); break;
        case Flip.y: break;
        case Flip.xy: area.size.x *= -1.0f; break;
    }
    if (isPixelSnapped) {
        bk.drawViewport(
            viewport.data,
            area.floor(),
            target.floor(),
            origin.floor(),
            options.rotation,
            options.color,
        );
    } else {
        bk.drawViewport(
            viewport.data,
            area,
            target,
            origin,
            options.rotation,
            options.color,
        );
    }
}

/// Draws the viewport at the given position with the specified draw options.
void drawViewport(ViewportId viewport, Vec2 position, DrawOptions options = DrawOptions()) {
    drawViewportArea(viewport, Rect(viewport.size), position, options);
}

/// Draws a single character from the specified font at the given position with the specified draw options.
Vec2 drawRune(FontId font, dchar rune, Vec2 position, DrawOptions options = DrawOptions()) {
    version (ParinSkipDrawChecks) {
    } else {
        if (font.isNull) {
            if (isEmptyFontVisible) font = engineFont;
            else return Vec2();
        }
    }

    auto rect = font.glyphInfo(rune).rect.toRect();
    auto origin = options.origin.isZero ? rect.origin(options.hook) : options.origin;
    bk.pushMatrix();
    if (isPixelSnapped) {
        bk.matrixTranslate(floor(position.x), floor(position.y), 0.0f);
    } else {
        bk.matrixTranslate(position.x, position.y, 0.0f);
    }
    bk.matrixRotate(options.rotation, 0.0f, 0.0f, 1.0f);
    bk.matrixScale(options.scale.x, options.scale.y, 1.0f);
    bk.matrixTranslate(floor(-origin.x), floor(-origin.y), 0.0f);
    bk.drawRune(font.data, rune, Vec2(), options.color);
    bk.popMatrix();
    return rect.size;
}

/// Draws a single character from the default font at the given position with the specified draw options.
/// Check the `setDefaultFont` function before using this function.
Vec2 drawRune(dchar rune, Vec2 position, DrawOptions options = DrawOptions()) {
    return drawRune(_engineState.defaultFont, rune, position, options);
}

/// Draws the specified text with the given font at the given position using the provided draw options.
// NOTE: Text drawing needs to go over the text 3 times. This can be made into 2 times in the future if needed by copy-pasting the measureTextSize inside this function.
Vec2 drawText(FontId font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    enum lineCountOfBuffers = 512;
    static FixedList!(IStr, lineCountOfBuffers)  linesBuffer = void;
    static FixedList!(short, lineCountOfBuffers) linesWidthBuffer = void;

    version (ParinSkipDrawChecks) {
    } else {
        if (font.isNull) {
            if (isEmptyFontVisible) font = engineFont;
            else return Vec2();
        }
    }

    auto result = Vec2();
    linesBuffer.clear();
    linesWidthBuffer.clear();
    // Get some info about the text.
    auto textCodepointCount = 0;
    auto textMaxLineWidth = 0;
    auto textHeight = font.size;
    {
        auto lineCodepointIndex = 0;
        auto textCodepointIndex = 0;
        while (textCodepointIndex < text.length) {
            textCodepointCount += 1;
            auto codepointSize = 0;
            auto codepoint = TEMP_REPLACE_ME_GetCodepointNext(&text[textCodepointIndex], &codepointSize);
            if (codepoint == '\n' || textCodepointIndex == text.length - codepointSize) {
                linesBuffer.append(text[lineCodepointIndex .. textCodepointIndex + (codepoint != '\n')]);
                linesWidthBuffer.push(cast(ushort) (measureTextSize(font, linesBuffer[$ - 1]).x));
                if (textMaxLineWidth < linesWidthBuffer[$ - 1]) textMaxLineWidth = linesWidthBuffer[$ - 1];
                if (codepoint == '\n') textHeight += font.lineSpacing;
                lineCodepointIndex = cast(ushort) (textCodepointIndex + 1);
            }
            textCodepointIndex += codepointSize;
        }
        if (textMaxLineWidth < extra.alignmentWidth) textMaxLineWidth = extra.alignmentWidth;
    }
    result.x = textMaxLineWidth; // I kinda hate the names lol.
    result.y = textHeight;

    // Prepare the the text for drawing.
    auto origin = Rect(textMaxLineWidth, textHeight).origin(options.hook);
    bk.pushMatrix();
    if (isPixelSnapped) {
        bk.matrixTranslate(floor(position.x), floor(position.y), 0.0f);
    } else {
        bk.matrixTranslate(position.x, position.y, 0.0f);
    }
    bk.matrixRotate(options.rotation, 0.0f, 0.0f, 1.0f);
    bk.matrixScale(options.scale.x, options.scale.y, 1.0f);
    bk.matrixTranslate(floor(-origin.x), floor(-origin.y), 0.0f);
    // Draw the text.
    auto drawMaxCodepointCount = extra.visibilityCount ? extra.visibilityCount : textCodepointCount * extra.visibilityRatio;
    auto drawCodepointCounter = 0;
    auto textOffsetY = 0;
    foreach (i, line; linesBuffer) {
        auto lineCodepointIndex = 0;
        // Find the initial x offset for the text.
        auto textOffsetX = 0;
        if (extra.isRightToLeft) {
            final switch (extra.alignment) {
                case Alignment.left: textOffsetX = linesWidthBuffer[i]; break;
                case Alignment.center: textOffsetX = textMaxLineWidth / 2 + linesWidthBuffer[i] / 2; break;
                case Alignment.right: textOffsetX = textMaxLineWidth; break;
            }
        } else {
            final switch (extra.alignment) {
                case Alignment.left: break;
                case Alignment.center: textOffsetX = textMaxLineWidth / 2 - linesWidthBuffer[i] / 2; break;
                case Alignment.right: textOffsetX = textMaxLineWidth - linesWidthBuffer[i]; break;
            }
        }
        // Go over the characters and draw them.
        if (extra.isRightToLeft) {
            lineCodepointIndex = cast(int) line.length;
            while (lineCodepointIndex > 0) {
                if (drawCodepointCounter >= drawMaxCodepointCount) break;
                auto codepointSize = 0;
                auto codepoint = TEMP_REPLACE_ME_GetCodepointPrevious(&line.ptr[lineCodepointIndex], &codepointSize);
                auto glyphInfo = font.glyphInfo(codepoint);
                if (lineCodepointIndex == line.length) {
                    if (glyphInfo.advanceX) {
                        textOffsetX -= glyphInfo.advanceX + font.runeSpacing;
                    } else {
                        textOffsetX -= glyphInfo.rect.w + font.runeSpacing;
                    }
                } else {
                    auto temp = 0;
                    auto nextRightToLeftGlyphInfo = font.glyphInfo(TEMP_REPLACE_ME_GetCodepointPrevious(&line[lineCodepointIndex], &temp));
                    if (nextRightToLeftGlyphInfo.advanceX) {
                        textOffsetX -= nextRightToLeftGlyphInfo.advanceX + font.runeSpacing;
                    } else {
                        textOffsetX -= nextRightToLeftGlyphInfo.rect.w + font.runeSpacing;
                    }
                }
                if (codepoint != ' ' && codepoint != '\t') {
                    bk.drawRune(font.data, codepoint, Vec2(textOffsetX, textOffsetY), options.color);
                }
                drawCodepointCounter += 1;
                lineCodepointIndex -= codepointSize;
            }
            drawCodepointCounter += 1;
            textOffsetY += font.lineSpacing;
        } else {
            while (lineCodepointIndex < line.length) {
                if (drawCodepointCounter >= drawMaxCodepointCount) break;
                auto codepointSize = 0;
                auto codepoint = TEMP_REPLACE_ME_GetCodepointNext(&line[lineCodepointIndex], &codepointSize);
                auto glyphInfo = font.glyphInfo(codepoint);
                if (codepoint != ' ' && codepoint != '\t') {
                    bk.drawRune(font.data, codepoint, Vec2(textOffsetX, textOffsetY), options.color);
                }
                if (glyphInfo.advanceX) {
                    textOffsetX += glyphInfo.advanceX + font.runeSpacing;
                } else {
                    textOffsetX += glyphInfo.rect.w + font.runeSpacing;
                }
                drawCodepointCounter += 1;
                lineCodepointIndex += codepointSize;
            }
            drawCodepointCounter += 1;
            textOffsetY += font.lineSpacing;
        }
    }
    bk.popMatrix();
    return result;
}

/// Draws text with the default font at the given position with the provided draw options.
/// Check the `setDefaultFont` function before using this function.
Vec2 drawText(IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    return drawText(_engineState.defaultFont, text, position, options, extra);
}

/// Draws debug engine information at the given position with the provided draw options.
/// Hold the left mouse button to create and resize a debug area.
/// Hold the right mouse button to move the debug area.
/// Press the middle mouse button to clear the debug area.
void drawDebugEngineInfo(Vec2 screenPoint, Camera camera = Camera(), DrawOptions options = DrawOptions(), bool isLogging = false) {
    static clickPoint = Vec2();
    static clickOffset = Vec2();
    static a = Vec2();
    static b = Vec2();
    static s = Vec2();

    IStr text;
    auto mouse = mouse.toScenePoint(camera);
    if (Mouse.middle.isPressed) s = Vec2();
    if (Mouse.right.isDown) {
        if (s.isZero) {
            if (Mouse.right.isPressed) clickPoint = mouse;
            a = Vec2(min(clickPoint.x, mouse.x), min(clickPoint.y, mouse.y));
            b = a;
        } else {
            if (Mouse.right.isPressed) clickOffset = a - mouse;
            a = mouse + clickOffset;
        }
    }
    if (Mouse.left.isDown) {
        if (Mouse.left.isPressed) clickPoint = mouse;
        a = Vec2(min(clickPoint.x, mouse.x), min(clickPoint.y, mouse.y));
        b = Vec2(max(clickPoint.x, mouse.x), max(clickPoint.y, mouse.y));
        s = b - a;
        text = "FPS: {}\nAssets: (T{} F{} S{})\nMouse: A({} {}) B({} {}) S({} {})".fmt(
            fps,
            bk.backendTextureCount,
            bk.backendFontCount - 1,
            bk.backendSoundCount,
            cast(int) a.x,
            cast(int) a.y,
            cast(int) b.x,
            cast(int) b.y,
            cast(int) s.x,
            cast(int) s.y,
        );
    } else {
        if (s.isZero) {
            text = "FPS: {}\nAssets: (T{} F{} S{})\nMouse: ({} {})".fmt(
                fps,
                bk.backendTextureCount,
                bk.backendFontCount - 1,
                bk.backendSoundCount,
                cast(int) mouse.x,
                cast(int) mouse.y,
            );
        } else {
            text = "FPS: {}\nAssets: (T{} F{} S{})\nMouse: ({} {})\nArea: A({} {}) B({} {}) S({} {})".fmt(
                fps,
                bk.backendTextureCount,
                bk.backendFontCount - 1,
                bk.backendSoundCount,
                cast(int) mouse.x,
                cast(int) mouse.y,
                cast(int) a.x,
                cast(int) a.y,
                cast(int) b.x,
                cast(int) b.y,
                cast(int) s.x,
                cast(int) s.y,
            );
        }
    }
    drawRect(Rect(a.toCanvasPoint(camera), s), defaultEngineDebugColor1);
    drawRect(Rect(a.toCanvasPoint(camera), s), defaultEngineDebugColor2, 1);
    drawText(text, screenPoint, options);
    if (isLogging && (Mouse.left.isReleased || Mouse.right.isReleased)) {
        printfln(
            "Debug Engine Info\n A: Vec2({}, {})\n B: Vec2({}, {})\n S: Vec2({}, {})",
            cast(int) a.x,
            cast(int) a.y,
            cast(int) b.x,
            cast(int) b.y,
            cast(int) s.x,
            cast(int) s.y,
        );
    }
}

/// Draws debug tile information at the given position with the provided draw options.
void drawDebugTileInfo(int tileWidth, int tileHeight, Vec2 screenPoint, Camera camera = Camera(), DrawOptions options = DrawOptions(), bool isLogging = false) {
    auto mouse = mouse.toScenePoint(camera);
    auto gridPoint = Vec2(mouse.x / tileWidth, mouse.y / tileHeight).floor();
    auto tile = Rect(gridPoint.x * tileWidth, gridPoint.y * tileHeight, tileWidth, tileHeight);
    auto text = "Grid: ({} {})\nWorld: ({} {})".fmt(
        cast(int) gridPoint.x,
        cast(int) gridPoint.y,
        cast(int) tile.x,
        cast(int) tile.y,
    );
    drawRect(Rect(tile.position.toCanvasPoint(camera), tile.size), defaultEngineDebugColor1);
    drawRect(Rect(tile.position.toCanvasPoint(camera), tile.size), defaultEngineDebugColor2, 1);
    drawText(text, screenPoint, options);
    if (isLogging && (Mouse.left.isReleased || Mouse.right.isReleased)) {
        printfln(
            "Debug Tile Info\n Grid: Vec2({}, {})\n World: Vec2({}, {})",
            cast(int) gridPoint.x,
            cast(int) gridPoint.y,
            cast(int) tile.x,
            cast(int) tile.y,
        );
    }
}

/// Sets the position of `dprint*` text.
void setDprintPosition(Vec2 value) {
    _engineState.dprintPosition = value;
}

/// Sets the drawing options for `dprint*` text.
void setDprintOptions(DrawOptions value) {
    _engineState.dprintOptions = value;
}

/// Sets the maximum number of `dprint*` lines.
/// Older lines are removed once this limit is reached. Use 0 for unlimited.
void setDprintLineCountLimit(Sz value) {
    _engineState.dprintLineCountLimit = value;
}

/// Sets the visibility state of `dprint*` text.
void setDprintVisibility(bool value) {
    _engineState.dprintIsVisible = value;
}

/// Toggles the visibility state of `dprint*` text.
void toggleDprintVisibility() {
    setDprintVisibility(!_engineState.dprintIsVisible);
}

/// Clears all `dprint*` text.
void clearDprintBuffer() {
    _engineState.dprintBuffer.clear();
    _engineState.dprintLineCount = 0;
}

/// Returns the contents of the `dprint*` buffer as an `IStr`.
/// The returned string references the internal buffer and may change if more text is printed.
IStr dprintBuffer() {
    return _engineState.dprintBuffer.items;
}

/// Adds a formatted line to the `dprint*` text.
void dprintfln(A...)(IStr fmtStr, A args) {
    if (_engineState.dprintLineCountLimit != 0) {
        while (_engineState.dprintLineCount >= _engineState.dprintLineCountLimit) {
            while (_engineState.dprintBuffer.length && _engineState.dprintBuffer[0] != '\n') _engineState.dprintBuffer.removeShift(0);
            if (_engineState.dprintBuffer.length && _engineState.dprintBuffer[0] == '\n') _engineState.dprintBuffer.removeShift(0);
            _engineState.dprintLineCount -= 1;
        }
    }
    sprintfln(_engineState.dprintBuffer, fmtStr, args);
    _engineState.dprintLineCount += 1;
}

/// Adds a line to the `dprint*` text.
void dprintln(A...)(A args) {
    if (_engineState.dprintLineCountLimit != 0) {
        while (_engineState.dprintLineCount >= _engineState.dprintLineCountLimit) {
            while (_engineState.dprintBuffer.length && _engineState.dprintBuffer[0] != '\n') _engineState.dprintBuffer.removeShift(0);
            if (_engineState.dprintBuffer.length && _engineState.dprintBuffer[0] == '\n') _engineState.dprintBuffer.removeShift(0);
            _engineState.dprintLineCount -= 1;
        }
    }
    sprintln(_engineState.dprintBuffer, args);
    _engineState.dprintLineCount += 1;
}
