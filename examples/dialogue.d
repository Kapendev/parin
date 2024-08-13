/// This example shows how to use the Popka chat system.
import popka;

// The game variables.
auto chat = Chat();
auto script = "
    # This is a comment.

    ! choiceCount

    * menuPoint
    ^ Select first choice. ^ Select second choice. ^ End chat.

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

bool gameLoop() {
    // Update the game.
    if (chat.canUpdate) {
        if (chat.hasChoices) {
            auto keys = digitChars[1 .. 1 + chat.choices.length];
            foreach (i, key; keys) {
                if (key.isPressed) {
                    chat.pick(i);
                    break;
                }
            }
        } else if (Keyboard.space.isPressed) {
            chat.update();
        }
    }

    // Draw the chat.
    if (chat.hasChoices) {
        foreach (i, choice; chat.choices) {
            auto choicePosition = Vec2(8, 8 + i * 14);
            drawDebugText("{}".format(i + 1), choicePosition);
            drawDebugText("   | {}".format(choice), choicePosition);
        }
    } else if (chat.canUpdate) {
        drawDebugText("{}: {}".format(chat.actor, chat.text));
    } else {
        drawDebugText("The chat has ended.");
    }

    // Draw the game info/
    auto infoPosition = Vec2(8, resolution.y - 2 - 14 * 2);
    drawRect(Rect(0, resolution.y * 0.8, resolution.x, resolution.y), gray1);
    drawDebugText("Press 1, 2 or 3 to select a choice.", infoPosition);
    drawDebugText("\nPress space to continue.", infoPosition);
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    // Parse the chat script of the game.
    // The first update makes the chat go to the first available line.
    chat.parse(script);
    chat.update();
    updateWindow!gameLoop();
}

mixin addGameStart!(gameStart, 640, 360);
