/// This example shows how to draw a 9-patch texture in Parin.

import parin;

auto atlas = TextureId();
auto patchAtlasArea = Rect(5 * 16, 1 * 16, Vec2(16 * 3));

void ready() {
    lockResolution(320, 180);
    atlas = loadTexture("atlas.png");
}

bool update(float dt) {
    auto start = Vec2(8);
    // Draw a 9-patch texture with a size based on the mouse position.
    drawTexturePatch(atlas, patchAtlasArea, Rect(start, mouse - start), true);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
