// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `engine` module functions as a lightweight 2D game engine.
module parin.engine;

version (ParinSkipDrawChecks) pragma(msg, "Parin: Skipping draw checks.");

import bk = parin.backend;

import parin.joka.ascii;
import parin.joka.io;
import parin.joka.memory;
import parin.joka.interpolation;

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
    EngineFlag.isNullTextureVisible |
    EngineFlag.isNullFontVisible |
    EngineFlag.isLoggingLoadOrSaveFaults |
    EngineFlag.isLoggingMemoryTrackingInfo;

enum defaultEngineValidateErrorMessage = "Resource is invalid or was never assigned.";
enum defaultEngineLoadErrorMessage     = "ERROR({}:{}): Could not load {} from \"{}\".";
enum defaultEngineSaveErrorMessage     = "ERROR({}:{}): Could not save {} from \"{}\".";

version (WebAssembly) {
    enum defaultEngineAssetsPathCapacity           = 4 * kilobyte;
    enum defaultEngineScreenshotTargetPathCapacity = 1 * kilobyte;
    enum defaultEngineEnvArgsCapacity              = 16;
    enum defaultEngineLoadOrSaveTextCapacity       = 16 * kilobyte;
    enum defaultEngineEngineTasksCapacity          = 56;
    enum defaultEngineArenaCapacity                = 1 * megabyte;
    enum defaultEngineDprintCapacity               = 2 * kilobyte;
} else {
    enum defaultEngineAssetsPathCapacity           = 8 * kilobyte;
    enum defaultEngineScreenshotTargetPathCapacity = 2 * kilobyte;
    enum defaultEngineEnvArgsCapacity              = 64;
    enum defaultEngineLoadOrSaveTextCapacity       = 16 * kilobyte;
    enum defaultEngineEngineTasksCapacity          = 112;
    enum defaultEngineArenaCapacity                = 4 * megabyte;
    enum defaultEngineDprintCapacity               = 8 * kilobyte;
}

enum defaultEngineDprintPosition       = Vec2(8, 6);
enum defaultEngineDprintLineCountLimit = 14;

enum defaultEngineDebugColor1 = white.alpha(120);
enum defaultEngineDebugColor2 = black.alpha(170);
// ----------

@trusted:

/// The engine font identifier.
enum engineFont = FontId(ResourceId(1));
/// The engine viewport identifier.
enum engineViewport = ViewportId(ResourceId(1));

/// A container type holding scheduled engine tasks.
alias EngineTasks = GenList!(
    Task,
    SparseList!(Task, FixedList!(SparseListItem!Task, defaultEngineEngineTasksCapacity)),
    FixedList!(Gen, defaultEngineEngineTasksCapacity)
);

/// An identifier for a scheduled engine task.
alias EngineTaskId = GenIndex;
/// Type representing the internal engine flags.
alias EngineFlags = uint;

///  The internal engine flags.
enum EngineFlag : EngineFlags {
    none                        = 0x000000,
    isUpdating                  = 0x000001,
    isUsingAssetsPath           = 0x000002,
    isPixelSnapped              = 0x000004,
    isPixelPerfect              = 0x000008,
    isNullTextureVisible        = 0x000010,
    isNullFontVisible           = 0x000020,
    isLoggingLoadOrSaveFaults   = 0x000040,
    isLoggingMemoryTrackingInfo = 0x000080,
    isDebugMode                 = 0x000100,
}

/// Information about the engine viewport, including its drawing region and size constraints.
struct EngineViewportInfo {
    Rect area;      /// The area covered by the viewport.
    Vec2 minSize;   /// The minimum size that the viewport can be.
    Vec2 maxSize;   /// The maximum size that the viewport can be.
    float minRatio; /// The minimum ratio between minSize and maxSize.
}

/// Internal representation of a viewport within the engine.
struct EngineViewport {
    ViewportId data; /// The viewport data.
    int lockWidth;   /// The target lock width.
    int lockHeight;  /// The target lock height.
    bool isChanging; /// The flag that triggers the new lock state.
    bool isLocking;  /// The flag that tells what the new lock state is.
}

/// Internal state of the engine.
struct EngineState {
    EngineFlags flags = defaultEngineFlags;
    UpdateFunc updateFunc;
    CallFunc debugModeFunc;
    CallFunc debugModeBeginFunc;
    CallFunc debugModeEndFunc;
    Keyboard debugModeKey = defaultEngineDebugModeKey;
    bool debugModePreviousState;
    bool debugModeEnteringFrameState;
    bool debugModeExitingFrameState;

    EngineViewportInfo viewportInfoBuffer;
    Vec2 mouseBuffer;
    Vec2 wasdBuffer;
    Vec2 wasdPressedBuffer;
    Vec2 wasdReleasedBuffer;

    bool clipIsActive;
    Rgba windowBorderColor = black;
    Filter defaultFilter;
    Wrap defaultWrap;
    FontId defaultFont = engineFont;
    TextureId defaultTexture;
    Camera userCamera;
    ViewportId userViewport;
    Fault lastLoadOrSaveFault;
    IStr memoryTrackingInfoFilter;
    FStr!defaultEngineAssetsPathCapacity assetsPath;
    FStr!defaultEngineScreenshotTargetPathCapacity screenshotTargetPath;
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

    /// Checks whether the resource is null (default value).
    bool isNull() {
        return bk.resourceIsNull(data);
    }

    /// Checks whether the resource is valid (loaded). Null is invalid.
    bool isValid() {
        return bk.textureIsValid(data);
    }

    /// Returns this resource if valid, or asserts with the given message if not.
    TextureId validate(IStr message = defaultEngineValidateErrorMessage) {
        return isValid ? this : assert(0, message);
    }

    /// Returns the filter mode.
    Filter filter() {
        return bk.textureFilter(data);
    }

    /// Sets the filter mode.
    void setFilter(Filter value) {
        bk.textureSetFilter(data, value);
    }

    /// Returns the wrap mode.
    Wrap wrap() {
        return bk.textureWrap(data);
    }

    /// Sets the wrap mode.
    void setWrap(Wrap value) {
        bk.textureSetWrap(data, value);
    }

    /// Returns the width in pixels.
    int width() {
        return bk.textureWidth(data);
    }

    /// Returns the height in pixels.
    int height() {
        return bk.textureHeight(data);
    }

    /// Returns the size in pixels.
    Vec2 size() {
        return bk.textureSize(data);
    }

    /// Frees the resource and resets the identifier to null.
    void free() {
        bk.textureFree(data);
        data = ResourceId();
    }
}

/// A font identifier.
struct FontId {
    ResourceId data;

    @safe nothrow @nogc:

    /// Checks whether the resource is null (default value).
    bool isNull() {
        return bk.resourceIsNull(data);
    }

    /// Checks whether the resource is valid (loaded). Null is invalid.
    bool isValid() {
        return bk.fontIsValid(data);
    }

