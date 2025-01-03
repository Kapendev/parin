/// This example shows how to use the text field.

import parin;

char[32] textBuffer;
Str text;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    prepareUi();
    setUiFocus(0);
    setUiStartPoint(Vec2());
    // Create the text field and print if enter is pressed.
    // Text field combos: ctrl+backspace, ctrl+x
    if (uiTextField(resolution, text, textBuffer)) {
        println(text);
    }
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
