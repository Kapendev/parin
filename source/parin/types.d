// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

module parin.types;

import parin.joka.math;
import parin.joka.types;
import parin.joka.containers;

alias UpdateFunc = bool function(float dt);
alias CallFunc   = void function();
alias ResourceId = GenIndex;

@safe nothrow @nogc:

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
    nearest, /// Nearest neighbor filtering (blocky).
    linear,  /// Bilinear filtering (smooth).
}

/// Texture wrapping modes.
enum Wrap : ubyte {
    clamp,  /// Clamps texture.
    repeat, /// Repeats texture.
}

/// Texture blending modes.
enum Blend : ubyte {
    alpha,      /// Standard alpha blending.
    additive,   /// Adds colors for light effects.
    multiplied, /// Multiplies colors for shadows.
    add,        /// Simply adds colors.
    sub,        /// Simply subtracts colors.
}

/// A limited set of keyboard keys.
enum Keyboard : ubyte {
    none,         /// Not a key.
    apostrophe,   /// The `'` key.
    comma,        /// The `,` key.
    minus,        /// The `-` key.
    period,       /// The `.` key.
    slash,        /// The `/` key.
    n0,           /// The 0 key.
    n1,           /// The 1 key.
    n2,           /// The 2 key.
    n3,           /// The 3 key.
    n4,           /// The 4 key.
    n5,           /// The 5 key.
    n6,           /// The 6 key.
    n7,           /// The 7 key.
    n8,           /// The 8 key.
    n9,           /// The 9 key.
    nn0,          /// The 0 key on the numpad.
    nn1,          /// The 1 key on the numpad.
    nn2,          /// The 2 key on the numpad.
    nn3,          /// The 3 key on the numpad.
    nn4,          /// The 4 key on the numpad.
    nn5,          /// The 5 key on the numpad.
    nn6,          /// The 6 key on the numpad.
    nn7,          /// The 7 key on the numpad.
    nn8,          /// The 8 key on the numpad.
    nn9,          /// The 9 key on the numpad.
    semicolon,    /// The `;` key.
    equal,        /// The `=` key.
    a,            /// The A key.
    b,            /// The B key.
    c,            /// The C key.
    d,            /// The D key.
    e,            /// The E key.
    f,            /// The F key.
    g,            /// The G key.
    h,            /// The H key.
    i,            /// The I key.
    j,            /// The J key.
    k,            /// The K key.
    l,            /// The L key.
    m,            /// The M key.
    n,            /// The N key.
    o,            /// The O key.
    p,            /// The P key.
    q,            /// The Q key.
    r,            /// The R key.
    s,            /// The S key.
    t,            /// The T key.
    u,            /// The U key.
    v,            /// The V key.
    w,            /// The W key.
    x,            /// The X key.
    y,            /// The Y key.
    z,            /// The Z key.
    bracketLeft,  /// The `[` key.
    bracketRight, /// The `]` key.
    backslash,    /// The `\` key.
    grave,        /// The `` ` `` key.
    space,        /// The space key.
    esc,          /// The escape key.
    enter,        /// The enter key.
    tab,          /// The tab key.
    backspace,    /// THe backspace key.
    insert,       /// The insert key.
    del,          /// The delete key.
    right,        /// The right arrow key.
    left,         /// The left arrow key.
    down,         /// The down arrow key.
    up,           /// The up arrow key.
    pageUp,       /// The page up key.
    pageDown,     /// The page down key.
    home,         /// The home key.
    end,          /// The end key.
    capsLock,     /// The caps lock key.
    scrollLock,   /// The scroll lock key.
    numLock,      /// The num lock key.
    printScreen,  /// The print screen key.
    pause,        /// The pause/break key.
    shift,        /// The left shift key.
    shiftRight,   /// The right shift key.
    ctrl,         /// The left control key.
    ctrlRight,    /// The right control key.
    alt,          /// The left alt key.
    altRight,     /// The right alt key.
    win,          /// The left windows/super/command key.
    winRight,     /// The right windows/super/command key.
    menu,         /// The menu key.
    f1,           /// The f1 key.
    f3,           /// The f3 key.
    f2,           /// The f2 key.
    f4,           /// The f4 key.
    f5,           /// The f5 key.
    f6,           /// The f6 key.
    f7,           /// The f7 key.
    f8,           /// The f8 key.
    f9,           /// The f9 key.
    f10,          /// The f10 key.
    f11,          /// The f11 key.
    f12,          /// The f12 key.
}

