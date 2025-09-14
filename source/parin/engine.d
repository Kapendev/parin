// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `engine` module functions as a lightweight 2D game engine.
module parin.engine;

version (ParinSkipDrawChecks) {
    pragma(msg, "Parin: Draw checks disabled. Invalid values may crash your game.");
}

import rl = parin.rl;

import joka.ascii;
import joka.io;
import joka.memory;
import parin.c.engine; // Don't ask.

public import joka.containers;
public import joka.math;
public import joka.types;

version (WebAssembly) {
    import em = parin.em;
}

__gshared EngineState* _engineState;

alias EngineUpdateFunc = bool function(float dt);
alias EngineFunc       = void function();
alias EngineFlags      = uint;

@trusted:

// ---------- Config
enum defaultEngineTitle        = "Parin";
enum defaultEngineWidth        = 960;
enum defaultEngineHeight       = 540;
enum defaultEngineFpsMax       = 60;
enum defaultEngineVsync        = true;
enum defaultEngineDebugModeKey = Keyboard.f3;

enum defaultEngineFlags =
    EngineFlag.isUsingAssetsPath |
    EngineFlag.isEmptyTextureVisible |
    EngineFlag.isEmptyFontVisible |
    EngineFlag.isLoggingLoadSaveFaults |
    EngineFlag.isLoggingMemoryTrackingInfo;

enum defaultEngineValidateErrorMessage = "Resource is invalid or was never assigned.";
enum defaultEngineLoadErrorMessage     = "Could not load file: \"{}\"";
enum defaultEngineSaveErrorMessage     = "Could not save file: \"{}\"";
enum defaultEngineTexturesCapacity     = 128;
enum defaultEngineSoundsCapacity       = 128;
enum defaultEngineFontsCapacity        = 16;
enum defaultEngineTasksCapacity        = 64;
enum defaultEngineArenaCapacity        = 32 * kilobyte;

enum defaultEngineEmptyTextureColor = white;
enum defaultEngineDebugColor1       = black.alpha(140);
enum defaultEngineDebugColor2       = white.alpha(140);
// ----------

/// The default engine font. This font should not be freed.
enum engineFont = FontId(GenIndex(1));

