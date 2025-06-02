/// This example shows how to use some of the debug functions of Parin.

import parin;

auto tileInfoMode = false;
auto camera = Camera(420, 69); // Create a camera at position (420, 69).

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Toggle debug information.
    if (Keyboard.space.isPressed) tileInfoMode = !tileInfoMode;
    // Draw debug information.
    if (tileInfoMode) {
        drawDebugTileInfo(16, 16, Vec2(8, 20), camera);
    } else {
        /// Hold the left mouse button to create and resize a debug area.
        /// Hold the right mouse button to move the debug area.
        /// Press the middle mouse button to clear the debug area.
        drawDebugEngineInfo(Vec2(8, 20), camera);
    }
    drawDebugText("Press SPACE to change information.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
