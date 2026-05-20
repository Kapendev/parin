// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `game` module provides game related types and functions.
module parin.joka.game;

import parin.joka.memory;
import parin.joka.math;
import parin.joka.types;

@safe nothrow @nogc:

enum defaultStoryFixedListCapacity = 16;

alias Palette(Sz N)    = StaticArray!(Rgba, N); /// A generic color palette of RGBA colors.
alias HexPalette(Sz N) = uint[N];               /// A generic color palette of hexadecimal numbers.

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

/// The kind of a story line.
enum StoryLineKind : ubyte {
    empty = ' ',      /// Not a line.
    comment = '#',    /// A comment.
    label = '*',      /// A label. Can be used to jump to a line.
    text = '|',       /// A line that just has text.
    pause = '.',      /// A line that ends the story.
    menu = '^',       /// A line that can provide user input.
    expression = '$', /// A line that can execute story expressions.
    procedure = '!',  /// A line that can execute D functions.
}

/// An operation in the story expression language.
enum StoryOp : ubyte {
    ADD = '+',
    SUB = '-',
    MUL = '*',
    DIV = '/',
    MOD = '%',
    AND = '&',
    OR = '|',
    LESS = '<',
    GREATER = '>',
    EQUAL = '=',
    NOT = '!',
    POP = '~',
    CLEAR,
    SWAP,
    COPY,
    COPYN,
    RANGE,
    IF,
    ELSE,
    THEN,
    CAT,
    SAME,
    WORD,
    NUMBER,
    LINE,
    DEBUG,
    LINEAR,
    ASSERT,
    END,
    ECHO,
    ECHON,
    LEAK,
    LEAKN,
    HERE,
    GET,
    GETN,
    SET,
    INIT,
    DROP,
    DROPN,
    INC,
    DEC,
    INCN,
    DECN,
    TOG,
    MENU,
    LOOP,
    SKIP,
    JUMP,
}

/// A fixed-size word in the story expression language.
alias StoryWord = char[24];
/// A number in the story expression language.
alias StoryNumber = int;
/// The underlying data of a story value.
alias StoryValueData = Union!(StoryWord, StoryNumber);

/// A value in the story expression language, either a word or a number.
struct StoryValue {
    StoryValueData data;

    alias data this;

    @safe nothrow @nogc:

    static foreach (Type; StoryValueData.Types) {
        this(Type value) {
            data = value;
        }
    }

    @trusted
    IStr toStr() {
        if (data.isType!StoryNumber) {
            return fmt("{}", data.as!StoryNumber());
        } else {
            auto temp = data.as!(StoryWord)()[];
            return fmt("{}", temp[0 .. temp.findStart(char.init)]);
        }
    }
}

/// A named variable in the story expression language.
struct StoryVariable {
    StoryWord name;
    StoryValue value;
}

/// A start and end index pair used to identify ranges in the story.
struct StoryStartEndPair {
    uint a;
    uint b;
}

/// A story script with its associated state for parsing and execution.
struct Story {
    LStr script;
    List!StoryStartEndPair pairs;
    List!StoryVariable labels;
    List!StoryVariable variables;
    StoryNumber lineIndex;
    StoryNumber nextLabelIndex;
    StoryNumber previousMenuResult;
    StoryNumber faultPrepareIndex;
    StoryOp faultOp;
    Sz faultTokenPosition;
    bool debugMode;
    bool linearMode;
    EchonFunc echonFunc;

    @safe nothrow:

    @trusted
    Fault prepare(IStr file = __FILE__, Sz line = __LINE__) {
        previousMenuResult = 0;
        resetLineIndex();
        pairs.clear();
        labels.clear();
        if (script.isEmpty) return Fault.none;
        auto startIndex = StoryNumber.init;
        auto prepareIndex = StoryNumber.init;
        foreach (i, c; script) {
            if (c == '\n') {
                auto pair = StoryStartEndPair(cast(uint) startIndex, cast(uint) i);
                auto scriptLine = script[pair.a .. pair.b + 1];
                pair.a += scriptLine.length - scriptLine.trimStart().length;
                if (pair.a > pair.b) {
                    pair.a = pair.b;
                    scriptLine = script[pair.a .. pair.b];
                } else {
                    pair.b -= scriptLine.length - scriptLine.trimEnd().length;
                    scriptLine = script[pair.a .. pair.b + 1];
                }
                auto kind = toStoryLineKind(scriptLine.length ? script[pair.a] : StoryLineKind.empty);
                if (kind.isNone) {
                    pairs.clear();
                    labels.clear();
                    faultPrepareIndex = prepareIndex;
                    return kind.fault;
                }
                if (kind.xx == StoryLineKind.label) {
                    auto name = scriptLine[1 .. $].trimStart();
                    auto word = StoryWord.init;
                    auto wordRef = word[];
                    if (auto fault = wordRef.copyChars(name)) {
                        pairs.clear();
                        labels.clear();
                        faultPrepareIndex = prepareIndex;
                        return fault;
                    }
                    labels.push(StoryVariable(word, StoryValue(cast(StoryNumber) pairs.length)), file, line);
                }
                pairs.push(pair, file, line);
                prepareIndex += 1;
                startIndex = cast(StoryNumber) (i + 1);
            }
        }
        resetLineIndex();
        return Fault.none;
    }

    Fault parse(IStr text, IStr file = __FILE__, Sz line = __LINE__) {
        script.clear();
        script.appendSource(file, line, text);
        return prepare(file, line);
    }

