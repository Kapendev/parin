/// This example shows how to use the drag handle.

import parin;

auto handleArea = Rect(40, 60, 60, 60);
auto handleOptions = UiOptions();

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    prepareUi();
    setUiFocus(0);
    // Toggle the limit of the drag handle.
    if (uiButton(Rect(8, 8, 120, 25), handleOptions.dragLimit.toStr())) {
        handleOptions.dragLimit = handleOptions.dragLimit ? UiDragLimit.none : UiDragLimit.viewport;
    }
    // Create the drag handle and print if it is dragged.
    if (uiDragHandle(handleArea, handleOptions)) {
        println(handleArea.position);
    }
    return false;
}

mixin runGame!(ready, update, null);
