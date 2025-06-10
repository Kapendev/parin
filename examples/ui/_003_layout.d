/// This example shows how to place UI items relative to each other.
/// It uses a technique called RectCut.
/// Learn more about RectCut here: https://halt.software/p/rectcut-for-dead-simple-ui-layouts

import parin;

auto groupHeight = 20;
auto groupMargin = 2;
auto buttonWidth = 20;
auto textWidth = 90;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    prepareUi();
    setUiFocus(0);
    // Create an area for arranging UI items.
    auto area = Rect(Vec2(8), resolution);
    auto group = Rect();
    // Group 1.
    group = area.subTop(groupHeight);
    uiText(group.subLeft(textWidth), "SUPER Button", UiOptions(Alignment.left));
    if (uiButton(group.subLeft(buttonWidth), "")) println("SUPER");
    // Margin.
    area.subTop(groupMargin);
    // Group 2.
    group = area.subTop(groupHeight);
    uiText(group.subLeft(textWidth), "HOT Button", UiOptions(Alignment.left));
    if (uiButton(group.subLeft(buttonWidth), "")) println("HOT");
    return false;
}

mixin runGame!(ready, update, null);
