// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example shows how to use the tile map structure of Popka.

import popka;

// The game variables.
auto atlas = Sprite();
auto map = TileMap();
auto camera = Camera();
auto cameraTarget = Vec2();
auto cameraSpeed = Vec2(120);

bool gameLoop() {
    // Move the camera.
    cameraTarget += wasd * cameraSpeed * deltaTime;
    camera.followPosition(cameraTarget);

    // Draw the game world.
    // The options can change the way something is drawn.
    auto options = DrawOptions();
    options.scale = Vec2(2);
    // Passing a camera to the tile map drawing function allows for efficient rendering by only drawing the tiles that are currently in view.
    camera.attach();
    draw(atlas, map, camera, options);
    camera.detach();
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    changeBackgroundColor(toRGB(0x0b0b0b));

    atlas.load("atlas.png");
    map.tileSize = Vec2(16);
    map.parse("145,0,65\n21,22,23\n37,38,39\n53,54,55");
    updateWindow!gameLoop();
    atlas.free();
}

mixin addGameStart!(gameStart, 640, 360);
