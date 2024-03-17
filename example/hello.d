// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// A hello-world example.

module popka.example.hello;

import popka.basic;

@safe @nogc nothrow:

void runHelloExample() {
    openWindow(640, 480);
    lockResolution(320, 180);
    while (isWindowOpen) {
        drawDebugText("Hello world!");
    }
    freeWindow();
}
