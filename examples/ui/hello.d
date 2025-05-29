/// This example serves as a classic hello world example, introducing the UI system of Parin.

import parin;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Prepare the UI for this frame. This call is required for the UI to function as expected.
    prepareUi();
    // Disable the UI focus for this frame. Focus is only needed for UIs that support keyboard controls.
    setUiFocus(0);
    // Create a button and print if it is clicked.
    if (uiButton(Rect(8, 8, 100, 25), "Hello world!")) println("World: Hi!");
    return false;
}

mixin runGame!(ready, update, null);
