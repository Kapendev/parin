// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/popka
// Version: v0.0.19
// ---

// TODO: Think about gaps in an atlas texture.
// TODO: Update all the doc comments here.

/// The `sprite` module provides a simple and flexible sprite.
module popka.sprite;

import popka.engine;

@safe @nogc nothrow:

struct SpriteAnimation {
    ubyte frameRow;
    ubyte frameCount;
    ubyte frameSpeed;

    @safe @nogc nothrow:

    this(ubyte frameRow, ubyte frameCount, ubyte frameSpeed) {
        this.frameRow = frameRow;
        this.frameCount = frameCount;
        this.frameSpeed = frameSpeed;
    }
}

struct Sprite {
    int width;
    int height;
    ushort atlasLeft;
    ushort atlasTop;
    float frameProgress = 0.0f;
    SpriteAnimation animation;

    @safe @nogc nothrow:

    this(int width, int height, ushort atlasLeft, ushort atlasTop, SpriteAnimation animation = SpriteAnimation()) {
        this.width = width;
        this.height = height;
        this.atlasLeft = atlasLeft;
        this.atlasTop = atlasTop;
        this.animation = animation;
    }

    bool hasFirstFrame() {
        return frame == 0;
    }

    bool hasLastFrame() {
        return animation.frameCount != 0 ? (frame == animation.frameCount - 1) : true;
    }

    int frame() {
        return cast(int) frameProgress;
    }

    void reset(int resetFrame = 0) {
        frameProgress = resetFrame;
    }

    void play(SpriteAnimation animation) {
        if (this.animation != animation) {
            reset();
            this.animation = animation;
        }
    }

    void update(float dt) {
        if (animation.frameCount <= 1) return;
        frameProgress = wrap(frameProgress + animation.frameSpeed * dt, 0.0f, animation.frameCount);
    }
}

void drawSprite(Texture texture, Sprite sprite, Vec2 position, DrawOptions options = DrawOptions()) {
    auto top = sprite.atlasTop + sprite.animation.frameRow * sprite.height;
    auto gridWidth = max(texture.width - sprite.atlasLeft, 0) / sprite.width;
    auto gridHeight = max(texture.height - top, 0) / sprite.height;
    if (gridWidth == 0 || gridHeight == 0) {
        return;
    }
    auto row = sprite.frame / gridWidth;
    auto col = sprite.frame % gridWidth;
    auto area = Rect(sprite.atlasLeft + col * sprite.width, top + row * sprite.height, sprite.width, sprite.height);
    drawTextureArea(texture, area, position, options);
}

void drawSprite(TextureId texture, Sprite sprite, Vec2 position, DrawOptions options = DrawOptions()) {
    drawSprite(texture.getOr(), sprite, position, options);
}