    // TODO: Needs a refaktor. I added some functions inside it for now to avoid the `__chkstk` error.
    @trusted
    Fault execute(IStr expression, IStr file = __FILE__, Sz line = __LINE__) {
        static FixedList!(StoryValue, defaultStoryFixedListCapacity) stack;
        alias Stack = FixedList!(StoryValue, defaultStoryFixedListCapacity);

        stack.clear();
        auto ifCounter = 0;
        auto tokenCount = 0;
        while (true) with (StoryOp) {
            if (expression.length == 0) break;
            auto token = expression.skipValue(' ');
            tokenCount += 1;
            expression = expression.trimStart();
            if (token.length == 0) continue;
            if (ifCounter > 0) {
                if (token == IF.toStr()) ifCounter += 1;
                if (token == ELSE.toStr() || token == THEN.toStr()) ifCounter -= 1;
                continue;
            }
            if (token.isMaybeStoryOp) {
                auto tempOp = token.toStoryOp();
                if (tempOp.isNone) {
                    faultTokenPosition = tokenCount;
                    return tempOp.fault;
                }
                auto op = tempOp.xx;
                final switch (op) {
                    case ADD:
                    case SUB:
                    case MUL:
                    case DIV:
                    case MOD:
                    case AND:
                    case OR:
                    case LESS:
                    case GREATER:
                    case EQUAL:
                        static Fault doEQUAL(ref Stack stack, StoryOp op, int tokenCount, ref Story story) {
                            with (story) {
                                if (stack.length < 2) return throwOpFault(op, tokenCount);
                                auto db = stack[$ - 1]; stack.pop();
                                auto da = stack[$ - 1]; stack.pop();
                                if (!da.isType!StoryNumber || !db.isType!StoryNumber) return throwOpFault(op, tokenCount);
                                auto a = da.as!StoryNumber;
                                auto b = db.as!StoryNumber;
                                auto c = StoryNumber.init;
                                switch (op) {
                                    case ADD: c = a + b; break;
                                    case SUB: c = a - b; break;
                                    case MUL: c = a * b; break;
                                    case DIV: c = (b != 0) ? (a / b) : 0; break;
                                    case MOD: c = (b != 0) ? (a % b) : 0; break;
                                    case AND: c = a && b; break;
                                    case OR: c = a || b; break;
                                    case LESS: c = a < b; break;
                                    case GREATER: c = a > b; break;
                                    case EQUAL: c = a == b; break;
                                    default: assert(0, "WTF!");
                                }
                                stack.append(StoryValue(c));
                                return Fault.none;
                            }
                        }
                        auto fault = doEQUAL(stack, op, tokenCount, this);
                        if (fault) return fault;
                        break;
                    case NOT:
                        static Fault doNOT(ref Stack stack, StoryOp op, int tokenCount, ref Story story) {
                            with (story) {
                                if (stack.length < 1) return throwOpFault(op, tokenCount);
                                auto da = stack[$ - 1]; stack.pop();
                                if (!da.isType!StoryNumber) return throwOpFault(op, tokenCount);
                                stack.append(StoryValue(!da.as!StoryNumber));
                                return Fault.none;
                            }
                        }
                        auto fault = doNOT(stack, op, tokenCount, this);
                        if (fault) return fault;
                        break;
                    case POP:
                        stack.pop();
                        break;
                    case CLEAR:
                        stack.clear();
                        break;
                    case SWAP:
                        if (stack.length < 2) return throwOpFault(op, tokenCount);
                        auto db = stack[$ - 1]; stack.pop();
                        auto da = stack[$ - 1]; stack.pop();
                        stack.append(db);
                        stack.append(da);
                        break;
                    case COPY:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        stack.append(stack[$ - 1]);
                        break;
                    case COPYN:
                        if (stack.length < 2) return throwOpFault(op, tokenCount);
                        stack.append(stack[$ - 2]);
                        stack.append(stack[$ - 2]);
                        break;
                    case RANGE:
                        static Fault doRANGE(ref Stack stack, StoryOp op, int tokenCount, ref Story story) {
                            with (story) {
                                if (stack.length < 3) return throwOpFault(op, tokenCount);
                                auto dc = stack[$ - 1]; stack.pop();
                                auto db = stack[$ - 1]; stack.pop();
                                auto da = stack[$ - 1]; stack.pop();
                                if (!da.isType!StoryNumber || !db.isType!StoryNumber || !dc.isType!StoryNumber) return throwOpFault(op, tokenCount);
                                auto a = da.as!StoryNumber();
                                auto b = db.as!StoryNumber();
                                auto c = dc.as!StoryNumber();
                                stack.append(StoryValue(a >= b && a <= c));
                                return Fault.none;
                            }
                        }
                        auto fault = doRANGE(stack, op, tokenCount, this);
                        if (fault) return fault;
                        break;
                    case IF:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack[$ - 1]; stack.pop();
                        if (!da.isType!StoryNumber) return throwOpFault(op, tokenCount);
                        if (!da.as!StoryNumber) ifCounter += 1;
                        break;
                    case ELSE:
                        ifCounter += 1;
                        break;
                    case THEN:
                        break;
                    case CAT:
                        static Fault doCAT(ref Stack stack, StoryOp op, int tokenCount, ref Story story) {
                            with (story) {
                                if (stack.length < 2) return throwOpFault(op, tokenCount);
                                auto db = stack[$ - 1]; stack.pop();
                                auto da = stack[$ - 1]; stack.pop();
                                if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                                StoryWord word;
                                auto data = concat(da.toStr(), db.toStr());
                                auto tempWordRef = word[];
                                if (auto fault = tempWordRef.copyChars(data)) {
                                    faultTokenPosition = tokenCount;
                                    return fault;
                                }
                                stack.append(StoryValue(word));
                                return Fault.none;
                            }
                        }
                        auto fault = doCAT(stack, op, tokenCount, this);
                        if (fault) return fault;
                        break;
                    case SAME:
                        static Fault doSAME(ref Stack stack, StoryOp op, int tokenCount, ref Story story) {
                            with (story) {
                                if (stack.length < 2) return throwOpFault(op, tokenCount);
                                auto db = stack[$ - 1]; stack.pop();
                                auto da = stack[$ - 1]; stack.pop();
                                auto a = da.as!StoryWord;
                                auto b = db.as!StoryWord;
                                stack.append(StoryValue(a == b));
                                return Fault.none;
                            }
                        }
                        auto fault = doSAME(stack, op, tokenCount, this);
                        if (fault) return fault;
                        break;
                    case WORD:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack[$ - 1]; stack.pop();
                        stack.append(StoryValue(da.isType!StoryWord));
                        break;
                    case NUMBER:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack[$ - 1]; stack.pop();
                        stack.append(StoryValue(da.isType!StoryNumber));
                        break;
                    case LINE:
                        stack.append(StoryValue(lineIndex + 1));
                        break;
                    case DEBUG:
                        stack.append(StoryValue(debugMode));
                        break;
                    case LINEAR:
                        stack.append(StoryValue(linearMode));
                        break;
                    case ASSERT:
                        if (stack.length) {
                            auto da = stack[$ - 1]; stack.pop();
                            if (da.isType!StoryWord || (da.isType!StoryNumber && !da.as!StoryNumber())) return Fault.assertion;
                        } else {
                            return Fault.assertion;
                        }
                        break;
                    case END:
                        return Fault.none;
                    case ECHO:
                    case ECHON:
                        auto space = "\n";
                        if (op == ECHON) space = " ";
                        if (stack.length) {
                            echon(stack[$ - 1].toStr(), space);
                            stack.pop();
                        }
                        else echon(space);
                        break;
                    case LEAK:
                    case LEAKN:
                        echon("Stack: [");
                        foreach (i, item; stack) {
                            auto space = " ";
                            auto separator = ",";
                            if (i == stack.length - 1) {
                                space = "";
                                separator = "";
                            }
                            echon(item.toStr(), separator, space);
                        }
                        echon("]\n");
                        if (op == LEAKN) {
                            echon("Variables: [");
                            foreach (i, item; variables) {
                                auto space = " ";
                                auto separator = ",";
                                if (i == variables.length - 1) {
                                    space = "";
                                    separator = "";
                                }
                                echon(StoryValue(item.name).toStr(), ": ", item.value.toStr(), separator, space);
                            }
                            echon("]\n");
                        }
                        break;
                    case HERE:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack[$ - 1]; stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        stack.append(StoryValue(findVariable(a) != -1));
                        break;
                    case GET:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack[$ - 1]; stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            stack.append(variables[aIndex].value);
                        } else {
                            return throwOpFault(op, tokenCount);
                        }
                        break;
                    case GETN:
                        static Fault doGETN(ref Stack stack, StoryOp op, int tokenCount, ref Story story) {
                            with (story) {
                                if (stack.length < 2) return throwOpFault(op, tokenCount);
                                auto db = stack[$ - 1]; stack.pop();
                                auto da = stack[$ - 1]; stack.pop();
                                if (!da.isType!StoryWord || !db.isType!StoryWord) return throwOpFault(op, tokenCount);
                                auto a = da.as!StoryWord();
                                auto b = db.as!StoryWord();
                                auto aIndex = findVariable(a);
                                auto bIndex = findVariable(b);
                                if (aIndex != -1 && bIndex != -1) {
                                    stack.append(variables[aIndex].value);
                                    stack.append(variables[bIndex].value);
                                } else {
                                    return throwOpFault(op, tokenCount);
                                }
                                return Fault.none;
                            }
                        }
                        auto fault = doGETN(stack, op, tokenCount, this);
                        if (fault) return fault;
                        break;
                    case SET:
                        static Fault doSET(ref Stack stack, StoryOp op, int tokenCount, ref Story story) {
                            with (story) {
                                if (stack.length < 2) return throwOpFault(op, tokenCount);
                                auto db = stack[$ - 1]; stack.pop();
                                auto da = stack[$ - 1]; stack.pop();
                                if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                                auto a = da.as!StoryWord();
                                auto aIndex = findVariable(a);
                                if (aIndex != -1) {
                                    variables[aIndex].value = db;
                                } else {
                                    variables.push(StoryVariable(a, db));
                                }
                                return Fault.none;
                            }
                        }
                        auto fault = doSET(stack, op, tokenCount, this);
                        if (fault) return fault;
                        break;
                    case INIT:
                        static Fault doINIT(ref Stack stack, StoryOp op, int tokenCount, ref Story story) {
                            with (story) {
                                if (stack.length < 1) return throwOpFault(op, tokenCount);
                                auto da = stack[$ - 1]; stack.pop();
                                if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                                auto a = da.as!StoryWord();
                                auto aIndex = findVariable(a);
                                if (aIndex != -1) {
                                    variables[aIndex].value = StoryValue(0);
                                } else {
                                    variables.push(StoryVariable(a, StoryValue(0)));
                                }
                                return Fault.none;
                            }
                        }
                        auto fault = doINIT(stack, op, tokenCount, this);
                        if (fault) return fault;
                        break;
                    case DROP:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack[$ - 1]; stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            variables.remove(aIndex);
                        }
                        break;
                    case DROPN:
                        variables.clear();
                        break;
                    case INC:
                    case DEC:
                        static Fault doDEC(ref Stack stack, StoryOp op, int tokenCount, ref Story story) {
                            with (story) {
                                if (stack.length < 1) return throwOpFault(op, tokenCount);
                                auto da = stack[$ - 1]; stack.pop();
                                if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                                auto a = da.as!StoryWord();
                                auto aIndex = findVariable(a);
                                if (aIndex != -1) {
                                    if (variables[aIndex].value.isType!StoryNumber) {
                                        variables[aIndex].value.as!StoryNumber() += (op == INC ? 1 : -1);
                                        stack.append(variables[aIndex].value);
                                    } else {
                                        return throwOpFault(op, tokenCount);
                                    }
                                } else {
                                    return throwOpFault(op, tokenCount);
                                }
                                return Fault.none;
                            }
                        }
                        auto fault = doDEC(stack, op, tokenCount, this);
                        if (fault) return fault;
                        break;
                    case INCN:
                    case DECN:
                        static Fault doDECN(ref Stack stack, StoryOp op, int tokenCount, ref Story story) {
                            with (story) {
                                if (stack.length < 2) return throwOpFault(op, tokenCount);
                                auto db = stack[$ - 1]; stack.pop();
                                auto da = stack[$ - 1]; stack.pop();
                                if (!da.isType!StoryWord || !db.isType!StoryNumber) return throwOpFault(op, tokenCount);
                                auto a = da.as!StoryWord();
                                auto b = db.as!StoryNumber();
                                auto aIndex = findVariable(a);
                                if (aIndex != -1) {
                                    if (variables[aIndex].value.isType!StoryNumber) {
                                        variables[aIndex].value.as!StoryNumber() += b * (op == INCN ? 1 : -1);
                                        stack.append(variables[aIndex].value);
                                    } else {
                                        return throwOpFault(op, tokenCount);
                                    }
                                } else {
                                    return throwOpFault(op, tokenCount);
                                }
                                return Fault.none;
                            }
                        }
                        auto fault = doDECN(stack, op, tokenCount, this);
                        if (fault) return fault;
                        break;
                    case TOG:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack[$ - 1]; stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            if (variables[aIndex].value.isType!StoryNumber) {
                                variables[aIndex].value.as!StoryNumber() = !variables[aIndex].value.as!StoryNumber();
                                stack.append(variables[aIndex].value);
                            } else {
                                return throwOpFault(op, tokenCount);
                            }
                        } else {
                            return throwOpFault(op, tokenCount);
                        }
                        break;
                    case MENU:
                        stack.append(StoryValue(previousMenuResult));
                        break;
                    case LOOP:
                        if (linearMode) break;
                        auto target = nextLabelIndex - 1;
                        if (target < 0 || target >= labels.length || labels.length == 0) {
                            resetLineIndex();
                        } else {
                            jumpLineIndex(target);
                        }
                        break;
                    case SKIP:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack[$ - 1]; stack.pop();
                        if (!da.isType!StoryNumber) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryNumber();
                        if (a == 0) break;
                        if (linearMode) break;
                        auto target = nextLabelIndex + (a > 0 ? a - 1 : a);
                        if (target < 0 || target >= labels.length || labels.length == 0) {
                            resetLineIndex();
                        } else {
                            jumpLineIndex(target);
                        }
                        break;
                    case JUMP:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack[$ - 1]; stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto aIndex = findLabel(a);
                        if (aIndex != -1) {
                            if (linearMode) break;
                            jumpLineIndex(aIndex);
                        } else {
                            return throwOpFault(op, tokenCount);
                        }
                        break;
                }
            } else if (token.isMaybeStoryNumber) {
                auto number = token.toSigned();
                if (number.isNone) {
                    faultTokenPosition = tokenCount;
                    return number.fault;
                }
                stack.append(StoryValue(cast(StoryNumber) number.xx));
            } else if (token.isMaybeStoryWord) {
                auto word = StoryWord.init;
                auto wordRef = word[];
                if (auto fault = wordRef.copyChars(token)) {
                    faultTokenPosition = tokenCount;
                    return fault;
                }
                stack.append(StoryValue(word));
            } else {
                faultTokenPosition = tokenCount;
                return Fault.invalid;
            }
        }
        return Fault.none;
    }

    Fault update(IStr file = __FILE__, Sz line = __LINE__) {
        if (lineCount == 0) return Fault.none;
        setLineIndex(lineIndex + 1);
        while (lineIndex < lineCount && !hasPause && !hasProcedure && !hasMenu && !hasText) {
            auto scriptLine = opIndex(lineIndex);
            if (scriptLine.length) {
                if (scriptLine[0] == StoryLineKind.expression) {
                    auto fault = execute(scriptLine[1 .. $].trimStart(), file, line);
                    if (fault) return fault;
                } else if (scriptLine[0] == StoryLineKind.label) {
                    setNextLabelIndex(nextLabelIndex + 1);
                }
            }
            setLineIndex(lineIndex + 1);
        }
        if (hasPause && lineIndex == lineCount) resetLineIndex();
        return Fault.none;
    }

    Fault select(Sz i, IStr file = __FILE__, Sz line = __LINE__) {
        previousMenuResult = cast(StoryNumber) (i + 1);
        return update(file, line);
    }

    void reserve(Sz capacity, IStr file = __FILE__, Sz line = __LINE__) {
        script.reserve(capacity, file, line);
        pairs.reserve(capacity, file, line);
        labels.reserve(capacity, file, line);
        variables.reserve(capacity, file, line);
    }

    void free(IStr file = __FILE__, Sz line = __LINE__) {
        script.free(file, line);
        pairs.free(file, line);
        labels.free(file, line);
        variables.free(file, line);
        this = Story();
    }

    @safe nothrow @nogc:

    void echon(IStr[] text...) {
        if (echonFunc) echonFunc(text);
    }

    IStr opIndex(Sz i) {
        if (i >= lineCount) assert(0, "Index `[{}]` does not exist.".fmt(i));
        return script[pairs[i].a .. pairs[i].b + 1];
    }

    StoryNumber lineCount() {
        return cast(StoryNumber) pairs.length;
    }

    bool hasKind(StoryLineKind kind) {
        if (lineIndex >= lineCount) return false;
        auto line = opIndex(lineIndex);
        return line.length && line[0] == kind;
    }

    bool hasEnd() {
        return lineIndex == lineCount;
    }

    bool hasPause() {
        if (hasEnd) return true;
        return hasKind(StoryLineKind.pause);
    }

    bool hasProcedure() {
        return hasKind(StoryLineKind.procedure);
    }

    bool hasMenu() {
        return hasKind(StoryLineKind.menu);
    }

    bool hasText() {
        return hasKind(StoryLineKind.text);
    }

    IStr[] procedure() {
        static FixedList!(IStr, defaultStoryFixedListCapacity) buffer;

        buffer.clear();
        if (!hasProcedure) return [];
        auto view = opIndex(lineIndex)[1 .. $].trimStart();
        while (view.length) {
            buffer.append(view.skipValue(' ').trimEnd());
            view = view.trimStart();
        }
        return buffer[];
    }

    IStr[] menu() {
        static FixedList!(IStr, defaultStoryFixedListCapacity) buffer;

        buffer.clear();
        if (!hasMenu) return [];
        auto view = opIndex(lineIndex)[1 .. $].trimStart();
        while (view.length) {
            buffer.append(view.skipValue(StoryLineKind.menu).trimEnd());
            view = view.trimStart();
        }
        return buffer[];
    }

    IStr text() {
        if (!hasText) return "";
        return opIndex(lineIndex)[1 .. $].trimStart();
    }

    Fault throwOpFault(StoryOp op, Sz position) {
        faultOp = op;
        faultTokenPosition = position;
        return Fault.invalid;
    }

    StoryNumber findVariable(StoryWord name) {
        foreach (i, variable; variables) {
            if (name == variable.name) return cast(StoryNumber) i;
        }
        return -1;
    }

    StoryNumber findLabel(StoryWord name) {
        foreach (i, label; labels) {
            if (name == label.name) return cast(StoryNumber) i;
        }
        return -1;
    }

    void setNextLabelIndex(StoryNumber value) {
        nextLabelIndex = cast(StoryNumber) (value % (labels.length + 1));
    }

    void setLineIndex(StoryNumber value) {
        lineIndex = (value) % (lineCount + 1);
    }

    void resetLineIndex() {
        lineIndex = lineCount;
        nextLabelIndex = 0;
    }

    void jumpLineIndex(StoryNumber labelIndex) {
        lineIndex = labels[labelIndex].value.as!StoryNumber();
        setNextLabelIndex(labelIndex + 1);
    }

    void ignoreLeak() {
        // TODO: Maybe think about using an arena for the story stuct.
        script.ignoreLeak();
        pairs.ignoreLeak();
        labels.ignoreLeak();
        variables.ignoreLeak();
    }
}