    /// Returns this resource if valid, or asserts with the given message if not.
    FontId validate(IStr message = defaultEngineValidateErrorMessage) {
        return isValid ? this : assert(0, message);
    }

    /// Returns the filter mode.
    Filter filter() {
        return bk.fontFilter(data);
    }

    /// Sets the filter mode.
    void setFilter(Filter value) {
        bk.fontSetFilter(data, value);
    }

    /// Returns the wrap mode.
    Wrap wrap() {
        return bk.fontWrap(data);
    }

    /// Sets the wrap mode.
    void setWrap(Wrap value) {
        bk.fontSetWrap(data, value);
    }

    /// Returns the font size in pixels.
    int size() {
        return bk.fontSize(data);
    }

    /// Returns the spacing between characters in pixels.
    int runeSpacing() {
        return bk.fontRuneSpacing(data);
    }

    /// Sets the spacing between characters in pixels.
    void setRuneSpacing(int value) {
        return bk.fontSetRuneSpacing(data, value);
    }

    /// Returns the spacing between lines in pixels.
    int lineSpacing() {
        return bk.fontLineSpacing(data);
    }

    /// Sets the spacing between lines in pixels.
    void setLineSpacing(int value) {
        bk.fontSetLineSpacing(data, value);
    }

    /// Returns the glyph information for the given rune.
    GlyphInfo glyphInfo(int rune) {
        return bk.fontGlyphInfo(data, rune);
    }

    /// Frees the resource and resets the identifier to null.
    void free() {
        if (this != engineFont) bk.fontFree(data);
        data = ResourceId();
    }
}

/// A sound identifier.
struct SoundId {
    ResourceId data;

    @safe nothrow @nogc:

    /// Checks whether the resource is null (default value).
    bool isNull() {
        return bk.resourceIsNull(data);
    }

    /// Checks whether the resource is valid (loaded). Null is invalid.
    bool isValid() {
        return bk.soundIsValid(data);
    }

    /// Returns this resource if valid, or asserts with the given message if not.
    SoundId validate(IStr message = defaultEngineValidateErrorMessage) {
        return isValid ? this : assert(0, message);
    }

    /// Returns the volume. The default value is 1.0 (normal level).
    float volume() {
        return bk.soundVolume(data);
    }

    /// Sets the volume. The default value is 1.0 (normal level).
    void setVolume(float value) {
        bk.soundSetVolume(data, value);
    }

    /// Returns the pan. The default value is 0.5 (center).
    float pan() {
        return bk.soundPan(data);
    }

    /// Sets the pan. The default value is 0.5 (center).
    void setPan(float value) {
        bk.soundSetPan(data, value);
    }

    /// Returns the pitch. The default value is 1.0 (base level).
    float pitch() {
        return bk.soundPitch(data);
    }

    /// Sets the pitch. The default value is 1.0 (base level).
    void setPitch(float value, bool canUpdatePitchVarianceBase = false) {
        bk.soundSetPitch(data, value, canUpdatePitchVarianceBase);
    }

    /// Returns the pitch variance. The default value is 1.0 (no variation).
    float pitchVariance() {
        return bk.soundPitchVariance(data);
    }

    /// Sets the pitch variance. The default value is 1.0 (no variation).
    void setPitchVariance(float value) {
        bk.soundSetPitchVariance(data, value);
    }

    /// Returns the pitch variance base. The default value is 1.0 (base level).
    float pitchVarianceBase() {
        return bk.soundPitchVarianceBase(data);
    }

    /// Sets the pitch variance base. The default value is 1.0 (base level).
    void setPitchVarianceBase(float value) {
        bk.soundSetPitchVarianceBase(data, value);
    }

    /// Returns true if the sound is set to repeat.
    bool canRepeat() {
        return bk.soundCanRepeat(data);
    }

    /// Sets whether the sound should repeat.
    void setCanRepeat(bool value) {
        bk.soundSetCanRepeat(data, value);
    }

    /// Returns true if the sound is currently active (playing).
    bool isActive() {
        return bk.soundIsActive(data);
    }

    /// Returns true if the sound is currently paused.
    bool isPaused() {
        return bk.soundIsPaused(data);
    }

    /// Returns the current playback time in seconds.
    float time() {
        return bk.soundTime(data);
    }

    /// Returns the total duration in seconds.
    float duration() {
        return bk.soundDuration(data);
    }

    /// Returns the progress. The value is between 0.0 and 1.0 (inclusive).
    float progress() {
        return bk.soundProgress(data);
    }

    /// Frees the resource and resets the identifier to null.
    void free() {
        bk.soundFree(data);
        data = ResourceId();
    }
}

/// A viewport identifier.
struct ViewportId {
    ResourceId data;

    @safe nothrow @nogc:

    /// Checks whether the resource is null (default value).
    bool isNull() {
        return bk.resourceIsNull(data);
    }

    /// Checks whether the resource is valid (loaded). Null is invalid.
    bool isValid() {
        return bk.viewportIsValid(data);
    }

    /// Returns this resource if valid, or asserts with the given message if not.
    ViewportId validate(IStr message = defaultEngineValidateErrorMessage) {
        return isValid ? this : assert(0, message);
    }

    /// Returns the filter mode.
    Filter filter() {
        return bk.viewportFilter(data);
    }

    /// Sets the filter mode.
    void setFilter(Filter value) {
        bk.viewportSetFilter(data, value);
    }

    /// Returns the wrap mode.
    Wrap wrap() {
        return bk.viewportWrap(data);
    }

    /// Sets the wrap mode.
    void setWrap(Wrap value) {
        bk.viewportSetWrap(data, value);
    }

    /// Returns the blend mode.
    Blend blend() {
        return bk.viewportBlend(data);
    }

    /// Sets the blend mode.
    void setBlend(Blend value) {
        return bk.viewportSetBlend(data, value);
    }

    /// Returns the color in RGBA.
    Rgba color() {
        return bk.viewportColor(data);
    }

    /// Sets the color in RGBA.
    void setColor(Rgba value) {
        bk.viewportSetColor(data, value);
    }

    /// Returns the width in pixels.
    int width() {
        return bk.viewportWidth(data);
    }

    /// Returns the height in pixels.
    int height() {
        return bk.viewportHeight(data);
    }

    /// Returns the size in pixels.
    Vec2 size() {
        return bk.viewportSize(data);
    }

    /// Returns true if the viewport has never been used (attached).
    bool isFirstUse() {
        return bk.viewportIsFirstUse(data);
    }

    /// Returns true if the viewport is attached.
    bool isAttached() {
        return bk.viewportIsAttached(data);
    }

    /// Resizes the viewport. Internally, this creates a new texture, so avoid calling it while the viewport is in use.
    void resize(int newWidth, int newHeight) {
        bk.viewportResize(data, newWidth, newHeight);
    }

    /// Frees the resource and resets the identifier to null.
    void free() {
        if (this != engineViewport) bk.viewportFree(data);
        data = ResourceId();
    }
}

