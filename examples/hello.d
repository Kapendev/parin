// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// A hello-world example.

module popka.examples.hello;

import popka;

@safe @nogc nothrow:

void runHelloExample() {
    openWindow(640, 480);
    lockResolution(320, 180);
    while (isWindowOpen) {
        draw("Hello world!");
    }
    freeWindow();
}
