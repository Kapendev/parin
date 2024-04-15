// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// An example that shows how to use the dialogue system of Popka.

module popka.examples.dialogue;

import popka.basic;

@safe @nogc nothrow:

void runDialogueExample() {
    openWindow(640, 480);
    lockResolution(320, 180);

    // The game variables.
    auto dialogue = Dialogue();
    auto script = "
        # This is a comment.

        ! choiceCount

        * menuPoint
        ^ Select first choice. ^ Select second choice. ^ End dialogue.

        * choice1
        > Bob
        | Hi.
        | My name is Bob.
        > Mia
        | Hello!
        | Nice to meet you!
        | My name is Mia.
        + choiceCount
        @ menuPoint

        * choice2
        > Bob
        | Yo Mia, this game is the bomb!
        > Mia
        | Trueee!
        + choiceCount
        @ menuPoint

        * End
    ";

    // Parse the dialogue script of the game.
    // The first update makes the dialogue go to the first available line.
    dialogue.parse(script);
    dialogue.update();

    while (isWindowOpen) {
        // Update the game.
        if (dialogue.hasText) {
            if (dialogue.hasOptions) {
                auto digits = digitChars[1 .. 1 + dialogue.options.length];
                foreach (i, key; digits) {
                    if (key.isPressed) {
                        dialogue.select(i);
                        break;
                    }
                }
            } else if (Keyboard.space.isPressed) {
                dialogue.update();
            }
        }

        // Draw the game.
        if (dialogue.hasOptions) {
            foreach (i, option; dialogue.options) {
                drawDebugText("{}. {}".fmt(i + 1, option), Vec2(8, 8 + i * 14));
            }
        } else if (dialogue.hasText) {
            drawDebugText("{}: {}".fmt(dialogue.actor, dialogue.text));
        } else {
            drawDebugText("The dialogue has ended.");
        }
        drawRect(Rect(0, resolution.y * 0.75, resolution.x, resolution.y * 0.25), darkGray);
        drawDebugText(
            "Press a number to pick an option.\nPress space to continue.",
            Vec2(8, resolution.y - 7 - 14 * 2)
        );
    }
    // Free all the game resources.
    dialogue.free();
    freeWindow();
}
