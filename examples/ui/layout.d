/// This example shows how to place UI items relative to each other.

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
    auto area = Rect(Vec2(8), resolution - Vec2(8));
    auto group = Rect();
    // Group 1.
    group = area.subTop(groupHeight);
    uiText(group.subLeft(textWidth), "Cool Button", UiOptions(Alignment.left));
    if (uiButton(group.subLeft(buttonWidth), "")) println("Cool");
    // Margin.
    area.subTop(groupMargin);
    // Group 2.
    group = area.subTop(groupHeight);
    uiText(group.subLeft(textWidth), "Super Button", UiOptions(Alignment.left));
    if (uiButton(group.subLeft(buttonWidth), "")) println("Super");
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
