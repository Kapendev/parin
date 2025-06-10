/// This example shows how to use the Parin dialogue system.

import parin;

auto infoText = "Press a number to select an option.\nPress SPACE to continue.";
auto infoArea = Rect(0, 180 * 0.8, 320, 180 * 0.2);
auto story = Story();
auto script = "
    # A comment.
    * label
    | Hello world!
    | This is a text line.
    | The next is a menu line.
    ^ Pick one. ^ Pick two. ^ Skip.
    $ MENU SKIP

    *
    | Text of option one.
    $ end JUMP

    *
    | Text of option two.
    $ end JUMP

    * end
    | JUMP goes to the label with the given name.
    | SKIP skips ahead N labels.
    | MENU returns the selected option.
";

void ready() {
    lockResolution(320, 180);
    // Parse the script. The first update goes to the first available line.
    story.parse(script);
    story.update();
}

bool update(float dt) {
    // Update the story.
    if (story.hasText || story.hasPause) {
        if (Keyboard.space.isPressed) story.update();
    }
    // Select an option based on a number.
    if (story.hasMenu) {
        foreach (i, digit; digitChars[1 .. story.menu.length + 1]) {
            if (digit.isPressed) story.select(i);
        }
    }
    // Draw the story.
    if (story.hasText) drawDebugText(story.text, Vec2(8));
    if (story.hasMenu) {
        foreach (i, option; story.menu) {
            drawDebugText("{} | {}".fmt(i + 1, option), Vec2(8, 8 + i * 14));
        }
    }
    if (story.hasPause) drawDebugText("The story is paused.", Vec2(8));
    drawRect(infoArea, gray1);
    drawDebugText(infoText, infoArea.centerPoint, DrawOptions(Hook.center), TextOptions(Alignment.left, 320 - 16));
    return false;
}

mixin runGame!(ready, update, null);
