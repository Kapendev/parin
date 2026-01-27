/// This example shows how to use the built-in texture depth sorting of Parin.

import parin;

auto position = Vec2(320 / 2 + 64, 180 / 2 - 16);

void ready() {
    lockResolution(320, 180);
    setDefaultTexture(loadTexture("parin_atlas.png"));
    setDefaultTextureAreaSize(Vec2(16));
}

bool update(float dt) {
    position += wasd * 120 * dt;
    // Sort and draw the objects at the end of the scope.
    // This can also be done with the `beginDepthSort` and `endDepthSort` functions.
    // NOTE: Depth sorting only supports textures. Keep other things outside of this scope.
    with (DepthSort()) {
        auto options = DrawOptions(Vec2(2));
        drawTextureArea(19, position, options);
        drawTextureArea(20, Vec2(140, 50), options);
        drawTextureArea(20, Vec2(140, 90), options);
        drawTextureArea(20, Vec2(140, 130), options);
    }
    drawText("Move with arrow keys.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
