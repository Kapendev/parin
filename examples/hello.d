// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example serves as a classic hello-world program, introducing the fundamental structure of a Popka program.

import popka;

// The main loop of the game. If true is returned, then the game will stop running.
bool gameLoop() {
    draw("Hello world!");
    return false;
}

// The starting point of the game.
void gameStart() {
    lockResolution(320, 180);
    updateWindow!gameLoop();
}

// Creates a main function that calls the `gameStart` function and creates a game window that is 640 pixels wide and 360 pixels tall.
mixin addGameStart!(gameStart, 640, 360);
