/// This example shows how to use the text field.

import parin;

Str text;
char[32] textBuffer;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    prepareUi();
    setUiFocus(0);
    // Create the text field and print if enter is pressed. Combos: ctrl+backspace, ctrl+x
    if (uiTextField(Rect(resolution), text, textBuffer)) println(text);
    return false;
}

mixin runGame!(ready, update, null);
