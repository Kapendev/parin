/// This example shows how to use the drag handle.

import parin;

auto handlePosition = Vec2(120, 60);
auto handleOptions = UiOptions();

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    prepareUi();
    setUiFocus(0);
    setUiStartPoint(Vec2(8));
    // Toggle the limit of the drag handle.
    if (uiButton(Vec2(80, 30), "Limit: {}".format(handleOptions.dragLimit))) {
        if (handleOptions.dragLimit) handleOptions.dragLimit = UiDragLimit.none;
        else handleOptions.dragLimit = UiDragLimit.viewport;
    }
    // Create the drag handle and print if it is dragged.
    if (uiDragHandle(Vec2(60), handlePosition, handleOptions)) {
        println(handlePosition);
    }
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
