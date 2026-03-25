/// This example shows how to use the new UI library.

import parin;
import parin.ui2;

void ready() {
    lockResolution(320, 180);
    ui.readyWithEngine();
}

bool update(float dt) {
    auto screen = IRect(resolutionWidth, resolutionHeight);
    screen.subAll(8);

    ui.beginFrame();
    scope (exit) ui.endFrame();

    // Use TAB and ENTER to select those buttons using the keyboard.
    with (ui.captureFocus(UiKeyNavigation.horizontal)) {
        auto menu = ui.rowItems(screen.subTop(15), 8, 8);
        if (ui.button(menu.pop(), "A")) println("A!");
        if (ui.button(menu.pop(), "B")) println("B!");
        if (ui.button(menu.pop(), "C")) println("C!");
        if (ui.button(menu.pop(), "D")) println("D!");
        if (ui.button(menu.pop(), "E")) println("E!");
    }

    // Use layouts and options to control how UI elements works.
    auto testText = "Hello\nWorldoo";
    auto testPart = ui.colSlice(IRect(screen.x, 40, 75, 130), 24, 7);
    {
        auto testSubPart = ui.rowSlice(testPart.pop(), testPart.w, 7);
        if (ui.button(testSubPart.pop(), testText, 0, UiOptionFlag.none))
            println("Pressed 1!");
        if (ui.button(testSubPart.pop(), testText, 0, UiOptionFlag.alignCenter))
            println("Pressed 2!");
    }
    {
        auto testSubPart = ui.rowSlice(testPart.pop(), testPart.w, 7);
        if (ui.button(testSubPart.pop(), testText, 0, UiOptionFlag.alignRight))
            println("Pressed 3!");
        if (ui.button(testSubPart.pop(), testText, 0, Key.space.isDown ? 0 : UiOptionFlag.turnOff))
            println("Pressed 4!");
    }

    return false;
}

mixin runGame!(ready, update, null);