alias _D = DrawOptions; /// Draw options (shorthand for `DrawOptions`).
alias _T = TextOptions; /// Text options (shorthand for `TextOptions`).
alias _C = Camera;      /// Camera (shorthand for `Camera`).
alias _V = Viewport;    /// Viewport (shorthand for `Viewport`).

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
    isLoggingLoadSaveFaults     = 0x000100,
    isLoggingMemoryTrackingInfo = 0x000200,
    isDebugMode                 = 0x000400,
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
    none = rl.KEY_NULL,                  /// Not a key.
    apostrophe = rl.KEY_APOSTROPHE,      /// The `'` key.
    comma = rl.KEY_COMMA,                /// The `,` key.
    minus = rl.KEY_MINUS,                /// The `-` key.
    period = rl.KEY_PERIOD,              /// The `.` key.
    slash = rl.KEY_SLASH,                /// The `/` key.
    n0 = rl.KEY_ZERO,                    /// The 0 key.
    n1 = rl.KEY_ONE,                     /// The 1 key.
    n2 = rl.KEY_TWO,                     /// The 2 key.
    n3 = rl.KEY_THREE,                   /// The 3 key.
    n4 = rl.KEY_FOUR,                    /// The 4 key.
    n5 = rl.KEY_FIVE,                    /// The 5 key.
    n6 = rl.KEY_SIX,                     /// The 6 key.
    n7 = rl.KEY_SEVEN,                   /// The 7 key.
    n8 = rl.KEY_EIGHT,                   /// The 8 key.
    n9 = rl.KEY_NINE,                    /// The 9 key.
    nn0 = rl.KEY_KP_0,                   /// The 0 key on the numpad.
    nn1 = rl.KEY_KP_1,                   /// The 1 key on the numpad.
    nn2 = rl.KEY_KP_2,                   /// The 2 key on the numpad.
    nn3 = rl.KEY_KP_3,                   /// The 3 key on the numpad.
    nn4 = rl.KEY_KP_4,                   /// The 4 key on the numpad.
    nn5 = rl.KEY_KP_5,                   /// The 5 key on the numpad.
    nn6 = rl.KEY_KP_6,                   /// The 6 key on the numpad.
    nn7 = rl.KEY_KP_7,                   /// The 7 key on the numpad.
    nn8 = rl.KEY_KP_8,                   /// The 8 key on the numpad.
    nn9 = rl.KEY_KP_9,                   /// The 9 key on the numpad.
    semicolon = rl.KEY_SEMICOLON,        /// The `;` key.
    equal = rl.KEY_EQUAL,                /// The `=` key.
    a = rl.KEY_A,                        /// The A key.
    b = rl.KEY_B,                        /// The B key.
    c = rl.KEY_C,                        /// The C key.
    d = rl.KEY_D,                        /// The D key.
    e = rl.KEY_E,                        /// The E key.
    f = rl.KEY_F,                        /// The F key.
    g = rl.KEY_G,                        /// The G key.
    h = rl.KEY_H,                        /// The H key.
    i = rl.KEY_I,                        /// The I key.
    j = rl.KEY_J,                        /// The J key.
    k = rl.KEY_K,                        /// The K key.
    l = rl.KEY_L,                        /// The L key.
    m = rl.KEY_M,                        /// The M key.
    n = rl.KEY_N,                        /// The N key.
    o = rl.KEY_O,                        /// The O key.
    p = rl.KEY_P,                        /// The P key.
    q = rl.KEY_Q,                        /// The Q key.
    r = rl.KEY_R,                        /// The R key.
    s = rl.KEY_S,                        /// The S key.
    t = rl.KEY_T,                        /// The T key.
    u = rl.KEY_U,                        /// The U key.
    v = rl.KEY_V,                        /// The V key.
    w = rl.KEY_W,                        /// The W key.
    x = rl.KEY_X,                        /// The X key.
    y = rl.KEY_Y,                        /// The Y key.
    z = rl.KEY_Z,                        /// The Z key.
    bracketLeft = rl.KEY_LEFT_BRACKET,   /// The `[` key.
    bracketRight = rl.KEY_RIGHT_BRACKET, /// The `]` key.
    backslash = rl.KEY_BACKSLASH,        /// The `\` key.
    grave = rl.KEY_GRAVE,                /// The `` ` `` key.
    space = rl.KEY_SPACE,                /// The space key.
    esc = rl.KEY_ESCAPE,                 /// The escape key.
    enter = rl.KEY_ENTER,                /// The enter key.
    tab = rl.KEY_TAB,                    /// The tab key.
    backspace = rl.KEY_BACKSPACE,        /// THe backspace key.
    insert = rl.KEY_INSERT,              /// The insert key.
    del = rl.KEY_DELETE,                 /// The delete key.
    right = rl.KEY_RIGHT,                /// The right arrow key.
    left = rl.KEY_LEFT,                  /// The left arrow key.
    down = rl.KEY_DOWN,                  /// The down arrow key.
    up = rl.KEY_UP,                      /// The up arrow key.
    pageUp = rl.KEY_PAGE_UP,             /// The page up key.
    pageDown = rl.KEY_PAGE_DOWN,         /// The page down key.
    home = rl.KEY_HOME,                  /// The home key.
    end = rl.KEY_END,                    /// The end key.
    capsLock = rl.KEY_CAPS_LOCK,         /// The caps lock key.
    scrollLock = rl.KEY_SCROLL_LOCK,     /// The scroll lock key.
    numLock = rl.KEY_NUM_LOCK,           /// The num lock key.
    printScreen = rl.KEY_PRINT_SCREEN,   /// The print screen key.
    pause = rl.KEY_PAUSE,                /// The pause/break key.
    shift = rl.KEY_LEFT_SHIFT,           /// The left shift key.
    shiftRight = rl.KEY_RIGHT_SHIFT,     /// The right shift key.
    ctrl = rl.KEY_LEFT_CONTROL,          /// The left control key.
    ctrlRight = rl.KEY_RIGHT_CONTROL,    /// The right control key.
    alt = rl.KEY_LEFT_ALT,               /// The left alt key.
    altRight = rl.KEY_RIGHT_ALT,         /// The right alt key.
    win = rl.KEY_LEFT_SUPER,             /// The left windows/super/command key.
    winRight = rl.KEY_RIGHT_SUPER,       /// The right windows/super/command key.
    menu = rl.KEY_KB_MENU,               /// The menu key.
    f1 = rl.KEY_F1,                      /// The f1 key.
    f2 = rl.KEY_F2,                      /// The f2 key.
    f3 = rl.KEY_F3,                      /// The f3 key.
    f4 = rl.KEY_F4,                      /// The f4 key.
    f5 = rl.KEY_F5,                      /// The f5 key.
    f6 = rl.KEY_F6,                      /// The f6 key.
    f7 = rl.KEY_F7,                      /// The f7 key.
    f8 = rl.KEY_F8,                      /// The f8 key.
    f9 = rl.KEY_F9,                      /// The f9 key.
    f10 = rl.KEY_F10,                    /// The f10 key.
    f11 = rl.KEY_F11,                    /// The f11 key.
    f12 = rl.KEY_F12,                    /// The f12 key.
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

/// A set of 4 integer margins.
struct Margin {
    int left;   /// The left side.
    int top;    /// The top side.
    int right;  /// The right side.
    int bottom; /// The bottom side.

    @safe nothrow @nogc:

    this(int left, int top, int right, int bottom) {
        this.left = left;
        this.top = top;
        this.right = right;
        this.bottom = bottom;
    }

    this(int left) {
        this(left, left, left, left);
    }
}

/// A part of a 9-slice.
struct SlicePart {
    IRect source;    /// The source area on the atlas texture.
    IRect target;    /// The target area on the canvas.
    IVec2 tileCount; /// The number of source tiles that fit inside the target.
    bool isCorner;   /// True if the part is a corner.
    bool canTile;    /// True if the part is an edge or the center.

    @safe nothrow @nogc:

    IStr toStr() {
        return "x={{}:{}} y={{}:{}} w={{}:{}} h={{}:{}}".fmt(
            source.position.x,
            target.position.x,
            source.position.y,
            target.position.y,
            source.size.x,
            target.size.x,
            source.size.y,
            target.size.y,
        );
    }

    IStr toString() {
        return toStr();
    }
}

/// The parts of a 9-slice.
alias SliceParts = Array!(SlicePart, 9);

/// Options for configuring drawing parameters.
struct DrawOptions {
    Vec2 origin    = Vec2(0.0f);   /// The origin point of the drawn object. This value can be used to force a specific origin.
    Vec2 scale     = Vec2(1.0f);   /// The scale of the drawn object.
    float rotation = 0.0f;         /// The rotation of the drawn object, in degrees.
    Rgba color     = white;        /// The color of the drawn object, in RGBA.
    Hook hook      = Hook.topLeft; /// A value representing the origin point of the drawn object when origin is zero.
    Flip flip      = Flip.none;    /// A value representing flipping orientations.

