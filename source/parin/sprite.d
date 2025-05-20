// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.44
// ---

// TODO: Think about gaps in an atlas texture.
// TODO: Update all the doc comments here.

/// The `sprite` module provides a simple and flexible sprite.
module parin.sprite;

import parin.engine;

@safe @nogc nothrow:

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

    @safe @nogc nothrow:

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

    @safe @nogc nothrow:

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

    @safe @nogc nothrow:

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

    @safe @nogc nothrow:

    SpriteAnimation pick(float angle) {
        auto id = (cast(int) round(snap(angle, angleStep) / angleStep)) % frameRows.length;
        return SpriteAnimation(frameRows[id], frameCount, frameSpeed, canRepeat);
    }
}

struct Sprite {
    int width;
    int height;
    ushort atlasLeft;
    ushort atlasTop;
    float frameProgress = 0.0f;
    SpriteAnimation animation;
    Vec2 position;
    bool isPaused;
    bool isPlaying;

    @safe @nogc nothrow:

    this(int width, int height, ushort atlasLeft, ushort atlasTop, Vec2 position = Vec2()) {
        this.width = width;
        this.height = height;
        this.atlasLeft = atlasLeft;
        this.atlasTop = atlasTop;
        this.position = position;
    }

    bool hasAnimation() {
        return animation.frameCount != 0;
    }

    bool hasFirstFrame() {
        return frame == 0;
    }

    bool hasLastFrame() {
        return hasAnimation ? (frame == animation.frameCount - 1) : true;
    }

    bool hasFirstFrameProgress() {
        return frameProgress == 0.0f;
    }

    bool hasLastFrameProgress() {
        return hasAnimation ? (frameProgress.fequals(animation.frameCount - epsilon)) : true;
    }

    Vec2 size() {
        return Vec2(width, height);
    }

    int frame() {
        return cast(int) frameProgress;
    }

    void reset(int resetFrame = 0) {
        frameProgress = resetFrame;
    }

    void play(SpriteAnimation newAnimation, bool canKeepProgress = false) {
        if (isPaused || animation == newAnimation) return;
        if (!canKeepProgress) reset();
        animation = newAnimation;
        isPlaying = true;
    }

    void stop() {
        if (isPaused) return;
        play(SpriteAnimation());
        isPlaying = false;
    }

    void pause() {
        isPaused = true;
    }

    void resume() {
        isPaused = false;
    }

    void update(float dt) {
        if (!hasAnimation || isPaused || !isPlaying) return;
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

void drawSpriteX(Texture texture, Sprite sprite, DrawOptions options = DrawOptions()) {
    if (sprite.width == 0 || sprite.height == 0) return;
    if (texture.isEmpty) {
        if (isEmptyTextureVisible) {
            auto rect = Rect(sprite.position, sprite.size * options.scale).area(options.hook);
            drawRect(rect, defaultEngineEmptyTextureColor);
            drawHollowRect(rect, 1, black);
        }
        return;
    }

    auto top = sprite.atlasTop + sprite.animation.frameRow * sprite.height;
    auto gridWidth = max(texture.width - sprite.atlasLeft, 0) / sprite.width;
    auto gridHeight = max(texture.height - top, 0) / sprite.height;
    if (gridWidth == 0 || gridHeight == 0) return;

    auto row = sprite.frame / gridWidth;
    auto col = sprite.frame % gridWidth;
    auto area = Rect(sprite.atlasLeft + col * sprite.width, top + row * sprite.height, sprite.width, sprite.height);
    drawTextureAreaX(texture, area, sprite.position, options);
}

void drawSprite(TextureId texture, Sprite sprite, DrawOptions options = DrawOptions()) {
    drawSpriteX(texture.getOr(), sprite, options);
}
