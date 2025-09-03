// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `sprite` module provides a simple and flexible sprite.
module parin.sprite;

import parin.engine;

@safe nothrow @nogc:

struct SpriteAnimation {
    ubyte frameRow;
    ubyte frameCount;
    ubyte frameSpeed;
    bool canRepeat = true;
}

struct SpriteAnimationGroup2 {
    ubyte[2] frameRows;
    ubyte frameCount;
    ubyte frameSpeed;
    bool canRepeat = true;

    enum angleStep = 180.0f;

    @safe nothrow @nogc:

    SpriteAnimation pick(float angle) {
        auto id = (cast(int) round(snap(angle, angleStep) / angleStep)) % frameRows.length;
        return SpriteAnimation(frameRows[id], frameCount, frameSpeed, canRepeat);
    }
}

struct SpriteAnimationGroup4 {
    ubyte[4] frameRows;
    ubyte frameCount;
    ubyte frameSpeed;
    bool canRepeat = true;

    enum angleStep = 90.0f;

    @safe nothrow @nogc:

    SpriteAnimation pick(float angle) {
        // NOTE: This is a hack to make things look better in simple cases.
        auto hackAngle = cast(int) round(angle);
        if (hackAngle == 135) return SpriteAnimation(frameRows[1], frameCount, frameSpeed);
        if (hackAngle == -135) return SpriteAnimation(frameRows[3], frameCount, frameSpeed);

        auto id = (cast(int) round(snap(angle, angleStep) / angleStep)) % frameRows.length;
        return SpriteAnimation(frameRows[id], frameCount, frameSpeed, canRepeat);
    }
}

struct SpriteAnimationGroup8 {
    ubyte[8] frameRows;
    ubyte frameCount;
    ubyte frameSpeed;
    bool canRepeat = true;

    enum angleStep = 45.0f;

    @safe nothrow @nogc:

    SpriteAnimation pick(float angle) {
        auto id = (cast(int) round(snap(angle, angleStep) / angleStep)) % frameRows.length;
        return SpriteAnimation(frameRows[id], frameCount, frameSpeed, canRepeat);
    }
}

struct SpriteAnimationGroup16 {
    ubyte[16] frameRows;
    ubyte frameCount;
    ubyte frameSpeed;
    bool canRepeat = true;

    enum angleStep = 22.5f;

    @safe nothrow @nogc:

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

    deprecated("Will be replaced with isActive.")
    alias isRunning = isActive;

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

    this(short width, short height, ushort atlasLeft, ushort atlasTop, Hook hook) {
        this(width, height, atlasLeft, atlasTop, Vec2(), hook);
    }

    pragma(inline, true) {
        @trusted ref float x() => position.x;
        @trusted ref float y() => position.y;
        Vec2 size() => Vec2(width, height);
        Rect area() => Rect(position, width, height).area(hook); // NOTE: Can be bad if someone sets a custom origin in the options.
        bool hasSize() => width != 0 && height != 0;

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
        void followPosition(Vec2 target, float speed) {
            position = position.moveTo(target, Vec2(speed));
        }

        /// Moves the sprite to follow the target position with gradual slowdown.
        void followPositionWithSlowdown(Vec2 target, float slowdown) {
            position = position.moveToWithSlowdown(target, Vec2(deltaTime), slowdown);
        }
    }
}

void drawSprite(Texture texture, Sprite sprite, DrawOptions options = DrawOptions()) {
    options.hook = sprite.hook; // NOTE: Might be a bad idea in the future.
    options.flip = sprite.flip; // NOTE: Might be a bad idea in the future.

    version (ParinSkipDrawChecks) {
    } else {
        if (texture.isEmpty) {
            if (isEmptyTextureVisible) {
                auto rect = Rect(sprite.position, sprite.size * options.scale).area(options.hook);
                drawRect(rect, defaultEngineEmptyTextureColor);
                drawHollowRect(rect, 1, black);
            }
            return;
        }
        if (!sprite.hasSize) return;
    }

    auto top = sprite.atlasTop + sprite.animation.frameRow * sprite.height;
    auto gridWidth = max(texture.width - sprite.atlasLeft, 0) / sprite.width; // NOTE: Could be saved maybe.

    version (ParinSkipDrawChecks) {
    } else {
        if (gridWidth == 0) return;
    }

    auto row = sprite.frame / gridWidth;
    auto col = sprite.frame % gridWidth;
    auto area = Rect(sprite.atlasLeft + col * sprite.width, top + row * sprite.height, sprite.width, sprite.height);
    drawTextureArea(texture, area, sprite.position, options);
}

void drawSprite(TextureId texture, Sprite sprite, DrawOptions options = DrawOptions()) {
    drawSprite(texture.getOr(), sprite, options);
}

void drawSprite(Sprite sprite, DrawOptions options = DrawOptions()) {
    drawSprite(defaultTexture.getOr(), sprite, options);
}