    @trusted nothrow @nogc:

    /// Initializes the options with the given rotation.
    this(float rotation, Hook hook = Hook.topLeft) {
        this.rotation = rotation;
        this.hook = hook;
    }

    /// Initializes the options with the given scale.
    this(Vec2 scale, Hook hook = Hook.topLeft) {
        this.scale = scale;
        this.hook = hook;
    }

    /// Initializes the options with the given color.
    this(Rgba color, Hook hook = Hook.topLeft) {
        this.color = color;
        this.hook = hook;
    }

    /// Initializes the options with the given flip.
    this(Flip flip, Hook hook = Hook.topLeft) {
        this.flip = flip;
        this.hook = hook;
    }

    /// Initializes the options with the given hook.
    this(Hook hook) {
        this.hook = hook;
    }
}

/// Options for configuring extra drawing parameters for text.
struct TextOptions {
    float visibilityRatio  = 1.0f;           /// Controls the visibility ratio of the text when visibilityCount is zero, where 0.0 means fully hidden and 1.0 means fully visible.
    int alignmentWidth     = 0;              /// The width of the aligned text. It is used as a hint and is not enforced.
    ushort visibilityCount = 0;              /// Controls the visibility count of the text. This value can be used to force a specific character count.
    Alignment alignment    = Alignment.left; /// A value represeting alignment orientations.
    bool isRightToLeft     = false;          /// Indicates whether the content of the text flows in a right-to-left direction.

    @trusted nothrow @nogc:

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

    @trusted nothrow @nogc:

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
/// To free these resources, use the `freeManagedEngineResources` function or the `free` method on the identifier.
/// The identifier is automatically invalidated when the resource is freed.
struct TextureId {
    GenIndex data;

    @trusted nothrow @nogc:

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
        return data.value && _engineState.textures.has(GenIndex(data.value - 1, data.generation));
    }

    /// Checks if the resource identifier is valid and asserts if it is not.
    TextureId validate(IStr message = defaultEngineValidateErrorMessage) {
        if (!isValid) assert(0, message);
        return this;
    }

    /// Retrieves the texture associated with the resource identifier.
    ref Texture get() {
        if (!isValid) assert(0, defaultEngineValidateErrorMessage);
        return _engineState.textures[GenIndex(data.value - 1, data.generation)];
    }

    /// Retrieves the texture associated with the resource identifier or returns a default value if invalid.
    Texture getOr() {
        return isValid ? _engineState.textures[GenIndex(data.value - 1, data.generation)] : Texture();
    }

    /// Frees the resource associated with the identifier.
    void free() {
        if (isValid) _engineState.textures.remove(GenIndex(data.value - 1, data.generation));
    }
}

/// A font resource.
struct Font {
    rl.Font data;
    int runeSpacing; /// The spacing between individual characters.
    int lineSpacing; /// The spacing between lines of text.

    @trusted nothrow @nogc:

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
/// To free these resources, use the `freeManagedEngineResources` function or the `free` method on the identifier.
/// The identifier is automatically invalidated when the resource is freed.
struct FontId {
    GenIndex data;

    @trusted nothrow @nogc:

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
        return data.value && _engineState.fonts.has(GenIndex(data.value - 1, data.generation));
    }

    /// Checks if the resource identifier is valid and asserts if it is not.
    FontId validate(IStr message = defaultEngineValidateErrorMessage) {
        if (!isValid) assert(0, message);
        return this;
    }

    /// Retrieves the font associated with the resource identifier.
    ref Font get() {
        if (!isValid) assert(0, defaultEngineValidateErrorMessage);
        return _engineState.fonts[GenIndex(data.value - 1, data.generation)];
    }

    /// Retrieves the font associated with the resource identifier or returns a default value if invalid.
    Font getOr() {
        return isValid ? _engineState.fonts[GenIndex(data.value - 1, data.generation)] : Font();
    }

    /// Frees the resource associated with the identifier.
    void free() {
        if (isValid && this != engineFont) _engineState.fonts.remove(GenIndex(data.value - 1, data.generation));
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
    Rgba color;     /// The background color of the viewport.
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
        _engineState.userViewport = Viewport();
        rl.EndBlendMode();
        rl.EndTextureMode();
        if (isResolutionLocked) rl.BeginTextureMode(_engineState.viewport.data.toRl());
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
    Vec2 position;         /// The position of the camera.
    Vec2 offset;           /// The offset of the view area of the camera.
    float rotation = 0.0f; /// The rotation angle of the camera, in degrees.
    float scale = 1.0f;    /// The zoom level of the camera.
    bool isCentered;       /// Determines if the camera's origin is at the center instead of the top left.
    bool isAttached;       /// Indicates whether the camera is currently in use.

    @trusted nothrow @nogc:

    /// Initializes the camera with the given position and optional centering.
    this(Vec2 position, bool isCentered = false) {
        this.position = position;
        this.isCentered = isCentered;
    }

    /// Initializes the camera with the given position and optional centering.
    this(float x, float y, bool isCentered = false) {
        this(Vec2(x, y), isCentered);
    }

    /// The X position of the camera.
    pragma(inline, true)
    ref float x() => position.x;
    /// The Y position of the camera.
    pragma(inline, true)
    ref float y() => position.y;
    /// The sum of the position and the offset of the camera.
    pragma(inline, true)
    Vec2 sum() => position + offset;

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
            return Rect(sum, resolution / Vec2(scale)).area(hook);
        } else {
            return Rect(sum, viewport.size / Vec2(scale)).area(hook);
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
        if (_engineState.userCamera.isAttached) {
            assert(0, "Cannot attach camera because another camera is already attached.");
        }
        isAttached = true;
        _engineState.userCamera = this;
        auto temp = toRl(this, _engineState.userViewport);
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
        _engineState.userCamera = Camera();
        rl.EndMode2D();
    }
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
alias Tasks = SparseList!Task;
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
    Fault lastLoadFault;
    IStr memoryTrackingInfoFilter;

