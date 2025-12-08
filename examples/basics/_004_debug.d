/// This example shows how to use some of the debug functions of Parin.

import parin;

// The current mode of the game.
auto mode = Mode.engineInfo;

// The update function is split into 3 parts.
enum Mode {
    engineInfo,
    printInfo,
}

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Change the debug mode.
    if (Keyboard.space.isPressed) {
        mode = cast(Mode) wrap(mode + 1, Mode.min, Mode.max + 1);
    }
    // Hide the dprint text if mode is not `printInfo`.
    setDprintVisibility(mode == Mode.printInfo);
    // Update based on the current mode.
    final switch (mode) {
        case Mode.printInfo:
            if (Keyboard.space.isPressed) dprintln("SPACE!");
            if (Keyboard.enter.isPressed) dprintln(elapsedTime);
            if (Keyboard.esc.isPressed && dprintBuffer.length) print("---\n", dprintBuffer);
            break;
        case Mode.engineInfo:
            drawDebugEngineInfo(defaultEngineDprintPosition);
            break;
    }
    return false;
}

mixin runGame!(ready, update, null);
