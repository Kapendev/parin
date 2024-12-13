/// This example serves as a classic hello-world example, introducing the UI system of Parin.

import parin;

auto buttonText = "Hello world!";

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    setUiStartPoint(Vec2(8));
    if (uiButton(Vec2(80, 30), buttonText)) {
        println(buttonText);
    }
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
