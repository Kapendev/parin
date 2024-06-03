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
    auto cameraTarget = Vec2(0, -14);
    auto cameraSpeed = Vec2(120);

    while (isWindowOpen) {
        // Move the camera.
        cameraTarget += wasd.normalize() * cameraSpeed * deltaTime;
        camera.followPosition(cameraTarget);

        // Draw the game world.
        camera.attach();
        draw("Move with arrow keys.");
        draw(camera.area.subAll(3), Color(50, 50, 40, 130));
        camera.detach();

        // Draw the game UI.
        draw("I am UI!");
        draw("+", resolution * 0.5);
        draw("+", resolution * 0.5 + (cameraTarget - camera.position));
    }
    freeWindow();
}
