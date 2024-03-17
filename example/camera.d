// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// An example that shows how to use the camera structure.

module popka.example.camera;

import popka.basic;

@safe @nogc nothrow:

void runCameraExample() {
    openWindow(640, 480);
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
        // This will move the camera in a smooth way.
        camera.follow(cameraTarget);

        // Draw the game.
        camera.attach();
        drawDebugText("I am not UI!");
        camera.detach();
        drawDebugText("I am UI!");
        drawDebugText("+", resolution * Vec2(0.5));
        drawDebugText("+", resolution * Vec2(0.5) + (cameraTarget - camera.position));
    }
    freeWindow();
}
