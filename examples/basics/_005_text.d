/// This example shows how to draw text in Parin.

import parin;

auto text = "Hello!\nI am you and you are me.\nSomething deep to think about.";
auto textPosition = Vec2(8);

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Set the alignment of the text, how many characters are visible this frame
    // and whether the content of the text flows in a right-to-left direction.
    auto options = DrawOptions(Hook.topLeft);
    auto extra = TextOptions();
    extra.alignment = Alignment.center;
    extra.visibilityRatio = fmod(elapsedTime * 0.3, 1.5);
    extra.isRightToLeft = true;
    // Draw the text with the engine font.
    auto textArea = Rect(textPosition, measureTextSize(engineFont, text));
    drawRect(textArea, black);
    drawText(engineFont, text, textPosition, options, extra);
    return false;
}

mixin runGame!(ready, update, null);
