// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/popka
// Version: v0.0.18
// ---

/// The `sprite` module provides a simple and extensible sprite.
module popka.sprite;

import popka.engine;

@safe @nogc nothrow:

// TODO: Think about gaps in an atlas texture.

struct Sprite {
    int width;
    int height;
    int atlasLeft;
    int atlasTop;
    int frameCount = 1;
    float frameSpeed = 1.0f;
    float frameProgress = 0.0f;

    @safe @nogc nothrow:

    this(int width, int height, int atlasLeft, int atlasTop, int frameCount = 1, float frameSpeed = 1.0f) {
        this.width = width;
        this.height = height;
        this.atlasLeft = atlasLeft;
        this.atlasTop = atlasTop;
        this.frameCount = frameCount;
        this.frameSpeed = frameSpeed;
    }

    this(int width, int height) {
        this(width, height, 0, 0);
    }

    int frame() {
        return cast(int) frameProgress;
    }

    void reset() {
        frameProgress = 0.0f;
    }

    void update(float dt) {
        frameProgress = wrap(frameProgress + frameSpeed * dt, 0.0f, frameCount);
    }
}

void drawSprite(Texture texture, Sprite sprite, Vec2 position, DrawOptions options = DrawOptions()) {
    auto gridWidth = max(texture.width - sprite.atlasLeft, 0) / sprite.width;
    auto gridHeight = max(texture.height - sprite.atlasTop, 0) / sprite.height;
    if (gridWidth == 0 || gridHeight == 0) {
        return;
    }
    auto row = sprite.frame / gridWidth;
    auto col = sprite.frame % gridWidth;
    auto area = Rect(sprite.atlasLeft + col * sprite.width, sprite.atlasTop + row * sprite.height, sprite.width, sprite.height);
    drawTextureArea(texture, area, position, options);
}

void drawSprite(TextureId texture, Sprite sprite, Vec2 position, DrawOptions options = DrawOptions()) {
    drawSprite(texture.getOr(), sprite, position, options);
}
