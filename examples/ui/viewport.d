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
    // Set the viewport state for subsequent UI items.
    setUiViewportState(viewportPosition, viewport.size, viewportScale);
    viewport.attach();

    setUiMargin(2);
    setUiStartPoint(Vec2(8));
    foreach (i; 0 .. 4) {
        if (uiButton(Vec2(14), i.toStr())) println(i);
    }

    viewport.detach();
    drawViewport(viewport, viewportPosition, DrawOptions(viewportScale));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
