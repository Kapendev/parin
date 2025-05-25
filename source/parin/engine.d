// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.44
// ---

// TODO: Check sound again. I think pause and resume don't work.

/// The `engine` module functions as a lightweight 2D game engine.
module parin.engine;

import rl = parin.rl;
import joka.ascii;
import joka.io;
import joka.memory;
public import joka.containers;
public import joka.math;
public import joka.types;

@trusted @nogc nothrow:

extern(C)
__gshared EngineState* engineState;

alias EngineUpdateFunc      = bool function(float dt);
alias EngineReadyFinishFunc = void function();
alias EngineFlags           = ushort;

enum defaultEngineValidateErrorMessage = "Resource is invalid or was never assigned.";
enum defaultEngineTexturesCapacity     = 128;
enum defaultEngineSoundsCapacity       = 128;
enum defaultEngineFontsCapacity        = 16;
enum defaultEngineEmptyTextureColor    = white;
enum engineFont                        = FontId(GenerationalIndex(1)); /// The default engine font. This font should not be freed.

enum EngineFlag : EngineFlags {
    none                  = 0x0000,
    isUpdating            = 0x0001,
    isUsingAssetsPath     = 0x0002,
    isPixelSnapped        = 0x0004,
    isPixelPerfect        = 0x0008,
    isEmptyTextureVisible = 0x0010,
    isEmptyFontVisible    = 0x0020,
    isFullscreen          = 0x0040,
    isCursorVisible       = 0x0080,
}

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
    nearest = rl.TEXTURE_FILTER_POINT,    /// Nearest neighbor filtering (blocky).
    linear  = rl.TEXTURE_FILTER_BILINEAR, /// Bilinear filtering (smooth).
}

/// Texture wrapping modes.
enum Wrap : ubyte {
    clamp  = rl.TEXTURE_WRAP_CLAMP,  /// Clamps texture.
    repeat = rl.TEXTURE_WRAP_REPEAT, /// Repeats texture.
}

/// Texture blending modes.
enum Blend : ubyte {
    alpha      = rl.BLEND_CUSTOM_SEPARATE, /// Standard alpha blending.
    additive   = rl.BLEND_ADDITIVE,        /// Adds colors for light effects.
    multiplied = rl.BLEND_MULTIPLIED,      /// Multiplies colors for shadows.
    add        = rl.BLEND_ADD_COLORS,      /// Simply adds colors.
    sub        = rl.BLEND_SUBTRACT_COLORS, /// Simply subtracts colors.
}

/// A limited set of keyboard keys.
enum Keyboard : ushort {
    none = rl.KEY_NULL,           /// Not a key.
    a = rl.KEY_A,                 /// The A key.
    b = rl.KEY_B,                 /// The B key.
    c = rl.KEY_C,                 /// The C key.
    d = rl.KEY_D,                 /// The D key.
    e = rl.KEY_E,                 /// The E key.
    f = rl.KEY_F,                 /// The F key.
    g = rl.KEY_G,                 /// The G key.
    h = rl.KEY_H,                 /// The H key.
    i = rl.KEY_I,                 /// The I key.
    j = rl.KEY_J,                 /// The J key.
    k = rl.KEY_K,                 /// The K key.
    l = rl.KEY_L,                 /// The L key.
    m = rl.KEY_M,                 /// The M key.
    n = rl.KEY_N,                 /// The N key.
    o = rl.KEY_O,                 /// The O key.
    p = rl.KEY_P,                 /// The P key.
    q = rl.KEY_Q,                 /// The Q key.
    r = rl.KEY_R,                 /// The R key.
    s = rl.KEY_S,                 /// The S key.
    t = rl.KEY_T,                 /// The T key.
    u = rl.KEY_U,                 /// The U key.
    v = rl.KEY_V,                 /// The V key.
    w = rl.KEY_W,                 /// The W key.
    x = rl.KEY_X,                 /// The X key.
    y = rl.KEY_Y,                 /// The Y key.
    z = rl.KEY_Z,                 /// The Z key.
    n0 = rl.KEY_ZERO,             /// The 0 key.
    n1 = rl.KEY_ONE,              /// The 1 key.
    n2 = rl.KEY_TWO,              /// The 2 key.
    n3 = rl.KEY_THREE,            /// The 3 key.
    n4 = rl.KEY_FOUR,             /// The 4 key.
    n5 = rl.KEY_FIVE,             /// The 5 key.
    n6 = rl.KEY_SIX,              /// The 6 key.
    n7 = rl.KEY_SEVEN,            /// The 7 key.
    n8 = rl.KEY_EIGHT,            /// The 8 key.
    n9 = rl.KEY_NINE,             /// The 9 key.
    nn0 = rl.KEY_KP_0,            /// The 0 key on the numpad.
    nn1 = rl.KEY_KP_1,            /// The 1 key on the numpad.
    nn2 = rl.KEY_KP_2,            /// The 2 key on the numpad.
    nn3 = rl.KEY_KP_3,            /// The 3 key on the numpad.
    nn4 = rl.KEY_KP_4,            /// The 4 key on the numpad.
    nn5 = rl.KEY_KP_5,            /// The 5 key on the numpad.
    nn6 = rl.KEY_KP_6,            /// The 6 key on the numpad.
    nn7 = rl.KEY_KP_7,            /// The 7 key on the numpad.
    nn8 = rl.KEY_KP_8,            /// The 8 key on the numpad.
    nn9 = rl.KEY_KP_9,            /// The 9 key on the numpad.
    f1 = rl.KEY_F1,               /// The f1 key.
    f2 = rl.KEY_F2,               /// The f2 key.
    f3 = rl.KEY_F3,               /// The f3 key.
    f4 = rl.KEY_F4,               /// The f4 key.
    f5 = rl.KEY_F5,               /// The f5 key.
    f6 = rl.KEY_F6,               /// The f6 key.
    f7 = rl.KEY_F7,               /// The f7 key.
    f8 = rl.KEY_F8,               /// The f8 key.
    f9 = rl.KEY_F9,               /// The f9 key.
    f10 = rl.KEY_F10,             /// The f10 key.
    f11 = rl.KEY_F11,             /// The f11 key.
    f12 = rl.KEY_F12,             /// The f12 key.
    left = rl.KEY_LEFT,           /// The left arrow key.
    right = rl.KEY_RIGHT,         /// The right arrow key.
    up = rl.KEY_UP,               /// The up arrow key.
    down = rl.KEY_DOWN,           /// The down arrow key.
    esc = rl.KEY_ESCAPE,          /// The escape key.
    enter = rl.KEY_ENTER,         /// The enter key.
    tab = rl.KEY_TAB,             /// The tab key.
    space = rl.KEY_SPACE,         /// The space key.
    backspace = rl.KEY_BACKSPACE, /// THe backspace key.
    shift = rl.KEY_LEFT_SHIFT,    /// The left shift key.
    ctrl = rl.KEY_LEFT_CONTROL,   /// The left control key.
    alt = rl.KEY_LEFT_ALT,        /// The left alt key.
    win = rl.KEY_LEFT_SUPER,      /// The left windows/super/command key.
    insert = rl.KEY_INSERT,       /// The insert key.
    del = rl.KEY_DELETE,          /// The delete key.
    home = rl.KEY_HOME,           /// The home key.
    end = rl.KEY_END,             /// The end key.
    pageUp = rl.KEY_PAGE_UP,      /// The page up key.
    pageDown = rl.KEY_PAGE_DOWN,  /// The page down key.
}

/// A limited set of mouse keys.
enum Mouse : ushort {
    none = 0,                            /// Not a button.
    left = rl.MOUSE_BUTTON_LEFT + 1,     /// The left mouse button.
    right = rl.MOUSE_BUTTON_RIGHT + 1,   /// The right mouse button.
    middle = rl.MOUSE_BUTTON_MIDDLE + 1, /// The middle mouse button.
}

/// A limited set of gamepad buttons.
enum Gamepad : ushort {
    none = rl.GAMEPAD_BUTTON_UNKNOWN,          /// Not a button.
    left = rl.GAMEPAD_BUTTON_LEFT_FACE_LEFT,   /// The left button.
    right = rl.GAMEPAD_BUTTON_LEFT_FACE_RIGHT, /// The right button.
    up = rl.GAMEPAD_BUTTON_LEFT_FACE_UP,       /// The up button.
    down = rl.GAMEPAD_BUTTON_LEFT_FACE_DOWN,   /// The down button.
    y = rl.GAMEPAD_BUTTON_RIGHT_FACE_UP,       /// The Xbox y, PlayStation triangle and Nintendo x button.
    x = rl.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT,    /// The Xbox x, PlayStation square and Nintendo y button.
    a = rl.GAMEPAD_BUTTON_RIGHT_FACE_DOWN,     /// The Xbox a, PlayStation cross and Nintendo b button.
    b = rl.GAMEPAD_BUTTON_RIGHT_FACE_LEFT,     /// The Xbox b, PlayStation circle and Nintendo a button.
    lt = rl.GAMEPAD_BUTTON_LEFT_TRIGGER_2,     /// The left trigger button.
    lb = rl.GAMEPAD_BUTTON_LEFT_TRIGGER_1,     /// The left bumper button.
    lsb = rl.GAMEPAD_BUTTON_LEFT_THUMB,        /// The left stick button.
    rt = rl.GAMEPAD_BUTTON_RIGHT_TRIGGER_2,    /// The right trigger button.
    rb = rl.GAMEPAD_BUTTON_RIGHT_TRIGGER_1,    /// The right bumper button.
    rsb = rl.GAMEPAD_BUTTON_RIGHT_THUMB,       /// The right stick button.
    back = rl.GAMEPAD_BUTTON_MIDDLE_LEFT,      /// The back button.
    start = rl.GAMEPAD_BUTTON_MIDDLE_RIGHT,    /// The start button.
    middle = rl.GAMEPAD_BUTTON_MIDDLE,         /// The middle button.
}

/// Options for configuring drawing parameters.
struct DrawOptions {
    Vec2 origin = Vec2(0.0f);             /// The origin point of the drawn object. This value can be used to force a specific origin.
    Vec2 scale = Vec2(1.0f);              /// The scale of the drawn object.
    float rotation = 0.0f;                /// The rotation of the drawn object, in degrees.
    Rgba color = white;                  /// The color of the drawn object, in RGBA.
    Hook hook = Hook.topLeft;             /// A value representing the origin point of the drawn object when origin is zero.
    Flip flip = Flip.none;                /// A value representing flipping orientations.

    @trusted @nogc nothrow:

    /// Initializes the options with the given rotation.
    this(float rotation) {
        this.rotation = rotation;
    }

    /// Initializes the options with the given scale.
    this(Vec2 scale) {
        this.scale = scale;
    }

    /// Initializes the options with the given color.
    this(Rgba color) {
        this.color = color;
    }

    /// Initializes the options with the given hook.
    this(Hook hook) {
        this.hook = hook;
    }

    /// Initializes the options with the given flip.
    this(Flip flip) {
        this.flip = flip;
    }
}

/// Options for configuring extra drawing parameters for text.
struct TextOptions {
    float visibilityRatio = 1.0f;         /// Controls the visibility ratio of the text when visibilityCount is zero, where 0.0 means fully hidden and 1.0 means fully visible.
    int alignmentWidth = 0;               /// The width of the aligned text. It is used as a hint and is not enforced.
    ushort visibilityCount = 0;           /// Controls the visibility count of the text. This value can be used to force a specific character count.
    Alignment alignment = Alignment.left; /// A value represeting alignment orientations.
    bool isRightToLeft = false;           /// Indicates whether the content of the text flows in a right-to-left direction.

