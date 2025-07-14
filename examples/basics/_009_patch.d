/// This example shows how to draw a 9-patch in Parin.

import parin;

auto atlas = TextureId();
auto patch = Rect(16 * 5, 16 * 1, Vec2(16 * 3)); // A 9-slice with 16x16 tiles.

void ready() {
    lockResolution(320, 180);
    atlas = loadTexture("parin_atlas.png");
}

bool update(float dt) {
    // Draw a 9-patch with a size based on the mouse position.
    drawTextureSlice(atlas, patch, Rect(Vec2(8), mouse - Vec2(8)), Margin(16), true);
    return false;
}

mixin runGame!(ready, update, null);
