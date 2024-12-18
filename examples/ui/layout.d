/// This example shows how to place UI items relative to each other.

import parin;

auto textSize = Vec2(80, 20);
auto buttonSize = Vec2(20);

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    prepareUi();
    setUiFocus(0);
    // Set the margin between subsequent UI items.
    setUiMargin(2);
    setUiStartPoint(Vec2(8));
    // Create a layout for arranging subsequent UI items.
    useUiLayout(Layout.h);
    uiText(textSize, "Cool Button", UiButtonOptions(Alignment.left));
    if (uiButton(buttonSize, "")) println("Cool");
    // Create a new layout under the previous layout.
    useUiLayout(Layout.h);
    uiText(textSize, "Super Button", UiButtonOptions(Alignment.left));
    if (uiButton(buttonSize, "")) println("Super");
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
