/// This example shows how to use viewports with UI items.

import parin;

auto viewport = Viewport(black);
auto viewportPosition = Vec2(32);
auto viewportScale = Vec2(2);

void ready() {
    lockResolution(320, 180);
    viewport.resize(60, 60);
}

bool update(float dt) {
    prepareUi();
    setUiFocus(0);
    // Set the viewport state for subsequent UI items.
    setUiViewportState(viewportPosition, viewport.size, viewportScale);
    viewport.attach();
    foreach (i; 0 .. 3) {
        if (uiButton(Rect(8, 8 + i * 22, 20, 20), i.toStr())) println(i);
    }
    viewport.detach();
    drawViewport(viewport, viewportPosition, DrawOptions(viewportScale));
    return false;
}

mixin runGame!(ready, update, null);
