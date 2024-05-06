// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example shows how to use the camera structure of Popka.

module popka.examples.camera;

import popka;

@safe @nogc nothrow:

void runCameraExample() {
    openWindow(640, 360);
    lockResolution(320, 180);

    // The game variables.
    auto camera = Camera(0, -14);
    auto cameraSpeed = Vec2(120);
    auto cameraTarget = Vec2(0, -14);

    while (isWindowOpen) {
        // Move the camera.
        auto cameraDirection = Vec2();
        if (Keyboard.left.isDown) {
            cameraDirection.x = -1;
        }
        if (Keyboard.right.isDown) {
            cameraDirection.x = 1;
        }
        if (Keyboard.up.isDown) {
            cameraDirection.y = -1;
        }
        if (Keyboard.down.isDown) {
            cameraDirection.y = 1;
        }
        cameraTarget += cameraDirection * cameraSpeed * Vec2(deltaTime);
        camera.follow(cameraTarget);

        // Draw the game world.
        camera.attach();
        draw("Move with arrow keys.");
        auto area = camera.area;
        area.subAll(3.0f);
        draw(area, Color(50, 50, 40, 130));
        camera.detach();

        // Draw the game UI.
        draw("I am UI!");
        draw("+", resolution * Vec2(0.5));
        draw("+", resolution * Vec2(0.5) + (cameraTarget - camera.position));
    }
    freeWindow();
}
