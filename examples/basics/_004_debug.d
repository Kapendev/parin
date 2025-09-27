/// This example shows how to use some of the debug functions of Parin.

import parin;

auto mode = Mode.printInfo;
auto hasPressedSpace = false;

enum Mode {
    printInfo,
    engineInfo,
    tileInfo,
}

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    with (Keyboard) {
        // Change debug mode.
        if (space.isPressed) {
            mode = cast(Mode) wrap(mode + 1, Mode.min, Mode.max + 1);
            dprintln("Mode: ", mode);
            hasPressedSpace = true;
        }
        // Print things on the window.
        if (enter.isPressed) dprintln("ENTER!");
        if (backspace.isPressed) dprintln("BACKSPACE!");
        if (shift.isPressed || shiftRight.isPressed) dprintln("SHIFT!");
        if (ctrl.isPressed || ctrlRight.isPressed) dprintln("CTRL!");
        // Print the print buffer if needed.
        if (esc.isPressed && dprintBuffer.length) print("---\n", dprintBuffer);
    }
    with (Mode) {
        // Hide the print output if mode is not `printInfo`.
        setDprintVisibility(mode == printInfo);
        final switch (mode) {
            case printInfo : break;
            case engineInfo: drawDebugEngineInfo(defaultEngineDprintPosition); break;
            case tileInfo  : drawDebugTileInfo(16, 16, defaultEngineDprintPosition); break;
        }
    }
    if (!hasPressedSpace) drawText("Press SPACE to change mode.", resolution * Vec2(0.5), DrawOptions(Hook.center));
    return false;
}

mixin runGame!(ready, update, null);
