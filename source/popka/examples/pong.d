// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example shows how to create a pong-like game with Popka.

module popka.examples.pong;

import popka;

@safe @nogc nothrow:

// TODO: MAKE THE GAME!
void runPongExample() {
    openWindow(640, 360);
    lockResolution(320, 180);

    // The game variables.
    auto player = Rect(resolution * 0.5, Vec2(16));

    // Change the background color.
    changeBackgroundColor(gray);

    while (isWindowOpen) {
        draw("Pong.");
    }
    freeWindow();
}
