// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example serves as a classic hello-world program, introducing the fundamental structure of a Popka program.

import popka;

bool gameLoop() {
    draw("Hello worldo!");
    return false;
}

void gameStart(string path) {
    openWindow(640, 360);
    updateWindow!gameLoop();
    closeWindow();
}

mixin addGameStart!gameStart;