/// A clipping region. Designed to be used with the `with` keyword.
struct Clip {
    Rect _clipArea;

    @safe nothrow @nogc:

    this(Rect area) {
        this._clipArea = area;
        beginClip(area);
    }

    this(Vec2 position, Vec2 size) {
        this(Rect(position, size));
    }

    this(Vec2 size) {
        this(Vec2(), size);
    }

    this(float x, float y, float w, float h) {
        this(Vec2(x, y), Vec2(w, h));
    }

    this(float w, float h) {
        this(Vec2(), Vec2(w, h));
    }

    this(Vec2 position, float w, float h) {
        this(position, Vec2(w, h));
    }

    this(float x, float y, Vec2 size) {
        this(Vec2(x, y), size);
    }

    ~this() {
        endClip();
    }
}

// NOTE: Was thinking that `Attached!Camera(camera)` would look bad, so I used a function.
struct _Attached(T) {
    T* _attachedObject;

    @trusted nothrow @nogc:

    this(ref T object) {
        this._attachedObject = &object;
        attach(*this._attachedObject);
    }

    ~this() {
        detach(*this._attachedObject);
    }
}

// NOTE: Can keep it here because of inferred attributes.
/// Attaches the camera for the scope and detaches automatically.
_Attached!T Attached(T)(ref T object) {
    return _Attached!T(object);
}

/// Opens the window with the given information.
/// Avoid calling this function manually.
void openWindow(int width, int height, const(IStr)[] args, IStr title = "Parin", bool vsync = defaultEngineVsync) {
    enum monogramPath = "parin_monogram.png";

    bk.openWindow(width, height, title, vsync, defaultEngineFpsMax, defaultEngineWindowMinWidth, defaultEngineWindowMinHeight);
    _engineState = jokaMake!EngineState();
    _engineState.tasks.push(Task());
    _engineState.arena.ready(defaultEngineArenaCapacity);
    _engineState.viewport.data = loadViewport(0, 0, gray);
    if (!vsync) setFpsMax(0);
    loadTexture(cast(const(ubyte)[]) import(monogramPath)).loadFont(defaultEngineFontRuneWidth, defaultEngineFontRuneHeight);
    if (args.length) {
        foreach (arg; args) _engineState.envArgsBuffer.append(arg);
        _engineState.assetsPath.append(pathConcat(args[0].pathDirName, "assets"));
    }
}

/// Opens the window with the given information using C strings.
/// Avoid calling this function manually.
void openWindowC(int width, int height, int argc, IStrz* argv, IStrz title = "Parin", bool vsync = defaultEngineVsync) {
    openWindow(width, height, null, title.strzToStr(), vsync);
    if (argc) {
        foreach (i; 0 .. argc) _engineState.envArgsBuffer.append(argv[i].strzToStr());
        _engineState.assetsPath.append(pathConcat(_engineState.envArgsBuffer[0].pathDirName, "assets"));
    }
}

/// Starts the main window loop. Accepts an update function and optional debug callbacks.
/// Returns when the update function returns true.
/// Avoid calling this function manually.
void updateWindow(UpdateFunc updateFunc, CallFunc debugModeFunc = null, CallFunc debugModeBeginFunc = null, CallFunc debugModeEndFunc = null) {
    static bool updateWindowLoop() {
        // Update buffers and resources.
        bk.pumpEvents();
        _updateViewportInfoBuffer();
        _updateEngineMouseBuffer(bk.mouse);
        _updateEngineWasdBuffer();

        // Begin drawing.
        if (isResolutionLocked) {
            bk.beginViewport(_engineState.viewport.data.data);
        } else {
            bk.beginDrawing();
        }
        bk.clearBackground(_engineState.viewport.data.color);

        // Update and draw the game.
        auto result = false;
        with (ScopedArena(_engineState.arena)) {
            bk.beginDroppedPaths();
            _engineState.debugModePreviousState = isDebugMode;
            foreach (id; _engineState.tasks.ids) {
                if (_engineState.tasks[id].update(deltaTime)) cancel(id);
            }
            result = _engineState.updateFunc(deltaTime);
            if (_engineState.debugModeKey.isPressed) toggleIsDebugMode();
            if (isDebugMode || isExitingDebugMode || _engineState.debugModePreviousState) {
                if (_engineState.debugModeBeginFunc) _engineState.debugModeBeginFunc();
                if (_engineState.debugModeFunc) _engineState.debugModeFunc();
                if (_engineState.debugModeEndFunc) _engineState.debugModeEndFunc();
            }
            if (_engineState.dprintIsVisible) {
                drawText(_engineState.dprintBuffer.items, _engineState.dprintPosition, _engineState.dprintOptions);
            }
            _engineState.debugModeEnteringFrameState = isDebugMode && !_engineState.debugModePreviousState;
            _engineState.debugModeExitingFrameState = !isDebugMode && _engineState.debugModePreviousState;
            bk.endDroppedPaths();
        }

        // End drawing.
        if (isResolutionLocked) {
            auto info = engineViewportInfo;
            bk.endViewport(_engineState.viewport.data.data);
            bk.beginDrawing();
            bk.clearBackground(_engineState.windowBorderColor);
            bk.drawViewport(_engineState.viewport.data.data, Rect(info.minSize.x, -info.minSize.y), info.area, Vec2(), 0.0f, white);
            bk.endDrawing();
        } else {
            bk.endDrawing();
        }

        // Screenshot code.
        if (_engineState.screenshotTargetPath.length) {
            bk.takeScreenshot(_engineState.screenshotTargetPath.items);
            _engineState.screenshotTargetPath.clear();
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

    _engineState.updateFunc = updateFunc;
    _engineState.debugModeFunc = debugModeFunc;
    _engineState.debugModeBeginFunc = debugModeBeginFunc;
    _engineState.debugModeEndFunc = debugModeEndFunc;
    _engineState.flags |= EngineFlag.isUpdating;
    bk.updateWindow!(updateWindowLoop);
    _engineState.flags &= ~EngineFlag.isUpdating;
}

/// Closes the window.
/// Avoid calling this function manually.
void closeWindow() {
    auto filter = _engineState.memoryTrackingInfoFilter; // NOTE: I assume `filter` is a static string or managed by the user.
    auto isLogging = isLoggingMemoryTrackingInfo;
    _engineState.arena.free();
    _engineState.jokaFree();
    _engineState = null;
    bk.closeWindow();
    static if (isTrackingMemory) {
        if (isLogging) printMemoryTrackingInfo(filter);
    }
}

/// This mixin sets up a main function that opens and updates the window using the `ready`, `update`, and `finish` functions.
/// Optional callbacks for debug mode can also be provided.
mixin template runGame(
    alias readyFunc,
    alias updateFunc,
    alias finishFunc,
    int width = defaultEngineWidth,
    int height = defaultEngineHeight,
    IStr title = defaultEngineTitle,
    alias debugModeFunc = null,
    alias debugModeBeginFunc = null,
    alias debugModeEndFunc = null,
    bool vsyncOffHack = false,
) {
    int _runGame() {
        import mypr = parin.engine;
        static if (__traits(isStaticFunction, debugModeFunc))      { enum debugMode1 = &debugModeFunc;      } else { enum debugMode1 = null; }
        static if (__traits(isStaticFunction, debugModeBeginFunc)) { enum debugMode2 = &debugModeBeginFunc; } else { enum debugMode2 = null; }
        static if (__traits(isStaticFunction, debugModeEndFunc))   { enum debugMode3 = &debugModeEndFunc;   } else { enum debugMode3 = null; }

        static if (__traits(isStaticFunction, readyFunc))  readyFunc();
        static if (__traits(isStaticFunction, updateFunc)) mypr.updateWindow(&updateFunc, debugMode1, debugMode2, debugMode3);
        static if (__traits(isStaticFunction, finishFunc)) finishFunc();
        mypr.closeWindow();
        return 0;
    }

    version (D_BetterC) {
        extern(C)
        int main(int argc, const(char)** argv) {
            import mypr = parin.engine;
            mypr.openWindowC(width, height, argc, argv, title, vsyncOffHack ? false : defaultEngineVsync);
            return _runGame();
        }
    } else {
        int main(immutable(char)[][] args) {
            import mypr = parin.engine;
            mypr.openWindow(width, height, args, title, vsyncOffHack ? false : defaultEngineVsync);
            return _runGame();
        }
    }
}

Vec2 drawText(A...)(FontId font, InterpolationHeader header, A args, InterpolationFooter footer, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    return drawText(font, fmt(header, args, footer), position, options, extra);
}

Vec2 drawText(A...)(InterpolationHeader header, A args, InterpolationFooter footer, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    return drawText(fmt(header, args, footer), position, options, extra);
}

void dprintfln(A...)(InterpolationHeader header, A args, InterpolationFooter footer) {
    // NOTE: Both `fmtStr` and `fmtArgs` can be copy-pasted when working with IES. Main copy is in the `fmt` function.
    enum fmtStr = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T) { result ~= args[i].toString(); }
            else static if (isInterExpType!T) { result ~= defaultAsciiFmtArgStr; }
        } return result;
    }();
    enum fmtArgs = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T || isInterExpType!T) {}
            else { result ~= "args[" ~ i.stringof ~ "],"; }
        } return result;
    }();
    mixin("dprintfln(fmtStr,", fmtArgs, ");");
}