enum boxNoneId        = 0;
enum boxUnionTypeBit  = (cast(BoxUnionId) 1) << (BoxUnionId.sizeof * 8 - 1);
enum boxErrorMessage  = "Box is invalid or was never assigned.";
enum boxFixedCapacity = 256;

struct GBoxIdPair(T) {
    T x;
    T y;
}

/// A generic box ID.
alias BoxId              = ushort;
/// Generic box flags.
alias BoxFlags           = ushort;
alias BoxUnionId         = BoxId;
alias BoxUnionIdGroup    = FixedList!(BoxUnionId, boxFixedCapacity);

/// An box actor ID.
struct BoxActorId { mixin typed!BoxId; }
/// A box wall ID.
struct BoxWallId  { mixin typed!BoxId; }

/// A generic box ID pair.
alias BoxIdPair        = GBoxIdPair!BoxId;
/// A box actor ID pair.
alias BoxActorIdPair   = GBoxIdPair!BoxActorId;
/// A wall actor ID pair.
alias BoxWallIdPair    = GBoxIdPair!BoxWallId;

alias BoxIdBuffer      = FixedList!(BoxId, boxFixedCapacity);
alias BoxActorIdBuffer = FixedList!(BoxActorId, boxFixedCapacity);
alias BoxWallIdBuffer  = FixedList!(BoxWallId, boxFixedCapacity);

