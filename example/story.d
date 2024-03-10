// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// An example that shows how to use the dialogue system of Popka.
// TODO: This example needs some work.

module popka.example.story;

import popka.basic;
import popka.game.dialogue;

void runStoryExample() {
    openWindow(640, 480);
    lockResolution(320, 180);

    // The game variables.
    auto file = "
        # This is a comment.

        > Alex
        | Hi.
        | My name is Alex.
        > Maria
        | Hello!
        | Nice to meet you!
        -

        # I don't know why this does not work...
        # * Point
        # > Actor3
        # | This is a loop.
        # @ Point
    ";
    auto dialogue = Dialogue();

    // Parse the file that is the story of the game.
    dialogue.parse(file);

    while (isWindowOpen) {
        // The first update makes the dialogue system go to the first available line.
        if (!dialogue.canUpdate) {
            dialogue.reset();
            dialogue.update();
        }
        // Update the story.
        if (Keyboard.space.isPressed) {
            dialogue.update();
        }
        // Draw the game.
        drawDebugText("{}: {}".fmt(dialogue.actor, dialogue.content));
    }
    // Free all the game resources.
    dialogue.free();
    freeWindow();
}
