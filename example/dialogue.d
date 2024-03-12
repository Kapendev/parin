// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// An example that shows how to use the dialogue system of Popka.
// TODO: This example needs some work.

module popka.example.dialogue;

import popka.basic;
import popka.game.dialogue;

void runDialogueExample() {
    openWindow(640, 480);
    lockResolution(320, 180);

    // The game variables.
    auto dialogue = Dialogue();
    auto script = "
        # This is a comment.

        * Point1
        > Bob
        | Hi.
        | My name is Bob.
        > Mia
        | Hello!
        | Nice to meet you!
        -

        * Point2
        > Bob
        | Yo Mia, this game is the bomb!
        > Mia
        | Trueee!
        -
    ";

    // Parse the dialogue script of the game.
    // The first update makes the dialogue go to the first available line.
    dialogue.parse(script);
    dialogue.jump("Point2");
    dialogue.update();

    while (isWindowOpen) {
        if (dialogue.canUpdate) {
            if (Keyboard.space.isPressed) {
                dialogue.update();
            }
            drawDebugText("{}: {}".fmt(dialogue.actor, dialogue.text));
        } else {
            drawDebugText("End of dialogue.");
        }
    }

    // Free all the game resources.
    dialogue.free();
    freeWindow();
}