enum BoxUnionType : ubyte {
    wall  = 0x0,
    actor = 0x1,
}

/// The flags of a box.
enum BoxFlag : BoxFlags {
    none       = 0x0,
    isPassable = 0x1,
    isRiding   = 0x2,
}

/// The side of a box.
enum BoxSide : ubyte {
    none,
    top,
    left,
    right,
    bottom,
}

/// The area of a box.
alias Box = SRect;

/// The properties of a box.
struct BoxProperties {
    Vec2 remainder;
    BoxFlags flags;
    BoxSide side;
}

/// The data of a box.
struct BoxData {
    Box area;
    BoxProperties properties;
}

/// A helper for mobing things around a world.
struct BoxMover {
    Vec2 direction;
    Vec2 velocity;
    float speed = 1.0f;
    float acceleration = 0.0f;
    float gravity = 0.0f;
    float jump = 0.0f;
    float gravityFallFactor = 0.7f;
    float decelerationFactor = 0.3f;

    @safe nothrow @nogc:

    this(float speed, float acceleration = 0.0f, float gravity = 0.0f, float jump = 0.0f) {
        this.speed = speed;
        this.acceleration = acceleration;
        this.gravity = gravity;
        this.jump = jump;
    }

    bool isSmooth() {
        return acceleration != 0.0f;
    }

