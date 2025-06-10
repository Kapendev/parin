/// This example shows how to use the viewport structure of Parin.

import parin;

auto viewport = Viewport(black); // Create a viewport with a black background.

void ready() {
    // Resize the viewport based on the current resolution.
    viewport.resize(resolutionWidth / 2, resolutionHeight / 2);
}

bool update(float dt) {
    // Resize the viewport when the window is resized.
    if (isWindowResized) viewport.resize(resolutionWidth / 2, resolutionHeight / 2);
    // Draw the mouse position inside the viewport.
    auto viewportCenter = viewport.size * Vec2(0.5);
    auto viewportMousePosition = mouse - Rect(resolution * Vec2(0.5), viewport.size).centerArea.position;
    viewport.attach();
    drawVec2(viewportCenter, 20);
    drawVec2(viewportMousePosition, 20);
    viewport.detach();
    // Draw the viewport and other things inside the window.
    drawViewport(viewport, resolution * Vec2(0.5), DrawOptions(Hook.center));
    drawDebugText("Move the mouse inside the box and resize the window.", Vec2(12), DrawOptions(Vec2(2)));
    return false;
}

mixin runGame!(ready, update, null);
