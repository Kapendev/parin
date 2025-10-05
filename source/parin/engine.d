// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

// TODO: Viewports and sounds use raylib types instead of the generic ones. Change that.
// TODO: Replace the `rl.` calls with `.bk` calls.
// TODO: Fix microui lol.
// NOTE: Search for: TODO: STOPPED HERE!!

/// The `engine` module functions as a lightweight 2D game engine.
module parin.engine;

import bk = parin.backend;
import rl = parin.bindings.rl;
version (WebAssembly) {
    import em = parin.bindings.em;
}

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
enum defaultEngineWindowMinWidth  = 240;
enum defaultEngineWindowMinHeight = 135;
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
enum defaultEngineTexturesCapacity       = 128;
enum defaultEngineSoundsCapacity         = 128;
enum defaultEngineFontsCapacity          = 16;
enum defaultEngineEnvArgsCapacity        = 64;
enum defaultEngineLoadOrSaveTextCapacity = 14 * kilobyte;
enum defaultEngineTasksCapacity          = 127;
enum defaultEngineArenaCapacity          = 4 * megabyte;

enum defaultEngineDprintCapacity       = 8 * kilobyte;
enum defaultEngineDprintPosition       = Vec2(8, 6);
enum defaultEngineDprintLineCountLimit = 14;

enum defaultEngineDebugColor1 = white.alpha(120);
enum defaultEngineDebugColor2 = black.alpha(180);
// ----------

/// The default engine font.
enum engineFont = FontId(GenIndex(1), 0, defaultEngineFontRuneHeight);

alias EngineUpdateFunc = bool function(float dt);
alias EngineFunc       = void function();
alias EngineFlags      = uint;

@trusted:

alias D_ = DrawOptions; /// Shorthand for `DrawOptions`.
alias T_ = TextOptions; /// Shorthand for `TextOptions`.
alias C_ = Camera;      /// Shorthand for `Camera`.
alias V_ = Viewport;    /// Shorthand for `Viewport`.

enum EngineFlag : EngineFlags {
    none                        = 0x000000,
    isUpdating                  = 0x000001,
    isUsingAssetsPath           = 0x000002,
    isPixelSnapped              = 0x000004,
    isPixelPerfect              = 0x000008,
    isFullscreen                = 0x000010,
    isCursorVisible             = 0x000020,
    isEmptyTextureVisible       = 0x000040,
    isEmptyFontVisible          = 0x000080,
    isLoggingLoadOrSaveFaults   = 0x000100,
    isLoggingMemoryTrackingInfo = 0x000200,
    isDebugMode                 = 0x000400,
}

/// A texture identifier.
struct TextureId {
    alias Self = TextureId;

    ResourceId data;

    pragma(inline, true) @trusted nothrow @nogc:

    /// Checks if the texture is null (default value).
    bool isNull() {
        return bk.resourceIsNull(data);
    }

    /// Checks if the texture is valid (loaded). Null is invalid.
    bool isValid() {
        return bk.textureIsValid(data);
    }

    /// Checks if the texture is valid (loaded) and asserts if it is not.
    Self validate(IStr message = defaultEngineValidateErrorMessage) {
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
    }
}

/// A font identifier.
struct FontId {
    alias Self = FontId;

    ResourceId data;
    int runeSpacing; /// The spacing between individual characters.
    int lineSpacing; /// The spacing between lines of text.

    pragma(inline, true) @trusted nothrow @nogc:

    /// Checks if the font is null (default value).
    bool isNull() {
        return bk.resourceIsNull(data);
    }

    /// Checks if the font is valid (loaded). Null is invalid.
    bool isValid() {
        return bk.fontIsValid(data);
    }

    /// Checks if the font is valid (loaded) and asserts if it is not.
    Self validate(IStr message = defaultEngineValidateErrorMessage) {
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

    GlyphInfo glyphInfo(int rune) {
        return bk.fontGlyphInfo(data, rune);
    }

    /// Frees the loaded font.
    void free() {
        bk.fontFree(data);
    }
}

/// A sound resource.
struct Sound {
    Union!(rl.Sound, rl.Music) data;
    float pitch = 1.0f;
    float pitchVariance = 1.0f; // A value of 1.0 means no variation.
    float pitchVarianceBase = 1.0f;
    bool canRepeat;
    bool isActive;
    bool isPaused;

    @trusted nothrow @nogc:

    deprecated("Will be replaced with canRepeat.")
    alias isLooping = canRepeat;
    deprecated("Will be replaced with a variable called isActive. Remove `()` when using this name.")
    bool isPlaying() { return this.isActive; }

    /// Checks if the sound is not loaded.
    bool isEmpty() {
        if (data.isType!(rl.Sound)) {
            return data.as!(rl.Sound)().stream.sampleRate == 0;
        } else {
            return data.as!(rl.Music)().stream.sampleRate == 0;
        }
    }

    /// Returns the current playback time of the sound.
    float time() {
        if (data.isType!(rl.Sound)) {
            return 0.0f;
        } else {
            return rl.GetMusicTimePlayed(data.as!(rl.Music)());
        }
    }

    /// Returns the total duration of the sound.
    float duration() {
        if (data.isType!(rl.Sound)) {
            return 0.0f;
        } else {
            return rl.GetMusicTimeLength(data.as!(rl.Music)());
        }
    }

    /// Returns the progress of the sound.
    float progress() {
        if (duration == 0.0f) return 0.0f;
        return time / duration;
    }

    /// Sets the volume level for the sound. One is the default value.
    void setVolume(float value) {
        if (data.isType!(rl.Sound)) {
            rl.SetSoundVolume(data.as!(rl.Sound)(), value);
        } else {
            rl.SetMusicVolume(data.as!(rl.Music)(), value);
        }
    }

    /// Sets the pitch of the sound. One is the default value.
    void setPitch(float value, bool canUpdatePitchVarianceBase = false) {
        pitch = value;
        if (canUpdatePitchVarianceBase) pitchVarianceBase = value;
        if (data.isType!(rl.Sound)) {
            rl.SetSoundPitch(data.as!(rl.Sound)(), value);
        } else {
            rl.SetMusicPitch(data.as!(rl.Music)(), value);
        }
    }

    /// Sets the stereo panning of the sound. One is the default value.
    void setPan(float value) {
        if (data.isType!(rl.Sound)) {
            rl.SetSoundPan(data.as!(rl.Sound)(), value);
        } else {
            rl.SetMusicPan(data.as!(rl.Music)(), value);
        }
    }

    /// Frees the loaded sound.
    void free() {
        if (isEmpty) return;
        if (data.isType!(rl.Sound)) {
            rl.UnloadSound(data.as!(rl.Sound)());
        } else {
            rl.UnloadMusicStream(data.as!(rl.Music)());
        }
        this = Sound();
    }
}

/// An identifier for a managed engine resource. Managed resources can be safely shared throughout the code.
/// To free these resources, use the `freeManagedEngineResources` function or the `free` method on the identifier.
/// The identifier is automatically invalidated when the resource is freed.
struct SoundId {
    GenIndex data;

    @trusted nothrow @nogc:

    deprecated("Will be replaced with canRepeat.")
    alias isLooping = canRepeat;
    deprecated("Will be replaced with setCanRepeat.")
    alias setIsLooping = setCanRepeat;
    deprecated("Will be replaced with isActive.")
    bool isPlaying() { return isActive; }

    /// Returns the pitch variance of the sound associated with the resource identifier.
    float pitchVariance() {
        return getOr().pitchVariance;
    }

    /// Sets the pitch variance for the sound associated with the resource identifier. One is the default value.
    void setPitchVariance(float value) {
        getOr().pitchVariance = value;
    }