    EngineViewport viewport;
    GenList!Texture textures;
    GenList!Sound sounds;
    GenList!Font fonts;
    List!IStr envArgsBuffer;
    List!IStr droppedFilePathsBuffer;
    LStr loadTextBuffer;
    LStr saveTextBuffer;
    LStr assetsPath;
    Tasks tasks;
    GrowingArena arena;
}

/// Opens a window with the specified size and title.
/// You should avoid calling this function manually.
void _openWindow(int width, int height, const(IStr)[] args, IStr title = "Parin") {
    enum monogramPath = "parin_monogram.png";
    enum targetHtmlElementId = "canvas";

    if (rl.IsWindowReady) return;
    // Raylib stuff.
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | (defaultEngineVsync ? rl.FLAG_VSYNC_HINT : 0));
    rl.SetTraceLogLevel(rl.LOG_ERROR);
    rl.InitWindow(width, height, title.toCStr().getOr());
    rl.InitAudioDevice();
    rl.SetExitKey(rl.KEY_NULL);
    rl.SetTargetFPS(defaultEngineFpsMax);
    rl.SetWindowMinSize(240, 135);
    rl.rlSetBlendFactorsSeparate(0x0302, 0x0303, 1, 0x0303, 0x8006, 0x8006);
    // Parin stuff.
    _engineState = jokaMake!EngineState();
    _engineState.fullscreenState.previousWindowWidth = width;
    _engineState.fullscreenState.previousWindowHeight = height;
    _engineState.viewport.data.color = gray;
    if (args.length) {
        foreach (arg; args) _engineState.envArgsBuffer.appendSource(__FILE__, __LINE__, arg);
        _engineState.assetsPath.appendSource(__FILE__, __LINE__, pathConcat(args[0].pathDirName, "assets"));
    }
    _engineState.loadTextBuffer.reserve(8192);
    _engineState.saveTextBuffer.reserve(8192);
    _engineState.droppedFilePathsBuffer.reserve(defaultEngineFontsCapacity);
    _engineState.textures.reserve(defaultEngineTexturesCapacity);
    _engineState.sounds.reserve(defaultEngineSoundsCapacity);
    _engineState.fonts.reserve(defaultEngineFontsCapacity);
    _engineState.tasks.reserve(defaultEngineTasksCapacity);
    _engineState.arena.ready(defaultEngineArenaCapacity);
    toTexture(cast(const(ubyte)[]) import(monogramPath)).toFontAscii(6, 12).toFontId();
    // Wasm stuff.
    version (WebAssembly) {
        em.emscripten_set_mousemove_callback_on_thread(targetHtmlElementId, null, true, &_engineMouseCallbackWeb);
    }
}

/// Opens a window with the specified size and title, using C strings.
/// You should avoid calling this function manually.
void _openWindowC(int width, int height, int argc, ICStr* argv, ICStr title = "Parin") {
    _openWindow(width, height, null, title.cStrToStr());
    foreach (i; 0 .. argc) _engineState.envArgsBuffer.appendSource(__FILE__, __LINE__, argv[i].cStrToStr());
    if (_engineState.envArgsBuffer.length) _engineState.assetsPath.appendSource(__FILE__, __LINE__, pathConcat(_engineState.envArgsBuffer[0].pathDirName, "assets"));
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
        if (rl.IsFileDropped) {
            auto list = rl.LoadDroppedFiles();
            foreach (i; 0 .. list.count) {
                _engineState.droppedFilePathsBuffer.append(list.paths[i].toStr());
            }
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
    _engineState.arena.clear();
    auto dt = deltaTime;
    foreach (id; _engineState.tasks.ids) {
        if (_engineState.tasks[id].update(dt)) _engineState.tasks.remove(id);
    }
    auto result = _engineState.updateFunc(dt);
    if (_engineState.debugModeKey.isPressed) toggleIsDebugMode();
    if (isDebugMode) {
        if (_engineState.debugModeBeginFunc) _engineState.debugModeBeginFunc();
        if (_engineState.debugModeFunc) _engineState.debugModeFunc();
        if (_engineState.debugModeEndFunc) _engineState.debugModeEndFunc();
    }
    _engineState.tickCount += 1;
    if (rl.IsFileDropped) {
        // NOTE: LoadDroppedFiles just returns a global variable.
        rl.UnloadDroppedFiles(rl.LoadDroppedFiles());
        _engineState.droppedFilePathsBuffer.clear();
    }
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

    // VSync code.
    // NOTE: Could copy this style for viewport and fullscreen. They do have other problems though.
    if (_engineState.vsync != loopVsync) {
        // TODO: The comment will be removed when we replace raylib lol.
        // gf.glfwSwapInterval(_engineState.vsync);
    }
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
    auto isLogging = isLoggingMemoryTrackingInfo;
    auto filter = _engineState.memoryTrackingInfoFilter; // NOTE: Yeah, I know.

    _engineState.viewport.free();
    _engineState.textures.freeWithItems();
    _engineState.sounds.freeWithItems();
    _engineState.fonts.freeWithItems();
    _engineState.envArgsBuffer.free();
    _engineState.droppedFilePathsBuffer.free();
    _engineState.loadTextBuffer.free();
    _engineState.saveTextBuffer.free();
    _engineState.assetsPath.free();
    _engineState.tasks.free();
    _engineState.arena.free();
    jokaFree(_engineState);
    _engineState = null;

    rl.CloseAudioDevice();
    rl.CloseWindow();
    if (isLogging) printMemoryTrackingInfo(filter);
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
        static if (__traits(isStaticFunction, debugModeFunc)) enum debugMode1 = &debugModeFunc;
        else enum debugMode1 = null;
        static if (__traits(isStaticFunction, debugModeBeginFunc)) enum debugMode2 = &debugModeBeginFunc;
        else enum debugMode2 = null;
        static if (__traits(isStaticFunction, debugModeEndFunc)) enum debugMode3 = &debugModeEndFunc;
        else enum debugMode3 = null;

        static if (__traits(isStaticFunction, readyFunc)) readyFunc();
        static if (__traits(isStaticFunction, updateFunc)) _updateWindow(&updateFunc, debugMode1, debugMode2, debugMode3);
        static if (__traits(isStaticFunction, finishFunc)) finishFunc();
        _closeWindow();
        return 0;
    }

    version (D_BetterC) {
        extern(C)
        int main(int argc, const(char)** argv) {
            _openWindowC(width, height, argc, argv, title);
            return _runGame();
        }
    } else {
        int main(immutable(char)[][] args) {
            _openWindow(width, height, args, title);
            return _runGame();
        }
    }
}