@trusted nothrow:

/// Allocates raw memory from the frame arena.
void* frameMalloc(Sz size, Sz alignment, IStr file = __FILE__, Sz line = __LINE__) {
    return _engineState.arena.malloc(size, alignment, file, line);
}

/// Reallocates memory from the frame arena.
void* frameRealloc(void* ptr, Sz oldSize, Sz newSize, Sz alignment, IStr file = __FILE__, Sz line = __LINE__) {
    return _engineState.arena.realloc(ptr, oldSize, newSize, alignment, file, line);
}

/// Allocates uninitialized memory for a single value of type `T`.
T* frameMakeBlank(T)(IStr file = __FILE__, Sz line = __LINE__) {
    return _engineState.arena.makeBlank!T(file, line);
}

/// Allocates and initializes a single value of type `T`.
T* frameMake(T)(IStr file = __FILE__, Sz line = __LINE__) {
    return _engineState.arena.make!T(file, line);
}

/// Allocates and initializes a single value of type `T`.
T* frameMake(T)(const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
    return _engineState.arena.make!T(value, file, line);
}

/// Allocates uninitialized memory for an array of type `T` with the given length.
T[] frameMakeSliceBlank(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
    return _engineState.arena.makeSliceBlank!T(length, file, line);
}

/// Allocates and initializes an array of type `T` with the given length.
T[] frameMakeSlice(T)(Sz length, IStr file = __FILE__, Sz line = __LINE__) {
    return _engineState.arena.makeSlice!T(length, file, line);
}

/// Allocates and initializes an array of type `T` with the given length.
T[] frameMakeSlice(T)(Sz length, const(T) value, IStr file = __FILE__, Sz line = __LINE__) {
    return _engineState.arena.makeSlice!T(length, value, file, line);
}

/// Allocates and initializes an array of type `T` with the given slice.
T[] frameMakeSlice(T)(const(T)[] values, IStr file = __FILE__, Sz line = __LINE__) {
    return _engineState.arena.makeSlice!T(values, file, line);
}

/// Allocates a temporary text buffer for this frame.
/// Each call returns a new buffer.
BStr prepareTempText(Sz capacity = defaultEngineLoadOrSaveTextCapacity, IStr file = __FILE__, Sz line = __LINE__) {
    return BStr(frameMakeSliceBlank!char(capacity, file, line));
}

/// Schedules a task to run every interval.
/// Set `count` to limit how many times it runs. Use -1 to run indefinitely.
/// If `canCallNow` is true, the task runs immediately.
EngineTaskId every(UpdateFunc func, float interval, int count = -1, bool canCallNow = false) {
    return _engineState.tasks.push(Task(interval, canCallNow ? interval : 0, func, cast(byte) count));
}

/// Cancels a scheduled task by its ID.
void cancel(EngineTaskId id) {
    if (id.value == 0) return;
    _engineState.tasks.remove(id);
}

/// Loads a texture file (PNG) with default filter and wrap modes.
/// Uses the assets path unless the input starts with `/` or `\`, or `isUsingAssetsPath` is false.
/// Path separators are normalized to the platform's native format.
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

/// Loads a texture file (PNG) from memory with default filter and wrap modes.
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

/// Loads a font file (TTF) with default filter and wrap modes.
/// Uses the assets path unless the input starts with `/` or `\`, or `isUsingAssetsPath` is false.
/// Path separators are normalized to the platform's native format.
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

/// Loads a font file (TTF) from memory with default filter and wrap modes.
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

/// Loads a font file (TTF) from a texture with default filter and wrap modes.
/// The input texture will be invalidated after loading.
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

/// Loads a sound file (WAV, OGG, MP3) with default playback settings.
/// Uses the assets path unless the input starts with `/` or `\`, or `isUsingAssetsPath` is false.
/// Path separators are normalized to the platform's native format.
SoundId loadSound(IStr path, float volume, float pitch, bool canRepeat, float pitchVariance = 1.0f, IStr file = __FILE__, Sz line = __LINE__) {
    auto trap = Fault.none;
    auto data = bk.loadSound(toAssetsPath(path), volume, pitch, canRepeat, pitchVariance).get(trap);
    if (didLoadOrSaveSucceed(trap, fmt(defaultEngineLoadErrorMessage, file, line, "sound", path.toAssetsPath()))) {
        return SoundId(data);
    }
    return SoundId();
}

/// Loads a viewport with default filter and wrap modes.
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