    @trusted @nogc nothrow:

    /// Initializes the options with the given visibility ratio.
    this(float visibilityRatio) {
        this.visibilityRatio = visibilityRatio;
    }

    /// Initializes the options with the given alignment.
    this(Alignment alignment, int alignmentWidth = 0) {
        this.alignment = alignment;
        this.alignmentWidth = alignmentWidth;
    }
}

/// A texture resource.
struct Texture {
    rl.Texture2D data;

    @trusted @nogc nothrow:

    /// Checks if the texture is not loaded.
    bool isEmpty() {
        return data.id <= 0;
    }

    /// Returns the width of the texture.
    int width() {
        return data.width;
    }

    /// Returns the height of the texture.
    int height() {
        return data.height;
    }

    /// Returns the size of the texture.
    Vec2 size() {
        return Vec2(width, height);
    }

    /// Sets the filter mode of the texture.
    void setFilter(Filter value) {
        if (isEmpty) return;
        rl.SetTextureFilter(data, value);
    }

    /// Sets the wrap mode of the texture.
    void setWrap(Wrap value) {
        if (isEmpty) return;
        rl.SetTextureWrap(data, value);
    }

    /// Frees the loaded texture.
    void free() {
        if (isEmpty) return;
        rl.UnloadTexture(data);
        this = Texture();
    }
}

/// An identifier for a managed engine resource. Managed resources can be safely shared throughout the code.
/// To free these resources, use the `freeEngineResources` function or the `free` method on the identifier.
/// The identifier is automatically invalidated when the resource is freed.
struct TextureId {
    GenerationalIndex data;

    @trusted @nogc nothrow:

    /// Returns the width of the texture associated with the resource identifier.
    int width() {
        return getOr().width;
    }

    /// Returns the height of the texture associated with the resource identifier.
    int height() {
        return getOr().height;
    }

    /// Returns the size of the texture associated with the resource identifier.
    Vec2 size() {
        return getOr().size;
    }

    /// Sets the filter mode of the texture associated with the resource identifier.
    void setFilter(Filter value) {
        getOr().setFilter(value);
    }

    /// Sets the wrap mode of the texture associated with the resource identifier.
    void setWrap(Wrap value) {
        getOr().setWrap(value);
    }

    /// Checks if the resource identifier is valid. It becomes automatically invalid when the resource is freed.
    bool isValid() {
        return data.value && engineState.textures.has(GenerationalIndex(data.value - 1, data.generation));
    }

    /// Checks if the resource identifier is valid and asserts if it is not.
    TextureId validate(IStr message = defaultEngineValidateErrorMessage) {
        if (!isValid) assert(0, message);
        return this;
    }

    /// Retrieves the texture associated with the resource identifier.
    ref Texture get() {
        if (!isValid) assert(0, defaultEngineValidateErrorMessage);
        return engineState.textures[GenerationalIndex(data.value - 1, data.generation)];
    }

    /// Retrieves the texture associated with the resource identifier or returns a default value if invalid.
    Texture getOr() {
        return isValid ? engineState.textures[GenerationalIndex(data.value - 1, data.generation)] : Texture();
    }

    /// Frees the resource associated with the identifier.
    void free() {
        if (isValid) engineState.textures.remove(GenerationalIndex(data.value - 1, data.generation));
    }
}

/// A font resource.
struct Font {
    rl.Font data;
    int runeSpacing; /// The spacing between individual characters.
    int lineSpacing; /// The spacing between lines of text.

    @trusted @nogc nothrow:

    /// Checks if the font is not loaded.
    bool isEmpty() {
        return data.texture.id <= 0;
    }

    /// Returns the size of the font.
    int size() {
        return data.baseSize;
    }

    /// Sets the filter mode of the font.
    void setFilter(Filter value) {
        if (isEmpty) return;
        rl.SetTextureFilter(data.texture, value);
    }

    /// Sets the wrap mode of the font.
    void setWrap(Wrap value) {
        if (isEmpty) return;
        rl.SetTextureWrap(data.texture, value);
    }

    /// Frees the loaded font.
    void free() {
        if (isEmpty) return;
        rl.UnloadFont(data);
        this = Font();
    }
}

/// An identifier for a managed engine resource. Managed resources can be safely shared throughout the code.
/// To free these resources, use the `freeEngineResources` function or the `free` method on the identifier.
/// The identifier is automatically invalidated when the resource is freed.
struct FontId {
    GenerationalIndex data;

    @trusted @nogc nothrow:

    /// Returns the spacing between individual characters of the font associated with the resource identifier.
    int runeSpacing() {
        return getOr().runeSpacing;
    }

    /// Returns the spacing between lines of text of the font associated with the resource identifier.
    int lineSpacing() {
        return getOr().lineSpacing;
    };

    /// Returns the size of the font associated with the resource identifier.
    int size() {
        return getOr().size;
    }

    /// Sets the filter mode of the font associated with the resource identifier.
    void setFilter(Filter value) {
        getOr().setFilter(value);
    }

    /// Sets the wrap mode of the font associated with the resource identifier.
    void setWrap(Wrap value) {
        getOr().setWrap(value);
    }

    /// Checks if the resource identifier is valid. It becomes automatically invalid when the resource is freed.
    bool isValid() {
        return data.value && engineState.fonts.has(GenerationalIndex(data.value - 1, data.generation));
    }

    /// Checks if the resource identifier is valid and asserts if it is not.
    FontId validate(IStr message = defaultEngineValidateErrorMessage) {
        if (!isValid) assert(0, message);
        return this;
    }

    /// Retrieves the font associated with the resource identifier.
    ref Font get() {
        if (!isValid) assert(0, defaultEngineValidateErrorMessage);
        return engineState.fonts[GenerationalIndex(data.value - 1, data.generation)];
    }

    /// Retrieves the font associated with the resource identifier or returns a default value if invalid.
    Font getOr() {
        return isValid ? engineState.fonts[GenerationalIndex(data.value - 1, data.generation)] : Font();
    }

    /// Frees the resource associated with the identifier.
    void free() {
        if (isValid && this != engineFont) engineState.fonts.remove(GenerationalIndex(data.value - 1, data.generation));
    }
}

/// A sound resource.
struct Sound {
    Union!(rl.Sound, rl.Music) data;
    float pitch = 1.0f;
    float pitchVariance = 1.0f; // A value of 1 means no variation.
    float pitchVarianceBase = 1.0f;
    bool canRepeat;
    bool isPlaying_;
    bool isPaused;

    @trusted @nogc nothrow:

    deprecated("Will be replaced with canRepeat.")
    alias isLooping = canRepeat;
    deprecated("Will be replaced with a variable. Remove `()` when using this name.")
    bool isPlaying() { return this.isPlaying_; }

    /// Checks if the sound is not loaded.
    bool isEmpty() {
        if (data.isType!(rl.Sound)) {
            return data.get!(rl.Sound)().stream.sampleRate == 0;
        } else {
            return data.get!(rl.Music)().stream.sampleRate == 0;
        }
    }

    /// Returns the current playback time of the sound.
    float time() {
        if (data.isType!(rl.Sound)) {
            return 0.0f;
        } else {
            return rl.GetMusicTimePlayed(data.get!(rl.Music)());
        }
    }

    /// Returns the total duration of the sound.
    float duration() {
        if (data.isType!(rl.Sound)) {
            return 0.0f;
        } else {
            return rl.GetMusicTimeLength(data.get!(rl.Music)());
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
            rl.SetSoundVolume(data.get!(rl.Sound)(), value);
        } else {
            rl.SetMusicVolume(data.get!(rl.Music)(), value);
        }
    }

    /// Sets the pitch of the sound. One is the default value.
    void setPitch(float value, bool canUpdatePitchVarianceBase = false) {
        pitch = value;
        if (canUpdatePitchVarianceBase) pitchVarianceBase = value;
        if (data.isType!(rl.Sound)) {
            rl.SetSoundPitch(data.get!(rl.Sound)(), value);
        } else {
            rl.SetMusicPitch(data.get!(rl.Music)(), value);
        }
    }

    /// Sets the stereo panning of the sound. One is the default value.
    void setPan(float value) {
        if (data.isType!(rl.Sound)) {
            rl.SetSoundPan(data.get!(rl.Sound)(), value);
        } else {
            rl.SetMusicPan(data.get!(rl.Music)(), value);
        }
    }

    /// Frees the loaded sound.
    void free() {
        if (isEmpty) return;
        if (data.isType!(rl.Sound)) {
            rl.UnloadSound(data.get!(rl.Sound)());
        } else {
            rl.UnloadMusicStream(data.get!(rl.Music)());
        }
        this = Sound();
    }
}

/// An identifier for a managed engine resource. Managed resources can be safely shared throughout the code.
/// To free these resources, use the `freeEngineResources` function or the `free` method on the identifier.
/// The identifier is automatically invalidated when the resource is freed.
struct SoundId {
    GenerationalIndex data;

    deprecated("Will be replaced with canRepeat.")
    alias isLooping = canRepeat;
    deprecated("Will be replaced with setCanRepeat.")
    alias setIsLooping = setCanRepeat;

    @trusted @nogc nothrow:

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
    bool isPlaying() {
        return getOr().isPlaying_;
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
        return data.value && engineState.sounds.has(GenerationalIndex(data.value - 1, data.generation));
    }

    /// Checks if the resource identifier is valid and asserts if it is not.
    SoundId validate(IStr message = defaultEngineValidateErrorMessage) {
        if (!isValid) assert(0, message);
        return this;
    }

    /// Retrieves the sound associated with the resource identifier.
    ref Sound get() {
        if (!isValid) assert(0, defaultEngineValidateErrorMessage);
        return engineState.sounds[GenerationalIndex(data.value - 1, data.generation)];
    }

    /// Retrieves the sound associated with the resource identifier or returns a default value if invalid.
    Sound getOr() {
        return isValid ? engineState.sounds[GenerationalIndex(data.value - 1, data.generation)] : Sound();
    }

    /// Frees the resource associated with the identifier.
    void free() {
        if (isValid) engineState.sounds.remove(GenerationalIndex(data.value - 1, data.generation));
    }
}

/// A viewing area for rendering.
struct Viewport {
    rl.RenderTexture2D data;
    Rgba color;     /// The background color of the viewport.
    Blend blend;     /// A value representing blending modes.
    bool isAttached; /// Indicates whether the viewport is currently in use.

