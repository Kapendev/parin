/// This example shows how to draw textures in a Pico-8–style workflow.

import parin;

auto position = Vec2(320 / 2 - 16, 180 / 2 - 16);

void ready() {
    lockResolution(320, 180);
    // Set the default texture and area size that will be used by the draw functions.
    setDefaultTexture(loadTexture("parin_atlas.png"));
    setDefaultTextureAreaSize(Vec2(16));
}

bool update(float dt) {
    position += wasd * 120 * dt;
    // Draw a texture area using a Pico-8–style ID.
    drawTextureArea(58 + cast(int) fmod(elapsedTime * 2, 4), position, DrawOptions(Vec2(2)));
    drawText("Move with arrow keys.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