/// Loads a text file and returns the contents as a list.
/// Uses the assets path unless the input starts with `/` or `\`, or `isUsingAssetsPath` is false.
/// Path separators are normalized to the platform's native format.
LStr loadText(IStr path, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = readText(path.toAssetsPath());
    if (didLoadOrSaveSucceed(result.fault, fmt(defaultEngineLoadErrorMessage, file, line, "text", path.toAssetsPath()))) return result.get();
    return LStr();
}

/// Loads a text file into a temporary buffer for the current frame.
/// Uses the assets path unless the input starts with `/` or `\`, or `isUsingAssetsPath` is false.
/// Path separators are normalized to the platform's native format.
IStr loadTempText(IStr path, Sz capacity = defaultEngineLoadOrSaveTextCapacity, IStr file = __FILE__, Sz line = __LINE__) {
    auto tempText = BStr(frameMakeSliceBlank!char(capacity, file, line));
    loadTextIntoBuffer(path, tempText, file, line);
    return tempText.items;
}

/// Loads a text file into the given buffer.
/// Uses the assets path unless the input starts with `/` or `\`, or `isUsingAssetsPath` is false.
/// Path separators are normalized to the platform's native format.
Fault loadTextIntoBuffer(L = LStr)(IStr path, ref L listBuffer, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = readTextIntoBuffer(path.toAssetsPath(), listBuffer);
    didLoadOrSaveSucceed(result, fmt(defaultEngineLoadErrorMessage, file, line, "text", path.toAssetsPath()));
    return result;
}

/// Saves a text file with the given content.
/// Uses the assets path unless the input starts with `/` or `\`, or `isUsingAssetsPath` is false.
/// Path separators are normalized to the platform's native format.
Fault saveText(IStr path, IStr text, IStr file = __FILE__, Sz line = __LINE__) {
    auto result = writeText(path.toAssetsPath(), text);
    if (isLoggingLoadOrSaveFaults && result) eprintfln(defaultEngineSaveErrorMessage, file, line, "text", path.toAssetsPath());
    return result;
}

/// Sets the path used as the assets folder.
void setAssetsPath(IStr path) {
    _engineState.assetsPath.clear();
    _engineState.assetsPath.append(path);
}

@trusted nothrow @nogc:

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

