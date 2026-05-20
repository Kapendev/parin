// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `game` module provides game related types and functions.
module parin.joka.game;

import parin.joka.types;
import parin.joka.math;

@safe nothrow @nogc:

alias Palette(Sz N)    = StaticArray!(Rgba, N); /// A generic color palette of RGBA colors.
alias HexPalette(Sz N) = uint[N];               /// A generic color palette of hexadecimal numbers.

/// A 2-color palette inspired by the Playdate.
/// Link: https://kapendev.itch.io/will-of-the-hair-wisp
enum Wisp2 : Rgba {
    black = toRgb(wisp2[0]), /// 0x322F29
    white = toRgb(wisp2[1]), /// 0xDAD6D0
}

/// A 4-color palette inspired by the Game Boy.
/// Link: https://lospec.com/palette-list/2-bit-matrix
enum Gb4 : Rgba {
    black     = toRgb(gb4[0]), /// 0x343434
    darkGray  = toRgb(gb4[1]), /// 0x5B8C7C
    lightGray = toRgb(gb4[2]), /// 0xADD9BC
    white     = toRgb(gb4[3]), /// 0xF2FFF2
}

/// An 8-color palette inspired by the NES.
/// Link: https://lospec.com/palette-list/mf-8
enum Nes8 : Rgba {
    black  = toRgb(nes8[0]), /// 0x292320
    brown  = toRgb(nes8[1]), /// 0xA7763E
    purple = toRgb(nes8[2]), /// 0x7F339A
    red    = toRgb(nes8[3]), /// 0xE04113
    green  = toRgb(nes8[4]), /// 0x32A75C
    blue   = toRgb(nes8[5]), /// 0x1AC1FE
    yellow = toRgb(nes8[6]), /// 0xFDD156
    white  = toRgb(nes8[7]), /// 0xFCF8EA
}

/// A 16-color palette used by the PICO-8.
/// Link: https://lospec.com/palette-list/pico-8
enum Pico8 : Rgba {
    black      = toRgb(pico8[0]),  /// 0x000000
    navy       = toRgb(pico8[1]),  /// 0x1D2B53
    maroon     = toRgb(pico8[2]),  /// 0x7E2553
    darkGreen  = toRgb(pico8[3]),  /// 0x008751
    brown      = toRgb(pico8[4]),  /// 0xAB5236
    darkGray   = toRgb(pico8[5]),  /// 0x5F574F
    lightGray  = toRgb(pico8[6]),  /// 0xC2C3C7
    white      = toRgb(pico8[7]),  /// 0xFFF1E8
    red        = toRgb(pico8[8]),  /// 0xFF004D
    orange     = toRgb(pico8[9]),  /// 0xFFA300
    yellow     = toRgb(pico8[10]), /// 0xFFEC27
    lightGreen = toRgb(pico8[11]), /// 0x00E436
    blue       = toRgb(pico8[12]), /// 0x29ADFF
    purple     = toRgb(pico8[13]), /// 0x83769C
    pink       = toRgb(pico8[14]), /// 0xFF77A8
    peach      = toRgb(pico8[15]), /// 0xFFCCAA
}

/// A 2-color palette inspired by the Playdate.
/// Link: https://kapendev.itch.io/will-of-the-hair-wisp
immutable HexPalette!2 wisp2 = [
    0x322F29,
    0xDAD6D0,
];

/// A 4-color palette inspired by the Game Boy.
/// Link: https://lospec.com/palette-list/2-bit-matrix
immutable HexPalette!4 gb4 = [
    0x343434,
    0x5B8C7C,
    0xADD9BC,
    0xF2FFF2,
];

/// An 8-color palette inspired by the NES.
/// Link: https://lospec.com/palette-list/mf-8
immutable HexPalette!8 nes8 = [
    0x292320,
    0xA7763E,
    0x7F339A,
    0xE04113,
    0x32A75C,
    0x1AC1FE,
    0xFDD156,
    0xFCF8EA,
];

