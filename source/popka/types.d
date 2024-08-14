// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/popka
// Version: v0.0.16
// ---

/// The `types` module defines all the types used within the `engine` module.
module popka.types;

import ray = popka.ray;
public import joka;

@safe @nogc nothrow:

EngineState engineState;

/// A type representing flipping orientations.
enum Flip : ubyte {
    none, /// No flipping.
    x,    /// Flipped along the X-axis.
    y,    /// Flipped along the Y-axis.
    xy,   /// Flipped along both X and Y axes.
}

/// A type representing texture filtering modes.
enum Filter : ubyte {
    nearest, /// Nearest neighbor filtering (blocky).
    linear,  /// Bilinear filtering (smooth).
}

/// A type representing a limited set of keyboard keys.
enum Keyboard {
    a = ray.KEY_A,                 /// The A key.
    b = ray.KEY_B,                 /// The B key.
    c = ray.KEY_C,                 /// The C key.
    d = ray.KEY_D,                 /// The D key.
    e = ray.KEY_E,                 /// The E key.
    f = ray.KEY_F,                 /// The F key.
    g = ray.KEY_G,                 /// The G key.
    h = ray.KEY_H,                 /// The H key.
    i = ray.KEY_I,                 /// The I key.
    j = ray.KEY_J,                 /// The J key.
    k = ray.KEY_K,                 /// The K key.
    l = ray.KEY_L,                 /// The L key.
    m = ray.KEY_M,                 /// The M key.
    n = ray.KEY_N,                 /// The N key.
    o = ray.KEY_O,                 /// The O key.
    p = ray.KEY_P,                 /// The P key.
    q = ray.KEY_Q,                 /// The Q key.
    r = ray.KEY_R,                 /// The R key.
    s = ray.KEY_S,                 /// The S key.
    t = ray.KEY_T,                 /// The T key.
    u = ray.KEY_U,                 /// The U key.
    v = ray.KEY_V,                 /// The V key.
    w = ray.KEY_W,                 /// The W key.
    x = ray.KEY_X,                 /// The X key.
    y = ray.KEY_Y,                 /// The Y key.
    z = ray.KEY_Z,                 /// The Z key.
    n0 = ray.KEY_ZERO,             /// The 0 key.
    n1 = ray.KEY_ONE,              /// The 1 key.
    n2 = ray.KEY_TWO,              /// The 2 key.
    n3 = ray.KEY_THREE,            /// The 3 key.
    n4 = ray.KEY_FOUR,             /// The 4 key.
    n5 = ray.KEY_FIVE,             /// The 5 key.
    n6 = ray.KEY_SIX,              /// The 6 key.
    n7 = ray.KEY_SEVEN,            /// The 7 key.
    n8 = ray.KEY_EIGHT,            /// The 8 key.
    n9 = ray.KEY_NINE,             /// The 9 key.
    nn0 = ray.KEY_KP_0,            /// The 0 key on the numpad.
    nn1 = ray.KEY_KP_1,            /// The 1 key on the numpad.
    nn2 = ray.KEY_KP_2,            /// The 2 key on the numpad.
    nn3 = ray.KEY_KP_3,            /// The 3 key on the numpad.
    nn4 = ray.KEY_KP_4,            /// The 4 key on the numpad.
    nn5 = ray.KEY_KP_5,            /// The 5 key on the numpad.
    nn6 = ray.KEY_KP_6,            /// The 6 key on the numpad.
    nn7 = ray.KEY_KP_7,            /// The 7 key on the numpad.
    nn8 = ray.KEY_KP_8,            /// The 8 key on the numpad.
    nn9 = ray.KEY_KP_9,            /// The 9 key on the numpad.
    f1 = ray.KEY_F1,               /// The f1 key.
    f2 = ray.KEY_F2,               /// The f2 key.
    f3 = ray.KEY_F3,               /// The f3 key.
    f4 = ray.KEY_F4,               /// The f4 key.
    f5 = ray.KEY_F5,               /// The f5 key.
    f6 = ray.KEY_F6,               /// The f6 key.
    f7 = ray.KEY_F7,               /// The f7 key.
    f8 = ray.KEY_F8,               /// The f8 key.
    f9 = ray.KEY_F9,               /// The f9 key.
    f10 = ray.KEY_F10,             /// The f10 key.
    f11 = ray.KEY_F11,             /// The f11 key.
    f12 = ray.KEY_F12,             /// The f12 key.
    left = ray.KEY_LEFT,           /// The left arrow key.
    right = ray.KEY_RIGHT,         /// The right arrow key.
    up = ray.KEY_UP,               /// The up arrow key.
    down = ray.KEY_DOWN,           /// The down arrow key.
    esc = ray.KEY_ESCAPE,          /// The escape key.
    enter = ray.KEY_ENTER,         /// The enter key.
    tab = ray.KEY_TAB,             /// The tab key.
    space = ray.KEY_SPACE,         /// The space key.
    backspace = ray.KEY_BACKSPACE, /// THe backspace key.
    shift = ray.KEY_LEFT_SHIFT,    /// The left shift key.
    ctrl = ray.KEY_LEFT_CONTROL,   /// The left control key.
    alt = ray.KEY_LEFT_ALT,        /// The left alt key.
    win = ray.KEY_LEFT_SUPER,      /// The left windows/super/command key.
    insert = ray.KEY_INSERT,       /// The insert key.
    del = ray.KEY_DELETE,          /// The delete key.
    home = ray.KEY_HOME,           /// The home key.
    end = ray.KEY_END,             /// The end key.
    pageUp = ray.KEY_PAGE_UP,      /// The page up key.
    pageDown = ray.KEY_PAGE_DOWN,  /// The page down key.
}