/// A limited set of mouse keys.
enum Mouse : ubyte {
    none,   /// Not a button.
    left,   /// The left mouse button.
    right,  /// The right mouse button.
    middle, /// The middle mouse button.
}

/// A limited set of gamepad buttons.
enum Gamepad : ubyte {
    none,   /// Not a button.
    left,   /// The left button.
    right,  /// The right button.
    up,     /// The up button.
    down,   /// The down button.
    y,      /// The Xbox y, PlayStation triangle and Nintendo x button.
    x,      /// The Xbox x, PlayStation square and Nintendo y button.
    a,      /// The Xbox a, PlayStation cross and Nintendo b button.
    b,      /// The Xbox b, PlayStation circle and Nintendo a button.
    lt,     /// The left trigger button.
    lb,     /// The left bumper button.
    lsb,    /// The left stick button.
    rt,     /// The right trigger button.
    rb,     /// The right bumper button.
    rsb,    /// The right stick button.
    back,   /// The back button.
    start,  /// The start button.
    middle, /// The middle button.
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
}

/// The parts of a 9-slice.
alias SliceParts = StaticArray!(SlicePart, 9);

// Font glyph info.
struct GlyphInfo {
    int value;    // Character value.
    IVec2 offset; // Character offset when drawing.
    int advanceX; // Character advance position X.
    IRect rect;   // Character rectangle.
}

/// Options for configuring drawing parameters.
struct DrawOptions {
    Vec2 origin    = Vec2(0.0f);   /// The origin point of the drawn object. This value can be used to force a specific origin.
    Vec2 scale     = Vec2(1.0f);   /// The scale of the drawn object.
    float rotation = 0.0f;         /// The rotation of the drawn object, in degrees.
    Rgba color     = white;        /// The color of the drawn object, in RGBA.
    Hook hook      = Hook.topLeft; /// A value representing the origin point of the drawn object when origin is zero.
    Flip flip      = Flip.none;    /// A value representing flipping orientations.
    ubyte layer    = 0;            /// A value that can be used by depth sorting functions.

    @safe nothrow @nogc:

    this(float rotation, Hook hook = Hook.topLeft, ubyte layer = 0) {
        this.rotation = rotation;
        this.hook = hook;
        this.layer = layer;
    }

    this(Vec2 scale, Hook hook = Hook.topLeft, ubyte layer = 0) {
        this.scale = scale;
        this.hook = hook;
        this.layer = layer;
    }

    this(Rgba color, Hook hook = Hook.topLeft, ubyte layer = 0) {
        this.color = color;
        this.hook = hook;
        this.layer = layer;
    }

    this(Flip flip, Hook hook = Hook.topLeft, ubyte layer = 0) {
        this.flip = flip;
        this.hook = hook;
        this.layer = layer;
    }

    this(Hook hook, ubyte layer = 0) {
        this.hook = hook;
        this.layer = layer;
    }
}

/// Options for configuring extra drawing parameters for text.
struct TextOptions {
    float visibilityRatio  = 1.0f;           /// Controls the visibility ratio of the text when visibilityCount is zero, where 0.0 means fully hidden and 1.0 means fully visible.
    int alignmentWidth     = 0;              /// The width of the aligned text. It is used as a hint and is not enforced.
    ushort visibilityCount = 0;              /// Controls the visibility count of the text. This value can be used to force a specific character count.
    Alignment alignment    = Alignment.left; /// A value represeting alignment orientations.
    bool isRightToLeft     = false;          /// Indicates whether the content of the text flows in a right-to-left direction.

    @safe nothrow @nogc:

