// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The basic module acts as a central hub,
/// bundling together numerous specialized modules.

module popka.example.basic;

public import popka.example.camera;
public import popka.example.coins;
public import popka.example.dialogue;
public import popka.example.hello;

@safe @nogc nothrow:

void runEveryExample() {
    runHelloExample();
    runCoinsExample();
    runCameraExample();
    runDialogueExample();
}

unittest {}
