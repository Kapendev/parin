/// This example shows how to draw text in Parin.

import parin;

auto text = "Hello!\nI am you and you are me.\nSomething deep to think about.";

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Set the alignment of the text, how many characters are visible this frame
    // and whether the content of the text flows in a right-to-left direction.
    auto options = DrawOptions(brown);
    auto extra = TextOptions();
    extra.alignment = Alignment.center;
    extra.visibilityRatio = fmod(elapsedTime * 0.3, 1.5);
    extra.isRightToLeft = true;
    // Draw the text.
    drawRect(Rect(Vec2(8), measureTextSize(engineFont, text)), black);
    drawText(engineFont, text, Vec2(8), options, extra);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
