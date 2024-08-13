// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example shows how to use the camera structure of Popka.
import popka;

// The game variables.
auto camera = Camera(0, -14);
auto cameraTarget = Vec2(0, -14);
auto cameraSpeed = Vec2(120);

bool gameLoop() {
    // Move the camera.
    cameraTarget += wasd * cameraSpeed * Vec2(deltaTime);
    camera.followPosition(cameraTarget, Vec2(deltaTime));

    // Draw the game world.
    auto cameraArea = Rect(camera.position, resolution).area(camera.hook).subAll(3);
    attachCamera(camera);
    drawDebugText("Move with arrow keys.");
    drawRect(cameraArea, Color(50, 50, 40, 130));
    detachCamera(camera);

    // Draw the game UI.
    drawDebugText("I am UI!");
    drawDebugText("+", resolution * Vec2(0.5));
    drawDebugText("+", resolution * Vec2(0.5) + (cameraTarget - camera.position));
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    updateWindow!gameLoop();
}

mixin addGameStart!(gameStart, 640, 360);
