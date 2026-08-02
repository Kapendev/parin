/// This example shows how to use the built-in texture depth sorting of Parin.

import parin;

auto position = Vec2(320 / 2 + 64, 180 / 2 - 16);
auto atlas = TextureId();

void ready() {
    lockResolution(320, 180);
    atlas = loadTexture("parin_atlas.png");
}

bool update(float dt) {
    position += wasd * 120 * dt;
    // Sort and draw the objects at the end of the scope.
    // This can also be done with the `beginDepthSort` and `endDepthSort` functions.
    // NOTE: Depth sorting only supports textures. Keep other things outside of this scope.
    with (DepthSort(DepthSortMode.topDown)) {
        auto options = DrawOptions(Vec2(2));
        drawTextureArea(atlas, Rect(11 * 16, 0, 16, 16), position, options);
        drawTextureArea(atlas, Rect(10 * 16, 0, 16, 16), Vec2(140, 50), options);
        drawTextureArea(atlas, Rect(10 * 16, 0, 16, 16), Vec2(140, 90), options);
        drawTextureArea(atlas, Rect(10 * 16, 0, 16, 16), Vec2(140, 130), options);
    }
    drawText("Move with arrow keys.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
