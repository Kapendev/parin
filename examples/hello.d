// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example serves as a classic hello-world program, introducing the fundamental structure of a Popka program.
import popka;

// The game loop. This is called every frame.
// If true is returned, then the game will stop running.
bool gameLoop() {
    drawDebugText("Hello world!");
    return false;
}

// The game start. This is one time.
void gameStart() {
    lockResolution(320, 180);
    updateWindow!gameLoop();
}

// Creates a main function that calls the given function and creates a game window that is 640 pixels wide and 360 pixels tall.
mixin addGameStart!(gameStart, 640, 360);