    bool isTopDown() {
        return gravity == 0.0f;
    }

    Vec2 move() {
        if (isTopDown) {
            if (isSmooth) {
                if (direction.x > 0.0f) {
                    velocity.x = min(velocity.x + direction.x * acceleration, direction.x * speed);
                } else if (direction.x < 0.0f) {
                    velocity.x = max(velocity.x + direction.x * acceleration, direction.x * speed);
                }
                if (velocity.x != direction.x * speed) {
                   velocity.x = lerp(velocity.x, 0.0f, decelerationFactor);
                }
                if (direction.y > 0.0f) {
                    velocity.y = min(velocity.y + direction.y * acceleration, direction.y * speed);
                } else if (direction.y < 0.0f) {
                    velocity.y = max(velocity.y + direction.y * acceleration, direction.y * speed);
                }
                if (velocity.y != direction.y * speed) {
                   velocity.y = lerp(velocity.y, 0.0f, decelerationFactor);
                }
            } else {
                velocity.x = direction.x * speed;
                velocity.y = direction.y * speed;
            }
            velocity.x = velocity.x;
            velocity.y = velocity.y;
        } else {
            if (isSmooth) {
                if (direction.x > 0.0f) {
                    velocity.x = min(velocity.x + acceleration, speed);
                } else if (direction.x < 0.0f) {
                    velocity.x = max(velocity.x - acceleration, -speed);
                }
                if (velocity.x != direction.x * speed) {
                   velocity.x = lerp(velocity.x, 0.0f, decelerationFactor);
                }
            } else {
                velocity.x = direction.x * speed;
            }
            velocity.x = velocity.x;
            if (velocity.y > 0.0f) velocity.y += gravity;
            else velocity.y += gravity * gravityFallFactor;
            if (direction.y < 0.0f) velocity.y = -jump;
        }
        return velocity;
    }

    Vec2 move(Vec2 newDirection) {
        direction = newDirection;
        return move();
    }
}

// NOTE: The spatial grid needs some work I think. Some function do not support it? No idea.
/// A box world.
struct BoxWorld {
    List!BoxData walls;
    List!BoxData actors;
    Grid!BoxUnionIdGroup grid;
    BoxIdBuffer collisionIdBuffer;
    BoxIdBuffer squishedIdBuffer;
    int gridTileWidth;
    int gridTileHeight;

    @safe nothrow:

    this(Sz capacity, IStr file = __FILE__, Sz line = __LINE__) {
        reserve(capacity, file, line);
    }

    BoxWallId pushWall(Box box, BoxSide side = BoxSide.none, IStr file = __FILE__, Sz line = __LINE__) {
        auto data = BoxData(box, BoxProperties());
        data.properties.side = side;
        walls.push(data, file, line);
        auto id = cast(BoxId) walls.length;
        if (grid.length != 0) {
            auto point = getGridPoint(box);
            if (isGridPointValid(point)) grid[point.y, point.x].append(id & ~boxUnionTypeBit);
        }
        return BoxWallId(id);
    }

    alias appendWall = pushWall;

    BoxActorId pushActor(Box box, BoxSide side = BoxSide.none, IStr file = __FILE__, Sz line = __LINE__) {
        auto data = BoxData(box, BoxProperties());
        data.properties.side = side;
        actors.push(data, file, line);
        auto id = cast(BoxId) actors.length;
        if (grid.length != 0) {
            auto point = getGridPoint(box);
            if (isGridPointValid(point)) grid[point.y, point.x].append(cast(BoxUnionId) (id | boxUnionTypeBit));
        }
        return BoxActorId(id);
    }

    alias appendActor = pushActor;

    Fault parseWallsCsv(IStr csv, int tileWidth, int tileHeight, IStr file = __FILE__, Sz line = __LINE__) {
        clearWalls();
        if (csv.length == 0) return Fault.invalid;
        auto rowCount = 0;
        auto colCount = 0;
        while (csv.length != 0) {
            rowCount += 1;
            colCount = 0;
            auto csvLine = csv.skipLine();
            while (csvLine.length != 0) {
                colCount += 1;
                auto tile = csvLine.skipValue(',').toSigned();
                if (tile.isNone) {
                    walls.clear();
                    return Fault.invalid;
                }
                if (tile.xx <= -1) continue;
                pushWall(Box((colCount - 1) * tileWidth, (rowCount - 1) * tileHeight, cast(Box.Size) tileWidth, cast(Box.Size) tileHeight), BoxSide.none, file, line);
            }
        }
        return Fault.none;
    }

    void reserve(Sz capacity, IStr file = __FILE__, Sz line = __LINE__) {
        walls.reserve(capacity, file, line);
        actors.reserve(capacity, file, line);
    }

    void enableGrid(Sz rowCount, Sz colCount, int tileWidth, int tileHeight, IStr file = __FILE__, Sz line = __LINE__) {
        gridTileWidth = tileWidth;
        gridTileHeight = tileHeight;
        grid.resizeBlank(rowCount, colCount, file, line);
        foreach (ref group; grid) group.clear();
        foreach (i, wall; walls) {
            auto id = cast(BoxId) (i + 1);
            auto point = getGridPoint(wall.area);
            if (isGridPointValid(point)) grid[point.y, point.x].append(id & ~boxUnionTypeBit);
        }
        foreach (i, actor; actors) {
            auto id = cast(BoxId) (i + 1);
            auto point = getGridPoint(actor.area);
            if (isGridPointValid(point)) grid[point.y, point.x].append(cast(BoxUnionId) (id | boxUnionTypeBit));
        }
    }

    void free(IStr file = __FILE__, Sz line = __LINE__) {
        walls.free(file, line);
        actors.free(file, line);
        grid.free(file, line);
        collisionIdBuffer.clear();
        squishedIdBuffer.clear();
        gridTileWidth = 0;
        gridTileHeight = 0;
    }

    @safe nothrow @nogc:

    void disableGrid() {
        gridTileWidth = 0;
        gridTileHeight = 0;
        grid.clear();
    }

    void removeWall(BoxWallId id) {
        if (id == boxNoneId) assert(0, boxErrorMessage);
        // Goodbye, Mr. Anderson.
        walls[id - 1].area.x = cast(typeof(Box.position.x)) float.max;
        walls[id - 1].properties.flags |= BoxFlag.isPassable;
    }

    void removeActor(BoxActorId id) {
        if (id == boxNoneId) assert(0, boxErrorMessage);
        // Goodbye, Mr. Anderson.
        actors[id - 1].area.x = cast(typeof(Box.position.x)) float.max;
        actors[id - 1].properties.flags |= BoxFlag.isPassable;
    }

    void clearWalls() {
        if (grid.length != 0) return;
        walls.clear();
    }

    void clearActors() {
        if (grid.length != 0) return;
        actors.clear();
    }

    bool isGridPointValid(IVec2 point) {
        return point.x >= 0 && point.y >= 0 && grid.has(point.y, point.x);
    }

    alias getGridPoint = gridPoint;

