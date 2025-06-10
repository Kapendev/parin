/// This example shows how to create a simple menu.

import parin;

auto activeMenu = 0;
auto buttonWidth = 70;
auto buttonHeight = 25;
auto buttonMargin = 2;

IStr[4] mainMenu = [
    "Start",
    "Continue",
    "Settings",
    "Quit",
];

IStr[2] continueMenu = [
    "Save 1",
    "Back",
];

IStr[3] settingsMenu = [
    "Controls",
    "Audio",
    "Back",
];

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    prepareUi();
    setUiFocus(0);
    // Get the current menu.
    auto menu = mainMenu[];
    if (activeMenu == 1) menu = continueMenu[];
    else if (activeMenu == 2) menu = settingsMenu[];
    // Draw the menu.
    auto area = Rect(
        resolution * Vec2(0.5),
        buttonWidth,
        buttonHeight * menu.length + buttonMargin * (menu.length - 1),
    ).area(Hook.center);
    foreach (item; menu) {
        if (uiButton(area.subTop(buttonHeight), item)) {
            println(item);
            if (activeMenu == 0 && item == "Continue") activeMenu = 1;
            if (activeMenu == 0 && item == "Settings") activeMenu = 2;
            if (item == "Back") activeMenu = 0;
            if (item == "Quit") return true;
        }
        area.subTop(buttonMargin);
    }
    return false;
}

mixin runGame!(ready, update, null);
