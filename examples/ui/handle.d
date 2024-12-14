/// This example shows how to use the drag handle.

// TODO: There is a small bug with overlapping UI items. Fix it.

import parin;

auto handlePosition = Vec2(120, 60);
auto handleOptions = UiButtonOptions();

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    setUiStartPoint(Vec2(8));
    // Toggle the limit of the drag handle.
    if (uiButton(Vec2(80, 30), "Limit: {}".format(handleOptions.dragLimit))) {
        if (handleOptions.dragLimit) handleOptions.dragLimit = UiDragLimit.none;
        else handleOptions.dragLimit = UiDragLimit.viewport;
    }
    // Create the drag handle and return true if it is dragged.
    if (uiDragHandle(Vec2(60), handlePosition, handleOptions)) {
        println(handlePosition);
    }
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