    /// Returns the pitch variance base of the sound associated with the resource identifier.
    float pitchVarianceBase() {
        return getOr().pitchVarianceBase;
    }

    /// Sets the pitch variance base for the sound associated with the resource identifier. One is the default value.
    void setPitchVarianceBase(float value) {
        getOr().pitchVarianceBase = value;
    }

    /// Returns true if the sound associated with the resource identifier can repeat.
    bool canRepeat() {
        return getOr().canRepeat;
    }

    /// Returns true if the sound associated with the resource identifier is playing.
    bool isActive() {
        return getOr().isActive;
    }

    /// Returns true if the sound associated with the resource identifier is paused.
    bool isPaused() {
        return getOr().isPaused;
    }

    /// Returns the current playback time of the sound associated with the resource identifier.
    float time() {
        return getOr().time;
    }

    /// Returns the total duration of the sound associated with the resource identifier.
    float duration() {
        return getOr().duration;
    }

    /// Returns the progress of the sound associated with the resource identifier.
    float progress() {
        return getOr().progress;
    }

    /// Sets the volume level for the sound associated with the resource identifier. One is the default value.
    void setVolume(float value) {
        getOr().setVolume(value);
    }

    /// Sets the pitch for the sound associated with the resource identifier. One is the default value.
    void setPitch(float value, bool canUpdateBuffer = false) {
        getOr().setPitch(value, canUpdateBuffer);
    }

    /// Sets the stereo panning for the sound associated with the resource identifier. One is the default value.
    void setPan(float value) {
        getOr().setPan(value);
    }

    /// Sets the repeat mode for the sound associated with the resource identifier.
    void setCanRepeat(bool value) {
        if (isValid) get().canRepeat = value;
    }

    /// Checks if the resource identifier is valid. It becomes automatically invalid when the resource is freed.
    bool isValid() {
        return data.value && _engineState.sounds.has(GenIndex(data.value - 1, data.generation));
    }

    /// Checks if the resource identifier is valid and asserts if it is not.
    SoundId validate(IStr message = defaultEngineValidateErrorMessage) {
        if (!isValid) assert(0, message);
        return this;
    }

    /// Retrieves the sound associated with the resource identifier.
    ref Sound get() {
        if (!isValid) assert(0, defaultEngineValidateErrorMessage);
        return _engineState.sounds[GenIndex(data.value - 1, data.generation)];
    }

    /// Retrieves the sound associated with the resource identifier or returns a default value if invalid.
    Sound getOr() {
        return isValid ? _engineState.sounds[GenIndex(data.value - 1, data.generation)] : Sound();
    }

    /// Frees the resource associated with the identifier.
    void free() {
        if (isValid) _engineState.sounds.remove(GenIndex(data.value - 1, data.generation));
    }
}

/// A viewing area for rendering.
struct Viewport {
    rl.RenderTexture2D data;
    Rgba color;      /// The background color of the viewport.
    Blend blend;     /// A value representing blending modes.
    bool isAttached; /// Indicates whether the viewport is currently in use.

    @trusted nothrow @nogc:

    /// Initializes the viewport with the given size, background color and blend mode.
    this(Rgba color, Blend blend = Blend.alpha) {
        this.color = color;
        this.blend = blend;
    }

    /// Checks if the viewport is not loaded.
    bool isEmpty() {
        return data.texture.id <= 0;
    }

    /// Returns the width of the viewport.
    int width() {
        return data.texture.width;
    }

    /// Returns the height of the viewport.
    int height() {
        return data.texture.height;
    }

    /// Returns the size of the viewport.
    Vec2 size() {
        return Vec2(width, height);
    }

    /// Resizes the viewport to the given width and height.
    /// Internally, this allocates a new render texture, so avoid calling it while the viewport is in use.
    void resize(int newWidth, int newHeight) {
        if (width == newWidth && height == newHeight) return;
        if (!isEmpty) rl.UnloadRenderTexture(data);
        if (newWidth <= 0 || newHeight <= 0) {
            data = rl.RenderTexture2D();
            return;
        }
        data = rl.LoadRenderTexture(newWidth, newHeight);
        setFilter(_engineState.defaultFilter);
        setWrap(_engineState.defaultWrap);
    }

    /// Attaches the viewport, making it active.
    // NOTE: The engine viewport should not use this function.
    void attach() {
        if (isEmpty) return;
        if (_engineState.userViewport.isAttached) {
            assert(0, "Cannot attach viewport because another viewport is already attached.");
        }
        isAttached = true;
        _engineState.userViewport = this;
        if (isResolutionLocked) rl.EndTextureMode();
        rl.BeginTextureMode(data);
        rl.ClearBackground(color.toRl());
        bk.beginBlend(blend);
    }

    /// Detaches the viewport, making it inactive.
    // NOTE: The engine viewport should not use this function.
    void detach() {
        if (isEmpty) return;
        if (!isAttached) {
            assert(0, "Cannot detach viewport because it is not the attached viewport.");
        }
        isAttached = false;
        _engineState.userViewport = Viewport();
        bk.endBlend();
        rl.EndTextureMode();
        if (isResolutionLocked) rl.BeginTextureMode(_engineState.viewport.data.toRl());
    }

    /// Sets the filter mode of the viewport.
    void setFilter(Filter value) {
        if (isEmpty) return;
        rl.SetTextureFilter(data.texture, bk.toRl(value)); // TODO: REMOVE THE & BECAUSE VOID& HANDELE
    }

    /// Sets the wrap mode of the viewport.
    void setWrap(Wrap value) {
        if (isEmpty) return;
        rl.SetTextureWrap(data.texture, bk.toRl(value)); // TODO: REMOVE THE & BECAUSE VOID& HANDELE
    }

    /// Frees the loaded viewport.
    void free() {
        if (isEmpty) return;
        rl.UnloadRenderTexture(data);
        this = Viewport();
    }
}

/// Attaches the camera, making it active.
void attach(ref Camera camera, Rounding type = Rounding.none) {
    if (_engineState.userCamera.isAttached) assert(0, "Cannot attach camera because another camera is already attached.");
    bk.cameraAttach(camera, resolution, isPixelSnapped ? Rounding.floor : type);
    _engineState.userCamera = camera;
}

/// Detaches the camera, making it inactive.
void detach(ref Camera camera) {
    if (!camera.isAttached) assert(0, "Cannot detach camera because it is not the attached camera.");
    bk.cameraDetach(camera);
    _engineState.userCamera = Camera();
}

/// Represents a scheduled task with interval, repeat count, and callback function.
struct Task {
    float interval = 0.0f;  /// The interval of the task, in seconds.
    float time = 0.0f;      /// The current time of the task.
    EngineUpdateFunc func;  /// The callback function of the task.
    byte count;             /// Number of times the task will run, with -1 indicating it runs forever.

    @trusted:

    /// Updates the task, similar to the main update function.
    bool update(float dt) {
        if (count == 0) return true;
        time += dt;
        if (time >= interval) {
            auto status = func(interval);
            time -= interval;
            if (count > 0) {
                count -= 1;
                if (count == 0) return true;
            }
            if (status) return true;
        }
        return false;
    }
}

/// A container holding scheduled tasks.
alias Tasks = SparseList!(Task, FixedList!(SparseListItem!Task, defaultEngineTasksCapacity));
/// An identifier for a scheduled task.
alias TaskId = uint;

/// Information about the engine viewport, including its area.
struct EngineViewportInfo {
    Rect area;             /// The area covered by the viewport.
    Vec2 minSize;          /// The minimum size that the viewport can be.
    Vec2 maxSize;          /// The maximum size that the viewport can be.
    float minRatio = 0.0f; /// The minimum ratio between minSize and maxSize.
}

/// The engine viewport.
struct EngineViewport {
    Viewport data;   /// The viewport data.
    int lockWidth;   /// The target lock width.
    int lockHeight;  /// The target lock height.
    bool isChanging; /// The flag that triggers the new lock state.
    bool isLocking;  /// The flag that tells what the new lock state is.

