// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// An example that shows how to use the dialogue system of Popka.

module popka.examples.dialogue;

import popka;

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
            if (dialogue.hasChoices) {
                auto digits = digitChars[1 .. 1 + dialogue.choices.length];
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
        if (dialogue.hasChoices) {
            foreach (i, choice; dialogue.choices) {
                auto choicePosition = Vector2(8, 8 + i * 14);
                draw("{}".fmt(i + 1), choicePosition);
                draw("   | {}".fmt(choice), choicePosition);
            }
        } else if (dialogue.hasText) {
            draw("{}: {}".fmt(dialogue.actor, dialogue.text));
        } else {
            draw("The dialogue has ended.");
        }
        draw(Rectangle(0, resolution.y * 0.8, resolution.x, resolution.y), darkGray);
        auto infoPosition = Vector2(8, resolution.y - 2 - 14 * 2);
        draw("Press 1, 2 or 3 to select a choice.", infoPosition);
        draw("\nPress space to continue.", infoPosition);
    }
    freeWindow();
}
