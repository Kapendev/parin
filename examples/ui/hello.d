/// This example serves as a classic hello-world example, introducing the UI system of Parin.

import parin;

auto buttonText = "Hello world!";

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Prepare the UI for this frame. This call is required for the UI to function as expected.
    prepareUi();
    // Set the starting point for subsequent UI items.
    setUiStartPoint(Vec2(8));
    // Create a button and print if it is clicked.
    if (uiButton(Vec2(80, 30), buttonText)) {
        println(buttonText);
    }
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