    IVec2 gridPoint(Box box) {
        if (!grid.length) assert(0, "Can't get a grid point from a disabled grid.");
        return IVec2(
            box.position.x / gridTileWidth - (box.position.x < 0),
            box.position.y / gridTileHeight - (box.position.y < 0),
        );
    }

    alias getWall = wall;

    ref Box wall(BoxWallId id) {
        if (id == boxNoneId) assert(0, boxErrorMessage);
        return walls[id - 1].area;
    }

    alias getWallProperties = wallProperties;

    ref BoxProperties wallProperties(BoxWallId id) {
        if (id == boxNoneId) assert(0, boxErrorMessage);
        return walls[id - 1].properties;
    }

    alias getActor = actor;

    ref Box actor(BoxActorId id) {
        if (id == boxNoneId) assert(0, boxErrorMessage);
        return actors[id - 1].area;
    }

    alias getActorProperties = actorProperties;

    ref BoxProperties actorProperties(BoxActorId id) {
        if (id == boxNoneId) assert(0, boxErrorMessage);
        return actors[id - 1].properties;
    }

    alias getWallCollisions = wallCollisions;

    @trusted
    BoxWallId[] wallCollisions(Box box, bool canStopAtFirst = false) {
        collisionIdBuffer.clear();
        if (grid.length) {
            auto point = getGridPoint(box);
            foreach (y; -1 .. 2) { foreach (x; -1 .. 2) {
                auto otherPoint = IVec2(point.x + x, point.y + y);
                if (!isGridPointValid(otherPoint)) continue;
                foreach (taggedId; grid[otherPoint.y, otherPoint.x]) {
                    auto i = (taggedId & ~boxUnionTypeBit) - 1;
                    auto isActor = taggedId & boxUnionTypeBit;
                    if (isActor) continue;
                    if ((~walls[i].properties.flags & BoxFlag.isPassable) && walls[i].area.hasIntersection(box)) {
                        collisionIdBuffer.push(cast(BoxId) (i + 1));
                        if (canStopAtFirst) return (cast(BoxWallIdBuffer*) &collisionIdBuffer).items;
                    }
                }
            }}
        } else {
            foreach (i, wall; walls) {
                if ((~wall.properties.flags & BoxFlag.isPassable) && wall.area.hasIntersection(box)) {
                    collisionIdBuffer.push(cast(BoxId) (i + 1));
                    if (canStopAtFirst) return (cast(BoxWallIdBuffer*) &collisionIdBuffer).items;
                }
            }
        }
        return (cast(BoxWallIdBuffer*) &collisionIdBuffer).items;
    }

    BoxWallId hasWallCollision(Box box) {
        auto boxes = getWallCollisions(box, true);
        return boxes.length ? boxes[0] : BoxWallId(0);
    }

    BoxWallId hasWallCollision(BoxWallId id) {
        return hasWallCollision(getWall(id));
    }

    BoxWallId hasWallCollision(BoxWallId id1, BoxWallId id2) {
        return getWall(id1).hasIntersection(getWall(id2)) ? id2 : BoxWallId(0);
    }

    alias getActorCollisions = actorCollisions;

    @trusted
    BoxActorId[] actorCollisions(Box box, bool canStopAtFirst = false) {
        collisionIdBuffer.clear();
        if (grid.length) {
            auto point = getGridPoint(box);
            foreach (y; -1 .. 2) { foreach (x; -1 .. 2) {
                auto otherPoint = IVec2(point.x + x, point.y + y);
                if (!isGridPointValid(otherPoint)) continue;
                foreach (taggedId; grid[otherPoint.y, otherPoint.x]) {
                    auto i = (taggedId & ~boxUnionTypeBit) - 1;
                    auto isWall = !(taggedId & boxUnionTypeBit);
                    if (isWall) continue;
                    if ((~actors[i].properties.flags & BoxFlag.isPassable) && actors[i].area.hasIntersection(box)) {
                        collisionIdBuffer.push(cast(BoxId) (i + 1));
                        if (canStopAtFirst) return (cast(BoxActorIdBuffer*) &collisionIdBuffer).items;
                    }
                }
            }}
        } else {
            foreach (i, actor; actors) {
                if ((~actor.properties.flags & BoxFlag.isPassable) && actor.area.hasIntersection(box)) {
                    collisionIdBuffer.push(cast(BoxId) (i + 1));
                    if (canStopAtFirst) return (cast(BoxActorIdBuffer*) &collisionIdBuffer).items;
                }
            }
        }
        return (cast(BoxActorIdBuffer*) &collisionIdBuffer).items;
    }

    BoxActorId hasActorCollision(Box box) {
        auto boxes = getActorCollisions(box, true);
        return boxes.length ? boxes[0] : BoxActorId(0);
    }

    BoxActorId hasActorCollision(BoxActorId id) {
        return hasActorCollision(getActor(id));
    }

    BoxActorId hasActorCollision(BoxActorId id1, BoxActorId id2) {
        return getActor(id1).hasIntersection(getActor(id2)) ? id2 : BoxActorId(0);
    }

    BoxWallId moveActorX(BoxActorId id, float amount) {
        auto actor = &getActor(id);
        auto properties = &getActorProperties(id);
        properties.remainder.x += amount;
        auto move = cast(int) properties.remainder.x.round();
        if (move == 0) return BoxWallId(boxNoneId);

        int moveSign = move.sign();
        properties.remainder.x -= move;
        while (move != 0) {
            auto tempBox = Box(actor.position + IVec2(moveSign, 0), actor.size);
            auto wallId = hasWallCollision(tempBox);
            if (wallId) {
                // One way stuff.
                auto wall = &getWall(wallId);
                auto wallProperties = &getWallProperties(wallId);
                final switch (wallProperties.side) with (BoxSide) {
                    case none:
                        break;
                    case top:
                    case bottom:
                        wallId = boxNoneId;
                        break;
                    case left:
                        if (wall.position.x < actor.position.x || wall.hasIntersection(*actor)) wallId = boxNoneId;
                        break;
                    case right:
                        if (wall.position.x > actor.position.x || wall.hasIntersection(*actor)) wallId = boxNoneId;
                        break;
                }
            }
            if ((~properties.flags & BoxFlag.isPassable) && wallId) {
                return wallId;
            } else {
                // Move.
                if (grid.length) {
                    auto oldPoint = getGridPoint(*actor);
                    actor.position.x += moveSign;
                    move -= moveSign;
                    auto newPoint = getGridPoint(*actor);
                    if (oldPoint != newPoint) {
                        if (isGridPointValid(oldPoint)) {
                            foreach (j, taggedId; grid[oldPoint.y, oldPoint.x]) {
                                auto i = (taggedId & ~boxUnionTypeBit) - 1;
                                auto isActor = taggedId & boxUnionTypeBit;
                                if (isActor && (i + 1 == id)) {
                                    grid[oldPoint.y, oldPoint.x].remove(j);
                                    break;
                                }
                            }
                        }
                        if (isGridPointValid(newPoint)) {
                            grid[newPoint.y, newPoint.x].append(cast(BoxUnionId) (id | boxUnionTypeBit));
                        }
                    }
                } else {
                    actor.position.x += moveSign;
                    move -= moveSign;
                }
            }
        }
        return BoxWallId(boxNoneId);
    }

