/// This example shows how to use some of the debug functions of Parin.

import parin;

auto mode = Mode.engineInfo;

enum Mode {
    engineInfo,
    tileInfo,
}

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Toggle the current debug mode.
    if (Keyboard.space.isPressed) {
        mode = cast(Mode) !mode;
        trace(mode);
    }
    // Draw the current debug information.
    with (Mode) final switch (mode) {
        case engineInfo:
            // Left mouse button to create an area, right to move the area and middle to remove the area.
            drawDebugEngineInfo(Vec2(8, 20));
            break;
        case tileInfo:
            drawDebugTileInfo(16, 16, Vec2(8, 20));
            break;
    }
    drawDebugText("Press SPACE to toggle the debug mode.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
