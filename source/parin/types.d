// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

module parin.types;

public import joka.math;
public import joka.types;
public import joka.containers;

alias ResourceId = GenIndex;

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
enum Keyboard : ushort {
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
enum Mouse : ushort {
    none,   /// Not a button.
    left,   /// The left mouse button.
    right,  /// The right mouse button.
    middle, /// The middle mouse button.
}

/// A limited set of gamepad buttons.
enum Gamepad : ushort {
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
alias SliceParts = Array!(SlicePart, 9);

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
    ref float x() => position.x;
    /// The Y position of the camera.
    ref float y() => position.y;
    /// The sum of the position and the offset of the camera.
    Vec2 sum() => position + offset;
    /// Returns the current hook associated with the camera.
    Hook hook() => isCentered ? Hook.center : Hook.topLeft;
    /// Returns the origin of the camera.
    Vec2 origin(Vec2 canvasSize) => Rect(canvasSize / Vec2(scale)).origin(hook);
    /// Returns the area covered by the camera.
    Rect area(Vec2 canvasSize) => Rect(sum, canvasSize / Vec2(scale)).area(hook);

    /// Returns the top left point of the camera.
    Vec2 topLeftPoint(Vec2 canvasSize) => area(canvasSize).topLeftPoint;
    /// Returns the top point of the camera.
    Vec2 topPoint(Vec2 canvasSize) => area(canvasSize).topPoint;
    /// Returns the top right point of the camera.
    Vec2 topRightPoint(Vec2 canvasSize) => area(canvasSize).topRightPoint;
    /// Returns the left point of the camera.
    Vec2 leftPoint(Vec2 canvasSize) => area(canvasSize).leftPoint;
    /// Returns the center point of the camera.
    Vec2 centerPoint(Vec2 canvasSize) => area(canvasSize).centerPoint;
    /// Returns the right point of the camera.
    Vec2 rightPoint(Vec2 canvasSize) => area(canvasSize).rightPoint;
    /// Returns the bottom left point of the camera.
    Vec2 bottomLeftPoint(Vec2 canvasSize) => area(canvasSize).bottomLeftPoint;
    /// Returns the bottom point of the camera.
    Vec2 bottomPoint(Vec2 canvasSize) => area(canvasSize).bottomPoint;
    /// Returns the bottom right point of the camera.
    Vec2 bottomRightPoint(Vec2 canvasSize) => area(canvasSize).bottomRightPoint;

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
