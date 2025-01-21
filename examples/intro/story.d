/// This example shows how to use the Parin dialogue system.

import parin;
import parin.story;

auto story = Story();
auto script = "
    # A comment.
    * label
    | Hello world!
    | This is a text line.
    | The next line will be a menu line.
    ^ Option number 1 ^ Option number 2 ^ Go to end
    $ MENU SKIP

    *
    | Text of option 1.
    $ end JUMP

    *
    | Text of option 2.
    $ end JUMP

    * end
    | Expression lines are used to go to labels.
    | JUMP goes to the label with the given name.
    | SKIP skips ahead N labels.
    | MENU returns the selected option.
    | That's it. I Hope this helps.
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
        if (Keyboard.enter.isPressed) story.update();
    }
    if (story.hasMenu) {
        // Select an option based on a number.
        foreach (i, digit; digitChars[1 .. story.menu.length + 1]) {
            if (digit.isPressed) story.select(i);
        }
    }

    // Draw the story.
    if (story.hasText) {
        drawDebugText(story.text, Vec2(8));
    }
    if (story.hasMenu) {
        foreach (i, option; story.menu) {
            drawDebugText("{} | {}".format(i + 1, option), Vec2(8, 8 + i * 14));
        }
    }
    if (story.hasPause) {
        drawDebugText("The story is paused.", Vec2(8));
    }
    // Draw some info.
    auto w = resolutionWidth;
    auto h = resolutionHeight;
    auto text = "Press 1, 2 or 3 to select an option.\nPress enter to continue.";
    auto textArea = Rect(0, h * 0.8, w, h * 0.2);
    auto textPosition = textArea.centerPoint;
    auto textOptions = DrawOptions(Alignment.left, w - 16);
    textOptions.hook = Hook.center;
    drawRect(textArea, gray1);
    drawDebugText(text, textPosition, textOptions);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
