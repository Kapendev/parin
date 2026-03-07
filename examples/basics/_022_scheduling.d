/// This example shows how the scheduling system works.

import parin;

auto text = "GNU!";

// A function (task) that will run every N seconds.
bool updateText(float dt) {
    text ~= '!';
    return false;
}

void ready() {
    lockResolution(320, 180);
    // Repeat this function every 5 seconds.
    repeatTask(&updateText, 0.5);
}

bool update(float dt) {
    drawText(text, Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