/// A 16-color palette used by the PICO-8.
/// Link: https://lospec.com/palette-list/pico-8
immutable HexPalette!16 pico8 = [
    0x000000,
    0x1D2B53,
    0x7E2553,
    0x008751,
    0xAB5236,
    0x5F574F,
    0xC2C3C7,
    0xFFF1E8,
    0xFF004D,
    0xFFA300,
    0xFFEC27,
    0x00E436,
    0x29ADFF,
    0x83769C,
    0xFF77A8,
    0xFFCCAA,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://github.com/morhetz/gruvbox
immutable HexPalette!16 gruvboxDark = [
    0x282828,
    0x3C3836,
    0x504945,
    0x665C54,
    0xBDAE93,
    0xD5C4A1,
    0xEBDBB2,
    0xFBF1C7,
    0xFB4934,
    0xFE8019,
    0xFABD2F,
    0xB8BB26,
    0x8EC07C,
    0x83A598,
    0xD3869B,
    0xD65D0E,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://github.com/morhetz/gruvbox
immutable HexPalette!16 gruvboxLight = [
    0xFBF1C7,
    0xEBDBB2,
    0xD5C4A1,
    0xBDAE93,
    0x665C54,
    0x504945,
    0x3C3836,
    0x282828,
    0x9D0006,
    0xAF3A03,
    0xB57614,
    0x79740E,
    0x427B58,
    0x076678,
    0x8F3F71,
    0xD65D0E,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://github.com/pulsar-edit/pulsar
immutable HexPalette!16 oneDark = [
    0x282C34,
    0x353B45,
    0x3E4451,
    0x545862,
    0x565C64,
    0xABB2BF,
    0xB6BDCA,
    0xC8CCD4,
    0xE06C75,
    0xD19A66,
    0xE5C07B,
    0x98C379,
    0x56B6C2,
    0x61AFEF,
    0xC678DD,
    0xBE5046,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://github.com/pulsar-edit/pulsar
immutable HexPalette!16 oneLight = [
    0xFAFAFA,
    0xF0F0F1,
    0xE5E5E6,
    0xA0A1A7,
    0x696C77,
    0x383A42,
    0x202227,
    0x090A0B,
    0xCA1243,
    0xD75F00,
    0xC18401,
    0x50A14F,
    0x0184BC,
    0x4078F2,
    0xA626A4,
    0x986801,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://ethanschoonover.com/solarized/
immutable HexPalette!16 solarizedDark = [
    0x002B36,
    0x073642,
    0x586E75,
    0x657B83,
    0x839496,
    0x93A1A1,
    0xEEE8D5,
    0xFDF6E3,
    0xDC322F,
    0xCB4B16,
    0xB58900,
    0x859900,
    0x2AA198,
    0x268BD2,
    0x6C71C4,
    0xD33682,
];

/// Based on monkyyy's repo: https://github.com/crazymonkyyy/leet-haker-colors
/// Link: https://ethanschoonover.com/solarized/
immutable HexPalette!16 solarizedLight = [
    0xFDF6E3,
    0xEEE8D5,
    0x93A1A1,
    0x839496,
    0x657B83,
    0x586E75,
    0x073642,
    0x002B36,
    0xDC322F,
    0xCB4B16,
    0xB58900,
    0x859900,
    0x2AA198,
    0x268BD2,
    0x6C71C4,
    0xD33682,
];

/// Flipping orientations.
enum Flip : ubyte {
    none, /// No flipping.
    x,    /// Flipped along the X-axis.
    y,    /// Flipped along the Y-axis.
    xy,   /// Flipped along both X and Y axes.
}

/// A tile with a texture atlas id, size, and position.
struct Tile {
    short width;   /// The width of the tile.
    short height;  /// The height of the tile.
    short id;      /// The atlas id of the tile.
    Flip flip;     /// A value representing flipping orientations.
    byte idOffset; /// An offset added to the id when sampling the atlas.
    Vec2 position; /// The position of the tile.

    @safe nothrow @nogc:

    /// Constructs a tile with the given size, id, and position.
    this(short width, short height, short id, Vec2 position = Vec2()) {
        this.width = width;
        this.height = height;
        this.id = id;
        this.position = position;
    }

    /// Constructs a tile with the given size, id, and position components.
    this(short width, short height, short id, float x, float y) {
        this(width, height, id, Vec2(x, y));
    }

    pragma(inline, true) {
        /// Returns a reference to the x component of the tile position.
        @trusted
        ref float x() {
            return position.x;
        }

        /// Returns a reference to the y component of the tile position.
        @trusted
        ref float y() {
            return position.y;
        }

        /// Returns the row of the tile in the atlas.
        Sz row(Sz colCount) {
            return (id + idOffset) / colCount;
        }

        /// Returns the column of the tile in the atlas.
        Sz col(Sz colCount) {
            return (id + idOffset) % colCount;
        }

        /// Returns the size of the tile as a 2D vector.
        Vec2 size() {
            return Vec2(width, height);
        }

        /// Returns the bounding rectangle of the tile.
        Rect area() {
            return Rect(position, width, height);
        }

        /// Returns the rectangle of the tile in the texture atlas.
        Rect textureArea(Sz colCount) {
            return Rect(col(colCount) * width, row(colCount) * height, width, height);
        }

        /// Returns true if the tile has no valid id.
        bool isEmpty() {
            return !hasId;
        }

        /// Returns true if the tile has a valid id.
        bool hasId() {
            return id + idOffset >= 0;
        }

        /// Returns true if the tile has a non-zero size.
        bool hasSize() {
            return width != 0 && height != 0;
        }

        /// Returns true if the tile has a valid id and a non-zero size.
        bool hasIdAndSize() {
            return (id + idOffset >= 0) && (width != 0 && height != 0);
        }

        /// Returns true if the tile area intersects with the given rectangle.
        bool hasIntersection(Rect otherArea) {
            return area.hasIntersection(otherArea);
        }

        /// Returns true if the tile area intersects with another tile.
        bool hasIntersection(Tile otherTile) {
            return hasIntersection(otherTile.area);
        }

        /// Returns the intersection rectangle of the tile area and the given rectangle.
        Rect intersection(Rect otherArea) {
            return area.intersection(otherArea);
        }

        /// Returns the intersection rectangle of the tile area and another tile.
        Rect intersection(Tile otherTile) {
            return intersection(otherTile.area);
        }

        /// Returns the bounding rectangle of the tile area and the given rectangle.
        Rect merger(Rect otherArea) {
            return area.merger(otherArea);
        }

        /// Returns the bounding rectangle of the tile area and another tile.
        Rect merger(Tile otherTile) {
            return merger(otherTile.area);
        }
    }

    /// Moves the tile to follow the target position at the specified speed.
    void followPosition(Vec2 target, float delta) {
        position = position.moveTo(target, Vec2(delta));
    }

    /// Moves the tile to follow the target position with gradual slowdown.
    void followPositionWithSlowdown(Vec2 target, float delta, float slowdown) {
        position = position.moveToWithSlowdown(target, Vec2(delta), slowdown);
    }
}

/// A single sprite animation, defined by its position in an atlas and playback settings.
struct SpriteAnimation {
    ubyte frameRow;        /// The atlas row this animation plays from.
    ubyte frameCount;      /// The number of frames in the animation.
    ubyte frameSpeed;      /// The playback speed of the animation.
    bool canRepeat = true; /// Whether the animation loops.
}

/// A sprite animation group that picks between 2 animations based on a direction angle.
struct SpriteAnimationGroup2 {
    ubyte[2] frameRows;    /// The atlas row for each directional animation.
    ubyte frameCount;      /// The number of frames in each animation.
    ubyte frameSpeed;      /// The playback speed of the animation.
    bool canRepeat = true; /// Whether the animation loops.

    enum angleStep = 180.0f; /// The angle step in degrees used to snap the input angle.

    @safe nothrow @nogc:

    /// Picks an animation based on the given angle in degrees.
    SpriteAnimation pick(float angle) {
        auto id = (cast(int) round(snap(angle, angleStep) / angleStep)) % frameRows.length;
        return SpriteAnimation(frameRows[id], frameCount, frameSpeed, canRepeat);
    }
}

/// A sprite animation group that picks between 4 animations based on a direction angle.
struct SpriteAnimationGroup4 {
    ubyte[4] frameRows;    /// The atlas row for each directional animation.
    ubyte frameCount;      /// The number of frames in each animation.
    ubyte frameSpeed;      /// The playback speed of the animation.
    bool canRepeat = true; /// Whether the animation loops.

    enum angleStep = 90.0f; /// The angle step in degrees used to snap the input angle.

    @safe nothrow @nogc:

    /// Picks an animation based on the given angle in degrees.
    SpriteAnimation pick(float angle) {
        // NOTE: This is a hack to make things look better in simple cases.
        auto hackAngle = cast(int) round(angle);
        if (hackAngle == 135) return SpriteAnimation(frameRows[1], frameCount, frameSpeed);
        if (hackAngle == -135) return SpriteAnimation(frameRows[3], frameCount, frameSpeed);

        auto id = (cast(int) round(snap(angle, angleStep) / angleStep)) % frameRows.length;
        return SpriteAnimation(frameRows[id], frameCount, frameSpeed, canRepeat);
    }
}

/// A sprite animation group that picks between 8 animations based on a direction angle.
struct SpriteAnimationGroup8 {
    ubyte[8] frameRows;    /// The atlas row for each directional animation.
    ubyte frameCount;      /// The number of frames in each animation.
    ubyte frameSpeed;      /// The playback speed of the animation.
    bool canRepeat = true; /// Whether the animation loops.

    enum angleStep = 45.0f; /// The angle step in degrees used to snap the input angle.

    @safe nothrow @nogc:

    /// Picks an animation based on the given angle in degrees.
    SpriteAnimation pick(float angle) {
        auto id = (cast(int) round(snap(angle, angleStep) / angleStep)) % frameRows.length;
        return SpriteAnimation(frameRows[id], frameCount, frameSpeed, canRepeat);
    }
}

/// A sprite animation group that picks between 16 animations based on a direction angle.
struct SpriteAnimationGroup16 {
    ubyte[16] frameRows;   /// The atlas row for each directional animation.
    ubyte frameCount;      /// The number of frames in each animation.
    ubyte frameSpeed;      /// The playback speed of the animation.
    bool canRepeat = true; /// Whether the animation loops.

    enum angleStep = 22.5f; /// The angle step in degrees used to snap the input angle.

    @safe nothrow @nogc:

    /// Picks an animation based on the given angle in degrees.
    SpriteAnimation pick(float angle) {
        auto id = (cast(int) round(snap(angle, angleStep) / angleStep)) % frameRows.length;
        return SpriteAnimation(frameRows[id], frameCount, frameSpeed, canRepeat);
    }
}

/// A sprite with support for animation, positioning, and movement.
struct Sprite {
    short width;                /// The width of the sprite.
    short height;               /// The height of the sprite.
    ushort atlasLeft;           /// X offset in the texture atlas.
    ushort atlasTop;            /// Y offset in the texture atlas.
    float frameProgress = 0.0f; /// The current animation progress. The value is between 0 and animation.frameCount (exclusive).
    bool isPaused;              /// The pause state of the sprite.
    SpriteAnimation animation;  /// The current animation.
    Vec2 position;              /// The position of the sprite.
    Hook hook;                  /// A value representing the origin point of the drawn object when origin is zero.
    Flip flip;                  /// A value representing flipping orientations.

    @safe nothrow @nogc:

    /// Initializes the sprite with the specified size, atlas position, and optional world position.
    this(short width, short height, ushort atlasLeft, ushort atlasTop, Vec2 position = Vec2(), Hook hook = Hook.topLeft) {
        this.width = width;
        this.height = height;
        this.atlasLeft = atlasLeft;
        this.atlasTop = atlasTop;
        this.position = position;
        this.hook = hook;
    }

    /// Initializes the sprite with the specified size, atlas position, and world position.
    this(short width, short height, ushort atlasLeft, ushort atlasTop, float x, float y, Hook hook = Hook.topLeft) {
        this(width, height, atlasLeft, atlasTop, Vec2(x, y), hook);
    }

    /// Initializes the sprite with the specified size, atlas position, and world position.
    this(short width, short height, ushort atlasLeft, ushort atlasTop, Hook hook) {
        this(width, height, atlasLeft, atlasTop, Vec2(), hook);
    }

    pragma(inline, true) {
        /// Returns a reference to the x component of the sprite position.
        @trusted
        ref float x() {
            return position.x;
        }

        /// Returns a reference to the y component of the sprite position.
        @trusted
        ref float y() {
            return position.y;
        }

        /// Returns the size of the sprite as a 2D vector.
        Vec2 size() {
            return Vec2(width, height);
        }

        /// Returns the bounding rectangle of the sprite, adjusted by the hook.
        Rect area() {
            return Rect(position, width, height).area(hook); // NOTE: Can be bad if someone sets a custom origin in the options.
        }

        /// Returns true if the sprite has a non-zero size.
        bool hasSize() {
            return width != 0 && height != 0;
        }

        /// Returns true if the sprite is currently active (running).
        bool isActive() {
            return animation.frameCount != 0;
        }

        /// Returns true if the sprite has an animation assigned.
        bool hasAnimation() {
            return isActive;
        }

        /// Returns true if the sprite is on the first animation frame.
        bool hasFirstFrame() {
            return hasAnimation ? frame == 0 : false;
        }

        /// Returns true if the sprite is on the last animation frame.
        bool hasLastFrame() {
            return hasAnimation ? frame == animation.frameCount - 1 : false;
        }

        /// Returns true if the sprite is on the first animation frame progress.
        bool hasFirstFrameProgress() {
            return hasAnimation ? frameProgress.fequals(0.0f) : false;
        }

        /// Returns true if the sprite is on the last animation frame progress.
        bool hasLastFrameProgress() {
            return hasAnimation ? frameProgress.fequals(animation.frameCount - epsilon) : false;
        }

        /// Returns the current animation frame of the sprite.
        int frame() {
            return cast(int) frameProgress;
        }

        /// Resets the animation frame of the sprite.
        void reset(int resetFrame = 0) {
            frameProgress = resetFrame;
        }

        /// Starts playing a new animation, optionally preserving current frame progress.
        void play(SpriteAnimation newAnimation, bool canKeepProgress = false) {
            if (animation == newAnimation) return;
            if (!canKeepProgress) frameProgress = 0.0f;
            animation = newAnimation;
            isPaused = false;
        }

        /// Stops the current animation of the sprite.
        void stop() {
            play(SpriteAnimation());
        }

        /// Pauses the current animation of the sprite.
        void pause() {
            isPaused = true;
        }

        /// Resumes the current animation of the sprite.
        void resume() {
            isPaused = false;
        }

        /// Toggles the paused state of the sprite.
        void toggleIsPaused() {
            if (isPaused) resume();
            else pause();
        }

        /// Updates the state of the sprite.
        void update(float dt) {
            if (!isActive || isPaused) return;
            if (animation.canRepeat) frameProgress = fmod(frameProgress + animation.frameSpeed * dt, animation.frameCount);
            else frameProgress = min(frameProgress + animation.frameSpeed * dt, animation.frameCount - epsilon);
        }

        /// Moves the sprite to follow the target position at the specified speed.
        void followPosition(Vec2 target, float delta) {
            position = position.moveTo(target, Vec2(delta));
        }

        /// Moves the sprite to follow the target position with gradual slowdown.
        void followPositionWithSlowdown(Vec2 target, float delta, float slowdown) {
            position = position.moveToWithSlowdown(target, Vec2(delta), slowdown);
        }
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

/// Converts a CSV row to a color palette.
/// If the row can't be parsed, then the first value of the palette will be blank.
Palette!N csvRowToPalette(Sz N)(IStr csv, Sz row = 0, Sz startCol = 0) {
    Palette!N result = void;

    auto line = csv.skipLine();
    while (row > 0) { row -= 1; line = csv.skipLine(); }
    auto fields = line.split(',');
    if (startCol >= fields.length) return Palette!N();
    fields = fields[startCol .. $];
    if (fields.length != N) return Palette!N();

    foreach (i, field; fields) {
        auto value = field.toRgba();
        if (value == blank) return Palette!N();
        result[i] = value;
    }
    return result;
}
