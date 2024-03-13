// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// An example that shows how to use the dialogue system of Popka.

module popka.example.dialogue;

import popka.basic;

void runDialogueExample() {
    openWindow(640, 480);
    lockResolution(320, 180);

    // The game variables.
    auto dialogue = Dialogue();
    auto script = "
        # This is a comment.

        ^ Select first point. ^ Select second point.

        . Point1
        > Bob
        | Hi.
        | My name is Bob.
        > Mia
        | Hello!
        | Nice to meet you!
        | My name is Mia.
        @ Point1

        . Point2
        > Bob
        | Yo Mia, this game is the bomb!
        > Mia
        | Trueee!
        @ Point2
    ";

    // Parse the dialogue script of the game.
    // The first update makes the dialogue go to the first available line.
    dialogue.parse(script);
    dialogue.update();

    while (isWindowOpen) {
        // Update the game.
        if (Keyboard.r.isPressed) {
            dialogue.reset();
            dialogue.update();
        }
        if (dialogue.canUpdate) {
            if (dialogue.hasMenu) {
                foreach (i, key; digitChars[1 .. 1 + dialogue.options.length]) {
                    if (isPressed(key)) {
                        dialogue.select(i);
                        break;
                    }
                }
            } else if (Keyboard.space.isPressed) {
                dialogue.update();
            }
        }

        // Draw the game.
        if (dialogue.hasMenu) {
            foreach (i, option; dialogue.options) {
                drawDebugText("{}. {}".fmt(i + 1, option), Vec2(8, 8 + i * 14));
            }
        } else if (dialogue.canUpdate) {
            drawDebugText("{}: {}".fmt(dialogue.actor, dialogue.text));
        } else {
            drawDebugText("The dialogue has ended.");
        }
        drawRect(Rect(0, resolution.y * 0.5, resolution.x, 1), lightGray);
        drawDebugText(
            "Press a number to pick an option.\nPress space to continue.\nPress R to restart.",
            Vec2(8, resolution.y - 14 * 3 - 8)
        );
    }
    // Free all the game resources.
    dialogue.free();
    freeWindow();
}
