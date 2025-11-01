/// This example shows how to use the viewport structure of Parin.

import parin;

auto viewport = ViewportId();

void ready() {
    viewport = loadViewport(resolutionWidth / 2, resolutionHeight / 2, black); // Create a viewport with a black background.
}

bool update(float dt) {
    // Resize the viewport when the window is resized.
    if (isWindowResized) viewport.resize(resolutionWidth / 2, resolutionHeight / 2);
    // Draw the mouse position inside the viewport.
    auto viewportCenter = viewport.size * Vec2(0.5);
    auto viewportMousePosition = mouse - Rect(resolution * Vec2(0.5), viewport.size).centerArea.position;
    viewport.attach();
    drawVec2(viewportCenter, white, 20);
    drawVec2(viewportMousePosition, white, 20);
    viewport.detach();
    // Draw the viewport and other things inside the window.
    drawViewport(viewport, resolution * Vec2(0.5), DrawOptions(Hook.center));
    drawText("Move the mouse inside the box and resize the window.", Vec2(12), DrawOptions(Vec2(2)));
    return false;
}

mixin runGame!(ready, update, null);