    @trusted nothrow @nogc:

    /// Frees the loaded viewport.
    void free() {
        lockWidth = 0;
        lockHeight = 0;
        isChanging = false;
        isLocking = false;
        data.free();
    }
}

/// The engine fullscreen state.
struct EngineFullscreenState {
    int previousWindowWidth;  /// The previous window with before entering fullscreen mode.
    int previousWindowHeight; /// The previous window height before entering fullscreen mode.
    float changeTime = 0.0f;  /// The current change time.
    bool isChanging;          /// The flag that triggers the fullscreen state.

    enum changeDuration = 0.03f;
}

/// The engine state.
struct EngineState {
    EngineFlags flags = defaultEngineFlags;
    EngineUpdateFunc updateFunc;
    EngineFunc debugModeFunc;
    EngineFunc debugModeBeginFunc;
    EngineFunc debugModeEndFunc;
    Keyboard debugModeKey = defaultEngineDebugModeKey;

    EngineFullscreenState fullscreenState;
    EngineViewportInfo viewportInfoBuffer;
    Vec2 mouseBuffer;
    Vec2 wasdBuffer;
    Vec2 wasdPressedBuffer;
    Vec2 wasdReleasedBuffer;

    int fpsMax = defaultEngineFpsMax;
    bool vsync = defaultEngineVsync;
    Sz tickCount;
    Rgba borderColor = black;
    Filter defaultFilter;
    Wrap defaultWrap;
    FontId defaultFont = engineFont;
    TextureId defaultTexture;
    Camera userCamera;
    Viewport userViewport;
    Fault lastLoadOrSaveFault;
    IStr memoryTrackingInfoFilter;
    FStr!defaultEngineAssetsPathCapacity assetsPath;
    FixedList!(IStr, defaultEngineEnvArgsCapacity) envArgsBuffer;
    Tasks tasks;

    FStr!defaultEngineDprintCapacity dprintBuffer;
    Vec2 dprintPosition = defaultEngineDprintPosition;
    DrawOptions dprintOptions;
    Sz dprintLineCount;
    Sz dprintLineCountLimit = defaultEngineDprintLineCountLimit;
    bool dprintIsVisible = true;