    @trusted @nogc nothrow:

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
        setFilter(engineState.defaultFilter);
        setWrap(engineState.defaultWrap);
    }

    /// Attaches the viewport, making it active.
    // NOTE: The engine viewport should not use this function.
    void attach() {
        if (isEmpty) return;
        if (engineState.userViewport.isAttached) {
            assert(0, "Cannot attach viewport because another viewport is already attached.");
        }
        isAttached = true;
        engineState.userViewport = this;
        if (isResolutionLocked) rl.EndTextureMode();
        rl.BeginTextureMode(data);
        rl.ClearBackground(color.toRl());
        rl.BeginBlendMode(blend);
    }

    /// Detaches the viewport, making it inactive.
    // NOTE: The engine viewport should not use this function.
    void detach() {
        if (isEmpty) return;
        if (!isAttached) {
            assert(0, "Cannot detach viewport because it is not the attached viewport.");
        }
        isAttached = false;
        engineState.userViewport = Viewport();
        rl.EndBlendMode();
        rl.EndTextureMode();
        if (isResolutionLocked) rl.BeginTextureMode(engineState.viewport.data.toRl());
    }

    /// Sets the filter mode of the viewport.
    void setFilter(Filter value) {
        if (isEmpty) return;
        rl.SetTextureFilter(data.texture, value);
    }

    /// Sets the wrap mode of the viewport.
    void setWrap(Wrap value) {
        if (isEmpty) return;
        rl.SetTextureWrap(data.texture, value);
    }

    /// Frees the loaded viewport.
    void free() {
        if (isEmpty) return;
        rl.UnloadRenderTexture(data);
        this = Viewport();
    }
}

/// A camera.
struct Camera {
    Vec2 position;         /// The position of the cammera.
    float rotation = 0.0f; /// The rotation angle of the camera, in degrees.
    float scale = 1.0f;    /// The zoom level of the camera.
    bool isCentered;       /// Determines if the camera's origin is at the center instead of the top left.
    bool isAttached;       /// Indicates whether the camera is currently in use.

    @trusted @nogc nothrow:

    /// Initializes the camera with the given position and optional centering.
    this(float x, float y, bool isCentered = false) {
        this.position.x = x;
        this.position.y = y;
        this.isCentered = isCentered;
    }

    /// Returns the current hook associated with the camera.
    Hook hook() {
        return isCentered ? Hook.center : Hook.topLeft;
    }

    /// Returns the origin of the camera.
    Vec2 origin(Viewport viewport = Viewport()) {
        if (viewport.isEmpty) {
            return Rect(resolution / Vec2(scale)).origin(hook);
        } else {
            return Rect(viewport.size / Vec2(scale)).origin(hook);
        }
    }

    /// Returns the area covered by the camera.
    Rect area(Viewport viewport = Viewport()) {
        if (viewport.isEmpty) {
            return Rect(position, resolution / Vec2(scale)).area(hook);
        } else {
            return Rect(position, viewport.size / Vec2(scale)).area(hook);
        }
    }

    /// Returns the top left point of the camera.
    Vec2 topLeftPoint() {
        return area.topLeftPoint;
    }

    /// Returns the top point of the camera.
    Vec2 topPoint() {
        return area.topPoint;
    }

    /// Returns the top right point of the camera.
    Vec2 topRightPoint() {
        return area.topRightPoint;
    }

    /// Returns the left point of the camera.
    Vec2 leftPoint() {
        return area.leftPoint;
    }

    /// Returns the center point of the camera.
    Vec2 centerPoint() {
        return area.centerPoint;
    }

    /// Returns the right point of the camera.
    Vec2 rightPoint() {
        return area.rightPoint;
    }

    /// Returns the bottom left point of the camera.
    Vec2 bottomLeftPoint() {
        return area.bottomLeftPoint;
    }

    /// Returns the bottom point of the camera.
    Vec2 bottomPoint() {
        return area.bottomPoint;
    }

    /// Returns the bottom right point of the camera.
    Vec2 bottomRightPoint() {
        return area.bottomRightPoint;
    }

    /// Moves the camera to follow the target position at the specified speed.
    void followPosition(Vec2 target, float speed) {
        position = position.moveTo(target, Vec2(speed));
    }

    /// Moves the camera to follow the target position with gradual slowdown.
    void followPositionWithSlowdown(Vec2 target, float slowdown) {
        position = position.moveToWithSlowdown(target, Vec2(deltaTime), slowdown);
    }

    /// Adjusts the camera’s zoom level to follow the target value at the specified speed.
    void followScale(float target, float speed) {
        scale = scale.moveTo(target, speed);
    }

    /// Adjusts the camera’s zoom level to follow the target value with gradual slowdown.
    void followScaleWithSlowdown(float target, float slowdown) {
        scale = scale.moveToWithSlowdown(target, deltaTime, slowdown);
    }

    /// Attaches the camera, making it active.
    void attach() {
        if (engineState.userCamera.isAttached) {
            assert(0, "Cannot attach camera because another camera is already attached.");
        }
        isAttached = true;
        engineState.userCamera = this;
        auto temp = this.toRl(engineState.userViewport);
        if (isPixelSnapped) {
            temp.target.x = temp.target.x.floor();
            temp.target.y = temp.target.y.floor();
            temp.offset.x = temp.offset.x.floor();
            temp.offset.y = temp.offset.y.floor();
        }
        rl.BeginMode2D(temp);
    }

    /// Detaches the camera, making it inactive.
    void detach() {
        if (!isAttached) {
            assert(0, "Cannot detach camera because it is not the attached camera.");
        }
        isAttached = false;
        engineState.userCamera = Camera();
        rl.EndMode2D();
    }
}

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
    EngineFlags flags =
        EngineFlag.isUsingAssetsPath |
        EngineFlag.isEmptyTextureVisible |
        EngineFlag.isEmptyFontVisible;

    EngineUpdateFunc updateFunc;
    EngineFullscreenState fullscreenState;
    EngineViewportInfo viewportInfoBuffer;
    Vec2 mouseBuffer;
    Vec2 wasdBuffer;
    Vec2 wasdPressedBuffer;
    Vec2 wasdReleasedBuffer;

    Sz tickCount;
    Rgba borderColor = black;
    Filter defaultFilter;
    Wrap defaultWrap;
    Camera userCamera;
    Viewport userViewport;

    EngineViewport viewport;
    GenerationalList!Texture textures;
    GenerationalList!Sound sounds;
    GenerationalList!Font fonts;
    List!IStr envArgsBuffer;
    List!IStr droppedFilePathsBuffer;
    LStr loadTextBuffer;
    LStr saveTextBuffer;
    LStr assetsPath;
}

/// Converts a raylib type to a Parin type.
pragma(inline, true)
Rgba toParin(rl.Color from) {
    return Rgba(from.r, from.g, from.b, from.a);
}

/// Converts a raylib type to a Parin type.
pragma(inline, true)
Vec2 toParin(rl.Vector2 from) {
    return Vec2(from.x, from.y);
}

/// Converts a raylib type to a Parin type.
pragma(inline, true)
Vec3 toParin(rl.Vector3 from) {
    return Vec3(from.x, from.y, from.z);
}

/// Converts a raylib type to a Parin type.
pragma(inline, true)
Vec4 toParin(rl.Vector4 from) {
    return Vec4(from.x, from.y, from.z, from.w);
}

/// Converts a raylib type to a Parin type.
pragma(inline, true)
Rect toParin(rl.Rectangle from) {
    return Rect(from.x, from.y, from.width, from.height);
}

/// Converts a raylib type to a Parin type.
pragma(inline, true)
Texture toParin(rl.Texture2D from) {
    return Texture(from);
}

/// Converts a raylib type to a Parin type.
pragma(inline, true)
Font toParin(rl.Font from) {
    return Font(from);
}

/// Converts a Parin type to a raylib type.
pragma(inline, true)
rl.Color toRl(Rgba from) {
    return rl.Color(from.r, from.g, from.b, from.a);
}

/// Converts a Parin type to a raylib type.
pragma(inline, true)
rl.Vector2 toRl(Vec2 from) {
    return rl.Vector2(from.x, from.y);
}

/// Converts a Parin type to a raylib type.
pragma(inline, true)
rl.Vector3 toRl(Vec3 from) {
    return rl.Vector3(from.x, from.y, from.z);
}

/// Converts a Parin type to a raylib type.
pragma(inline, true)
rl.Vector4 toRl(Vec4 from) {
    return rl.Vector4(from.x, from.y, from.z, from.w);
}

/// Converts a Parin type to a raylib type.
pragma(inline, true)
rl.Rectangle toRl(Rect from) {
    return rl.Rectangle(from.position.x, from.position.y, from.size.x, from.size.y);
}

/// Converts a Parin type to a raylib type.
pragma(inline, true)
rl.Texture2D toRl(Texture from) {
    return from.data;
}

/// Converts a Parin type to a raylib type.
pragma(inline, true)
rl.Font toRl(Font from) {
    return from.data;
}

/// Converts a Parin type to a raylib type.
pragma(inline, true)
rl.RenderTexture2D toRl(Viewport from) {
    return from.data;
}

/// Converts a Parin type to a raylib type.
pragma(inline, true)
rl.Camera2D toRl(Camera from, Viewport viewport = Viewport()) {
    return rl.Camera2D(
        Rect(viewport.isEmpty ? resolution : viewport.size).origin(from.isCentered ? Hook.center : Hook.topLeft).toRl(),
        from.position.toRl(),
        from.rotation,
        from.scale,
    );
}

/// C wrapper over the method with the same name.
extern(C)
void attachCamera(ref Camera camera) {
    camera.attach();
}

/// C wrapper over the method with the same name.
extern(C)
void detachCamera(ref Camera camera) {
    camera.detach();
}

/// C wrapper over the method with the same name.
extern(C)
void attachViewport(ref Viewport viewport) {
    viewport.attach();
}

/// C wrapper over the method with the same name.
extern(C)
void detachViewport(ref Viewport viewport) {
    viewport.detach();
}

/// Converts a texture into a managed engine resource.
/// The texture will be freed when the resource is freed.
extern(C)
TextureId toTextureId(Texture from) {
    if (from.isEmpty) return TextureId();
    auto id = TextureId(engineState.textures.append(from));
    id.data.value += 1;
    return id;
}

/// Converts a font into a managed engine resource.
/// The font will be freed when the resource is freed.
extern(C)
FontId toFontId(Font from) {
    if (from.isEmpty) return FontId();
    auto id = FontId(engineState.fonts.append(from));
    id.data.value += 1;
    return id;
}

/// Converts a sound into a managed engine resource.
/// The sound will be freed when the resource is freed.
extern(C)
SoundId toSoundId(Sound from) {
    if (from.isEmpty) return SoundId();
    auto id = SoundId(engineState.sounds.append(from));
    id.data.value += 1;
    return id;
}

/// Converts an ASCII bitmap font texture into a font.
/// The texture will be freed when the font is freed.
// NOTE: The number of items allocated is calculated as: (font width / tile width) * (font height / tile height)
// NOTE: It uses the raylib allocator.
extern(C)
Font toAsciiFont(Texture from, int tileWidth, int tileHeight) {
    if (from.isEmpty || tileWidth <= 0|| tileHeight <= 0) return Font();
    auto result = Font();
    result.lineSpacing = tileHeight;
    auto rowCount = from.height / tileHeight;
    auto colCount = from.width / tileWidth;
    auto maxCount = rowCount * colCount;
    result.data.baseSize = tileHeight;
    result.data.glyphCount = maxCount;
    result.data.glyphPadding = 0;
    result.data.texture = from.data;
    result.data.recs = cast(rl.Rectangle*) rl.MemAlloc(cast(uint) (maxCount * rl.Rectangle.sizeof));
    foreach (i; 0 .. maxCount) {
        result.data.recs[i].x = (i % colCount) * tileWidth;
        result.data.recs[i].y = (i / colCount) * tileHeight;
        result.data.recs[i].width = tileWidth;
        result.data.recs[i].height = tileHeight;
    }
    result.data.glyphs = cast(rl.GlyphInfo*) rl.MemAlloc(cast(uint) (maxCount * rl.GlyphInfo.sizeof));
    foreach (i; 0 .. maxCount) {
        result.data.glyphs[i] = rl.GlyphInfo();
        result.data.glyphs[i].value = i + 32;
    }
    return result;
}

