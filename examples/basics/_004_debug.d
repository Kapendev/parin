/// This example shows how to use some of the debug functions of Parin.

import parin;

auto mode = Mode.printInfo;   // The current mode of the game.
auto hasPressedSpace = false; // Used to check if SPACE has been pressed at least one time.

// The update function is split into 3 parts.
enum Mode {
    printInfo,
    engineInfo,
    tileInfo,
}

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Change the debug mode.
    if (Keyboard.space.isPressed) {
        mode = cast(Mode) wrap(mode + 1, Mode.min, Mode.max + 1);
        dprintln("Mode: ", mode);
        hasPressedSpace = true;
    }
    // Hide the dprint text if mode is not `printInfo`.
    setDprintVisibility(mode == Mode.printInfo);
    // Update based on the current mode.
    final switch (mode) {
        case Mode.printInfo:
            // Print things on the window.
            if (Keyboard.enter.isPressed) dprintln("ENTER!");
            if (Keyboard.backspace.isPressed) dprintln("BACKSPACE!");
            // Print the buffer if needed on the terminal.
            if (Keyboard.esc.isPressed && dprintBuffer.length) print("---\n", dprintBuffer);
            break;
        case Mode.engineInfo:
            drawDebugEngineInfo(defaultEngineDprintPosition);
            break;
        case Mode.tileInfo:
            drawDebugTileInfo(16, 16, defaultEngineDprintPosition);
            break;
    }
    if (!hasPressedSpace) drawText("Press SPACE to change mode.", resolution * Vec2(0.5), DrawOptions(Hook.center));
    return false;
}

mixin runGame!(ready, update, null);