/// Schedule a function (task) to run every interval, optionally limited by count.
TaskId every(float interval, EngineUpdateFunc func, int count = -1, bool canCallNow = false) {
    _engineState.tasks.append(Task(interval, canCallNow ? interval : 0, func, cast(byte) count));
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

/// Converts bytes into a texture. Returns an empty texture on error.
Texture toTexture(const(ubyte)[] from, IStr ext = ".png") {
    auto image = rl.LoadImageFromMemory(ext.toCStr().getOr(), from.ptr, cast(int) from.length);
    auto value = rl.LoadTextureFromImage(image).toPr();
    rl.UnloadImage(image);
    value.setFilter(_engineState.defaultFilter);
    value.setWrap(_engineState.defaultWrap);
    return value;
}

/// Converts bytes into a font. Returns an empty font on error.
Font toFont(const(ubyte)[] from, int size, int runeSpacing = -1, int lineSpacing = -1, IStr32 runes = null, IStr ext = ".ttf") {
    auto value = rl.LoadFontFromMemory(ext.toCStr().getOr(), from.ptr, cast(int) from.length, size, cast(int*) runes.ptr, cast(int) runes.length).toPr(runeSpacing, lineSpacing);
    value.setFilter(_engineState.defaultFilter);
    value.setWrap(_engineState.defaultWrap);
    return value;
}

/// Converts an ASCII bitmap font texture into a font.
/// The texture will be freed when the font is freed.
// NOTE: The number of items allocated is calculated as: (font width / tile width) * (font height / tile height)
// NOTE: It uses the raylib allocator.
Font toFontAscii(Texture from, int tileWidth, int tileHeight) {
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

deprecated("Will be renamed to toFontAscii.")
alias toAsciiFont = toFontAscii;

/// Converts a texture into a managed engine resource.
/// The texture will be freed when the resource is freed.
TextureId toTextureId(Texture from) {
    if (from.isEmpty) return TextureId();
    auto id = TextureId(_engineState.textures.append(from));
    id.data.value += 1;
    return id;
}

/// Converts a font into a managed engine resource.
/// The font will be freed when the resource is freed.
FontId toFontId(Font from) {
    if (from.isEmpty) return FontId();
    auto id = FontId(_engineState.fonts.append(from));
    id.data.value += 1;
    return id;
}

/// Converts a sound into a managed engine resource.
/// The sound will be freed when the resource is freed.
SoundId toSoundId(Sound from) {
    if (from.isEmpty) return SoundId();
    auto id = SoundId(_engineState.sounds.append(from));
    id.data.value += 1;
    return id;
}

/// Returns the fault from the last managed engine resource load call.
Fault lastLoadFault() {
    return _engineState.lastLoadFault;
}

/// Loads a text file from the assets folder and saves the content into the given buffer.
/// Supports both forward slashes and backslashes in file paths.
Fault loadRawTextIntoBuffer(IStr path, ref LStr buffer) {
    auto result = readTextIntoBuffer(path.toAssetsPath(), buffer);
    if (isLoggingLoadSaveFaults && result) printfln(defaultEngineLoadErrorMessage, path.toAssetsPath());
    return result;
}

/// Loads a text file from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Maybe!LStr loadRawText(IStr path) {
    return readText(path.toAssetsPath());
}

/// Loads a text file from the assets folder.
/// The resource remains valid until this function is called again.
/// Supports both forward slashes and backslashes in file paths.
Maybe!IStr loadTempText(IStr path) {
    auto fault = loadRawTextIntoBuffer(path, _engineState.loadTextBuffer);
    return Maybe!IStr(_engineState.loadTextBuffer.items, fault);
}

/// Loads a texture file (PNG) from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Maybe!Texture loadRawTexture(IStr path) {
    auto value = rl.LoadTexture(path.toAssetsPath().toCStr().getOr()).toPr();
    value.setFilter(_engineState.defaultFilter);
    value.setWrap(_engineState.defaultWrap);
    auto result = Maybe!Texture(value, value.isEmpty.toFault(Fault.cantFind));
    if (isLoggingLoadSaveFaults && result.isNone) printfln(defaultEngineLoadErrorMessage, path.toAssetsPath());
    return result;
}

