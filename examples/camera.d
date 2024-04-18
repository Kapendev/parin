// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// An example that shows how to use the camera structure.

module popka.examples.camera;

import popka;

@safe @nogc nothrow:

void runCameraExample() {
    openWindow(640, 480);
    lockResolution(320, 180);

    // The game variables.
    auto camera = Camera(0, -14);
    auto cameraSpeed = Vector2(120);
    auto cameraTarget = Vector2(0, -14);

    while (isWindowOpen) {
        // Move the camera.
        auto cameraDirection = Vector2();
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
        cameraTarget += cameraDirection * cameraSpeed * Vector2(deltaTime);
        camera.follow(cameraTarget);

        // Draw the game.
        camera.attach();
        draw("I am not UI!");
        camera.detach();
        draw("I am UI!");
        draw("+", resolution * Vector2(0.5));
        draw("+", resolution * Vector2(0.5) + (cameraTarget - camera.position));
    }
    freeWindow();
}
