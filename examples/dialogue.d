/// This example shows how to use the Popka dialogue system.
import popka;

// The game variables.
auto dialogue = Dialogue();
auto script = "
    # This is a comment.

    * menuPoint
    ^ Select first choice. ^ Select second choice. ^ End dialogue.

    * choice1
    > Bob
    | Hi.
    | My name is Bob.
    > Mia
    | Hello!
    | My name is Mia.
    @ menuPoint

    * choice2
    > Bob
    | Yo Mia, this game is the bomb!
    > Mia
    | Trueee!
    @ menuPoint

    * End
";

void ready() {
    lockResolution(320, 180);
    // Parse the dialogue script. The first update makes the dialogue go to the first available line.
    dialogue.parse(script);
    dialogue.update();
}

bool update(float dt) {
    // Update the dialogue.
    if (dialogue.canUpdate) {
        if (dialogue.hasChoices) {
            // Check if a number is pressed and pick a choice based on that number.
            foreach (i, digit; digitChars[1 .. dialogue.choices.length + 1]) {
                if (digit.isPressed) {
                    dialogue.pick(i);
                    break;
                }
            }
        } else if (Keyboard.space.isPressed) {
            dialogue.update();
        }
    }

    // Draw the dialogue.
    if (dialogue.hasChoices) {
        foreach (i, choice; dialogue.choices) {
            auto choicePosition = Vec2(8, 8 + i * 14);
            drawDebugText("{}".format(i + 1), choicePosition);
            drawDebugText("   | {}".format(choice), choicePosition);
        }
    } else if (dialogue.canUpdate) {
        drawDebugText("{}: {}".format(dialogue.actor, dialogue.text), Vec2(8));
    } else {
        drawDebugText("The dialogue has ended.", Vec2(8));
    }

    // Draw the game info.
    auto infoPosition = Vec2(8, resolution.y - 2 - 14 * 2);
    drawRect(Rect(0, resolution.y * 0.8, resolution.x, resolution.y), gray1);
    drawDebugText("Press 1, 2 or 3 to select a choice.", infoPosition);
    drawDebugText("\nPress space to continue.", infoPosition);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
