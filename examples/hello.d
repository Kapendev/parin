// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example serves as a classic hello-world program, introducing the fundamental structure of a Popka program.

import popka;

bool gameLoop() {
    draw("Hello world!");
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    updateWindow!gameLoop();
}

mixin addGameStart!(gameStart, 640, 360);