/// Loads a texture file (PNG) from the assets folder.
/// The resource can be safely shared throughout the code and is automatically invalidated when the resource is freed.
/// Supports both forward slashes and backslashes in file paths.
TextureId loadTexture(IStr path) {
    return loadRawTexture(path).get(_engineState.lastLoadFault).toTextureId();
}

/// Loads a font file (TTF, OTF) from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Maybe!Font loadRawFont(IStr path, int size, int runeSpacing = -1, int lineSpacing = -1, IStr32 runes = null) {
    auto value = rl.LoadFontEx(path.toAssetsPath().toCStr().getOr(), size, cast(int*) runes.ptr, cast(int) runes.length).toPr(runeSpacing, lineSpacing);
    if (isLoggingLoadSaveFaults && value.isEmpty) printfln(defaultEngineLoadErrorMessage, path.toAssetsPath());
    if (value.isEmpty) {
        return Maybe!Font(Fault.cantFind);
    } else {
        value.setFilter(_engineState.defaultFilter);
        value.setWrap(_engineState.defaultWrap);
        return Maybe!Font(value);
    }
}

/// Loads a font file (TTF, OTF) from the assets folder.
/// The resource can be safely shared throughout the code and is automatically invalidated when the resource is freed.
/// Supports both forward slashes and backslashes in file paths.
FontId loadFont(IStr path, int size, int runeSpacing = -1, int lineSpacing = -1, IStr32 runes = null) {
    return loadRawFont(path, size, runeSpacing, lineSpacing, runes).get(_engineState.lastLoadFault).toFontId();
}

/// Loads an ASCII bitmap font file (PNG) from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
// NOTE: The number of items allocated for this font is calculated as: (font width / tile width) * (font height / tile height)
Maybe!Font loadRawFontFromTexture(IStr path, int tileWidth, int tileHeight) {
    auto value = loadRawTexture(path).getOr();
    return Maybe!Font(value.toFontAscii(tileWidth, tileHeight), value.isEmpty.toFault(Fault.cantFind));
}

/// Loads an ASCII bitmap font file (PNG) from the assets folder.
/// The resource can be safely shared throughout the code and is automatically invalidated when the resource is freed.
/// Supports both forward slashes and backslashes in file paths.
// NOTE: The number of items allocated for this font is calculated as: (font width / tile width) * (font height / tile height)
FontId loadFontFromTexture(IStr path, int tileWidth, int tileHeight) {
    return loadRawFontFromTexture(path, tileWidth, tileHeight).get(_engineState.lastLoadFault).toFontId();
}

/// Loads a sound file (WAV, OGG, MP3) from the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Maybe!Sound loadRawSound(IStr path, float volume, float pitch, bool canRepeat = false, float pitchVariance = 1.0f) {
    auto value = Sound();
    if (path.endsWith(".wav")) {
        value.data = rl.LoadSound(path.toAssetsPath().toCStr().getOr());
    } else {
        value.data = rl.LoadMusicStream(path.toAssetsPath().toCStr().getOr());
    }
    if (isLoggingLoadSaveFaults && value.isEmpty) printfln(defaultEngineLoadErrorMessage, path.toAssetsPath());
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
SoundId loadSound(IStr path, float volume, float pitch, bool canRepeat = false, float pitchVariance = 1.0f) {
    return loadRawSound(path, volume, pitch, canRepeat, pitchVariance).get(_engineState.lastLoadFault).toSoundId();
}

/// Saves a text file to the assets folder.
/// Supports both forward slashes and backslashes in file paths.
Fault saveText(IStr path, IStr text) {
    auto result = writeText(path.toAssetsPath(), text);
    if (isLoggingLoadSaveFaults && result) printfln(defaultEngineSaveErrorMessage, path.toAssetsPath());
    return result;
}

/// Sets the path of the assets folder.
void setAssetsPath(IStr path) {
    _engineState.assetsPath.clear();
    _engineState.assetsPath.append(path);
}

