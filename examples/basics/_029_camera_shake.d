/// This example shows how to shake the camera.
/// Press space for a small shake and enter for a big one.

import parin;

auto camera = Camera(0, 0, true);
auto player = Rect(16, 16);

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    // Move the player and shake the camera.
    player.position += wasd * 120 * dt;
    if (Keyboard.space.isPressed) camera.shake(2, 0.2);
    if (Keyboard.enter.isPressed) camera.shake(8, 0.6);
    // Update the camera. The shake is added on top of the camera position.
    camera.followPositionWithSlowdown(player.position, dt, 0.15);
    camera.updateShake(dt);
    // Draw the world inside the camera.
    with (Attached(camera)) {
        foreach (row; -4 .. 5) {
            foreach (col; -7 .. 8) {
                if ((row + col) % 2 == 0) drawRect(Rect(col * 32 - 8, row * 32 - 8, 16, 16), gray3);
            }
        }
        drawRect(player.centerArea, cyan);
    }
    // Draw the UI. It is outside the camera, so it does not shake.
    drawText("Move with arrow keys.\nPress space or enter to shake.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