    BoxWallId moveActorXTo(BoxActorId id, float to, float amount) {
        auto actor = &getActor(id);
        auto target = moveTo(cast(float) actor.position.x, to.floor(), amount);
        return moveActorX(id, target - actor.position.x);
    }

    BoxWallId moveActorXToWithSlowdown(BoxActorId id, float to, float amount, float slowdown) {
        auto actor = &getActor(id);
        auto target = moveToWithSlowdown(cast(float) actor.position.x, to.floor(), amount, slowdown);
        return moveActorX(id, target - actor.position.x);
    }

    BoxWallId moveActorY(BoxActorId id, float amount) {
        auto actor = &getActor(id);
        auto properties = &getActorProperties(id);
        properties.remainder.y += amount;
        auto move = cast(int) properties.remainder.y.round();
        if (move == 0) return BoxWallId(boxNoneId);

        int moveSign = move.sign();
        properties.remainder.y -= move;
        while (move != 0) {
            auto tempBox = Box(actor.position + IVec2(0, moveSign), actor.size);
            auto wallId = hasWallCollision(tempBox);
            if (wallId) {
                // One way stuff.
                auto wall = &getWall(wallId);
                auto wallProperties = &getWallProperties(wallId);
                final switch (wallProperties.side) with (BoxSide) {
                    case none:
                        break;
                    case left:
                    case right:
                        wallId = boxNoneId;
                        break;
                    case top:
                        if (wall.position.y < actor.position.y || wall.hasIntersection(*actor)) wallId = boxNoneId;
                        break;
                    case bottom:
                        if (wall.position.y > actor.position.y || wall.hasIntersection(*actor)) wallId = boxNoneId;
                        break;
                }
            }
            if ((~properties.flags & BoxFlag.isPassable) && wallId) {
                return wallId;
            } else {
                // Move.
                if (grid.length) {
                    auto oldPoint = getGridPoint(*actor);
                    actor.position.y += moveSign;
                    move -= moveSign;
                    auto newPoint = getGridPoint(*actor);
                    if (oldPoint != newPoint) {
                        if (isGridPointValid(oldPoint)) {
                            foreach (j, taggedId; grid[oldPoint.y, oldPoint.x]) {
                                auto i = (taggedId & ~boxUnionTypeBit) - 1;
                                auto isActor = taggedId & boxUnionTypeBit;
                                if (isActor && (i + 1 == id)) {
                                    grid[oldPoint.y, oldPoint.x].remove(j);
                                    break;
                                }
                            }
                        }
                        if (isGridPointValid(newPoint)) {
                            grid[newPoint.y, newPoint.x].append(cast(BoxUnionId) (id | boxUnionTypeBit));
                        }
                    }
                } else {
                    actor.position.y += moveSign;
                    move -= moveSign;
                }
            }
        }
        return BoxWallId(boxNoneId);
    }

    BoxWallId moveActorYTo(BoxActorId id, float to, float amount) {
        auto actor = &getActor(id);
        auto target = moveTo(cast(float) actor.position.y, to.floor(), amount);
        return moveActorY(id, target - actor.position.y);
    }

    BoxWallId moveActorYToWithSlowdown(BoxActorId id, float to, float amount, float slowdown) {
        auto actor = &getActor(id);
        auto target = moveToWithSlowdown(cast(float) actor.position.y, to.floor(), amount, slowdown);
        return moveActorY(id, target - actor.position.y);
    }

    BoxWallIdPair moveActor(BoxActorId id, Vec2 amount) {
        auto result = BoxWallIdPair();
        result.x = cast(int) moveActorX(id, amount.x);
        result.y = cast(int) moveActorY(id, amount.y);
        return result;
    }

    BoxWallIdPair moveActorTo(BoxActorId id, Vec2 to, Vec2 amount) {
        auto actor = &getActor(id);
        auto target = moveTo(actor.position.toVec(), to.floor(), amount);
        return moveActor(id, target - actor.position.toVec());
    }

    BoxWallIdPair moveActorToWithSlowdown(BoxActorId id, Vec2 to, Vec2 amount, float slowdown) {
        auto actor = &getActor(id);
        auto target = moveToWithSlowdown(actor.position.toVec(), to.floor(), amount, slowdown);
        return moveActor(id, target - actor.position.toVec());
    }

    BoxActorId[] moveWallX(BoxWallId id, float amount) {
        return moveWall(id, Vec2(amount, 0.0f));
    }

    BoxActorId[] moveWallXTo(BoxWallId id, float to, float amount) {
        auto wall = &getWall(id);
        auto target = moveTo(cast(float) wall.position.x, to.floor(), amount);
        return moveWallX(id, target - wall.position.x);
    }

    BoxActorId[] moveWallXToWithSlowdown(BoxWallId id, float to, float amount, float slowdown) {
        auto wall = &getWall(id);
        auto target = moveToWithSlowdown(cast(float) wall.position.x, to.floor(), amount, slowdown);
        return moveWallX(id, target - wall.position.x);
    }

    BoxActorId[] moveWallY(BoxWallId id, float amount) {
        return moveWall(id, Vec2(0.0f, amount));
    }

    BoxActorId[] moveWallYTo(BoxWallId id, float to, float amount) {
        auto wall = &getWall(id);
        auto target = moveTo(cast(float) wall.position.y, to.floor(), amount);
        return moveWallY(id, target - wall.position.y);
    }

    BoxActorId[] moveWallYToWithSlowdown(BoxWallId id, float to, float amount, float slowdown) {
        auto wall = &getWall(id);
        auto target = moveToWithSlowdown(cast(float) wall.position.y, to.floor(), amount, slowdown);
        return moveWallY(id, target - wall.position.y);
    }

