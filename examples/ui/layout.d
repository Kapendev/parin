/// This example shows how to place buttons relative to each other.

import parin;

auto buttonSize = Vec2(32);

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    prepareUi();
    // Set the margin between subsequent UI items.
    setUiMargin(2);
    setUiStartPoint(Vec2(8));
    // Create a layout for arranging subsequent UI items.
    useUiLayout(Layout.h);
    if (uiButton(buttonSize, "1")) println(1);
    if (uiButton(buttonSize, "2")) println(2);
    // Create a new layout under the previous layout.
    useUiLayout(Layout.h);
    if (uiButton(buttonSize, "3")) println(3);
    if (uiButton(buttonSize, "4")) println(4);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
