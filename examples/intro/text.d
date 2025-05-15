/// This example shows how to draw text in Parin.

import parin;

auto text = "Hello!\nI am you and you are me.\nSomething deep to think about.";

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    auto options = TextOptions();
    // Set the alignment of the text.
    options.alignment = Alignment.center;
    // Update how many characters are visible this frame.
    options.visibilityRatio = fmod(elapsedTime * 0.3, 1.5);
    // Set whether the content of the text flows in a right-to-left direction.
    options.isRightToLeft = false;

    auto size = measureTextSizeX(engineFont, text);
    drawRect(Rect(Vec2(8), size), black);
    drawTextX(engineFont, text, Vec2(8), DrawOptions(), options);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