/// Returns the opposite flip value.
/// The opposite of every flip value except none is none.
/// The fallback value is returned if the flip value is none.
extern(C)
Flip oppositeFlip(Flip flip, Flip fallback) {
    return flip == fallback ? Flip.none : fallback;
}

/// Returns the arguments that this application was started with.
IStr[] envArgs() {
    return engineState.envArgsBuffer[];
}

/// Returns a random integer between 0 and int.max (inclusive).
extern(C)
int randi() {
    return rl.GetRandomValue(0, int.max);
}

/// Returns a random floating point number between 0.0 and 1.0 (inclusive).
extern(C)
float randf() {
    return rl.GetRandomValue(0, cast(int) float.max) / cast(float) cast(int) float.max;
}

/// Sets the seed of the random number generator to the given value.
extern(C)
void randomizeSeed(int seed) {
    rl.SetRandomSeed(seed);
}

/// Randomizes the seed of the random number generator.
extern(C)
void randomize() {
    randomizeSeed(randi);
}

/// Converts a world point to a screen point based on the given camera.
extern(C)
Vec2 toScreenPoint(Vec2 position, Camera camera, Viewport viewport = Viewport()) {
    return toParin(rl.GetWorldToScreen2D(position.toRl(), camera.toRl(viewport)));
}

/// Converts a screen point to a world point based on the given camera.
extern(C)
Vec2 toWorldPoint(Vec2 position, Camera camera, Viewport viewport = Viewport()) {
    return toParin(rl.GetScreenToWorld2D(position.toRl(), camera.toRl(viewport)));
}

/// Returns the path of the assets folder.
extern(C)
IStr assetsPath() {
    return engineState.assetsPath.items;
}

/// Sets the path of the assets folder.
extern(C)
void setAssetsPath(IStr path) {
    engineState.assetsPath.clear();
    engineState.assetsPath.append(path);
}

/// Converts a path to a path within the assets folder.
extern(C)
IStr toAssetsPath(IStr path) {
    if (!isUsingAssetsPath) return path;
    return pathConcat(assetsPath, path).pathFormat();
}

/// Returns the dropped file paths of the current frame.
extern(C)
IStr[] droppedFilePaths() {
    return engineState.droppedFilePathsBuffer[];
}

/// Returns a reference to a cleared temporary text container.
/// The resource remains valid until this function is called again.
ref LStr prepareTempText() {
    engineState.saveTextBuffer.clear();
    return engineState.saveTextBuffer;
}

/// Loads a text file from the assets folder and saves the content into the given buffer.
/// Supports both forward slashes and backslashes in file paths.
Fault loadRawTextIntoBuffer(IStr path, ref LStr buffer) {
    auto targetPath = isUsingAssetsPath ? path.toAssetsPath() : path;
    return readTextIntoBuffer(targetPath, buffer);
}

/// Loads a text file from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Result!LStr loadRawText(IStr path) {
    auto targetPath = isUsingAssetsPath ? path.toAssetsPath() : path;
    return readText(targetPath);
}

/// Loads a text file from the assets folder.
/// The resource remains valid until this function is called again.
/// Supports both forward slashes and backslashes in file paths.
Result!IStr loadTempText(IStr path) {
    auto fault = loadRawTextIntoBuffer(path, engineState.loadTextBuffer);
    return Result!IStr(engineState.loadTextBuffer.items, fault);
}

/// Loads a texture file (PNG) from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Result!Texture loadRawTexture(IStr path) {
    auto targetPath = isUsingAssetsPath ? path.toAssetsPath() : path;
    auto value = rl.LoadTexture(targetPath.toCStr().getOr()).toParin();
    value.setFilter(engineState.defaultFilter);
    value.setWrap(engineState.defaultWrap);
    return Result!Texture(value, value.isEmpty.toFault(Fault.cantFind));
}

/// Loads a texture file (PNG) from the assets folder.
/// The resource can be safely shared throughout the code and is automatically invalidated when the resource is freed.
/// Supports both forward slashes and backslashes in file paths.
extern(C)
TextureId loadTexture(IStr path) {
    auto resource = loadRawTexture(path);
    if (resource.isNone) return TextureId();
    return resource.get().toTextureId();
}

/// Loads a font file (TTF, OTF) from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Result!Font loadRawFont(IStr path, int size, int runeSpacing, int lineSpacing, IStr32 runes = "") {
    auto targetPath = isUsingAssetsPath ? path.toAssetsPath() : path;
    auto value = rl.LoadFontEx(targetPath.toCStr().getOr(), size, runes == "" ? null : cast(int*) runes.ptr, cast(int) runes.length).toParin();
    if (value.data.texture.id == rl.GetFontDefault().texture.id) {
        value = Font();
    }
    value.runeSpacing = runeSpacing;
    value.lineSpacing = lineSpacing;
    value.setFilter(engineState.defaultFilter);
    value.setWrap(engineState.defaultWrap);
    return Result!Font(value, value.isEmpty.toFault(Fault.cantFind));
}

/// Loads a font file (TTF, OTF) from the assets folder.
/// The resource can be safely shared throughout the code and is automatically invalidated when the resource is freed.
/// Supports both forward slashes and backslashes in file paths.
extern(C)
FontId loadFont(IStr path, int size, int runeSpacing, int lineSpacing, IStr32 runes = "") {
    auto resource = loadRawFont(path, size, runeSpacing, lineSpacing, runes);
    if (resource.isNone) return FontId();
    return resource.get().toFontId();
}

/// Loads an ASCII bitmap font file (PNG) from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
// NOTE: The number of items allocated for this font is calculated as: (font width / tile width) * (font height / tile height)
Result!Font loadRawFontFromTexture(IStr path, int tileWidth, int tileHeight) {
    auto value = loadRawTexture(path).getOr();
    return Result!Font(value.toAsciiFont(tileWidth, tileHeight), value.isEmpty.toFault(Fault.cantFind));
}

/// Loads an ASCII bitmap font file (PNG) from the assets folder.
/// The resource can be safely shared throughout the code and is automatically invalidated when the resource is freed.
/// Supports both forward slashes and backslashes in file paths.
// NOTE: The number of items allocated for this font is calculated as: (font width / tile width) * (font height / tile height)
extern(C)
FontId loadFontFromTexture(IStr path, int tileWidth, int tileHeight) {
    auto resource = loadRawFontFromTexture(path, tileWidth, tileHeight);
    if (resource.isNone) return FontId();
    return resource.get().toFontId();
}

/// Loads a sound file (WAV, OGG, MP3) from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Result!Sound loadRawSound(IStr path, float volume, float pitch, bool canRepeat = false, float pitchVariance = 1.0f) {
    auto targetPath = isUsingAssetsPath ? path.toAssetsPath() : path;
    auto value = Sound();
    if (path.endsWith(".wav")) {
        value.data = rl.LoadSound(targetPath.toCStr().getOr());
    } else {
        value.data = rl.LoadMusicStream(targetPath.toCStr().getOr());
    }
    if (value.isEmpty) {
        return Result!Sound();
    } else {
        value.setVolume(volume);
        value.setPitch(pitch, true);
        value.canRepeat = canRepeat;
        value.pitchVariance = pitchVariance;
        return Result!Sound(value);
    }
}

/// Loads a sound file (WAV, OGG, MP3) from the assets folder.
/// The resource can be safely shared throughout the code and is automatically invalidated when the resource is freed.
/// Supports both forward slashes and backslashes in file paths.
extern(C)
SoundId loadSound(IStr path, float volume, float pitch, bool canRepeat = false, float pitchVariance = 1.0f) {
    auto resource = loadRawSound(path, volume, pitch, canRepeat, pitchVariance);
    if (resource.isNone) return SoundId();
    return resource.get().toSoundId();
}

/// Saves a text file to the assets folder.
/// Supports both forward slashes and backslashes in file paths.
extern(C)
Fault saveText(IStr path, IStr text) {
    auto targetPath = isUsingAssetsPath ? path.toAssetsPath() : path;
    return writeText(targetPath, text);
}

/// Frees all managed engine resources.
extern(C)
void freeEngineResources() {
    foreach (ref item; engineState.textures.items) item.free();
    engineState.textures.clear();
    foreach (ref item; engineState.sounds.items) item.free();
    engineState.sounds.clear();
    // The engine font in stored with the user fonts, so it needs to be skipped.
    auto engineFontItemId = engineFont.data;
    engineFontItemId.value -= 1;
    foreach (id; engineState.fonts.ids) {
        if (id == engineFontItemId) continue;
        engineState.fonts[id].free();
        engineState.fonts.remove(id);
    }
}

/// Opens a URL in the default web browser (if available).
/// Redirect to Parin's GitHub when no URL is provided.
extern(C)
void openUrl(IStr url = "https://github.com/Kapendev/parin") {
    rl.OpenURL(url.toCStr().getOr());
}

/// Opens a window with the specified size and title.
/// You should avoid calling this function manually.
extern(C)
void openWindow(int width, int height, const(IStr)[] args, IStr title = "Parin") {
    if (rl.IsWindowReady) return;
    // Raylib stuff.
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_VSYNC_HINT);
    rl.SetTraceLogLevel(rl.LOG_ERROR);
    rl.InitWindow(width, height, title.toCStr().getOr());
    rl.InitAudioDevice();
    rl.SetExitKey(rl.KEY_NULL);
    rl.SetTargetFPS(60);
    rl.SetWindowMinSize(240, 135);
    rl.rlSetBlendFactorsSeparate(0x0302, 0x0303, 1, 0x0303, 0x8006, 0x8006);
    // Engine stuff.
    engineState = jokaMake!EngineState();
    engineState.fullscreenState.previousWindowWidth = width;
    engineState.fullscreenState.previousWindowHeight = height;
    engineState.viewport.data.color = gray;
    engineViewportInfo(true);
    if (args.length) {
        foreach (arg; args) engineState.envArgsBuffer.append(arg);
        engineState.assetsPath.append(pathConcat(args[0].pathDirName, "assets"));
    }
    engineState.loadTextBuffer.reserve(8192);
    engineState.saveTextBuffer.reserve(8192);
    engineState.droppedFilePathsBuffer.reserve(defaultEngineFontsCapacity);
    engineState.textures.reserve(defaultEngineTexturesCapacity);
    engineState.sounds.reserve(defaultEngineSoundsCapacity);
    engineState.fonts.reserve(defaultEngineFontsCapacity);
    // Load debug font.
    auto monogramData = cast(const(ubyte)[]) import("parin/monogram.png");
    auto monogramImage = rl.LoadImageFromMemory(".png", monogramData.ptr, cast(int) monogramData.length);
    auto monogramTexture = rl.LoadTextureFromImage(monogramImage).toParin();
    engineState.fonts.append(monogramTexture.toAsciiFont(6, 12));
    rl.UnloadImage(monogramImage);
}

/// Opens a window with the specified size and title, using C strings.
/// You should avoid calling this function manually.
extern(C)
void openWindowC(int width, int height, int argc, ICStr* argv, ICStr title = "Parin") {
    openWindow(width, height, null, title.cStrToStr());
    foreach (i; 0 .. argc) engineState.envArgsBuffer.append(argv[i].cStrToStr());
    if (engineState.envArgsBuffer.length) engineState.assetsPath.append(pathConcat(engineState.envArgsBuffer[0].pathDirName, "assets"));
}

