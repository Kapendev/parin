/// This example shows how to use the camera structure of Parin.

import parin;

auto camera = Camera(0, -14);     // Create a camera at position (0, -14).
auto cameraTarget = Vec2(0, -14); // The target position of the camera.

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Move the camera.
    cameraTarget += wasd * 120 * dt;
    camera.followPositionWithSlowdown(cameraTarget, dt, 0.15);
    // Draw the objects inside the camera.
    // This can also be done with the `attach` and `detach` functions.
    with (Attached(camera)) {
        drawText("Move with arrow keys.", Vec2(8));
        drawRect(camera.area(resolution).subAll(3), Color(50, 50, 40, 130));
    }
    // Draw the UI.
    drawText("I am UI!", Vec2(8));
    drawText("+", resolution * 0.5);
    drawText("+", resolution * 0.5 + (cameraTarget - camera.position));
    return false;
}

mixin runGame!(ready, update, null);