// TODO: Replace that with something in Joka. I was too lazy to write it myself.
int _TEMP_REPLACE_ME_GetCodepointNext(const(char)* text, int* codepointSize) {
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
int _TEMP_REPLACE_ME_GetCodepointPrevious(const(char)* text, int* codepointSize) {
    const(char)* ptr = text;
    int codepoint = 0x3f;       // Codepoint (defaults to '?')
    int cpSize = 0;
    *codepointSize = 0;

    // Move to previous codepoint
    do ptr--;
    while (((0x80 & ptr[0]) != 0) && ((0xc0 & ptr[0]) ==  0x80));

    codepoint = _TEMP_REPLACE_ME_GetCodepointNext(ptr, &cpSize);

    if (codepoint != 0) *codepointSize = cpSize;

    return codepoint;
}

/// Returns the current path used as the assets folder.
IStr assetsPath() {
    return _engineState.assetsPath.items;
}

/// Converts a path to one within the assets folder.
/// Returns the path unchanged if it is absolute or asset paths are disabled.
IStr toAssetsPath(IStr path) {
    if (!isUsingAssetsPath || path.isAbsolutePath) return path;
    return pathConcat(assetsPath, path).pathFmt();
}

/// Returns true if the assets path is used when loading.
bool isUsingAssetsPath() {
    return cast(bool) (_engineState.flags & EngineFlag.isUsingAssetsPath);
}

/// Sets whether the assets path should be used when loading.
void setIsUsingAssetsPath(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isUsingAssetsPath
        : _engineState.flags & ~EngineFlag.isUsingAssetsPath;
}

/// Returns true if load or save faults should be logged.
bool isLoggingLoadOrSaveFaults() {
    return cast(bool) (_engineState.flags & EngineFlag.isLoggingLoadOrSaveFaults);
}

/// Sets whether load or save faults should be logged.
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
void setIsLoggingMemoryTrackingInfo(bool value, IStr pathFilter = "") {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isLoggingMemoryTrackingInfo
        : _engineState.flags & ~EngineFlag.isLoggingMemoryTrackingInfo;
    _engineState.memoryTrackingInfoFilter = pathFilter;
}

/// Returns true if debug mode is active.
bool isDebugMode() {
    return cast(bool) (_engineState.flags & EngineFlag.isDebugMode);
}

/// Returns true when entering debug mode this frame.
bool isEnteringDebugMode() {
    return _engineState.debugModeEnteringFrameState;
}

/// Returns true when exiting debug mode this frame.
bool isExitingDebugMode() {
    return _engineState.debugModeExitingFrameState;
}

/// Sets whether debug mode should be active.
void setIsDebugMode(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isDebugMode
        : _engineState.flags & ~EngineFlag.isDebugMode;
    if (_engineState.flags & EngineFlag.isUpdating) {
    } else {
        // NOTE: Copy-paste from update window function.
        _engineState.debugModeEnteringFrameState = isDebugMode && !_engineState.debugModePreviousState;
        _engineState.debugModeExitingFrameState = !isDebugMode && _engineState.debugModePreviousState;
    }
}

/// Toggles the debug mode on or off.
void toggleIsDebugMode() {
    setIsDebugMode(!isDebugMode);
}

/// Sets the key that toggles debug mode.
void setDebugModeKey(Keyboard value) {
    _engineState.debugModeKey = value;
}

/// Returns true if the window was resized.
bool isWindowResized() {
    return bk.isWindowResized;
}

/// Sets the minimum size of the window.
void setWindowMinSize(int width, int height) {
    bk.setWindowMinSize(width, height);
}

/// Sets the maximum size of the window.
void setWindowMaxSize(int width, int height) {
    bk.setWindowMaxSize(width, height);
}

/// Returns the current background color (fill color) of the window.
Rgba windowBackgroundColor() {
    return _engineState.viewport.data.color;
}

/// Sets the background color (fill color) of the window.
void setWindowBackgroundColor(Rgba value) {
    _engineState.viewport.data.setColor(value);
}

/// Returns the current color of the window borders shown when the aspect ratio is fixed.
Rgba windowBorderColor() {
    return _engineState.windowBorderColor;
}

/// Sets the color of the window borders shown when the aspect ratio is fixed.
void setWindowBorderColor(Rgba value) {
    _engineState.windowBorderColor = value;
}

/// Sets the title of the window.
void setWindowTitle(IStr value) {
    bk.setWindowTitle(value);
}

/// Sets the window icon using an texture file (PNG).
/// Uses the assets path unless the input starts with `/` or `\`, or `isUsingAssetsPath` is false.
/// Path separators are normalized to the platform's native format.
Fault setWindowIconFromFiles(IStr path) {
    return bk.setWindowIconFromFiles(path.toAssetsPath());
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

/// Returns the current resolution.
Vec2 resolution() {
    return Vec2(resolutionWidth, resolutionHeight);
}

/// Returns true if the resolution is locked.
bool isResolutionLocked() {
    return !_engineState.viewport.data.size.isZero;
}

/// Locks the resolution to the given width and height.
void lockResolution(int width, int height) {
    // NOTE: Could maybe change for weird values.
    _engineState.viewport.lockWidth = width;
    _engineState.viewport.lockHeight = height;
    if (_engineState.flags & EngineFlag.isUpdating) {
        _engineState.viewport.isChanging = true;
        _engineState.viewport.isLocking = true;
    } else {
        _engineState.viewport.data.resize(width, height);
    }
}

/// Unlocks the resolution.
void unlockResolution() {
    if (_engineState.flags & EngineFlag.isUpdating) {
        _engineState.viewport.isChanging = true;
        _engineState.viewport.isLocking = false;
    } else {
        _engineState.viewport.data.resize(0, 0);
    }
}

/// Toggles resolution lock using the specified width and height.
void toggleResolution(int width, int height) {
    if (isResolutionLocked) unlockResolution();
    else lockResolution(width, height);
}

/// Returns information about the engine viewport, including its size and position.
EngineViewportInfo engineViewportInfo() {
    return _engineState.viewportInfoBuffer;
}

/// Returns true if the application is in fullscreen mode.
bool isFullscreen() {
    return bk.isFullscreen;
}

/// Sets whether the application should be in fullscreen mode.
void setIsFullscreen(bool value) {
    bk.setIsFullscreen(value);
}

/// Toggles fullscreen mode.
void toggleIsFullscreen() {
    setIsFullscreen(!isFullscreen);
}

/// Returns true if the cursor is visible.
bool isCursorVisible() {
    return bk.isCursorVisible;
}

/// Sets whether the cursor should be visible.
void setIsCursorVisible(bool value) {
    bk.setIsCursorVisible(value);
}

/// Toggles cursor visibility.
void toggleIsCursorVisible() {
    setIsCursorVisible(!isCursorVisible);
}

/// Returns the current frames per second (FPS).
int fps() {
    return bk.fps;
}

/// Returns the maximum frames per second (FPS).
int fpsMax() {
    return bk.fpsMax;
}

/// Sets the maximum frames per second (FPS).
void setFpsMax(int value) {
    bk.setFpsMax(value);
}

/// Returns the vertical synchronization (VSync) state.
bool vsync() {
    return bk.vsync;
}

/// Sets the vertical synchronization (VSync) state.
void setVsync(bool value) {
    bk.setVsync(value);
}

/// Returns the total elapsed time since the application started.
double elapsedTime() {
    return bk.elapsedTime;
}

/// Returns the total number of ticks since the application started.
ulong elapsedTicks() {
    return bk.elapsedTicks;
}

/// Returns the time elapsed since the last frame.
float deltaTime() {
    return bk.deltaTime;
}

/// Returns a random integer between 0 and int.max (inclusive).
int randi() {
    return bk.randi;
}

/// Returns a random float between 0.0 and 1.0 (inclusive).
float randf() {
    return bk.randf;
}

/// Randomizes the seed of the random number generator.
void randomize() {
    bk.randomize();
}

/// Sets the random number generator seed to the given value.
void setRandomSeed(int value) {
    bk.setRandomSeed(value);
}

/// Returns the default filter mode used for textures, fonts and viewports.
Filter defaultFilter() {
    return _engineState.defaultFilter;
}

/// Sets the default filter mode used for textures, fonts and viewports.
void setDefaultFilter(Filter value) {
    _engineState.defaultFilter = value;
}

/// Returns the default wrap mode used for textures, fonts and viewports.
Wrap defaultWrap() {
    return _engineState.defaultWrap;
}

/// Sets the default wrap mode used for textures, fonts and viewports.
void setDefaultWrap(Wrap value) {
    _engineState.defaultWrap = value;
}

/// Returns the default texture used for null textures.
TextureId defaultTexture() {
    return _engineState.defaultTexture;
}

/// Sets the default texture used for null textures.
void setDefaultTexture(TextureId value) {
    _engineState.defaultTexture = value;
}

/// Returns the default font used for null fonts.
FontId defaultFont() {
    return _engineState.defaultFont;
}

/// Sets the default font used for null fonts.
void setDefaultFont(FontId value) {
    _engineState.defaultFont = value;
}

/// Returns true if drawing is done when using a null texture.
bool isNullTextureVisible() {
    return cast(bool) (_engineState.flags & EngineFlag.isNullTextureVisible);
}

/// Sets whether drawing should be done when using a null texture.
void setIsNullTextureVisible(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isNullTextureVisible
        : _engineState.flags & ~EngineFlag.isNullTextureVisible;
}

/// Returns true if drawing is done when using a null font.
bool isNullFontVisible() {
    return cast(bool) (_engineState.flags & EngineFlag.isNullFontVisible);
}

/// Sets whether drawing should be done when using a null font.
void setIsNullFontVisible(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isNullFontVisible
        : _engineState.flags & ~EngineFlag.isNullFontVisible;
}

/// Returns true if drawing is snapped to pixel coordinates.
bool isPixelSnapped() {
    return cast(bool) (_engineState.flags & EngineFlag.isPixelSnapped);
}

/// Sets whether drawing should snap to pixel coordinates.
void setIsPixelSnapped(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isPixelSnapped
        : _engineState.flags & ~EngineFlag.isPixelSnapped;
}

/// Returns true if drawing is pixel-perfect.
bool isPixelPerfect() {
    return cast(bool) (_engineState.flags & EngineFlag.isPixelPerfect);
}

/// Sets whether drawing should be pixel-perfect.
void setIsPixelPerfect(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isPixelPerfect
        : _engineState.flags & ~EngineFlag.isPixelPerfect;
}

/// Returns the size of the text.
Vec2 measureTextSize(FontId font, IStr text, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    version (ParinSkipDrawChecks) {
    } else {
        if (font.isNull) {
            if (isNullFontVisible) font = engineFont;
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
        auto codepoint = _TEMP_REPLACE_ME_GetCodepointNext(&text[textCodepointIndex], &codepointByteCount);
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

/// Converts a scene point to a canvas point using the given camera and resolution.
Vec2 toCanvasPoint(Vec2 point, Camera camera) {
    return bk.toCanvasPoint(point, camera, resolution);
}

/// Converts a scene point to a canvas point using the given camera and canvas size.
Vec2 toCanvasPoint(Vec2 point, Camera camera, Vec2 canvasSize) {
    return bk.toCanvasPoint(point, camera, canvasSize);
}

/// Converts a canvas point to a scene point using the given camera and resolution.
Vec2 toScenePoint(Vec2 point, Camera camera) {
    return bk.toScenePoint(point, camera, resolution);
}

/// Converts a canvas point to a scene point using the given camera and canvas size.
Vec2 toScenePoint(Vec2 point, Camera camera, Vec2 canvasSize) {
    return bk.toScenePoint(point, camera, canvasSize);
}

/// Returns the arguments this application was started with.
IStr[] envArgs() {
    return _engineState.envArgsBuffer.items;
}

/// Returns the dropped paths from the current frame.
IStr[] droppedPaths() {
    return bk.droppedPaths;
}

/// Saves a screenshot to the given path.
/// Uses the assets path unless the input starts with `/` or `\`, or `isUsingAssetsPath` is false.
/// Path separators are normalized to the platform's native format.
void takeScreenshot(IStr path) {
    if (path.length == 0) return;
    _engineState.screenshotTargetPath.clear();
    _engineState.screenshotTargetPath.append(path.toAssetsPath());
}

/// Opens a URL in the default web browser.
void openUrl(IStr url) {
    bk.openUrl(url);
}

/// Returns the last fault from a load or save call.
Fault lastLoadOrSaveFault() {
    return _engineState.lastLoadOrSaveFault;
}

/// Helper for checking the result of a load or save call.
/// Returns true if the fault is none, false otherwise.
bool didLoadOrSaveSucceed(Fault fault, IStr message) {
    if (fault) {
        _engineState.lastLoadOrSaveFault = fault;
        if (isLoggingLoadOrSaveFaults) eprintln(message);
        return false;
    }
    return true;
}

/// Frees all loaded textures.
void freeAllTextureIds() {
    bk.freeAllTextures(false);
}

/// Frees all loaded fonts.
void freeAllFontIds() {
    bk.freeAllFonts(true);
}

/// Frees all loaded sounds.
void freeAllSoundIds() {
    bk.freeAllSounds(false);
}

/// Frees all loaded viewports.
void freeAllViewportIds() {
    bk.freeAllViewports(true);
}

/// Frees all loaded textures, fonts, sounds, and viewports.
void freeAllResourceIds() {
    freeAllTextureIds();
    freeAllFontIds();
    freeAllSoundIds();
    freeAllViewportIds();
}

/// Clears all engine tasks.
void clearAllEngineTasks() {
    _engineState.tasks.clear();
}

/// Returns the current mouse position on the window.
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

/// Returns true if the specified character is currently pressed.
bool isDown(char key) {
    return key ? bk.isDown(key) : false;
}

/// Returns true if the specified keyboard key is currently pressed.
bool isDown(Keyboard key) {
    return key ? bk.isDown(key) : false;
}

/// Returns true if the specified mouse button is currently pressed.
bool isDown(Mouse key) {
    return key ? bk.isDown(key) : false;
}

/// Returns true if the specified gamepad button is currently pressed.
bool isDown(Gamepad key, int id = 0) {
    return key ? bk.isDown(key, id) : false;
}

/// Returns true if the specified character was pressed this frame.
bool isPressed(char key) {
    return key ? bk.isPressed(key) : false;
}

/// Returns true if the specified keyboard key was pressed this frame.
bool isPressed(Keyboard key) {
    return key ? bk.isPressed(key) : false;
}

/// Returns true if the specified mouse button was pressed this frame.
bool isPressed(Mouse key) {
    return key ? bk.isPressed(key) : false;
}

/// Returns true if the specified gamepad button was pressed this frame.
bool isPressed(Gamepad key, int id = 0) {
    return key ? bk.isPressed(key, id) : false;
}

/// Returns true if the specified character was released this frame.
bool isReleased(char key) {
    return key ? bk.isReleased(key) : false;
}

/// Returns true if the specified keyboard key was released this frame.
bool isReleased(Keyboard key) {
    return key ? bk.isReleased(key) : false;
}

/// Returns true if the specified mouse button was released this frame.
bool isReleased(Mouse key) {
    return key ? bk.isReleased(key) : false;
}

/// Returns true if the specified gamepad button was released this frame.
bool isReleased(Gamepad key, int id = 0) {
    return key ? bk.isReleased(key, id) : false;
}

/// Returns the direction from the WASD and arrow keys that are currently down. The result is not normalized.
Vec2 wasd() {
    return _engineState.wasdBuffer;
}

/// Returns the direction from the WASD and arrow keys that were pressed this frame. The result is not normalized.
Vec2 wasdPressed() {
    return _engineState.wasdPressedBuffer;
}

/// Returns the direction from the WASD and arrow keys that were released this frame. The result is not normalized.
Vec2 wasdReleased() {
    return _engineState.wasdReleasedBuffer;
}

/// Returns the next recently pressed keyboard key.
/// This acts like a queue. Returns `Keyboard.none` if the queue is empty.
Keyboard dequeuePressedKey() {
    return bk.dequeuePressedKey();
}

/// Returns the next recently pressed character.
/// This acts like a queue. Returns `\0` if the queue is empty.
dchar dequeuePressedRune() {
    return bk.dequeuePressedRune();
}

/// Attaches the given camera and makes it active.
void attach(ref Camera camera, Rounding type = Rounding.none) {
    if (_engineState.userCamera.isAttached) assert(0, "Cannot attach camera because another camera is already attached.");
    bk.beginCamera(camera, resolution, isPixelSnapped ? Rounding.floor : type);
    _engineState.userCamera = camera;
}

// NOTE: The engine viewport should not use this function.
/// Attaches the given viewport and makes it active.
void attach(ViewportId viewport) {
    if (viewport.size.isZero) return;
    if (_engineState.userViewport.isAttached) assert(0, "Cannot attach viewport because another viewport is already attached.");
    if (isResolutionLocked) bk.endViewport(_engineState.viewport.data.data);
    bk.beginViewport(viewport.data);
    bk.clearBackground(viewport.color);
    bk.beginBlend(viewport.blend);
    _engineState.userViewport = viewport;
}

/// Detaches the currently active camera.
void detach(ref Camera camera) {
    if (!camera.isAttached) assert(0, "Cannot detach camera because it is not the attached camera.");
    bk.endCamera(camera);
    _engineState.userCamera = Camera();
}

// NOTE: The engine viewport should not use this function.
/// Detaches the currently active viewport.
void detach(ViewportId viewport) {
    if (viewport.size.isZero) return;
    if (!_engineState.userViewport.isAttached) assert(0, "Cannot detach viewport because it is not the attached viewport.");
    bk.endBlend();
    bk.endViewport(viewport.data);
    _engineState.userViewport = ViewportId();
    if (isResolutionLocked) bk.beginViewport(_engineState.viewport.data.data);
}

/// Begins a clipping region using the given area.
void beginClip(Rect area) {
    if (_engineState.clipIsActive) assert(0, "Cannot begin clip again.");
    bk.beginClip(area);
    _engineState.clipIsActive = true;
}

/// Begins a clipping region using the given area.
void beginClip(float x, float y, float w, float h) {
    beginClip(Rect(x, y, w, h));
}

/// Ends the active clipping region.
void endClip() {
    if (!_engineState.clipIsActive) assert(0, "Cannot end clip again.");
    bk.endClip();
    _engineState.clipIsActive = false;
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

/// Draws the texture at the given position with the specified draw options.
void drawTexture(TextureId texture, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTextureArea(texture, Rect(texture.size), position, options);
}

/// Draws a portion of the specified texture at the given position with the specified draw options.
void drawTextureArea(TextureId texture, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    version (ParinSkipDrawChecks) {
    } else {
        if (texture.isNull) {
            if (isNullTextureVisible) {
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
/// Call `setDefaultTexture` before using this function.
void drawTextureArea(Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTextureArea(_engineState.defaultTexture, area, position, options);
}

/// Draws a 9-slice from the specified texture area at the given target area.
void drawTextureSlice(TextureId texture, Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions()) {
    version (ParinSkipDrawChecks) {
    } else {
        if (texture.isNull) {
            if (isNullTextureVisible) {
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
/// Call `setDefaultTexture` before using this function.
void drawTextureSlice(Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions()) {
    drawTextureSlice(_engineState.defaultTexture, area, target, margin, canRepeat, options);
}

/// Draws a portion of the specified viewport at the given position with the specified draw options.
void drawViewportArea(ViewportId viewport, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    version (ParinSkipDrawChecks) {
    } else {
        if (!viewport.isValid) {
            if (isNullTextureVisible) {
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
            if (isNullFontVisible) font = engineFont;
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
/// Call `setDefaultFont` before using this function.
Vec2 drawRune(dchar rune, Vec2 position, DrawOptions options = DrawOptions()) {
    return drawRune(_engineState.defaultFont, rune, position, options);
}

/// Draws the specified text with the given font at the given position using the provided draw options.
Vec2 drawText(FontId font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    enum lineCountOfBuffers = 512;
    static FixedList!(IStr, lineCountOfBuffers)  linesBuffer = void;
    static FixedList!(short, lineCountOfBuffers) linesWidthBuffer = void;

    version (ParinSkipDrawChecks) {
    } else {
        if (font.isNull) {
            if (isNullFontVisible) font = engineFont;
            else return Vec2();
        }
    }

    // NOTE: Text drawing needs to go over the text 3 times. This can be made into 2 times in the future if needed by copy-pasting the measureTextSize inside this function.
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
            auto codepoint = _TEMP_REPLACE_ME_GetCodepointNext(&text[textCodepointIndex], &codepointSize);
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
                auto codepoint = _TEMP_REPLACE_ME_GetCodepointPrevious(&line.ptr[lineCodepointIndex], &codepointSize);
                auto glyphInfo = font.glyphInfo(codepoint);
                if (lineCodepointIndex == line.length) {
                    if (glyphInfo.advanceX) {
                        textOffsetX -= glyphInfo.advanceX + font.runeSpacing;
                    } else {
                        textOffsetX -= glyphInfo.rect.w + font.runeSpacing;
                    }
                } else {
                    auto temp = 0;
                    auto nextRightToLeftGlyphInfo = font.glyphInfo(_TEMP_REPLACE_ME_GetCodepointPrevious(&line[lineCodepointIndex], &temp));
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
                auto codepoint = _TEMP_REPLACE_ME_GetCodepointNext(&line[lineCodepointIndex], &codepointSize);
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
/// Call `setDefaultFont` before using this function.
Vec2 drawText(IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    return drawText(_engineState.defaultFont, text, position, options, extra);
}

/// Append a formatted line to the overlay text buffer.
/// Drawn after everything else using the current default font.
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

/// Append a line to the overlay text buffer.
/// Drawn after everything else using the current default font.
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

/// Returns the contents of the overlay text buffer.
/// The returned string references the internal buffer and may change if more text is printed.
IStr dprintBuffer() {
    return _engineState.dprintBuffer.items;
}

/// Sets the position of the overlay text.
void setDprintPosition(Vec2 value) {
    _engineState.dprintPosition = value;
}

/// Sets the drawing options for the overlay text.
void setDprintOptions(DrawOptions value) {
    _engineState.dprintOptions = value;
}

/// Sets the maximum number of overlay text lines.
/// Older lines are removed once this limit is reached. Use 0 for unlimited.
void setDprintLineCountLimit(Sz value) {
    _engineState.dprintLineCountLimit = value;
}

/// Sets the visibility state of the overlay text.
/// Does not affect manual drawing via `drawDprintBuffer`.
void setDprintVisibility(bool value) {
    _engineState.dprintIsVisible = value;
}

/// Toggles the visibility state of the overlay text.
/// Does not affect manual drawing via `drawDprintBuffer`.
void toggleDprintVisibility() {
    setDprintVisibility(!_engineState.dprintIsVisible);
}

/// Clears the overlay text.
void clearDprintBuffer() {
    _engineState.dprintBuffer.clear();
    _engineState.dprintLineCount = 0;
}

/// Draws the overlay text now instead of at the end of the frame.
/// The text will still be drawn automatically later unless the buffer is cleared with `clearDprintBuffer`, or visibility is disabled with `setDprintVisibility`.
void drawDprintBuffer() {
    drawText(_engineState.dprintBuffer.items, _engineState.dprintPosition, _engineState.dprintOptions);
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
            bk.textureCount,
            bk.fontCount - 1,
            bk.soundCount,
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
                bk.textureCount,
                bk.fontCount - 1,
                bk.soundCount,
                cast(int) mouse.x,
                cast(int) mouse.y,
            );
        } else {
            text = "FPS: {}\nAssets: (T{} F{} S{})\nMouse: ({} {})\nArea: A({} {}) B({} {}) S({} {})".fmt(
                fps,
                bk.textureCount,
                bk.fontCount - 1,
                bk.soundCount,
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

/// Plays the given sound. If the sound is already playing, this has no effect.
void playSound(SoundId sound) {
    bk.playSound(sound.data);
}

/// Stops playback of the given sound.
void stopSound(SoundId sound) {
    bk.stopSound(sound.data);
}

/// Starts playback of the given sound from the beginning.
void startSound(SoundId sound) {
    bk.startSound(sound.data);
}

/// Pauses playback of the given sound.
void pauseSound(SoundId sound) {
    bk.pauseSound(sound.data);
}

/// Resumes playback of the given sound if it was paused.
void resumeSound(SoundId sound) {
    bk.resumeSound(sound.data);
}

/// Toggles whether the sound is playing or stopped.
void toggleSoundIsActive(SoundId sound) {
    if (sound.isActive) stopSound(sound);
    else playSound(sound);
}

/// Toggles whether the sound is paused or resumed.
void toggleSoundIsPaused(SoundId sound) {
    if (sound.isPaused) resumeSound(sound);
    else pauseSound(sound);
}

/// Returns the current master volume level.
float masterVolume() {
    return bk.masterVolume;
}

/// Sets the master volume level.
void setMasterVolume(float value) {
    bk.setMasterVolume(value);
}
