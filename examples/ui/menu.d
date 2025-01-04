/// This example shows how to create a simple menu.

import parin;

auto buttonSize = Vec2(70, 24);
auto activeMenu = 0;

IStr[4] mainMenu = [
    "Start",
    "Continue",
    "Settings",
    "Quit",
];

IStr[3] continueMenu = [
    "Save 1",
    "Save 2",
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
    auto menuPoint = resolution * Vec2(0.5);
    menuPoint.x -= buttonSize.x * 0.5;
    menuPoint.y -= (buttonSize.y * menu.length + uiMargin * (menu.length - 1)) * 0.5;
    setUiStartPoint(menuPoint);
    foreach (item; menu) {
        if (uiButton(buttonSize, item)) {
            println(item);
            if (activeMenu == 0 && item == "Continue") activeMenu = 1;
            if (activeMenu == 0 && item == "Settings") activeMenu = 2;
            if (item == "Back") activeMenu = 0;
            if (item == "Quit") return true;
        }
    }
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
