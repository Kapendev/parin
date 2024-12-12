/// This example serves as a classic hello-world example, introducing the UI system of Parin.

import parin;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    auto text = "Hello world!";
    if (uiButtonAt(Vec2(8), Vec2(80, 30), engineFont, text)) {
        println(text);
    }
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
