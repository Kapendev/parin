/// This example shows how to use some of the debug functions of Parin.

import parin;

auto tileInfoMode = false;
auto camera = Camera(420, 69); // Create a camera at position (420, 69).

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Toggle debug info.
    if (Keyboard.space.isPressed) tileInfoMode = !tileInfoMode;
    // Draw debuf info.
    if (tileInfoMode) drawDebugTileInfo(16, 16, Vec2(8, 20), camera);
    else drawDebugEngineInfo(Vec2(8, 20), camera);
    drawDebugText("Press SPACE to change information.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