/// A type representing a limited set of mouse keys.
enum Mouse {
    left = ray.MOUSE_BUTTON_LEFT,     /// The left mouse button.
    right = ray.MOUSE_BUTTON_RIGHT,   /// The right mouse button.
    middle = ray.MOUSE_BUTTON_MIDDLE, /// The middle mouse button.
}

/// A type representing a limited set of gamepad buttons.
enum Gamepad {
    left = ray.GAMEPAD_BUTTON_LEFT_FACE_LEFT,   /// The left button.
    right = ray.GAMEPAD_BUTTON_LEFT_FACE_RIGHT, /// The right button.
    up = ray.GAMEPAD_BUTTON_LEFT_FACE_UP,       /// The up button.
    down = ray.GAMEPAD_BUTTON_LEFT_FACE_DOWN,   /// The down button.
    y = ray.GAMEPAD_BUTTON_RIGHT_FACE_UP,       /// The Xbox y, PlayStation triangle and Nintendo x button.
    x = ray.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT,    /// The Xbox x, PlayStation square and Nintendo y button.
    a = ray.GAMEPAD_BUTTON_RIGHT_FACE_DOWN,     /// The Xbox a, PlayStation cross and Nintendo b button.
    b = ray.GAMEPAD_BUTTON_RIGHT_FACE_LEFT,     /// The Xbox b, PlayStation circle and Nintendo a button.
    lt = ray.GAMEPAD_BUTTON_LEFT_TRIGGER_2,     /// The left trigger button.
    lb = ray.GAMEPAD_BUTTON_LEFT_TRIGGER_1,     /// The left bumper button.
    lsb = ray.GAMEPAD_BUTTON_LEFT_THUMB,        /// The left stick button.
    rt = ray.GAMEPAD_BUTTON_RIGHT_TRIGGER_2,    /// The right trigger button.
    rb = ray.GAMEPAD_BUTTON_RIGHT_TRIGGER_1,    /// The right bumper button.
    rsb = ray.GAMEPAD_BUTTON_RIGHT_THUMB,       /// The right stick button.
    back = ray.GAMEPAD_BUTTON_MIDDLE_LEFT,      /// The back button.
    start = ray.GAMEPAD_BUTTON_MIDDLE_RIGHT,    /// The start button.
    middle = ray.GAMEPAD_BUTTON_MIDDLE,         /// The middle button.
}

struct EngineFlags {
    bool isUpdating;
    bool isPixelPerfect;
    bool isVsync;
    bool isFpsLocked;
    bool isCursorHidden;
}

struct EngineViewport {
    Viewport data;
    int targetWidth;
    int targetHeight;
    bool isLockResolutionQueued;
    bool isUnlockResolutionQueued;

    alias data this;
}

