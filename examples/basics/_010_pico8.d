/// This example shows how to draw textures in a Pico-8–style workflow.

import parin;

auto position = Vec2(320 / 2 - 16, 180 / 2 - 16);

void ready() {
    lockResolution(320, 180);
    setDrawIdOptions(loadTexture("parin_atlas.png"), Vec2(16));
}

bool update(float dt) {
    position += wasd * 120 * dt;
    // Draw a texture area using a Pico-8–style ID.
    drawId(58 + cast(int) fmod(elapsedTime * 2, 4), position, DrawOptions(Vec2(2)));
    drawText("Move with arrow keys.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);

// --- Pico8 workflow

auto drawIdAtlas    = TextureId(); /// The atlas texture that has all the game tiles.
auto drawIdAreaSize = Vec2(16);    /// The size of the tiles on the atlas texture.
auto drawIdColCount = 64;          /// The amount of tiles inside a column on the atlas texture.

/// Sets the texture and area size that will be used by the `drawId` function.
void setDrawIdOptions(TextureId texture, Vec2 areaSize, int colCount = -1) {
    drawIdAtlas = texture;
    drawIdAreaSize = areaSize;
    if (drawIdAtlas.isValid) {
        drawIdColCount = (colCount <= 1) ? (drawIdAtlas.width / cast(int) areaSize.x) : colCount;
    } else {
        assert(0, "Cannot set default texture area size because the default texture is invalid or not assigned.");
    }
}

/// Draws a portion of the default texture by ID at the given position with the specified draw options.
/// Call `setDrawIdOptions` before using this function.
void drawId(int id, Vec2 position, DrawOptions options = DrawOptions()) {
    if (drawIdColCount == 0) assert(0, "Cannot draw texture area by ID because `setDefaultTextureAreaSize` was not called.");
    auto col = id % drawIdColCount;
    auto row = id / drawIdColCount;
    drawTextureArea(drawIdAtlas, Rect(col * drawIdAreaSize.x, row * drawIdAreaSize.y, drawIdAreaSize), position, options);
}
