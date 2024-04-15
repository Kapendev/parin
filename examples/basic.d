// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The basic module acts as a central hub,
/// bundling together numerous specialized modules.

module popka.examples.basic;

public import popka.examples.camera;
public import popka.examples.coins;
public import popka.examples.dialogue;
public import popka.examples.hello;

@safe @nogc nothrow:

void runEveryExample() {
    runHelloExample();
    runCoinsExample();
    runCameraExample();
    runDialogueExample();
}