struct EngineFullscreenState {
    Vec2 lastWindowSize;
    float toggleTimer = 0.0f;
    bool isToggleQueued;
    enum toggleWaitTime = 0.1f;
}

struct EngineState {
    EngineFlags flags;
    EngineFullscreenState fullscreenState;
    EngineViewport viewport;
    Color backgroundColor;
    LStr tempText;
    LStr assetsPath;

    @safe @nogc nothrow:

    void free() {
        viewport.free();
        tempText.free();
        assetsPath.free();
        this = EngineState();
    }
}

struct DrawOptions {
    Vec2 origin    = Vec2(0.0f);   /// The origin point of the drawn object.
    Vec2 scale     = Vec2(1.0f);   /// The scale of the drawn object.
    float rotation = 0.0f;         /// The rotation of the drawn object.
    Color color    = white;        /// The color of the drawn object.
    Hook hook      = Hook.topLeft; /// An value representing the origin point of the drawn object when origin is set to zero.
    Flip flip      = Flip.none;    /// An value representing flipping orientations.
}

struct Camera {
    Vec2 position;
    float rotation = 0.0f;
    float scale = 1.0f;
    bool isAttached;
    bool isCentered;

    @safe @nogc nothrow:

    this(Vec2 position) {
        this.position = position;
    }

    this(float x, float y) {
        this(Vec2(x, y));
    }

    Hook hook() {
        return isCentered ? Hook.center : Hook.topLeft;
    }

    void followPosition(Vec2 target, Vec2 delta, float slowdown = 0.15f) {
        if (slowdown <= 0.0f) {
            position = target;
        } else {
            position = position.moveToWithSlowdown(target, delta, slowdown);
        }
    }

    void followScale(float target, float delta, float slowdown = 0.15f) {
        if (slowdown <= 0.0f) {
            scale = target;
        } else {
            scale = scale.moveToWithSlowdown(target, delta, slowdown);
        }
    }
}

struct Texture {
    ray.Texture2D data;
    Filter filter;

    @safe @nogc nothrow:

    /// Returns true if the texture has not been loaded.
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

    /// Set the filter mode of the texture.
    @trusted
    void setFilter(Filter value) {
        if (isEmpty) return;
        filter = value;
        ray.SetTextureFilter(data, value.toRay());
    }

    /// Frees the loaded image.
    /// If an image is already freed, then this function will do nothing.
    @trusted
    void free() {
        if (isEmpty) {
            return;
        }
        ray.UnloadTexture(data);
        this = Texture();
    }
}

struct Viewport {
    ray.RenderTexture2D data;
    Filter filter;

    @safe @nogc nothrow:

    /// Returns true if the viewport has not been loaded.
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

    /// Set the filter mode of the viewport.
    @trusted
    void setFilter(Filter value) {
        if (isEmpty) return;
        filter = value;
        ray.SetTextureFilter(data.texture, value.toRay());
    }

    @trusted
    void free() {
        if (isEmpty) {
            return;
        }
        ray.UnloadRenderTexture(data);
        this = Viewport();
    }
}

struct Font {
    ray.Font data;
    Filter filter;
    int runeSpacing;
    int lineSpacing;

    @safe @nogc nothrow:

    /// Returns true if the font has not been loaded.
    bool isEmpty() {
        return data.texture.id <= 0;
    }

    /// Returns the size of the font.
    int size() {
        return data.baseSize;
    }

    /// Set the filter mode of the font.
    @trusted
    void setFilter(Filter value) {
        if (isEmpty) return;
        filter = value;
        ray.SetTextureFilter(data.texture, value.toRay());
    }

    @trusted
    void free() {
        if (isEmpty) {
            return;
        }
        ray.UnloadFont(data);
        this = Font();
    }
}

struct Audio {
    Data data;

    alias Sound = ray.Sound;
    alias Music = ray.Music;
    alias Data = Variant!(Sound, Music);

    @safe @nogc nothrow:

    Sound sound() {
        return data.get!Sound();
    }

    Music music() {
        return data.get!Music();
    }

    bool isSound() {
        return data.isKind!Sound;
    }

    bool isMusic() {
        return data.isKind!Music;
    }

    bool isEmpty() {
        if (isSound) {
            return sound.stream.sampleRate == 0;
        } else {
            return music.stream.sampleRate == 0;
        }
    }