@trusted nothrow @nogc:

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

    Texture toPr(rl.Texture2D from) {
        return Texture(from);
    }

    Font toPr(rl.Font from, int runeSpacing, int lineSpacing) {
        return from.texture.id == rl.GetFontDefault().texture.id
            ? Font()
            : Font(
                from,
                runeSpacing >= 0 ? runeSpacing : 0,
                lineSpacing >= 0 ? lineSpacing : from.baseSize,
            );
    }

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

    rl.Texture2D toRl(Texture from) {
        return from.data;
    }

    rl.Font toRl(Font from) {
        return from.data;
    }

    rl.RenderTexture2D toRl(Viewport from) {
        return from.data;
    }

    rl.Camera2D toRl(Camera from, Viewport viewport = Viewport()) {
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
    return _engineState.envArgsBuffer[];
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
Vec2 toScreenPoint(Vec2 position, Camera camera, Viewport viewport = Viewport()) {
    return toPr(rl.GetWorldToScreen2D(position.toRl(), camera.toRl(viewport)));
}

/// Converts a screen point to a world point based on the given camera.
Vec2 toWorldPoint(Vec2 position, Camera camera, Viewport viewport = Viewport()) {
    return toPr(rl.GetScreenToWorld2D(position.toRl(), camera.toRl(viewport)));
}

/// Returns the path of the assets folder.
IStr assetsPath() {
    return _engineState.assetsPath.items;
}

/// Converts a path to a path within the assets folder.
IStr toAssetsPath(IStr path) {
    if (!isUsingAssetsPath) return path;
    return pathConcat(assetsPath, path).pathFormat();
}

/// Returns the dropped file paths of the current frame.
IStr[] droppedFilePaths() {
    return _engineState.droppedFilePathsBuffer[];
}

/// Returns a reference to a cleared temporary text container.
/// The resource remains valid until this function is called again.
ref LStr prepareTempText() {
    _engineState.saveTextBuffer.clear();
    return _engineState.saveTextBuffer;
}

/// Frees all managed engine resources.
void freeManagedEngineResources() {
    foreach (ref item; _engineState.textures.items) item.free();
    _engineState.textures.clear();
    foreach (ref item; _engineState.sounds.items) item.free();
    _engineState.sounds.clear();
    // The engine font in stored with the user fonts, so it needs to be skipped.
    auto engineFontItemId = engineFont.data;
    engineFontItemId.value -= 1;
    foreach (id; _engineState.fonts.ids) {
        if (id == engineFontItemId) continue;
        _engineState.fonts[id].free();
        _engineState.fonts.remove(id);
    }
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

/// Returns true if loading should log on fault.
bool isLoggingLoadSaveFaults() {
    return cast(bool) (_engineState.flags & EngineFlag.isLoggingLoadSaveFaults);
}

/// Sets whether loading should log on fault.
void setIsLoggingLoadSaveFaults(bool value) {
    _engineState.flags = value
        ? _engineState.flags | EngineFlag.isLoggingLoadSaveFaults
        : _engineState.flags & ~EngineFlag.isLoggingLoadSaveFaults;
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
bool isDown(char key) {
    return rl.IsKeyDown(toUpper(key));
}

/// Returns true if the specified key is currently pressed.
bool isDown(Keyboard key) {
    return rl.IsKeyDown(key);
}

/// Returns true if the specified key is currently pressed.
bool isDown(Mouse key) {
    if (key) return rl.IsMouseButtonDown(key - 1);
    else return false;
}

/// Returns true if the specified key is currently pressed.
bool isDown(Gamepad key, int id = 0) {
    return rl.IsGamepadButtonDown(id, key);
}

/// Returns true if the specified key was pressed.
bool isPressed(char key) {
    return rl.IsKeyPressed(toUpper(key));
}

/// Returns true if the specified key was pressed.
bool isPressed(Keyboard key) {
    return rl.IsKeyPressed(key);
}

/// Returns true if the specified key was pressed.
bool isPressed(Mouse key) {
    if (key) return rl.IsMouseButtonPressed(key - 1);
    else return false;
}

/// Returns true if the specified key was pressed.
bool isPressed(Gamepad key, int id = 0) {
    return rl.IsGamepadButtonPressed(id, key);
}

/// Returns true if the specified key was released.
bool isReleased(char key) {
    return rl.IsKeyReleased(toUpper(key));
}

/// Returns true if the specified key was released.
bool isReleased(Keyboard key) {
    return rl.IsKeyReleased(key);
}

/// Returns true if the specified key was released.
bool isReleased(Mouse key) {
    if (key) return rl.IsMouseButtonReleased(key - 1);
    else return false;
}

/// Returns true if the specified key was released.
bool isReleased(Gamepad key, int id = 0) {
    return rl.IsGamepadButtonReleased(id, key);
}

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
Vec2 measureTextSize(Font font, IStr text, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
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
Vec2 measureTextSize(FontId font, IStr text, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    return measureTextSize(font.getOr(), text, options, extra);
}

/// Draws a rectangle with the specified area and color.
void drawRect(Rect area, Rgba color = white) {
    if (isPixelSnapped) {
        rl.DrawRectanglePro(area.floor().toRl(), rl.Vector2(0.0f, 0.0f), 0.0f, color.toRl());
    } else {
        rl.DrawRectanglePro(area.toRl(), rl.Vector2(0.0f, 0.0f), 0.0f, color.toRl());
    }
}

/// Draws a hollow rectangle with the specified area and color.
void drawHollowRect(Rect area, float thickness, Rgba color = white) {
    if (isPixelSnapped) {
        rl.DrawRectangleLinesEx(area.floor().toRl(), thickness, color.toRl());
    } else {
        rl.DrawRectangleLinesEx(area.toRl(), thickness, color.toRl());
    }
}

/// Draws a point at the specified location with the given size and color.
void drawVec2(Vec2 point, float size, Rgba color = white) {
    drawRect(Rect(point, size, size).centerArea, color);
}

/// Draws a circle with the specified area and color.
void drawCirc(Circ area, Rgba color = white) {
    if (isPixelSnapped) {
        rl.DrawCircleV(area.position.floor().toRl(), area.radius, color.toRl());
    } else {
        rl.DrawCircleV(area.position.toRl(), area.radius, color.toRl());
    }
}

/// Draws a hollow circle with the specified area and color.
void drawHollowCirc(Circ area, float thickness, Rgba color = white) {
    if (isPixelSnapped) {
        rl.DrawRing(area.position.floor().toRl(), area.radius - thickness, area.radius, 0.0f, 360.0f, 30, color.toRl());
    } else {
        rl.DrawRing(area.position.toRl(), area.radius - thickness, area.radius, 0.0f, 360.0f, 30, color.toRl());
    }
}

/// Draws a line with the specified area, thickness, and color.
void drawLine(Line area, float size, Rgba color = white) {
    if (isPixelSnapped) {
        rl.DrawLineEx(area.a.floor().toRl(), area.b.floor().toRl(), size, color.toRl());
    } else {
        rl.DrawLineEx(area.a.toRl(), area.b.toRl(), size, color.toRl());
    }
}

/// Draws a portion of the specified texture at the given position with the specified draw options.
void drawTextureArea(Texture texture, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    version (ParinSkipDrawChecks) {
    } else {
        if (texture.isEmpty) {
            if (isEmptyTextureVisible) {
                auto rect = Rect(position, (!area.hasSize ? Vec2(64) : area.size) * options.scale).area(options.hook);
                drawRect(rect, defaultEngineEmptyTextureColor);
                drawHollowRect(rect, 1, black);
            }
            return;
        }
        if (!area.hasSize) return;
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
void drawTextureArea(TextureId texture, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTextureArea(texture.getOr(), area, position, options);
}

/// Draws a portion of the default texture at the given position with the specified draw options.
/// Use the `setDefaultTexture` function before using this function.
void drawTextureArea(Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTextureArea(_engineState.defaultTexture.getOr(), area, position, options);
}

/// Draws the texture at the given position with the specified draw options.
void drawTexture(Texture texture, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTextureArea(texture, Rect(texture.size), position, options);
}

/// Draws the texture at the given position with the specified draw options.
void drawTexture(TextureId texture, Vec2 position, DrawOptions options = DrawOptions()) {
    drawTexture(texture.getOr(), position, options);
}

/// Draws a 9-slice from the specified texture area at the given target area.
void drawTextureSlice(Texture texture, Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions()) {
    // NOTE: New rule for options. Functions are allowed to ignore values. Should they handle bad values? Maybe.
    // NOTE: If we ever change options to pointers, remember to remove this part.
    options.hook = Hook.topLeft;
    options.origin = Vec2(0);
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

/// Draws a 9-slice from the specified texture area at the given target area.
void drawTextureSlice(TextureId texture, Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions()) {
    drawTextureSlice(texture.getOr(), area, target, margin, canRepeat, options);
}

/// Draws a 9-slice from the default texture area at the given target area.
/// Use the `setDefaultTexture` function before using this function.
void drawTextureSlice(Rect area, Rect target, Margin margin, bool canRepeat, DrawOptions options = DrawOptions()) {
    drawTextureSlice(_engineState.defaultTexture.getOr(), area, target, margin, canRepeat, options);
}

/// Draws a portion of the specified viewport at the given position with the specified draw options.
void drawViewportArea(Viewport viewport, Rect area, Vec2 position, DrawOptions options = DrawOptions()) {
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
void drawViewport(Viewport viewport, Vec2 position, DrawOptions options = DrawOptions()) {
    drawViewportArea(viewport, Rect(viewport.size), position, options);
}

/// Draws a single character from the specified font at the given position with the specified draw options.
void drawRune(Font font, dchar rune, Vec2 position, DrawOptions options = DrawOptions()) {
    version (ParinSkipDrawChecks) {
    } else {
        if (font.isEmpty) {
            if (isEmptyFontVisible) font = engineFont.get();
            else return;
        }
    }

    auto rect = toPr(rl.GetGlyphAtlasRec(font.data, rune));
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
void drawRune(FontId font, dchar rune, Vec2 position, DrawOptions options = DrawOptions()) {
    drawRune(font.getOr(), rune, position, options);
}

/// Draws a single character from the default font at the given position with the specified draw options.
/// Check the `setDefaultFont` function before using this function.
void drawRune(dchar rune, Vec2 position, DrawOptions options = DrawOptions()) {
    drawRune(_engineState.defaultFont, rune, position, options);
}

/// Draws the specified text with the given font at the given position using the provided draw options.
// NOTE: Text drawing needs to go over the text 3 times. This can be made into 2 times in the future if needed by copy-pasting the measureTextSize inside this function.
void drawText(Font font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    static FixedList!(IStr, 128) linesBuffer = void;
    static FixedList!(short, 128) linesWidthBuffer = void;

    version (ParinSkipDrawChecks) {
    } else {
        if (font.isEmpty) {
            if (isEmptyFontVisible) font = engineFont.get();
            else return;
        }
        if (text.length == 0) return;
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
                linesWidthBuffer.append(cast(ushort) (measureTextSize(font, linesBuffer[$ - 1]).x));
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
void drawText(FontId font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    drawText(font.getOr(), text, position, options, extra);
}

/// Draws text with the default font at the given position with the provided draw options.
/// Check the `setDefaultFont` function before using this function.
void drawText(IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions()) {
    drawText(_engineState.defaultFont, text, position, options, extra);
}

deprecated("Use `drawText(text, ...)`. It works the same, but you can also call `setDefaultFont` to change the font.")
alias drawDebugText = drawText;

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

    auto text = "OwO".fmt();
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
            _engineState.textures.length,
            _engineState.fonts.length - 1,
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
                _engineState.textures.length,
                _engineState.fonts.length - 1,
                _engineState.sounds.length,
                cast(int) mouse.x,
                cast(int) mouse.y,
            );
        } else {
            text = "FPS: {}\nAssets: (T{} F{} S{})\nMouse: ({} {})\nArea: A({} {}) B({} {}) S({} {})".fmt(
                fps,
                _engineState.textures.length,
                _engineState.fonts.length - 1,
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
    drawRect(Rect(a.toScreenPoint(camera), s), defaultEngineDebugColor2);
    drawHollowRect(Rect(a.toScreenPoint(camera), s), 1, defaultEngineDebugColor1);
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
    drawRect(Rect(tile.position.toScreenPoint(camera), tile.size), defaultEngineDebugColor2);
    drawHollowRect(Rect(tile.position.toScreenPoint(camera), tile.size), 1, defaultEngineDebugColor1);
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