    @trusted
    BoxActorId[] moveWall(BoxWallId id, Vec2 amount) {
        auto wall = &getWall(id);
        auto properties = &getWallProperties(id);
        if (properties.side) assert(0, "One-way collisions are not yet supported for moving walls.");
        properties.remainder += amount;

        squishedIdBuffer.clear();
        auto move = properties.remainder.round().toIVec();
        if (move.x != 0 || move.y != 0) {
            foreach (i, ref actorData; actors) {
                auto actorProperties = &actorData.properties;
                actorProperties.flags &= ~BoxFlag.isRiding;
                if (!actorProperties.side || (actorProperties.flags & BoxFlag.isPassable)) continue;
                auto rideBox = actorData.area;
                final switch (actorProperties.side) with (BoxSide) {
                    case none: break;
                    case top: rideBox.position.y += 1; break;
                    case left: rideBox.position.x += 1; break;
                    case right: rideBox.position.x -= 1; break;
                    case bottom: rideBox.position.y -= 1; break;
                }
                actorProperties.flags |= wall.hasIntersection(rideBox) ? BoxFlag.isRiding : 0x0;
            }
        }

        if (move.x != 0) {
            properties.remainder.x -= move.x;
            // Move.
            if (grid.length) {
                auto oldPoint = getGridPoint(*wall);
                wall.position.x += move.x;
                auto newPoint = getGridPoint(*wall);
                if (oldPoint != newPoint) {
                    if (isGridPointValid(oldPoint)) {
                        foreach (j, taggedId; grid[oldPoint.y, oldPoint.x]) {
                            auto i = (taggedId & ~boxUnionTypeBit) - 1;
                            auto isWall = !(taggedId & boxUnionTypeBit);
                            if (isWall && (i + 1 == id)) {
                                grid[oldPoint.y, oldPoint.x].remove(j);
                                break;
                            }
                        }
                    }
                    if (isGridPointValid(newPoint)) {
                        grid[newPoint.y, newPoint.x].append(id & ~boxUnionTypeBit);
                    }
                }
            } else {
                wall.position.x += move.x;
            }
            if (~properties.flags & BoxFlag.isPassable) {
                properties.flags |= BoxFlag.isPassable;
                foreach (i, ref actor; actors) {
                    if (actor.properties.flags & BoxFlag.isPassable) continue;
                    if (wall.hasIntersection(actor.area)) {
                        // Push actor.
                        auto wallLeft = wall.position.x;
                        auto wallRight = wall.position.x + wall.size.x;
                        auto actorLeft = actor.area.position.x;
                        auto actorRight = actor.area.position.x + actor.area.size.x;
                        auto actorPushAmount = (move.x > 0) ? (wallRight - actorLeft) : (wallLeft - actorRight);
                        if (moveActorX(BoxActorId(cast(BoxId) (i + 1)), actorPushAmount)) {
                            // Squish actor.
                            squishedIdBuffer.push(cast(BoxId) (i + 1));
                        }
                    } else if (actor.properties.flags & BoxFlag.isRiding) {
                        // Carry actor.
                        moveActorX(BoxActorId(cast(BoxId)  (i + 1)), move.x);
                    }
                }
                properties.flags &= ~BoxFlag.isPassable;
            }
        }
        if (move.y != 0) {
            properties.remainder.y -= move.y;
            // Move.
            if (grid.length) {
                auto oldPoint = getGridPoint(*wall);
                wall.position.y += move.y;
                auto newPoint = getGridPoint(*wall);
                if (oldPoint != newPoint) {
                    if (isGridPointValid(oldPoint)) {
                        foreach (j, taggedId; grid[oldPoint.y, oldPoint.x]) {
                            auto i = (taggedId & ~boxUnionTypeBit) - 1;
                            auto isWall = !(taggedId & boxUnionTypeBit);
                            if (isWall && (i + 1 == id)) {
                                grid[oldPoint.y, oldPoint.x].remove(j);
                                break;
                            }
                        }
                    }
                    if (isGridPointValid(newPoint)) {
                        grid[newPoint.y, newPoint.x].append(id & ~boxUnionTypeBit);
                    }
                }
            } else {
                wall.position.y += move.y;
            }
            if (~properties.flags & BoxFlag.isPassable) {
                properties.flags |= BoxFlag.isPassable;
                foreach (i, ref actor; actors) {
                    if (actor.properties.flags & BoxFlag.isPassable) continue;
                    if (wall.hasIntersection(actor.area)) {
                        // Push actor.
                        auto wallTop = wall.position.y;
                        auto wallBottom = wall.position.y + wall.size.y;
                        auto actorTop = actor.area.position.y;
                        auto actorBottom = actor.area.position.y + actor.area.size.y;
                        auto actorPushAmount = (move.y > 0) ? (wallBottom - actorTop) : (wallTop - actorBottom);
                        if (moveActorY(BoxActorId(cast(BoxId) (i + 1)), actorPushAmount)) {
                            // Squish actor.
                            squishedIdBuffer.push(BoxActorId(cast(BoxId) (i + 1)));
                        }
                    } else if (actor.properties.flags & BoxFlag.isRiding) {
                        // Carry actor.
                        moveActorY(BoxActorId(cast(BoxId) (i + 1)), move.y);
                    }
                }
                properties.flags &= ~BoxFlag.isPassable;
            }
        }
        return (cast(BoxActorIdBuffer*) &squishedIdBuffer).items;
    }

    BoxActorId[] moveWallTo(BoxWallId id, Vec2 to, Vec2 amount) {
        auto wall = &getWall(id);
        auto target = moveTo(wall.position.toVec(), to.floor(), amount);
        return moveWall(id, target - wall.position.toVec());
    }

    BoxActorId[] moveWallToWithSlowdown(BoxWallId id, Vec2 to, Vec2 amount, float slowdown) {
        auto wall = &getWall(id);
        auto target = moveToWithSlowdown(wall.position.toVec(), to.floor(), amount, slowdown);
        return moveWall(id, target - wall.position.toVec());
    }

    void clear() {
        walls.clear();
        actors.clear();
        foreach (ref group; grid) group.clear();
    }

    void ignoreLeak() {
        walls.ignoreLeak();
        actors.ignoreLeak();
        grid.ignoreLeak();
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

bool isMaybeStoryOp(IStr value) {
    if (value.length == 0) return false;
    auto c = value[0];
    if (c.isSymbol) {
        if (c == '_') return false;
        return value.length == 1;
    } else {
        return c.isUpper;
    }
}

bool isMaybeStoryNumber(IStr value) {
    if (value.length == 0) return false;
    auto c = value[0];
    if (c.isSymbol) {
        if (c == '_') return false;
        return value.length >= 2 && value[1].isDigit;
    } else {
        return c.isDigit;
    }
}

bool isMaybeStoryWord(IStr value) {
    if (value.length == 0) return false;
    auto c = value[0];
    return c == '_' || (!c.isUpper && !c.isSymbol);
}

Maybe!StoryLineKind toStoryLineKind(char from) {
    with (StoryLineKind) switch (from) {
        case ' ': return Maybe!StoryLineKind(empty);
        case '#': return Maybe!StoryLineKind(comment);
        case '*': return Maybe!StoryLineKind(label);
        case '|': return Maybe!StoryLineKind(text);
        case '.': return Maybe!StoryLineKind(pause);
        case '^': return Maybe!StoryLineKind(menu);
        case '$': return Maybe!StoryLineKind(expression);
        case '!': return Maybe!StoryLineKind(procedure);
        default : return Maybe!StoryLineKind(Fault.invalid);
    }
}

Maybe!StoryOp toStoryOp(IStr from) {
    with (StoryOp) switch (from) {
        case "+": return Maybe!StoryOp(ADD);
        case "-": return Maybe!StoryOp(SUB);
        case "*": return Maybe!StoryOp(MUL);
        case "/": return Maybe!StoryOp(DIV);
        case "%": return Maybe!StoryOp(MOD);
        case "&": return Maybe!StoryOp(AND);
        case "|": return Maybe!StoryOp(OR);
        case "<": return Maybe!StoryOp(LESS);
        case ">": return Maybe!StoryOp(GREATER);
        case "=": return Maybe!StoryOp(EQUAL);
        case "!": return Maybe!StoryOp(NOT);
        case "~": return Maybe!StoryOp(POP);
        default : break;
    }
    return toEnum!StoryOp(from);
}
