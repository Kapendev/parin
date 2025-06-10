/// This example shows how to use the camera structure of Parin.

import parin;

auto camera = Camera(0, -14);     // Create a camera at position (0, -14).
auto cameraTarget = Vec2(0, -14); // The target position of the camera.

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Move the camera.
    cameraTarget += wasd * Vec2(120 * dt);
    camera.followPositionWithSlowdown(cameraTarget, 0.15);
    // Draw the world.
    camera.attach();
    drawDebugText("Move with arrow keys.", Vec2(8));
    drawRect(camera.area.subAll(3), Color(50, 50, 40, 130));
    camera.detach();
    // Draw the UI.
    drawDebugText("I am UI!", Vec2(8));
    drawDebugText("+", resolution * Vec2(0.5));
    drawDebugText("+", resolution * Vec2(0.5) + (cameraTarget - camera.position));
    return false;
}

mixin runGame!(ready, update, null);