    this(float visibilityRatio) {
        this.visibilityRatio = visibilityRatio;
    }

    this(Alignment alignment, int alignmentWidth = 0) {
        this.alignment = alignment;
        this.alignmentWidth = alignmentWidth;
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

    @safe nothrow @nogc:

    this(Vec2 position, bool isCentered = false) {
        this.position = position;
        this.isCentered = isCentered;
    }

    this(float x, float y, bool isCentered = false) {
        this(Vec2(x, y), isCentered);
    }

    /// The X position of the camera.
    @trusted ref float x() {
        return position.x;
    }

    /// The Y position of the camera.
    @trusted ref float y() {
        return position.y;
    }

    /// The sum of the position and the offset of the camera.
    Vec2 sum() {
        return position + offset;
    }

    /// Returns the current hook associated with the camera.
    Hook hook() {
        return isCentered ? Hook.center : Hook.topLeft;
    }

    /// Returns the origin of the camera.
    Vec2 origin(Vec2 canvasSize) {
        return Rect(canvasSize / Vec2(scale)).origin(hook);
    }

    /// Returns the area covered by the camera.
    Rect area(Vec2 canvasSize) {
        return Rect(sum, canvasSize / Vec2(scale)).area(hook);
    }

    /// Returns the top left point of the camera.
    Vec2 topLeftPoint(Vec2 canvasSize) {
        return area(canvasSize).topLeftPoint;
    }

    /// Returns the top point of the camera.
    Vec2 topPoint(Vec2 canvasSize) {
        return area(canvasSize).topPoint;
    }

    /// Returns the top right point of the camera.
    Vec2 topRightPoint(Vec2 canvasSize) {
        return area(canvasSize).topRightPoint;
    }

    /// Returns the left point of the camera.
    Vec2 leftPoint(Vec2 canvasSize) {
        return area(canvasSize).leftPoint;
    }

    /// Returns the center point of the camera.
    Vec2 centerPoint(Vec2 canvasSize) {
        return area(canvasSize).centerPoint;
    }

    /// Returns the right point of the camera.
    Vec2 rightPoint(Vec2 canvasSize) {
        return area(canvasSize).rightPoint;
    }

    /// Returns the bottom left point of the camera.
    Vec2 bottomLeftPoint(Vec2 canvasSize) {
        return area(canvasSize).bottomLeftPoint;
    }

    /// Returns the bottom point of the camera.
    Vec2 bottomPoint(Vec2 canvasSize) {
        return area(canvasSize).bottomPoint;
    }

    /// Returns the bottom right point of the camera.
    Vec2 bottomRightPoint(Vec2 canvasSize) {
        return area(canvasSize).bottomRightPoint;
    }

    void floor() {
        position = position.floor();
        offset = offset.floor();
    }

    void ceil() {
        position = position.ceil();
        offset = offset.ceil();
    }

    void round() {
        position = position.round();
        offset = offset.round();
    }

    /// Moves the camera to follow the target position at the specified speed.
    void followPosition(Vec2 target, float delta) {
        position = position.moveTo(target, Vec2(delta));
    }

    /// Moves the camera to follow the target position with gradual slowdown.
    void followPositionWithSlowdown(Vec2 target, float delta, float slowdown) {
        position = position.moveToWithSlowdown(target, Vec2(delta), slowdown);
    }

    /// Adjusts the camera’s zoom level to follow the target value at the specified speed.
    void followScale(float target, float delta) {
        scale = scale.moveTo(target, delta);
    }

    /// Adjusts the camera’s zoom level to follow the target value with gradual slowdown.
    void followScaleWithSlowdown(float target, float delta, float slowdown) {
        scale = scale.moveToWithSlowdown(target, delta, slowdown);
    }
}

/// Represents a scheduled task with interval, repeat count, and callback function.
struct Task {
    float interval = 0.0f; /// The interval of the task, in seconds.
    float time = 0.0f;     /// The current time of the task.
    UpdateFunc func;       /// The callback function of the task.
    byte count;            /// Number of times the task will run, with -1 indicating it runs forever.

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
