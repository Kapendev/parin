/// This example shows how to use some of the debug functions of Parin.

import parin;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Change the debug mode.
    if (Keyboard.space.isPressed) toggleIsDebugMode();
    // Update based on debug mode.
    if (isDebugMode) drawDebugEngineInfo(Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