/// Use by the `updateWindow` function.
/// You should avoid calling this function manually.
extern(C)
bool updateWindowLoop() {
    // Begin drawing.
    if (isResolutionLocked) {
        rl.BeginTextureMode(engineState.viewport.data.toRl());
    } else {
        rl.BeginDrawing();
    }
    rl.ClearBackground(engineState.viewport.data.color.toRl());

    // The main loop.
    if (rl.IsFileDropped) {
        auto list = rl.LoadDroppedFiles();
        foreach (i; 0 .. list.count) {
            engineState.droppedFilePathsBuffer.append(list.paths[i].toStr());
        }
    }
    // Update buffers and resources.
    with (Keyboard) {
        if (isResolutionLocked) {
            auto rlMouse = rl.GetTouchPosition(0);
            auto info = engineViewportInfo;
            engineState.mouseBuffer = Vec2(
                floor((rlMouse.x - (info.maxSize.x - info.area.size.x) * 0.5f) / info.minRatio),
                floor((rlMouse.y - (info.maxSize.y - info.area.size.y) * 0.5f) / info.minRatio),
            );
        } else {
            engineState.mouseBuffer = rl.GetTouchPosition(0).toParin();
        }
        engineState.wasdBuffer = Vec2(
            (d.isDown || right.isDown) - (a.isDown || left.isDown),
            (s.isDown || down.isDown) - (w.isDown || up.isDown),
        );
        engineState.wasdPressedBuffer = Vec2(
            (d.isPressed || right.isPressed) - (a.isPressed || left.isPressed),
            (s.isPressed || down.isPressed) - (w.isPressed || up.isPressed),
        );
        engineState.wasdReleasedBuffer = Vec2(
            (d.isReleased || right.isReleased) - (a.isReleased || left.isReleased),
            (s.isReleased || down.isReleased) - (w.isReleased || up.isReleased),
        );
    }
    foreach (ref sound; engineState.sounds.items) {
        updateSoundX(sound);
    }
    auto result = engineState.updateFunc(deltaTime);
    engineState.tickCount = (engineState.tickCount + 1) % engineState.tickCount.max;
    if (rl.IsFileDropped) {
        // NOTE: LoadDroppedFiles just returns a global variable.
        rl.UnloadDroppedFiles(rl.LoadDroppedFiles());
        engineState.droppedFilePathsBuffer.clear();
    }

    // End drawing.
    if (isResolutionLocked) {
        auto info = engineViewportInfo;
        rl.EndTextureMode();
        rl.BeginDrawing();
        rl.ClearBackground(engineState.borderColor.toRl());
        rl.DrawTexturePro(
            engineState.viewport.data.toRl().texture,
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

    // Viewport code.
    if (engineState.viewport.isChanging) {
        if (engineState.viewport.isLocking) {
            engineState.viewport.data.resize(engineState.viewport.lockWidth, engineState.viewport.lockHeight);
        } else {
            auto temp = engineState.viewport.data.color;
            engineState.viewport.data.free();
            engineState.viewport.data.color = temp;
        }
        engineState.viewport.isChanging = false;
        engineViewportInfo(true);
    }
    // Fullscreen code.
    if (engineState.fullscreenState.isChanging) {
        engineState.fullscreenState.changeTime += deltaTime;
        if (engineState.fullscreenState.changeTime >= engineState.fullscreenState.changeDuration) {
            if (rl.IsWindowFullscreen()) {
                rl.ToggleFullscreen();
                // Size is first because raylib likes that. I will make raylib happy.
                rl.SetWindowSize(
                    engineState.fullscreenState.previousWindowWidth,
                    engineState.fullscreenState.previousWindowHeight,
                );
                rl.SetWindowPosition(
                    cast(int) (screenWidth * 0.5f - engineState.fullscreenState.previousWindowWidth * 0.5f),
                    cast(int) (screenHeight * 0.5f - engineState.fullscreenState.previousWindowHeight * 0.5f),
                );
            } else {
                rl.ToggleFullscreen();
            }
            engineState.fullscreenState.isChanging = false;
        }
    }
    return result;
}

/// Use by the `updateWindow` function.
/// You should avoid calling this function manually.
version(WebAssembly) {
    extern(C)
    void updateWindowLoopWeb() {
        if (updateWindowLoop()) rl.emscripten_cancel_main_loop();
    }
}

/// Updates the window every frame with the given function.
/// This function will return when the given function returns true.
/// You should avoid calling this function manually.
extern(C)
void updateWindow(bool function(float dt) updateFunc) {
    // Maybe bad idea, but makes life of no-attribute people easier.
    engineState.updateFunc = cast(EngineUpdateFunc) updateFunc;
    engineState.flags |= EngineFlag.isUpdating;
    version(WebAssembly) {
        rl.emscripten_set_main_loop(&updateWindowLoopWeb, 0, true);
    } else {
        while (true) if (rl.WindowShouldClose() || updateWindowLoop()) break;
    }
    engineState.flags &= ~EngineFlag.isUpdating;
}

/// Closes the window.
/// You should avoid calling this function manually.
extern(C)
void closeWindow() {
    if (!rl.IsWindowReady()) return;
    // NOTE: This leaks. Someone call the memory police!!!
    engineState = null;
    rl.CloseAudioDevice();
    rl.CloseWindow();
}

/// Returns true if the assets path is currently in use when loading.
extern(C)
bool isUsingAssetsPath() {
    return cast(bool) (engineState.flags & EngineFlag.isUsingAssetsPath);
}

/// Sets whether the assets path should be in use when loading.
extern(C)
void setIsUsingAssetsPath(bool value) {
    engineState.flags = value
        ? engineState.flags | EngineFlag.isUsingAssetsPath
        : engineState.flags & ~EngineFlag.isUsingAssetsPath;
}

/// Returns true if the drawing is snapped to pixel coordinates.
extern(C)
bool isPixelSnapped() {
    return cast(bool) (engineState.flags & EngineFlag.isPixelSnapped);
}

/// Sets whether drawing should be snapped to pixel coordinates.
extern(C)
void setIsPixelSnapped(bool value) {
    engineState.flags = value
        ? engineState.flags | EngineFlag.isPixelSnapped
        : engineState.flags & ~EngineFlag.isPixelSnapped;
}

/// Returns true if the drawing is done in a pixel perfect way.
extern(C)
bool isPixelPerfect() {
    return cast(bool) (engineState.flags & EngineFlag.isPixelPerfect);
}

/// Sets whether drawing should be done in a pixel-perfect way.
extern(C)
void setIsPixelPerfect(bool value) {
    engineState.flags = value
        ? engineState.flags | EngineFlag.isPixelPerfect
        : engineState.flags & ~EngineFlag.isPixelPerfect;
}

/// Returns true if drawing is done when an empty texture is used.
extern(C)
bool isEmptyTextureVisible() {
    return cast(bool) (engineState.flags & EngineFlag.isEmptyTextureVisible);
}

/// Sets whether drawing should be done when an empty texture is used.
extern(C)
void setIsEmptyTextureVisible(bool value) {
    engineState.flags = value
        ? engineState.flags | EngineFlag.isEmptyTextureVisible
        : engineState.flags & ~EngineFlag.isEmptyTextureVisible;
}

/// Returns true if drawing is done when an empty font is used.
extern(C)
bool isEmptyFontVisible() {
    return cast(bool) (engineState.flags & EngineFlag.isEmptyFontVisible);
}

/// Sets whether drawing should be done when an empty font is used.
extern(C)
void setIsEmptyFontVisible(bool value) {
    engineState.flags = value
        ? engineState.flags | EngineFlag.isEmptyFontVisible
        : engineState.flags & ~EngineFlag.isEmptyFontVisible;
}

/// Returns true if the application is currently in fullscreen mode.
// NOTE: There is a conflict between the flag and real-window-state, which could potentially cause issues for some users.
extern(C)
bool isFullscreen() {
    return cast(bool) (engineState.flags & EngineFlag.isFullscreen);
}

/// Sets whether the application should be in fullscreen mode.
// NOTE: This function introduces a slight delay to prevent some bugs observed on Linux. See the `updateWindow` function.
extern(C)
void setIsFullscreen(bool value) {
    version(WebAssembly) {
    } else {
        if (value == isFullscreen || engineState.fullscreenState.isChanging) return;
        engineState.flags = value
            ? engineState.flags | EngineFlag.isFullscreen
            : engineState.flags & ~EngineFlag.isFullscreen;
        if (value) {
            engineState.fullscreenState.previousWindowWidth = rl.GetScreenWidth();
            engineState.fullscreenState.previousWindowHeight = rl.GetScreenHeight();
            rl.SetWindowPosition(0, 0);
            rl.SetWindowSize(screenWidth, screenHeight);
        }
        engineState.fullscreenState.changeTime = 0.0f;
        engineState.fullscreenState.isChanging = true;
    }
}

/// Toggles the fullscreen mode on or off.
extern(C)
void toggleIsFullscreen() {
    setIsFullscreen(!isFullscreen);
}

/// Returns true if the cursor is currently visible.
extern(C)
bool isCursorVisible() {
    return cast(bool) (engineState.flags & EngineFlag.isCursorVisible);
}

/// Sets whether the cursor should be visible or hidden.
extern(C)
void setIsCursorVisible(bool value) {
    engineState.flags = value
        ? engineState.flags | EngineFlag.isCursorVisible
        : engineState.flags & ~EngineFlag.isCursorVisible;
    if (value) rl.ShowCursor();
    else rl.HideCursor();
}

/// Toggles the visibility of the cursor.
extern(C)
void toggleIsCursorVisible() {
    setIsCursorVisible(!isCursorVisible);
}

/// Returns true if the windows was resized.
extern(C)
bool isWindowResized() {
    return rl.IsWindowResized();
}

/// Sets the background color to the specified value.
extern(C)
void setBackgroundColor(Rgba value) {
    engineState.viewport.data.color = value;
}

/// Sets the border color to the specified value.
extern(C)
void setBorderColor(Rgba value) {
    engineState.borderColor = value;
}

/// Sets the minimum size of the window to the specified value.
extern(C)
void setWindowMinSize(int width, int height) {
    rl.SetWindowMinSize(width, height);
}

/// Sets the maximum size of the window to the specified value.
extern(C)
void setWindowMaxSize(int width, int height) {
    rl.SetWindowMaxSize(width, height);
}

/// Sets the window icon to the specified image that will be loaded from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
extern(C)
Fault setWindowIconFromFiles(IStr path) {
    auto targetPath = isUsingAssetsPath ? path.toAssetsPath() : path;
    auto image = rl.LoadImage(targetPath.toCStr().getOr());
    if (image.data == null) return Fault.cantFind;
    rl.SetWindowIcon(image);
    rl.UnloadImage(image);
    return Fault.none;
}

/// Returns information about the engine viewport, including its area.
extern(C)
EngineViewportInfo engineViewportInfo(bool isRecalculationForced = false) {
    auto result = &engineState.viewportInfoBuffer;
    if (!isRecalculationForced && !isWindowResized) return *result;
    if (isResolutionLocked) {
        result.minSize = resolution;
        result.maxSize = windowSize;
        auto ratio = result.maxSize / result.minSize;
        result.minRatio = min(ratio.x, ratio.y);
        if (isPixelPerfect) {
            auto roundMinRatio = result.minRatio.round();
            auto floorMinRation = result.minRatio.floor();
            result.minRatio = result.minRatio.fequals(roundMinRatio, 0.015f) ? roundMinRatio : floorMinRation;
        }
        auto targetSize = result.minSize * Vec2(result.minRatio);
        auto targetPosition = result.maxSize * Vec2(0.5f) - targetSize * Vec2(0.5f);
        result.area = Rect(
            targetPosition.floor(),
            ratio.x == result.minRatio ? targetSize.x : floor(targetSize.x),
            ratio.y == result.minRatio ? targetSize.y : floor(targetSize.y),
        );
    } else {
        result.minSize = windowSize;
        result.maxSize = result.minSize;
        result.minRatio = 1.0f;
        result.area = Rect(result.minSize);
    }
    return *result;
}

/// Returns the default filter mode.
extern(C)
Filter defaultFilter() {
    return engineState.defaultFilter;
}

/// Returns the default wrap mode.
extern(C)
Wrap defaultWrap() {
    return engineState.defaultWrap;
}

/// Sets the default filter mode to the specified value.
extern(C)
void setDefaultFilter(Filter value) {
    engineState.defaultFilter = value;
}

/// Sets the default wrap mode to the specified value.
extern(C)
void setDefaultWrap(Wrap value) {
    engineState.defaultWrap = value;
}

/// Returns the current master volume level.
extern(C)
float masterVolume() {
    return rl.GetMasterVolume();
}

/// Sets the master volume level to the specified value.
extern(C)
void setMasterVolume(float value) {
    rl.SetMasterVolume(value);
}

/// Returns true if the resolution is locked and cannot be changed.
extern(C)
bool isResolutionLocked() {
    return !engineState.viewport.data.isEmpty;
}

/// Locks the resolution to the specified width and height.
extern(C)
void lockResolution(int width, int height) {
    engineState.viewport.lockWidth = width;
    engineState.viewport.lockHeight = height;
    if (engineState.flags & EngineFlag.isUpdating) {
        engineState.viewport.isChanging = true;
        engineState.viewport.isLocking = true;
    } else {
        engineState.viewport.data.resize(width, height);
        engineViewportInfo(true);
    }
}

/// Unlocks the resolution, allowing it to be changed.
extern(C)
void unlockResolution() {
    if (engineState.flags & EngineFlag.isUpdating) {
        engineState.viewport.isChanging = true;
        engineState.viewport.isLocking = false;
    } else {
        auto temp = engineState.viewport.data.color;
        engineState.viewport.data.free();
        engineState.viewport.data.color = temp;
    }
}

/// Toggles between the current resolution and the specified width and height.
extern(C)
void toggleResolution(int width, int height) {
    if (isResolutionLocked) unlockResolution();
    else lockResolution(width, height);
}

/// Returns the current screen width.
extern(C)
int screenWidth() {
    return rl.GetMonitorWidth(rl.GetCurrentMonitor());
}

/// Returns the current screen height.
extern(C)
int screenHeight() {
    return rl.GetMonitorHeight(rl.GetCurrentMonitor());
}

/// Returns the current screen size.
extern(C)
Vec2 screenSize() {
    return Vec2(screenWidth, screenHeight);
}

/// Returns the current window width.
extern(C)
int windowWidth() {
    if (isFullscreen) return screenWidth;
    else return rl.GetScreenWidth();
}

/// Returns the current window height.
extern(C)
int windowHeight() {
    if (isFullscreen) return screenHeight;
    else return rl.GetScreenHeight();
}

/// Returns the current window size.
extern(C)
Vec2 windowSize() {
    return Vec2(windowWidth, windowHeight);
}

/// Returns the current resolution width.
extern(C)
int resolutionWidth() {
    if (isResolutionLocked) return engineState.viewport.data.width;
    else return windowWidth;
}

/// Returns the current resolution height.
extern(C)
int resolutionHeight() {
    if (isResolutionLocked) return engineState.viewport.data.height;
    else return windowHeight;
}

/// Returns the current resolution size.
extern(C)
Vec2 resolution() {
    return Vec2(resolutionWidth, resolutionHeight);
}

/// Returns the current position of the mouse on the screen.
pragma(inline, true)
extern(C)
Vec2 mouse() {
    return engineState.mouseBuffer;
}

/// Returns the current frames per second (FPS).
extern(C)
int fps() {
    return rl.GetFPS();
}

/// Returns the total elapsed time since the application started.
extern(C)
double elapsedTime() {
    return rl.GetTime();
}

/// Returns the total number of ticks elapsed since the application started.
extern(C)
long elapsedTickCount() {
    return engineState.tickCount;
}

/// Returns the time elapsed since the last frame.
extern(C)
float deltaTime() {
    return rl.GetFrameTime();
}

/// Returns the change in mouse position since the last frame.
extern(C)
Vec2 deltaMouse() {
    return rl.GetMouseDelta().toParin();
}

/// Returns the change in mouse wheel position since the last frame.
extern(C)
float deltaWheel() {
    auto result = 0.0f;
    version (WebAssembly) {
        result = -rl.GetMouseWheelMove();
    } version (OSX) {
        result = -rl.GetMouseWheelMove();
    } else {
        result = rl.GetMouseWheelMove();
    }
    if (result < 0.0f) result = -1.0f;
    else if (result > 0.0f) result = 1.0f;
    else result = 0.0f;
    return result;
}

/// Measures the size of the specified text when rendered with the given font and draw options.
extern(C)
Vec2 measureTextSizeX(Font font, IStr text, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    if (font.isEmpty || text.length == 0) return Vec2();

    auto lineCodepointCount = 0;
    auto lineMaxCodepointCount = 0;
    auto textWidth = 0;
    auto textMaxWidth = 0;
    auto textHeight = font.size;
    auto textCodepointIndex = 0;
    while (textCodepointIndex < text.length) {
        lineCodepointCount += 1;
        auto codepointByteCount = 0;
        auto codepoint = rl.GetCodepointNext(&text[textCodepointIndex], &codepointByteCount);
        auto glyphIndex = rl.GetGlyphIndex(font.data, codepoint);
        if (codepoint != '\n') {
            if (font.data.glyphs[glyphIndex].advanceX) {
                textWidth += font.data.glyphs[glyphIndex].advanceX + font.runeSpacing;
            } else {
                textWidth += cast(int) (font.data.recs[glyphIndex].width + font.data.glyphs[glyphIndex].offsetX + font.runeSpacing);
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

/// Measures the size of the specified text when rendered with the given font and draw options.
extern(C)
Vec2 measureTextSize(FontId font, IStr text, DrawOptions options = DrawOptions()) {
    return measureTextSizeX(font.getOr(), text, options);
}

/// Returns true if the specified key is currently pressed.
bool isDown(char key) {
    return rl.IsKeyDown(toUpper(key));
}

/// Returns true if the specified key is currently pressed.
extern(C)
bool isDownChar(char key) {
    return isDown(key);
}

/// Returns true if the specified key is currently pressed.
bool isDown(Keyboard key) {
    if (key == Keyboard.shift) {
        return rl.IsKeyDown(key) || rl.IsKeyDown(rl.KEY_RIGHT_SHIFT);
    } else if (key == Keyboard.ctrl) {
        return rl.IsKeyDown(key) || rl.IsKeyDown(rl.KEY_RIGHT_CONTROL);
    } else if (key == Keyboard.alt) {
        return rl.IsKeyDown(key) || rl.IsKeyDown(rl.KEY_RIGHT_ALT);
    } else {
        return rl.IsKeyDown(key);
    }
}

/// Returns true if the specified key is currently pressed.
extern(C)
bool isDownKeyboard(Keyboard key) {
    return isDown(key);
}

/// Returns true if the specified key is currently pressed.
bool isDown(Mouse key) {
    if (key) return rl.IsMouseButtonDown(key - 1);
    else return false;
}


/// Returns true if the specified key is currently pressed.
extern(C)
bool isDownMouse(Mouse key) {
    return isDown(key);
}

/// Returns true if the specified key is currently pressed.
bool isDown(Gamepad key, int id = 0) {
    return rl.IsGamepadButtonDown(id, key);
}

/// Returns true if the specified key is currently pressed.
extern(C)
bool isDownGamepad(Gamepad key, int id = 0) {
    return isDown(key, id);
}

/// Returns true if the specified key was pressed.
bool isPressed(char key) {
    return rl.IsKeyPressed(toUpper(key));
}

/// Returns true if the specified key was pressed.
extern(C)
bool isPressedChar(char key) {
    return isPressed(key);
}

/// Returns true if the specified key was pressed.
bool isPressed(Keyboard key) {
    if (key == Keyboard.shift) {
        return rl.IsKeyPressed(key) || rl.IsKeyPressed(rl.KEY_RIGHT_SHIFT);
    } else if (key == Keyboard.ctrl) {
        return rl.IsKeyPressed(key) || rl.IsKeyPressed(rl.KEY_RIGHT_CONTROL);
    } else if (key == Keyboard.alt) {
        return rl.IsKeyPressed(key) || rl.IsKeyPressed(rl.KEY_RIGHT_ALT);
    } else {
        return rl.IsKeyPressed(key);
    }
}


/// Returns true if the specified key was pressed.
extern(C)
bool isPressedKeyboard(Keyboard key) {
    return isPressed(key);
}

/// Returns true if the specified key was pressed.
bool isPressed(Mouse key) {
    if (key) return rl.IsMouseButtonPressed(key - 1);
    else return false;
}


/// Returns true if the specified key was pressed.
extern(C)
bool isPressedMouse(Mouse key) {
    return isPressed(key);
}

/// Returns true if the specified key was pressed.
bool isPressed(Gamepad key, int id = 0) {
    return rl.IsGamepadButtonPressed(id, key);
}

/// Returns true if the specified key was pressed.
extern(C)
bool isPressedGamepad(Gamepad key, int id = 0) {
    return isPressed(key, id);
}

/// Returns true if the specified key was released.
bool isReleased(char key) {
    return rl.IsKeyReleased(toUpper(key));
}


/// Returns true if the specified key was released.
extern(C)
bool isReleasedChar(char key) {
    return isReleased(key);
}

/// Returns true if the specified key was released.
bool isReleased(Keyboard key) {
    if (key == Keyboard.shift) {
        return rl.IsKeyReleased(key) || rl.IsKeyReleased(rl.KEY_RIGHT_SHIFT);
    } else if (key == Keyboard.ctrl) {
        return rl.IsKeyReleased(key) || rl.IsKeyReleased(rl.KEY_RIGHT_CONTROL);
    } else if (key == Keyboard.alt) {
        return rl.IsKeyReleased(key) || rl.IsKeyReleased(rl.KEY_RIGHT_ALT);
    } else {
        return rl.IsKeyReleased(key);
    }
}

/// Returns true if the specified key was released.
extern(C)
bool isReleasedKeyboard(Keyboard key) {
    return isReleased(key);
}

/// Returns true if the specified key was released.
bool isReleased(Mouse key) {
    if (key) return rl.IsMouseButtonReleased(key - 1);
    else return false;
}

/// Returns true if the specified key was released.
extern(C)
bool isReleasedMouse(Mouse key) {
    return isReleased(key);
}

/// Returns true if the specified key was released.
bool isReleased(Gamepad key, int id = 0) {
    return rl.IsGamepadButtonReleased(id, key);
}

/// Returns true if the specified key was released.
extern(C)
bool isReleasedGamepad(Gamepad key, int id = 0) {
    return isReleased(key);
}

/// Returns the recently pressed keyboard key.
/// This function acts like a queue, meaning that multiple calls will return other recently pressed keys.
/// A none key is returned when the queue is empty.
extern(C)
Keyboard dequeuePressedKey() {
    return cast(Keyboard) rl.GetKeyPressed();
}

/// Returns the recently pressed character.
/// This function acts like a queue, meaning that multiple calls will return other recently pressed characters.
/// A none character is returned when the queue is empty.
extern(C)
dchar dequeuePressedRune() {
    return rl.GetCharPressed();
}

/// Returns the directional input based on the WASD and arrow keys when they are down.
/// The vector is not normalized.
pragma(inline, true)
extern(C)
Vec2 wasd() {
    return engineState.wasdBuffer;
}

/// Returns the directional input based on the WASD and arrow keys when they are pressed.
/// The vector is not normalized.
pragma(inline, true)
extern(C)
Vec2 wasdPressed() {
    return engineState.wasdPressedBuffer;
}

/// Returns the directional input based on the WASD and arrow keys when they are released.
/// The vector is not normalized.
pragma(inline, true)
extern(C)
Vec2 wasdReleased() {
    return engineState.wasdReleasedBuffer;
}

/// Resets the specific sound.
extern(C)
void resetSoundX(ref Sound sound) {
    auto wasPlaying = sound.isPlaying_;
    stopSoundX(sound);
    if (wasPlaying) playSoundX(sound);
}

/// Resets the specific sound.
extern(C)
void resetSound(SoundId sound) {
    if (sound.isValid) resetSoundX(sound.get());
}

/// Plays the specified sound.
extern(C)
void playSoundX(ref Sound sound) {
    if (sound.isEmpty || sound.isPaused || sound.isPlaying_) return;
    sound.isPlaying_ = true;
    if (sound.pitchVariance != 1.0f) {
        sound.setPitch(sound.pitchVarianceBase + (sound.pitchVarianceBase * sound.pitchVariance - sound.pitchVarianceBase) * randf);
    }
    if (sound.data.isType!(rl.Sound)) {
        rl.PlaySound(sound.data.get!(rl.Sound)());
    } else {
        rl.PlayMusicStream(sound.data.get!(rl.Music)());
    }
}

/// Plays the specified sound.
extern(C)
void playSound(SoundId sound) {
    if (sound.isValid) playSoundX(sound.get());
}

/// Stops playback of the specified sound.
extern(C)
void stopSoundX(ref Sound sound) {
    if (sound.isEmpty || sound.isPaused || !sound.isPlaying_) return;
    sound.isPlaying_ = false;
    if (sound.data.isType!(rl.Sound)) {
        rl.StopSound(sound.data.get!(rl.Sound)());
    } else {
        rl.StopMusicStream(sound.data.get!(rl.Music)());
    }
}

/// Stops playback of the specified sound.
extern(C)
void stopSound(SoundId sound) {
    if (sound.isValid) stopSoundX(sound.get());
}

/// Pauses playback of the specified sound.
extern(C)
void pauseSoundX(ref Sound sound) {
    if (sound.isEmpty || !sound.isPaused) return;
    sound.isPaused = true;
    if (sound.data.isType!(rl.Sound)) {
        rl.PauseSound(sound.data.get!(rl.Sound)());
    } else {
        rl.PauseMusicStream(sound.data.get!(rl.Music)());
    }
}

/// Pauses playback of the specified sound.
extern(C)
void pauseSound(SoundId sound) {
    if (sound.isValid) pauseSoundX(sound.get());
}

/// Resumes playback of the specified paused sound.
extern(C)
void resumeSoundX(ref Sound sound) {
    if (sound.isEmpty || sound.isPaused) return;
    sound.isPaused = false;
    if (sound.data.isType!(rl.Sound)) {
        rl.ResumeSound(sound.data.get!(rl.Sound)());
    } else {
        rl.ResumeMusicStream(sound.data.get!(rl.Music)());
    }
}

/// Resumes playback of the specified paused sound.
extern(C)
void resumeSound(SoundId sound) {
    if (sound.isValid) resumeSoundX(sound.get());
}

/// Updates the playback state of the specified sound.
extern(C)
void updateSoundX(ref Sound sound) {
    if (sound.isEmpty || sound.isPaused || !sound.isPlaying_) return;
    if (sound.data.isType!(rl.Sound)) {
        if (rl.IsSoundPlaying(sound.data.get!(rl.Sound)())) return;
        sound.isPlaying_ = false;
        if (sound.canRepeat) playSoundX(sound);
    } else {
        auto isPlayingInternally = rl.IsMusicStreamPlaying(sound.data.get!(rl.Music)());
        auto hasLoopedInternally = sound.duration - sound.time < 0.1f;
        if (hasLoopedInternally) {
            if (sound.canRepeat) {
                // Copy-paste from `playSound`. Maybe make that a function.
                if (sound.pitchVariance != 1.0f) {
                    sound.setPitch(sound.pitchVarianceBase + (sound.pitchVarianceBase * sound.pitchVariance - sound.pitchVarianceBase) * randf);
                }
            } else {
                stopSoundX(sound);
                isPlayingInternally = false;
            }
        }
        if (isPlayingInternally) rl.UpdateMusicStream(sound.data.get!(rl.Music)());
    }
}

/// This function does nothing because managed resources are updated by the engine.
/// It only exists to make it easier to swap between resource types.
extern(C)
void updateSound(SoundId sound) {
    // if (sound.isValid) updateSoundX(sound.get());
}

/// Draws a rectangle with the specified area and color.
extern(C)
void drawRect(Rect area, Rgba color = white) {
    if (isPixelSnapped) {
        rl.DrawRectanglePro(area.floor().toRl(), rl.Vector2(0.0f, 0.0f), 0.0f, color.toRl());
    } else {
        rl.DrawRectanglePro(area.toRl(), rl.Vector2(0.0f, 0.0f), 0.0f, color.toRl());
    }
}

/// Draws a hollow rectangle with the specified area and color.
extern(C)
void drawHollowRect(Rect area, float thickness, Rgba color = white) {
    if (isPixelSnapped) {
        rl.DrawRectangleLinesEx(area.floor().toRl(), thickness, color.toRl());
    } else {
        rl.DrawRectangleLinesEx(area.toRl(), thickness, color.toRl());
    }
}

/// Draws a point at the specified location with the given size and color.
extern(C)
void drawVec2(Vec2 point, float size, Rgba color = white) {
    drawRect(Rect(point, size, size).centerArea, color);
}

/// Draws a circle with the specified area and color.
extern(C)
void drawCirc(Circ area, Rgba color = white) {
    if (isPixelSnapped) {
        rl.DrawCircleV(area.position.floor().toRl(), area.radius, color.toRl());
    } else {
        rl.DrawCircleV(area.position.toRl(), area.radius, color.toRl());
    }
}

/// Draws a hollow circle with the specified area and color.
extern(C)
void drawHollowCirc(Circ area, float thickness, Rgba color = white) {
    if (isPixelSnapped) {
        rl.DrawRing(area.position.floor().toRl(), area.radius - thickness, area.radius, 0.0f, 360.0f, 30, color.toRl());
    } else {
        rl.DrawRing(area.position.toRl(), area.radius - thickness, area.radius, 0.0f, 360.0f, 30, color.toRl());
    }
}

/// Draws a line with the specified area, thickness, and color.
extern(C)
void drawLine(Line area, float size, Rgba color = white) {
    if (isPixelSnapped) {
        rl.DrawLineEx(area.a.floor().toRl(), area.b.floor().toRl(), size, color.toRl());
    } else {
        rl.DrawLineEx(area.a.toRl(), area.b.toRl(), size, color.toRl());
    }
}

/// Draws a portion of the specified texture at the given position with the specified draw options.
extern(C)
void drawTextureAreaX(Texture texture, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    if (texture.isEmpty) {
        if (area.size.x <= 0.0f || area.size.y <= 0.0f) area.size = Vec2(64);
        if (isEmptyTextureVisible) {
            auto rect = Rect(position, area.size * options.scale).area(options.hook);
            drawRect(rect, defaultEngineEmptyTextureColor);
            drawHollowRect(rect, 1, black);
        }
        return;
    } else {
        if (area.size.x <= 0.0f || area.size.y <= 0.0f) return;
    }

    auto target = Rect(position, area.size * options.scale.abs());
    auto origin = options.origin.isZero ? target.origin(options.hook) : options.origin;
    auto flip = options.flip;
    if (options.scale.x < 0.0f && options.scale.y < 0.0f) {
        flip = oppositeFlip(flip, Flip.xy);
    } else if (options.scale.x < 0.0f) {
        flip = oppositeFlip(flip, Flip.x);
    } else if (options.scale.y < 0.0f) {
        flip = oppositeFlip(flip, Flip.y);
    }
    final switch (flip) {
        case Flip.none: break;
        case Flip.x: area.size.x *= -1.0f; break;
        case Flip.y: area.size.y *= -1.0f; break;
        case Flip.xy: area.size *= Vec2(-1.0f); break;
    }
    if (isPixelSnapped) {
        rl.DrawTexturePro(
            texture.data,
            area.floor().toRl(),
            target.floor().toRl(),
            origin.floor().toRl(),
            options.rotation,
            options.color.toRl(),
        );
    } else {
        rl.DrawTexturePro(
            texture.data,
            area.toRl(),
            target.toRl(),
            origin.toRl(),
            options.rotation,
            options.color.toRl(),
        );
    }
}

/// Draws a portion of the specified texture at the given position with the specified draw options.
extern(C)
void drawTextureArea(TextureId texture, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTextureAreaX(texture.getOr(), area, position, options);
}

/// Draws the texture at the given position with the specified draw options.
extern(C)
void drawTextureX(Texture texture, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTextureAreaX(texture, Rect(texture.size), position, options);
}

/// Draws the texture at the given position with the specified draw options.
extern(C)
void drawTexture(TextureId texture, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTextureX(texture.getOr(), position, options);
}

/// Draws a 9-patch texture from the specified texture area at the given target area.
extern(C)
void drawTexturePatchX(Texture texture, Rect area, Rect target, bool isTiled, DrawOptions options = DrawOptions()) {
    if (texture.isEmpty) {
        if (isEmptyTextureVisible) {
            auto rect = target.area(options.hook);
            drawRect(rect, defaultEngineEmptyTextureColor);
            drawHollowRect(rect, 1, black);
        }
        return;
    }

    auto tileSize = (area.size / Vec2(3.0f)).floor();
    auto hOptions = options;
    auto vOptions = options;
    auto cOptions = options;
    auto cleanScaleX = (target.size.x - 2.0f * tileSize.x) / tileSize.x;
    auto cleanScaleY = (target.size.y - 2.0f * tileSize.y) / tileSize.y;
    hOptions.scale.x *= cleanScaleX;
    vOptions.scale.y *= cleanScaleY;
    cOptions.scale = Vec2(hOptions.scale.x, vOptions.scale.y);
    // 1
    auto partPosition = target.position;
    auto partArea = Rect(area.position, tileSize);
    drawTextureAreaX(texture, partArea, partPosition, options);
    // 2
    partPosition.x += tileSize.x * options.scale.x;
    partArea.position.x += tileSize.x;
    if (isTiled) {
        foreach (i; 0 .. cast(int) cleanScaleX.ceil()) {
            auto tempPartPosition = partPosition;
            tempPartPosition.x += i * tileSize.x * options.scale.x;
            drawTextureAreaX(texture, partArea, tempPartPosition, options);
        }
    } else {
        drawTextureAreaX(texture, partArea, partPosition, hOptions);
    }
    // 3
    partPosition.x += tileSize.x * hOptions.scale.x;
    partArea.position.x += tileSize.x;
    drawTextureAreaX(texture, partArea, partPosition, options);
    // 4
    partPosition.x = target.position.x;
    partPosition.y += tileSize.y * options.scale.y;
    partArea.position.x = area.position.x;
    partArea.position.y += tileSize.y;
    if (isTiled) {
        foreach (i; 0 .. cast(int) cleanScaleY.ceil()) {
            auto tempPartPosition = partPosition;
            tempPartPosition.y += i * tileSize.y * options.scale.y;
            drawTextureAreaX(texture, partArea, tempPartPosition, options);
        }
    } else {
        drawTextureAreaX(texture, partArea, partPosition, vOptions);
    }
    // 5
    partPosition.x += tileSize.x * options.scale.x;
    partArea.position.x += tileSize.x;
    drawTextureAreaX(texture, partArea, partPosition, cOptions);
    // 6
    partPosition.x += tileSize.x * hOptions.scale.x;
    partArea.position.x += tileSize.x;
    if (isTiled) {
        foreach (i; 0 .. cast(int) cleanScaleY.ceil()) {
            auto tempPartPosition = partPosition;
            tempPartPosition.y += i * tileSize.y * options.scale.y;
            drawTextureAreaX(texture, partArea, tempPartPosition, options);
        }
    } else {
        drawTextureAreaX(texture, partArea, partPosition, vOptions);
    }
    // 7
    partPosition.x = target.position.x;
    partPosition.y += tileSize.y * vOptions.scale.y;
    partArea.position.x = area.position.x;
    partArea.position.y += tileSize.y;
    drawTextureAreaX(texture, partArea, partPosition, options);
    // 8
    partPosition.x += tileSize.x * options.scale.x;
    partArea.position.x += tileSize.x;
    if (isTiled) {
        foreach (i; 0 .. cast(int) cleanScaleX.ceil()) {
            auto tempPartPosition = partPosition;
            tempPartPosition.x += i * tileSize.x * options.scale.x;
            drawTextureAreaX(texture, partArea, tempPartPosition, options);
        }
    } else {
        drawTextureAreaX(texture, partArea, partPosition, hOptions);
    }
    // 9
    partPosition.x += tileSize.x * hOptions.scale.x;
    partArea.position.x += tileSize.x;
    drawTextureAreaX(texture, partArea, partPosition, options);
}

/// Draws a 9-patch texture from the specified texture area at the given target area.
extern(C)
void drawTexturePatch(TextureId texture, Rect area, Rect target, bool isTiled, DrawOptions options = DrawOptions()) {
    drawTexturePatchX(texture.getOr(), area, target, isTiled, options);
}

/// Draws a portion of the specified viewport at the given position with the specified draw options.
extern(C)
void drawViewportArea(Viewport viewport, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    // Some basic rules to make viewports noob friendly.
    final switch (options.flip) {
        case Flip.none: options.flip = Flip.y; break;
        case Flip.x: options.flip = Flip.xy; break;
        case Flip.y: options.flip = Flip.none; break;
        case Flip.xy: options.flip = Flip.x; break;
    }
    drawTextureAreaX(viewport.data.texture.toParin(), area, position, options);
}

/// Draws the viewport at the given position with the specified draw options.
extern(C)
void drawViewport(Viewport viewport, Vec2 position, DrawOptions options = DrawOptions()) {
    drawViewportArea(viewport, Rect(viewport.size), position, options);
}

/// Draws a single character from the specified font at the given position with the specified draw options.
extern(C)
void drawRuneX(Font font, dchar rune, Vec2 position, DrawOptions options = DrawOptions()) {
    if (font.isEmpty) return;
    auto rect = toParin(rl.GetGlyphAtlasRec(font.data, rune));
    auto origin = options.origin.isZero ? rect.origin(options.hook) : options.origin;
    rl.rlPushMatrix();
    if (isPixelSnapped) {
        rl.rlTranslatef(position.x.floor(), position.y.floor(), 0.0f);
    } else {
        rl.rlTranslatef(position.x, position.y, 0.0f);
    }
    rl.rlRotatef(options.rotation, 0.0f, 0.0f, 1.0f);
    rl.rlScalef(options.scale.x, options.scale.y, 1.0f);
    rl.rlTranslatef(-origin.x.floor(), -origin.y.floor(), 0.0f);
    rl.DrawTextCodepoint(font.data, rune, rl.Vector2(0.0f, 0.0f), font.size, options.color.toRl());
    rl.rlPopMatrix();
}

/// Draws a single character from the specified font at the given position with the specified draw options.
extern(C)
void drawRune(FontId font, dchar rune, Vec2 position, DrawOptions options = DrawOptions()) {
    drawRuneX(font.getOr(), rune, position, options);
}

/// Draws the specified text with the given font at the given position using the provided draw options.
// NOTE: Text drawing needs to go over the text 3 times. This can be made into 2 times in the future if needed by copy-pasting the measureTextSize inside this function.
extern(C)
void drawTextX(Font font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    static FixedList!(IStr, 128) linesBuffer = void;
    static FixedList!(short, 128) linesWidthBuffer = void;

    if (text.length == 0) return;
    if (font.isEmpty) {
        if (isEmptyFontVisible) font = engineFont.get();
        else return;
    }
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
                linesWidthBuffer.append(cast(ushort) (measureTextSizeX(font, linesBuffer[$ - 1]).x));
                if (textMaxLineWidth < linesWidthBuffer[$ - 1]) textMaxLineWidth = linesWidthBuffer[$ - 1];
                if (codepoint == '\n') textHeight += font.lineSpacing;
                lineCodepointIndex = cast(ushort) (textCodepointIndex + 1);
            }
            textCodepointIndex += codepointSize;
        }
        if (textMaxLineWidth < extra.alignmentWidth) textMaxLineWidth = extra.alignmentWidth;
    }

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
                auto glyphIndex = rl.GetGlyphIndex(font.data, codepoint);
                if (lineCodepointIndex == line.length) {
                    if (font.data.glyphs[glyphIndex].advanceX) {
                        textOffsetX -= font.data.glyphs[glyphIndex].advanceX + font.runeSpacing;
                    } else {
                        textOffsetX -= cast(int) (font.data.recs[glyphIndex].width + font.runeSpacing);
                    }
                } else {
                    auto temp = 0;
                    auto nextRightToLeftGlyphIndex = rl.GetGlyphIndex(font.data, rl.GetCodepointPrevious(&line[lineCodepointIndex], &temp));
                    if (font.data.glyphs[nextRightToLeftGlyphIndex].advanceX) {
                        textOffsetX -= font.data.glyphs[nextRightToLeftGlyphIndex].advanceX + font.runeSpacing;
                    } else {
                        textOffsetX -= cast(int) (font.data.recs[nextRightToLeftGlyphIndex].width + font.runeSpacing);
                    }
                }
                if (codepoint != ' ' && codepoint != '\t') {
                    rl.DrawTextCodepoint(font.data, codepoint, rl.Vector2(textOffsetX, textOffsetY), font.size, options.color.toRl());
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
                auto glyphIndex = rl.GetGlyphIndex(font.data, codepoint);
                if (codepoint != ' ' && codepoint != '\t') {
                    rl.DrawTextCodepoint(font.data, codepoint, rl.Vector2(textOffsetX, textOffsetY), font.size, options.color.toRl());
                }
                if (font.data.glyphs[glyphIndex].advanceX) {
                    textOffsetX += font.data.glyphs[glyphIndex].advanceX + font.runeSpacing;
                } else {
                    textOffsetX += cast(int) (font.data.recs[glyphIndex].width + font.runeSpacing);
                }
                drawCodepointCounter += 1;
                lineCodepointIndex += codepointSize;
            }
            drawCodepointCounter += 1;
            textOffsetY += font.lineSpacing;
        }
    }
    rl.rlPopMatrix();
}

/// Draws text with the given font at the given position using the provided draw options.
extern(C)
void drawText(FontId font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    drawTextX(font.getOr(), text, position, options, extra);
}

/// Draws debug text at the given position with the provided draw options.
extern(C)
void drawDebugText(IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    drawText(engineFont, text, position, options, extra);
}

/// Draws debug engine information at the given position with the provided draw options.
/// Hold the left mouse button down to... TODO.
/// Hold the right mouse button down to... TODO.
/// Press the middle mouse button to... TODO.
extern(C)
void drawDebugEngineInfo(Vec2 position, DrawOptions options = DrawOptions()) {
    static clickPoint = Vec2();
    static clickOffset = Vec2();
    static a = Vec2();
    static b = Vec2();
    static s = Vec2();

    auto text = "OwO".fmt();
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
        text = "FPS: {}\nMouse: A({} {}) B({} {}) S({} {})\nAssets: (T{} F{} S{})".fmt(
            fps,
            cast(int) a.x,
            cast(int) a.y,
            cast(int) b.x,
            cast(int) b.y,
            cast(int) s.x,
            cast(int) s.y,
            engineState.textures.length,
            engineState.fonts.length - 1,
            engineState.sounds.length,
        );
    } else {
        text = "FPS: {}\nMouse: ({} {})\nAssets: (T{} F{} S{})".fmt(
            fps,
            cast(int) mouse.x,
            cast(int) mouse.y,
            engineState.textures.length,
            engineState.fonts.length - 1,
            engineState.sounds.length,
        );
    }
    drawRect(Rect(a, s), white.alpha(130));
    drawHollowRect(Rect(a, s), 1, gray.alpha(130));
    drawDebugText(text, position, options);
    debug {
        if (Mouse.left.isReleased || Mouse.right.isReleased) {
            printfln(
                "Debug Engine Info\n A: Vec2({}, {})\n B: Vec2({}, {})\n S: Vec2({}, {})\n",
                cast(int) a.x,
                cast(int) a.y,
                cast(int) b.x,
                cast(int) b.y,
                cast(int) s.x,
                cast(int) s.y,
            );
        }
    }
}

/// Mixes in a game loop template with specified functions for initialization, update, and cleanup, and sets window size and title.
mixin template runGame(alias readyFunc, alias updateFunc, alias finishFunc, int width = 960, int height = 540, IStr title = "Parin") {
    version (D_BetterC) {
        extern(C)
        int main(int argc, const(char)** argv) {
            alias f = extern(C) bool function(float dt);
            openWindowC(width, height, argc, argv, title);
            readyFunc();
            updateWindow(cast(f) &updateFunc);
            finishFunc();
            closeWindow();
            return 0;
        }
    } else {
        void main(immutable(char)[][] args) {
            alias f = extern(C) bool function(float dt);
            openWindow(width, height, args, title);
            readyFunc();
            updateWindow(cast(f) &updateFunc);
            finishFunc();
            closeWindow();
        }
    }
}