    EngineViewport viewport;
    GenList!Sound sounds;
    GrowingArena arena;
}

/// Opens a window with the specified size and title.
/// You should avoid calling this function manually.
void _openWindow(int width, int height, const(IStr)[] args, IStr title = "Parin") {
    enum monogramPath = "parin_monogram.png";
    enum targetHtmlElementId = "canvas";

    bk.readyBackend(width, height, title, defaultEngineVsync, defaultEngineFpsMax, defaultEngineWindowMinWidth, defaultEngineWindowMinHeight);
    _engineState = jokaMake!EngineState();
    _engineState.fullscreenState.previousWindowWidth = width;
    _engineState.fullscreenState.previousWindowHeight = height;
    _engineState.viewport.data.color = gray;
    _engineState.sounds.reserve(defaultEngineSoundsCapacity);
    _engineState.arena.ready(defaultEngineArenaCapacity);
    // TODO: will have to remove the id thing and also change the toTexure names to load maybe.
    loadTexture(cast(const(ubyte)[]) import(monogramPath)).loadFont(defaultEngineFontRuneWidth, defaultEngineFontRuneHeight);
    if (args.length) {
        foreach (arg; args) _engineState.envArgsBuffer.append(arg);
        _engineState.assetsPath.append(pathConcat(args[0].pathDirName, "assets"));
    }

    version (WebAssembly) {
        em.emscripten_set_mousemove_callback_on_thread(targetHtmlElementId, null, true, &_engineMouseCallbackWeb);
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
    { // Update buffers and resources.
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
        _engineMouseCallback();
        _engineWasdCallback();
        foreach (ref sound; _engineState.sounds.items) {
            updateSound(sound);
        }
    }

    // Get some data before doing the game loop.
    auto loopVsync = vsync;
    // Begin drawing.
    if (isResolutionLocked) {
        rl.BeginTextureMode(_engineState.viewport.data.toRl());
    } else {
        rl.BeginDrawing();
    }
    rl.ClearBackground(_engineState.viewport.data.color.toRl());

    // Update the game.
    bk.beginDroppedPaths();
    _engineState.arena.clear();
    auto dt = deltaTime;
    foreach (id; _engineState.tasks.ids) {
        if (_engineState.tasks[id].update(dt)) _engineState.tasks.remove(id);
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
    _engineState.tickCount += 1;
    bk.endDroppedPaths();

    // End drawing.
    if (isResolutionLocked) {
        auto info = engineViewportInfo;
        rl.EndTextureMode();
        rl.BeginDrawing();
        rl.ClearBackground(_engineState.borderColor.toRl());
        rl.DrawTexturePro(
            _engineState.viewport.data.toRl().texture,
            rl.Rectangle(0.0f, 0.0f, info.minSize.x, -info.minSize.y),
            info.area.toRl(),
            rl.Vector2(0.0f, 0.0f),
            0.0f,
            rl.Color(255, 255, 255, 255),
        );
        rl.EndDrawing();
    } else {
        rl.EndDrawing();
    }

    // NOTE: Could copy this style for viewport and fullscreen. They do have other problems though.
    // VSync code.
    if (_engineState.vsync != loopVsync) bk.setVsync(_engineState.vsync);
    // Viewport code.
    if (_engineState.viewport.isChanging) {
        if (_engineState.viewport.isLocking) {
            _engineState.viewport.data.resize(_engineState.viewport.lockWidth, _engineState.viewport.lockHeight);
        } else {
            auto temp = _engineState.viewport.data.color;
            _engineState.viewport.data.free();
            _engineState.viewport.data.color = temp;
        }
        _engineState.viewport.isChanging = false;
    }
    // Fullscreen code.
    if (_engineState.fullscreenState.isChanging) {
        _engineState.fullscreenState.changeTime += dt;
        if (_engineState.fullscreenState.changeTime >= _engineState.fullscreenState.changeDuration) {
            if (rl.IsWindowFullscreen()) {
                rl.ToggleFullscreen();
                // Size is first because raylib likes that. I will make raylib happy.
                rl.SetWindowSize(
                    _engineState.fullscreenState.previousWindowWidth,
                    _engineState.fullscreenState.previousWindowHeight,
                );
                rl.SetWindowPosition(
                    cast(int) (screenWidth * 0.5f - _engineState.fullscreenState.previousWindowWidth * 0.5f),
                    cast(int) (screenHeight * 0.5f - _engineState.fullscreenState.previousWindowHeight * 0.5f),
                );
            } else {
                rl.ToggleFullscreen();
            }
            _engineState.fullscreenState.isChanging = false;
        }
    }
    return result;
}

version (WebAssembly) {
    /// Use by the `updateWindow` function.
    /// You should avoid calling this function manually.
    void _updateWindowLoopWeb() {
        if (_updateWindowLoop()) em.emscripten_cancel_main_loop();
    }
}

/// Updates the window every frame with the given function.
/// This function will return when the given function returns true.
/// You should avoid calling this function manually.
void _updateWindow(EngineUpdateFunc updateFunc, EngineFunc debugModeFunc = null, EngineFunc debugModeBeginFunc = null, EngineFunc debugModeEndFunc = null) {
    _engineState.updateFunc = updateFunc;
    _engineState.debugModeFunc = debugModeFunc;
    _engineState.debugModeBeginFunc = debugModeBeginFunc;
    _engineState.debugModeEndFunc = debugModeEndFunc;

    _engineState.flags |= EngineFlag.isUpdating;
    version (WebAssembly) {
        em.emscripten_set_main_loop(&_updateWindowLoopWeb, 0, true);
    } else {
        while (true) if (rl.WindowShouldClose() || _updateWindowLoop()) break;
    }
    _engineState.flags &= ~EngineFlag.isUpdating;
}

/// Closes the window.
/// You should avoid calling this function manually.
void _closeWindow() {
    if (!rl.IsWindowReady()) return;
    // NOTE: I assume `filter` is a static string or managed by the user.
    auto filter = _engineState.memoryTrackingInfoFilter;
    auto isLogging = isLoggingMemoryTrackingInfo;

    _engineState.viewport.free();
    _engineState.sounds.freeWithItems();
    _engineState.arena.free();
    jokaFree(_engineState);
    _engineState = null;

    bk.freeBackend();
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
TaskId every(float interval, EngineUpdateFunc func, int count = -1, bool canCallNow = false) {
    _engineState.tasks.push(Task(interval, canCallNow ? interval : 0, func, cast(byte) count));
    return cast(TaskId) (_engineState.tasks.length - 1);
}

/// Cancel a scheduled task by its ID.
void cancel(TaskId id) {
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

/// Converts a sound into a managed engine resource.
/// The sound will be freed when the resource is freed.
// NOTE: We avoid passing sounds by value, but it's fine here because this function will not be called every frame.
SoundId toSoundId(Sound from) {
    if (from.isEmpty) return SoundId();
    auto id = SoundId(_engineState.sounds.push(from));
    id.data.value += 1;
    return id;
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
    auto data = bk.loadFont(toAssetsPath(path), size, runes).get(trap);
    if (didLoadOrSaveSucceed(trap, fmt(defaultEngineLoadErrorMessage, file, line, "font", path.toAssetsPath()))) {
        bk.fontSetFilter(data, _engineState.defaultFilter);
        bk.fontSetWrap(data, _engineState.defaultWrap);
        return FontId(data, runeSpacing >= 0 ? runeSpacing : 0, lineSpacing >= 0 ? lineSpacing : size);
    }
    return FontId();
}

/// Converts bytes into a font. Returns an empty font on error.
FontId loadFont(const(ubyte)[] memory, int size, int runeSpacing = -1, int lineSpacing = -1, IStr32 runes = "", IStr ext = ".ttf", IStr file = __FILE__, Sz line = __LINE__) {
    auto trap = Fault.none;
    auto data = bk.loadFont(memory, size, runes, ext).get(trap);
    if (didLoadOrSaveSucceed(trap, fmt(defaultEngineLoadErrorMessage, file, line, "font", "[MEMORY]"))) {
        bk.fontSetFilter(data, _engineState.defaultFilter);
        bk.fontSetWrap(data, _engineState.defaultWrap);
        return FontId(data, runeSpacing >= 0 ? runeSpacing : 0, lineSpacing >= 0 ? lineSpacing : size);
    }
    return FontId();
}

FontId loadFont(TextureId texture, int tileWidth, int tileHeight, IStr file = __FILE__, Sz line = __LINE__) {
    auto trap = Fault.none;
    auto data = bk.loadFont(texture.data, tileWidth, tileHeight).get(trap);
    if (didLoadOrSaveSucceed(trap, fmt(defaultEngineLoadErrorMessage, file, line, "font", "[TEXTURE]"))) {
        bk.fontSetFilter(data, _engineState.defaultFilter);
        bk.fontSetWrap(data, _engineState.defaultWrap);
        return FontId(data, 0, tileHeight);
    }
    return FontId();
}

/// Loads a sound file (WAV, OGG, MP3) from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Maybe!Sound loadRawSound(IStr path, float volume, float pitch, bool canRepeat = false, float pitchVariance = 1.0f, IStr file = __FILE__, Sz line = __LINE__) {
    auto value = Sound();
    if (path.endsWith(".wav")) {
        value.data = rl.LoadSound(path.toAssetsPath().toCStr().getOr());
    } else {
        value.data = rl.LoadMusicStream(path.toAssetsPath().toCStr().getOr());
    }
    if (isLoggingLoadOrSaveFaults && value.isEmpty) printfln!(StdStream.error)(defaultEngineLoadErrorMessage, file, line, "sound", path.toAssetsPath());
    if (value.isEmpty) {
        return Maybe!Sound();
    } else {
        value.setVolume(volume);
        value.setPitch(pitch, true);
        value.canRepeat = canRepeat;
        value.pitchVariance = pitchVariance;
        return Maybe!Sound(value);
    }
}

/// Loads a sound file (WAV, OGG, MP3) from the assets folder.
/// The resource can be safely shared throughout the code and is automatically invalidated when the resource is freed.
/// Supports both forward slashes and backslashes in file paths.
SoundId loadSound(IStr path, float volume, float pitch, bool canRepeat = false, float pitchVariance = 1.0f, IStr file = __FILE__, Sz line = __LINE__) {
    return loadRawSound(path, volume, pitch, canRepeat, pitchVariance, file, line).get(_engineState.lastLoadOrSaveFault).toSoundId();
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

bool didLoadOrSaveSucceed(Fault fault, IStr message) {
    if (fault) {
        _engineState.lastLoadOrSaveFault = fault;
        if (isLoggingLoadOrSaveFaults) println!(StdStream.error)(message);
        return false;
    }
    return true;
}

// NOTE: Internal stuff that you should not really use outside of `engine.d`.
pragma(inline, true) {
    Rgba toPr(rl.Color from) {
        return Rgba(from.r, from.g, from.b, from.a);
    }

    Vec2 toPr(rl.Vector2 from) {
        return Vec2(from.x, from.y);
    }

    Vec3 toPr(rl.Vector3 from) {
        return Vec3(from.x, from.y, from.z);
    }

    Vec4 toPr(rl.Vector4 from) {
        return Vec4(from.x, from.y, from.z, from.w);
    }

    Rect toPr(rl.Rectangle from) {
        return Rect(from.x, from.y, from.width, from.height);
    }

    // --- copy pasted to bk.
        rl.Color toRl(Rgba from) {
            return rl.Color(from.r, from.g, from.b, from.a);
        }

        rl.Vector2 toRl(Vec2 from) {
            return rl.Vector2(from.x, from.y);
        }

        rl.Vector3 toRl(Vec3 from) {
            return rl.Vector3(from.x, from.y, from.z);
        }

        rl.Vector4 toRl(Vec4 from) {
            return rl.Vector4(from.x, from.y, from.z, from.w);
        }

        rl.Rectangle toRl(Rect from) {
            return rl.Rectangle(from.position.x, from.position.y, from.size.x, from.size.y);
        }
    // ---

    rl.RenderTexture2D toRl(ref Viewport from) {
        return from.data;
    }

    rl.Camera2D toRl(Camera from) {
        return rl.Camera2D(
            Rect(resolution).origin(from.isCentered ? Hook.center : Hook.topLeft).toRl(),
            (from.position + from.offset).toRl(),
            from.rotation,
            from.scale,
        );
    }

    rl.Camera2D toRl(Camera from, ref Viewport viewport) {
        return rl.Camera2D(
            Rect(viewport.isEmpty ? resolution : viewport.size).origin(from.isCentered ? Hook.center : Hook.topLeft).toRl(),
            (from.position + from.offset).toRl(),
            from.rotation,
            from.scale,
        );
    }
}

void _setEngineMouseBuffer(Vec2 value) {
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

void _engineMouseCallback() {
    version (WebAssembly) {
        // Emscripten will do it for us. Check the `_engineMouseCallbackWeb` function.
    } else {
        _setEngineMouseBuffer(rl.GetTouchPosition(0).toPr());
    }
}

version (WebAssembly) {
    /// Use by Emscripten to update the mouse.
    /// You should avoid calling this function manually.
    nothrow @nogc extern(C):
    bool _engineMouseCallbackWeb(int eventType, const(em.EmscriptenMouseEvent)* mouseEvent, void* userData) {
        switch (eventType) {
            case em.EMSCRIPTEN_EVENT_MOUSEMOVE:
                _setEngineMouseBuffer(Vec2(mouseEvent.clientX, mouseEvent.clientY));
                return true;
            default:
                return false;
        }
    }
}

void _engineWasdCallback() {
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

/// Returns the opposite flip value.
/// The opposite of every flip value except none is none.
/// The fallback value is returned if the flip value is none.
Flip oppositeFlip(Flip flip, Flip fallback) {
    return flip == fallback ? Flip.none : fallback;
}

/// Computes the parts of a 9-slice.
SliceParts computeSliceParts(IRect source, IRect target, Margin margin) {
    SliceParts result;
    if (!source.hasSize || !target.hasSize) return result;
    auto canClipW = target.w - source.w < -margin.left - margin.right;
    auto canClipH = target.h - source.h < -margin.top - margin.bottom;

    // -- 1
    result[0].source.x  = source.x;                                              result[0].source.y = source.y;
    result[0].source.w  = margin.left;                                           result[0].source.h = margin.top;
    result[0].target.x  = target.x;                                              result[0].target.y = target.y;
    result[0].target.w  = margin.left;                                           result[0].target.h = margin.top;
    result[0].isCorner = true;

    result[1].source.x  = source.x + result[0].source.w;                         result[1].source.y = result[0].source.y;
    result[1].source.w  = source.w - margin.left - margin.right;                 result[1].source.h = result[0].source.h;
    result[1].target.x  = target.x + margin.left;                                result[1].target.y = result[0].target.y;
    result[1].target.w  = target.w - margin.left - margin.right;                 result[1].target.h = result[0].target.h;
    result[1].canTile = true;

    result[2].source.x  = source.x + result[0].source.w + result[1].source.w;    result[2].source.y = result[0].source.y;
    result[2].source.w  = margin.right;                                          result[2].source.h = result[0].source.h;
    result[2].target.x  = target.x + target.w - margin.right;                    result[2].target.y = result[0].target.y;
    result[2].target.w  = margin.right;                                          result[2].target.h = result[0].target.h;
    result[2].isCorner = true;

    // -- 2
    result[3].source.x  = result[0].source.x;                                    result[3].source.y = source.y + margin.top;
    result[3].source.w  = result[0].source.w;                                    result[3].source.h = source.h - margin.top - margin.bottom;
    result[3].target.x  = result[0].target.x;                                    result[3].target.y = target.y + margin.top;
    result[3].target.w  = result[0].target.w;                                    result[3].target.h = target.h - margin.top - margin.bottom;
    result[3].canTile = true;

    result[4].source.x  = result[1].source.x;                                    result[4].source.y = result[3].source.y;
    result[4].source.w  = result[1].source.w;                                    result[4].source.h = result[3].source.h;
    result[4].target.x  = result[1].target.x;                                    result[4].target.y = result[3].target.y;
    result[4].target.w  = result[1].target.w;                                    result[4].target.h = result[3].target.h;
    result[4].canTile = true;

    result[5].source.x  = result[2].source.x;                                    result[5].source.y = result[3].source.y;
    result[5].source.w  = result[2].source.w;                                    result[5].source.h = result[3].source.h;
    result[5].target.x  = result[2].target.x;                                    result[5].target.y = result[3].target.y;
    result[5].target.w  = result[2].target.w;                                    result[5].target.h = result[3].target.h;
    result[5].canTile = true;

    // -- 3
    result[6].source.x  = result[0].source.x;                                    result[6].source.y = source.y + margin.top + result[3].source.h;
    result[6].source.w  = result[0].source.w;                                    result[6].source.h = margin.bottom;
    result[6].target.x  = result[0].target.x;                                    result[6].target.y = target.y + margin.top + result[3].target.h;
    result[6].target.w  = result[0].target.w;                                    result[6].target.h = margin.bottom;
    result[6].isCorner = true;

    result[7].source.x  = result[1].source.x;                                    result[7].source.y = result[6].source.y;
    result[7].source.w  = result[1].source.w;                                    result[7].source.h = result[6].source.h;
    result[7].target.x  = result[1].target.x;                                    result[7].target.y = result[6].target.y;
    result[7].target.w  = result[1].target.w;                                    result[7].target.h = result[6].target.h;
    result[7].canTile = true;

    result[8].source.x  = result[2].source.x;                                    result[8].source.y = result[6].source.y;
    result[8].source.w  = result[2].source.w;                                    result[8].source.h = result[6].source.h;
    result[8].target.x  = result[2].target.x;                                    result[8].target.y = result[6].target.y;
    result[8].target.w  = result[2].target.w;                                    result[8].target.h = result[6].target.h;
    result[8].isCorner = true;

    if (canClipW) {
        foreach (ref item; result) {
            item.target.x = target.x;
            item.target.w = target.w;
        }
    }
    if (canClipH) {
        foreach (ref item; result) {
            item.target.y = target.y;
            item.target.h = target.h;
        }
    }
    result[1].tileCount.x = result[1].source.w ? result[1].target.w / result[1].source.w + 1 : 0;
    result[1].tileCount.y = result[1].source.h ? result[1].target.h / result[1].source.h + 1 : 0;
    result[3].tileCount.x = result[3].source.w ? result[3].target.w / result[3].source.w + 1 : 0;
    result[3].tileCount.y = result[3].source.h ? result[3].target.h / result[3].source.h + 1 : 0;
    result[4].tileCount.x = result[4].source.w ? result[4].target.w / result[4].source.w + 1 : 0;
    result[4].tileCount.y = result[4].source.h ? result[4].target.h / result[4].source.h + 1 : 0;
    result[5].tileCount.x = result[5].source.w ? result[5].target.w / result[5].source.w + 1 : 0;
    result[5].tileCount.y = result[5].source.h ? result[5].target.h / result[5].source.h + 1 : 0;
    result[7].tileCount.x = result[7].source.w ? result[7].target.w / result[7].source.w + 1 : 0;
    result[7].tileCount.y = result[7].source.h ? result[7].target.h / result[7].source.h + 1 : 0;
    return result;
}

/// Returns the arguments that this application was started with.
IStr[] envArgs() {
    return _engineState.envArgsBuffer.items;
}

/// Returns a random integer between 0 and int.max (inclusive).
int randi() {
    return rl.GetRandomValue(0, int.max);
}

/// Returns a random floating point number between 0.0 and 1.0 (inclusive).
float randf() {
    return rl.GetRandomValue(0, cast(int) float.max) / cast(float) cast(int) float.max;
}

/// Sets the seed of the random number generator to the given value.
void setRandomSeed(int value) {
    rl.SetRandomSeed(value);
}

/// Randomizes the seed of the random number generator.
void randomize() {
    setRandomSeed(randi);
}

/// Converts a world point to a screen point based on the given camera.
Vec2 toScreenPoint(Vec2 position, Camera camera) {
    return toPr(rl.GetWorldToScreen2D(position.toRl(), camera.toRl()));
}

/// Converts a world point to a screen point based on the given camera.
Vec2 toScreenPoint(Vec2 position, Camera camera, ref Viewport viewport) {
    return toPr(rl.GetWorldToScreen2D(position.toRl(), camera.toRl(viewport)));
}

/// Converts a screen point to a world point based on the given camera.
Vec2 toWorldPoint(Vec2 position, Camera camera) {
    return toPr(rl.GetScreenToWorld2D(position.toRl(), camera.toRl()));
}

/// Converts a screen point to a world point based on the given camera.
Vec2 toWorldPoint(Vec2 position, Camera camera, ref Viewport viewport) {
    return toPr(rl.GetScreenToWorld2D(position.toRl(), camera.toRl(viewport)));
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

/// Frees all managed engine resources.
void freeManagedEngineResources() {
    bk.freeAllTextures();
    foreach (ref item; _engineState.sounds.items) item.free();
    _engineState.sounds.clear();
}

deprecated("Was too generic. Use `freeManagedEngineResources` now.")
alias freeEngineResources = freeManagedEngineResources;

/// Opens a URL in the default web browser (if available).
/// Redirect to Parin's GitHub when no URL is provided.
void openUrl(IStr url = "https://github.com/Kapendev/parin") {
    rl.OpenURL(url.toCStr().getOr());
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
    return cast(bool) (_engineState.flags & EngineFlag.isFullscreen);
}

/// Sets whether the application should be in fullscreen mode.
// NOTE: This function introduces a slight delay to prevent some bugs observed on Linux. See the `updateWindow` function.
void setIsFullscreen(bool value) {
    version (WebAssembly) {
    } else {
        if (value == isFullscreen || _engineState.fullscreenState.isChanging) return;
        _engineState.flags = value
            ? _engineState.flags | EngineFlag.isFullscreen
            : _engineState.flags & ~EngineFlag.isFullscreen;
        if (value) {
            _engineState.fullscreenState.previousWindowWidth = rl.GetScreenWidth();
            _engineState.fullscreenState.previousWindowHeight = rl.GetScreenHeight();
            rl.SetWindowPosition(0, 0);
            rl.SetWindowSize(screenWidth, screenHeight);
        }
        _engineState.fullscreenState.changeTime = 0.0f;
        _engineState.fullscreenState.isChanging = true;
    }
}

/// Toggles the fullscreen mode on or off.
void toggleIsFullscreen() {
    setIsFullscreen(!isFullscreen);
}

/// Returns true if the cursor is currently visible.
bool isCursorVisible() {
    return cast(bool) (_engineState.flags & EngineFlag.isCursorVisible);
}

/// Sets whether the cursor should be visible or hidden.
void setIsCursorVisible(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isCursorVisible
        : _engineState.flags & ~EngineFlag.isCursorVisible;
    if (value) rl.ShowCursor();
    else rl.HideCursor();
}

/// Toggles the visibility of the cursor.
void toggleIsCursorVisible() {
    setIsCursorVisible(!isCursorVisible);
}

/// Returns true if the windows was resized.
bool isWindowResized() {
    return rl.IsWindowResized();
}

/// Sets the background color to the specified value.
void setBackgroundColor(Rgba value) {
    _engineState.viewport.data.color = value;
}

/// Sets the border color to the specified value.
void setBorderColor(Rgba value) {
    _engineState.borderColor = value;
}

/// Sets the minimum size of the window to the specified value.
void setWindowMinSize(int width, int height) {
    rl.SetWindowMinSize(width, height);
}

/// Sets the maximum size of the window to the specified value.
void setWindowMaxSize(int width, int height) {
    rl.SetWindowMaxSize(width, height);
}

/// Sets the window icon to the specified image that will be loaded from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Fault setWindowIconFromFiles(IStr path) {
    auto image = rl.LoadImage(path.toAssetsPath().toCStr().getOr());
    if (image.data == null) return Fault.cantFind;
    rl.SetWindowIcon(image);
    rl.UnloadImage(image);
    return Fault.none;
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
    return rl.GetMasterVolume();
}

/// Sets the master volume level to the specified value.
void setMasterVolume(float value) {
    rl.SetMasterVolume(value);
}

/// Returns true if the resolution is locked and cannot be changed.
bool isResolutionLocked() {
    return !_engineState.viewport.data.isEmpty;
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
        auto temp = _engineState.viewport.data.color;
        _engineState.viewport.data.free();
        _engineState.viewport.data.color = temp;
    }
}

/// Toggles between the current resolution and the specified width and height.
void toggleResolution(int width, int height) {
    if (isResolutionLocked) unlockResolution();
    else lockResolution(width, height);
}

/// Returns the current screen width.
int screenWidth() {
    return rl.GetMonitorWidth(rl.GetCurrentMonitor());
}

/// Returns the current screen height.
int screenHeight() {
    return rl.GetMonitorHeight(rl.GetCurrentMonitor());
}

/// Returns the current screen size.
Vec2 screenSize() {
    return Vec2(screenWidth, screenHeight);
}

/// Returns the current window width.
int windowWidth() {
    if (isFullscreen) return screenWidth;
    else return rl.GetScreenWidth();
}

/// Returns the current window height.
int windowHeight() {
    if (isFullscreen) return screenHeight;
    else return rl.GetScreenHeight();
}

/// Returns the current window size.
Vec2 windowSize() {
    return Vec2(windowWidth, windowHeight);
}

/// Returns the current resolution width.
int resolutionWidth() {
    if (isResolutionLocked) return _engineState.viewport.data.width;
    else return windowWidth;
}

/// Returns the current resolution height.
int resolutionHeight() {
    if (isResolutionLocked) return _engineState.viewport.data.height;
    else return windowHeight;
}

/// Returns the current resolution size.
Vec2 resolution() {
    return Vec2(resolutionWidth, resolutionHeight);
}

/// Returns the vertical synchronization state (VSync).
bool vsync() {
    return _engineState.vsync;
}

/// Sets the vertical synchronization state (VSync).
void setVsync(bool value) {
    version (WebAssembly) {
    } else {
        _engineState.vsync = value;
        if (_engineState.flags & EngineFlag.isUpdating) {
        } else {
            // TODO: Check the comment in the window loop function.
            // gf.glfwSwapInterval(value);
        }
    }
}

/// Returns the current frames per second (FPS).
int fps() {
    return rl.GetFPS();
}

/// Returns the maximum frames per second (FPS).
int fpsMax() {
    return _engineState.fpsMax;
}

/// Sets the maximum number of frames that can be rendered every second (FPS).
void setFpsMax(int value) {
    _engineState.fpsMax = value > 0 ? value : 0;
    rl.SetTargetFPS(_engineState.fpsMax);
}

/// Returns the total elapsed time since the application started.
double elapsedTime() {
    return rl.GetTime();
}

/// Returns the total number of ticks elapsed since the application started.
long elapsedTickCount() {
    return _engineState.tickCount;
}

/// Returns the time elapsed since the last frame.
float deltaTime() {
    return rl.GetFrameTime();
}

/// Returns the current position of the mouse on the screen.
pragma(inline, true)
Vec2 mouse() {
    return _engineState.mouseBuffer;
}

/// Returns the change in mouse position since the last frame.
Vec2 deltaMouse() {
    return rl.GetMouseDelta().toPr();
}

/// Returns the change in mouse wheel position since the last frame.
// TODO: The value still depends on target. Fix that one day?
float deltaWheel() {
    float result = void;
    version (WebAssembly) {
        result = rl.GetMouseWheelMove();
    } else version (OSX) {
        result = rl.GetMouseWheelMove();
    } else {
        result = -rl.GetMouseWheelMove();
    }
    return result;
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
    auto result = cast(Keyboard) rl.GetKeyPressed();
    if (result.toStr() == "?") return Keyboard.none; // NOTE: Could maybe be better, but who cares.
    return result;
}

/// Returns the recently pressed character.
/// This function acts like a queue, meaning that multiple calls will return other recently pressed characters.
/// A none character is returned when the queue is empty.
dchar dequeuePressedRune() {
    return rl.GetCharPressed();
}

/// Returns the directional input based on the WASD and arrow keys when they are down.
/// The vector is not normalized.
pragma(inline, true)
Vec2 wasd() {
    return _engineState.wasdBuffer;
}

/// Returns the directional input based on the WASD and arrow keys when they are pressed.
/// The vector is not normalized.
pragma(inline, true)
Vec2 wasdPressed() {
    return _engineState.wasdPressedBuffer;
}

/// Returns the directional input based on the WASD and arrow keys when they are released.
/// The vector is not normalized.
pragma(inline, true)
Vec2 wasdReleased() {
    return _engineState.wasdReleasedBuffer;
}

/// Plays the specified sound.
void playSound(ref Sound sound) {
    if (sound.isEmpty || sound.isActive) return;
    sound.isActive = true;
    resumeSound(sound);
    if (sound.pitchVariance != 1.0f) {
        sound.setPitch(sound.pitchVarianceBase + (sound.pitchVarianceBase * sound.pitchVariance - sound.pitchVarianceBase) * randf);
    }
    if (sound.data.isType!(rl.Sound)) {
        rl.PlaySound(sound.data.as!(rl.Sound)());
    } else {
        rl.PlayMusicStream(sound.data.as!(rl.Music)());
    }
}

/// Plays the specified sound.
void playSound(SoundId sound) {
    if (sound.isValid) playSound(sound.get());
}

/// Stops playback of the specified sound.
void stopSound(ref Sound sound) {
    if (sound.isEmpty || !sound.isActive) return;
    sound.isActive = false;
    resumeSound(sound);
    if (sound.data.isType!(rl.Sound)) {
        rl.StopSound(sound.data.as!(rl.Sound)());
    } else {
        rl.StopMusicStream(sound.data.as!(rl.Music)());
    }
}

/// Stops playback of the specified sound.
void stopSound(SoundId sound) {
    if (sound.isValid) stopSound(sound.get());
}

/// Pauses playback of the specified sound.
void pauseSound(ref Sound sound) {
    if (sound.isEmpty || sound.isPaused) return;
    sound.isPaused = true;
    if (sound.data.isType!(rl.Sound)) {
        rl.PauseSound(sound.data.as!(rl.Sound)());
    } else {
        rl.PauseMusicStream(sound.data.as!(rl.Music)());
    }
}

/// Pauses playback of the specified sound.
void pauseSound(SoundId sound) {
    if (sound.isValid) pauseSound(sound.get());
}

/// Resumes playback of the specified paused sound.
void resumeSound(ref Sound sound) {
    if (sound.isEmpty || !sound.isPaused) return;
    sound.isPaused = false;
    if (sound.data.isType!(rl.Sound)) {
        rl.ResumeSound(sound.data.as!(rl.Sound)());
    } else {
        rl.ResumeMusicStream(sound.data.as!(rl.Music)());
    }
}

/// Resumes playback of the specified paused sound.
void resumeSound(SoundId sound) {
    if (sound.isValid) resumeSound(sound.get());
}

/// Resets and plays the specified sound.
void startSound(ref Sound sound) {
    stopSound(sound);
    playSound(sound);
}

/// Resets and plays the specified sound.
void startSound(SoundId sound) {
    if (sound.isValid) startSound(sound.get());
}

/// Toggles the active state of the sound.
void toggleSoundIsActive(ref Sound sound) {
    if (sound.isActive) stopSound(sound);
    else playSound(sound);
}

/// Toggles the active state of the sound.
void toggleSoundIsActive(SoundId sound) {
    if (sound.isValid) toggleSoundIsActive(sound.get());
}

/// Toggles the paused state of the sound.
void toggleSoundIsPaused(ref Sound sound) {
    if (sound.isPaused) resumeSound(sound);
    else pauseSound(sound);
}

/// Toggles the paused state of the sound.
void toggleSoundIsPaused(SoundId sound) {
    if (sound.isValid) toggleSoundIsPaused(sound.get());
}

/// Updates the playback state of the specified sound.
void updateSound(ref Sound sound) {
    if (sound.isEmpty || sound.isPaused || !sound.isActive) return;
    if (sound.data.isType!(rl.Sound)) {
        if (rl.IsSoundPlaying(sound.data.as!(rl.Sound)())) return;
        sound.isActive = false;
        if (sound.canRepeat) playSound(sound);
    } else {
        auto isPlayingInternally = rl.IsMusicStreamPlaying(sound.data.as!(rl.Music)());
        auto hasLoopedInternally = sound.duration - sound.time < 0.1f;
        if (hasLoopedInternally) {
            if (sound.canRepeat) {
                // Copy-paste from `playSound`. Maybe make that a function.
                if (sound.pitchVariance != 1.0f) {
                    sound.setPitch(sound.pitchVarianceBase + (sound.pitchVarianceBase * sound.pitchVariance - sound.pitchVarianceBase) * randf);
                }
            } else {
                stopSound(sound);
                isPlayingInternally = false;
            }
        }
        if (isPlayingInternally) rl.UpdateMusicStream(sound.data.as!(rl.Music)());
    }
}

/// This function does nothing because managed resources are updated by the engine.
/// It only exists to make it easier to swap between resource types.
void updateSound(SoundId sound) {}

/// Measures the size of the specified text when rendered with the given font and draw options.
Vec2 measureTextSize(FontId font, IStr text, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    if (!font.isValid || text.length == 0) return Vec2();

    auto lineCodepointCount = 0;
    auto lineMaxCodepointCount = 0;
    auto textWidth = 0;
    auto textMaxWidth = 0;
    auto textHeight = font.size;
    auto textCodepointIndex = 0;
    while (textCodepointIndex < text.length) {
        lineCodepointCount += 1;
        auto codepointByteCount = 0;
        auto codepoint = rl.GetCodepointNext(&text[textCodepointIndex], &codepointByteCount); // TODO: REPLACE WITH JOKA THING
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
    if (!texture.isValid) {
        if (isEmptyTextureVisible) {
            auto rect = Rect(position, (!area.hasSize ? Vec2(64) : area.size) * options.scale).area(options.hook);
            drawRect(rect, defaultEngineDebugColor1);
            drawRect(rect, defaultEngineDebugColor2, 1);
        }
        return;
    }
    if (!area.hasSize) return;

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
    if (!texture.isValid) {
        if (isEmptyTextureVisible) {
            drawRect(target, defaultEngineDebugColor1);
            drawRect(target, defaultEngineDebugColor2, 1);
        }
        return;
    }
    if (!area.hasSize) return;

    // NOTE: New rule for options. Functions are allowed to ignore values. Should they handle bad values? Maybe.
    // NOTE: If we ever change options to pointers, remember to remove this part.
    options.hook = Hook.topLeft;
    options.origin = Vec2(0);
    options.scale = Vec2(1);
    foreach (part; computeSliceParts(area.floor().toIRect(), target.floor().toIRect(), margin)) {
        if (canRepeat && part.canTile) {
            options.scale = Vec2(1);
            foreach (y; 0 .. part.tileCount.y) { foreach (x; 0 .. part.tileCount.x) {
                auto sourceW = (x != part.tileCount.x - 1) ? part.source.w : max(0, part.target.w - x * part.source.w);
                auto sourceH = (y != part.tileCount.y - 1) ? part.source.h : max(0, part.target.h - y * part.source.h);
                drawTextureArea(
                    texture,
                    Rect(part.source.x, part.source.y, sourceW, sourceH),
                    Vec2(part.target.x + x * part.source.w, part.target.y + y * part.source.h),
                    options,
                );
            }}
        } else {
            options.scale = Vec2(
                part.target.w / cast(float) part.source.w,
                part.target.h / cast(float) part.source.h,
            );
            drawTextureArea(
                texture,
                Rect(part.source.x, part.source.y, part.source.w, part.source.h),
                Vec2(part.target.x, part.target.y),
                options,
            );
        }
    }
}

/// Draws a 9-slice from the default texture area at the given target area.
/// Use the `setDefaultTexture` function before using this function.
void drawTextureSlice(Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions()) {
    drawTextureSlice(_engineState.defaultTexture, area, target, margin, canRepeat, options);
}

/* TODO
/// Draws a portion of the specified viewport at the given position with the specified draw options.
void drawViewportArea(ref Viewport viewport, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    // Some basic rules to make viewports noob friendly.
    final switch (options.flip) {
        case Flip.none: options.flip = Flip.y; break;
        case Flip.x: options.flip = Flip.xy; break;
        case Flip.y: options.flip = Flip.none; break;
        case Flip.xy: options.flip = Flip.x; break;
    }
    drawTextureArea(viewport.data.texture.toPr(), area, position, options);
}

/// Draws the viewport at the given position with the specified draw options.
void drawViewport(ref Viewport viewport, Vec2 position, DrawOptions options = DrawOptions()) {
    drawViewportArea(viewport, Rect(viewport.size), position, options);
}
*/

/// Draws a single character from the specified font at the given position with the specified draw options.
void drawRune(FontId font, dchar rune, Vec2 position, DrawOptions options = DrawOptions()) {
    if (!font.isValid) {
        if (isEmptyFontVisible) font = engineFont;
        else return;
    }

    auto rect = font.glyphInfo(rune).rect.toRect(); // TODO
    auto origin = options.origin.isZero ? rect.origin(options.hook) : options.origin;
    //  TODO: STOPPED HERE!! Look at older parin code maybe.
    rl.rlPushMatrix();
    if (isPixelSnapped) {
        rl.rlTranslatef(position.x.floor(), position.y.floor(), 0.0f);
    } else {
        rl.rlTranslatef(position.x, position.y, 0.0f);
    }
    rl.rlRotatef(options.rotation, 0.0f, 0.0f, 1.0f);
    rl.rlScalef(options.scale.x, options.scale.y, 1.0f);
    rl.rlTranslatef(-origin.x.floor(), -origin.y.floor(), 0.0f);
    bk.drawRune(font.data, rune, Vec2(), 1, options.color);
    rl.rlPopMatrix();
}

/// Draws a single character from the default font at the given position with the specified draw options.
/// Check the `setDefaultFont` function before using this function.
void drawRune(dchar rune, Vec2 position, DrawOptions options = DrawOptions()) {
    drawRune(_engineState.defaultFont, rune, position, options);
}

/// Draws the specified text with the given font at the given position using the provided draw options.
// NOTE: Text drawing needs to go over the text 3 times. This can be made into 2 times in the future if needed by copy-pasting the measureTextSize inside this function.
Vec2 drawText(FontId font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    enum lineCountOfBuffers = 1024;
    static FixedList!(IStr, lineCountOfBuffers)  linesBuffer = void;
    static FixedList!(short, lineCountOfBuffers) linesWidthBuffer = void;

    auto result = Vec2();
    if (!font.isValid) {
        if (isEmptyFontVisible) font = engineFont;
        else return Vec2();
    }

    if (text.length == 0) return Vec2();
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
            auto codepoint = rl.GetCodepointNext(&text[textCodepointIndex], &codepointSize);
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
    rl.rlPushMatrix();
    if (isPixelSnapped) {
        rl.rlTranslatef(position.x.floor(), position.y.floor(), 0.0f);
    } else {
        rl.rlTranslatef(position.x, position.y, 0.0f);
    }
    rl.rlRotatef(options.rotation, 0.0f, 0.0f, 1.0f);
    rl.rlScalef(options.scale.x, options.scale.y, 1.0f);
    rl.rlTranslatef(-origin.x.floor(), -origin.y.floor(), 0.0f);

    // Draw the text.
    auto drawMaxCodepointCount = extra.visibilityCount
        ? extra.visibilityCount
        : textCodepointCount * extra.visibilityRatio;
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
                auto codepoint = rl.GetCodepointPrevious(&line.ptr[lineCodepointIndex], &codepointSize);
                auto glyphInfo = font.glyphInfo(codepoint);
                if (lineCodepointIndex == line.length) {
                    if (glyphInfo.advanceX) {
                        textOffsetX -= glyphInfo.advanceX + font.runeSpacing;
                    } else {
                        textOffsetX -= glyphInfo.rect.w + font.runeSpacing;
                    }
                } else {
                    auto temp = 0;
                    auto nextRightToLeftGlyphInfo = font.glyphInfo(rl.GetCodepointPrevious(&line[lineCodepointIndex], &temp));
                    if (nextRightToLeftGlyphInfo.advanceX) {
                        textOffsetX -= nextRightToLeftGlyphInfo.advanceX + font.runeSpacing;
                    } else {
                        textOffsetX -= nextRightToLeftGlyphInfo.rect.w + font.runeSpacing;
                    }
                }
                if (codepoint != ' ' && codepoint != '\t') {
                    bk.drawRune(font.data, codepoint, Vec2(textOffsetX, textOffsetY), 1, options.color);
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
                auto codepoint = rl.GetCodepointNext(&line[lineCodepointIndex], &codepointSize);
                auto glyphInfo = font.glyphInfo(codepoint);
                if (codepoint != ' ' && codepoint != '\t') {
                    bk.drawRune(font.data, codepoint, Vec2(textOffsetX, textOffsetY), 1, options.color);
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
    rl.rlPopMatrix();
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
    auto mouse = mouse.toWorldPoint(camera);
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
            _engineState.sounds.length,
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
                _engineState.sounds.length,
                cast(int) mouse.x,
                cast(int) mouse.y,
            );
        } else {
            text = "FPS: {}\nAssets: (T{} F{} S{})\nMouse: ({} {})\nArea: A({} {}) B({} {}) S({} {})".fmt(
                fps,
                bk.backendTextureCount,
                bk.backendFontCount - 1,
                _engineState.sounds.length,
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
    drawRect(Rect(a.toScreenPoint(camera), s), defaultEngineDebugColor1);
    drawRect(Rect(a.toScreenPoint(camera), s), defaultEngineDebugColor2, 1);
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
    auto mouse = mouse.toWorldPoint(camera);
    auto gridPoint = Vec2(mouse.x / tileWidth, mouse.y / tileHeight).floor();
    auto tile = Rect(gridPoint.x * tileWidth, gridPoint.y * tileHeight, tileWidth, tileHeight);
    auto text = "Grid: ({} {})\nWorld: ({} {})".fmt(
        cast(int) gridPoint.x,
        cast(int) gridPoint.y,
        cast(int) tile.x,
        cast(int) tile.y,
    );
    drawRect(Rect(tile.position.toScreenPoint(camera), tile.size), defaultEngineDebugColor1);
    drawRect(Rect(tile.position.toScreenPoint(camera), tile.size), defaultEngineDebugColor2, 1);
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
