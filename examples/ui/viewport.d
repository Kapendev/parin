/// This example shows how to use viewports with UI items.

import parin;

auto viewport = Viewport(black);
auto viewportPosition = Vec2(100, 30);
auto viewportScale = Vec2(2);

void ready() {
    lockResolution(320, 180);
    viewport.resize(60, 60);
}

bool update(float dt) {
    auto size = Vec2(30);
    viewport.attach();
    setUiViewportState(viewportPosition, viewportScale);
    if (uiButtonAt(Vec2(8), size, engineFont, "UwU")) {
        println("UwU");
    }
    drawVec2(uiMouse, 4);
    viewport.detach();
    drawViewport(viewport, viewportPosition, DrawOptions(viewportScale));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
