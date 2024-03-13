// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// An example that shows how to use the dialogue system of Popka.

// TODO: Example might need some work.

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

        ^ Select first point. ^ Select second point.

        . Point1
        > Bob
        | Hi.
        | My name is Bob.
        > Mia
        | Hello!
        | Nice to meet you!
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
            if (dialogue.hasOptions) {
                foreach (i, key; "123456789"[0 .. dialogue.options.length]) {
                    if (isPressed(key)) {
                        dialogue.selectOption(i);
                        dialogue.update();
                        break;
                    }
                }
            } else if (Keyboard.space.isPressed) {
                dialogue.update();
            }
        }

        // Draw the game.
        if (dialogue.hasOptions) {
            foreach (i, option; dialogue.options.items) {
                drawDebugText("{}. {}".fmt(i + 1, option), Vec2(8, 8 + i * 14));
            }
        } else if (dialogue.canUpdate) {
            drawDebugText("{}: {}".fmt(dialogue.actor, dialogue.text));
        } else {
            drawDebugText("No more dialogue.");
        }
        drawDebugText("Press R to restart.", Vec2(8, 140));
    }

    // Free all the game resources.
    dialogue.free();
    freeWindow();
}
