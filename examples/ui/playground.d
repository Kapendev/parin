/// This example shows almost every UI item of Parin.

import parin;

char[20] textFieldBuffer;
Str textFieldText;

auto handleSize = Vec2(140, 7);
auto buttonSize = Vec2(60, 20);
auto textSize = Vec2(140, 12);
auto uiPoint = Vec2();

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    prepareUi();
    setUiFocus(0);
    if (Keyboard.f11.isPressed) toggleIsFullscreen();

    useUiLayout(Layout.h);
    uiDragHandle(handleSize, uiPoint);

    useUiLayout(Layout.h);
    if (uiButton(buttonSize, "Button")) println("Button");

    useUiLayout(Layout.h);
    uiText(textSize, "Hello world!");

    useUiLayout(Layout.h);
    uiTextField(textSize, textFieldText, textFieldBuffer);

    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
