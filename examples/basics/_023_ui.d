/// This example shows how to use the new UI library.

import parin;
import parin.uiNew;

void ready() {
    lockResolution(320, 180);
    ui.readyForEngine();
}

bool update(float dt) {
    auto screen = IRect(resolutionWidth, resolutionHeight);
    screen.subAll(8);

    ui.beginFrame();
    with (ui.captureFocus()) {
        auto menu = ui.row(screen.subTop(15), 4, 8);
        if (ui.button(menu.pop(), "A")) println("A!");
        if (ui.button(menu.pop(), "B")) println("B!");
        if (ui.button(menu.pop(), "C")) println("C!");
    }
    // TODO: something weird with: auto testCol = ui.col(IRect(30, 50, 100, 30), 0, 0, false, 100);
    if (ui.button(30, 40, 100, 24,  "Hello\nWorldo", 0, UiOptionFlag.none)) println("Hello!");
    if (ui.button(30, 70, 100, 24,  "Hello\nWorldo", 0, UiOptionFlag.alignCenter)) println("Hello!");
    if (ui.button(30, 100, 100, 24, "Hello\nWorldo", 0, UiOptionFlag.alignRight)) println("Hello!");
    if (ui.button(30, 130, 100, 24, "Hello\nWorldo", 0, UiOptionFlag.turnOff)) println("Hello!");
    ui.endFrame();

    return false;
}

mixin runGame!(ready, update, null);
