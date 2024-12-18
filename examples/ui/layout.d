/// This example shows how to place buttons relative to each other.

import parin;

auto buttonSize = Vec2(20);

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
    uiText(Vec2(70, buttonSize.y), "Button 1", UiButtonOptions(Alignment.left));
    if (uiButton(buttonSize, "")) println(1);
    // Create a new layout under the previous layout.
    useUiLayout(Layout.h);
    uiText(Vec2(70, buttonSize.y), "Button 22", UiButtonOptions(Alignment.left));
    if (uiButton(buttonSize, "")) println(22);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