    @trusted
    float time() {
        if (isSound) {
            return 0.0f;
        } else {
            return ray.GetMusicTimePlayed(music);
        }
    }

    @trusted
    float waitTime() {
        if (isSound) {
            return 0.0f;
        } else {
            return ray.GetMusicTimeLength(music);
        }
    }

    @trusted
    void setVolume(float value) {
        if (isSound) {
            ray.SetSoundVolume(sound, value);
        } else {
            ray.SetMusicVolume(music, value);
        }
    }

    @trusted
    void setPitch(float value) {
        if (isSound) {
            ray.SetSoundPitch(sound, value);
        } else {
            ray.SetMusicPitch(music, value);
        }
    }

    @trusted
    void setPan(float value) {
        if (isSound) {
            ray.SetSoundPan(sound, value);
        } else {
            ray.SetMusicPan(music, value);
        }
    }

    @trusted
    void free() {
        if (isEmpty) {
            return;
        }
        if (isSound) {
            ray.UnloadSound(sound);
        } else {
            ray.UnloadMusicStream(music);
        }
        this = Audio();
    }
}

/// Converts a raylib color to a Popka color.
Color toPopka(ray.Color from) {
    return Color(from.r, from.g, from.b, from.a);
}

/// Converts a raylib vector to a Popka vector.
Vec2 toPopka(ray.Vector2 from) {
    return Vec2(from.x, from.y);
}

/// Converts a raylib vector to a Popka vector.
Vec3 toPopka(ray.Vector3 from) {
    return Vec3(from.x, from.y, from.z);
}

/// Converts a raylib vector to a Popka vector.
Vec4 toPopka(ray.Vector4 from) {
    return Vec4(from.x, from.y, from.z, from.w);
}

/// Converts a raylib rectangle to a Popka rectangle.
Rect toPopka(ray.Rectangle from) {
    return Rect(from.x, from.y, from.width, from.height);
}

/// Converts a raylib texture to a Popka texture.
Texture toPopka(ray.Texture2D from) {
    auto result = Texture();
    result.data = from;
    return result;
}

/// Converts a raylib font to a Popka font.
Font toPopka(ray.Font from) {
    auto result = Font();
    result.data = from;
    return result;
}

/// Converts a raylib render texture to a Popka viewport.
Viewport toPopka(ray.RenderTexture2D from) {
    auto result = Viewport();
    result.data = from;
    return result;
}

/// Converts a Popka color to a raylib color.
ray.Color toRay(Color from) {
    return ray.Color(from.r, from.g, from.b, from.a);
}

/// Converts a Popka vector to a raylib vector.
ray.Vector2 toRay(Vec2 from) {
    return ray.Vector2(from.x, from.y);
}

/// Converts a Popka vector to a raylib vector.
ray.Vector3 toRay(Vec3 from) {
    return ray.Vector3(from.x, from.y, from.z);
}

/// Converts a Popka vector to a raylib vector.
ray.Vector4 toRay(Vec4 from) {
    return ray.Vector4(from.x, from.y, from.z, from.w);
}

/// Converts a Popka rectangle to a raylib rectangle.
ray.Rectangle toRay(Rect from) {
    return ray.Rectangle(from.position.x, from.position.y, from.size.x, from.size.y);
}

/// Converts a Popka texture to a raylib texture.
ray.Texture2D toRay(Texture from) {
    return from.data;
}

/// Converts a Popka font to a raylib font.
ray.Font toRay(Font from) {
    return from.data;
}

/// Converts a Popka viewport to a raylib render texture.
ray.RenderTexture2D toRay(Viewport from) {
    return from.data;
}

/// Converts a Popka filter to a raylib filter.
int toRay(Filter filter) {
    final switch (filter) {
        case Filter.nearest: return ray.TEXTURE_FILTER_POINT;
        case Filter.linear: return ray.TEXTURE_FILTER_BILINEAR;
    }
}

/// Returns the opposite flip value.
/// The opposite of every flip value except none is none.
/// The fallback value is returned if the flip value is none.
Flip opposite(Flip flip, Flip fallback) {
    if (flip == fallback) {
        return Flip.none;
    } else {
        return fallback;
    }
}
