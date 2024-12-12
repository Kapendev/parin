/// This example shows how to place buttons relative to each other.

import parin;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    auto size = Vec2(32);
    setUiMargin(2);
    setUiStartPoint(Vec2(8));
    useUiLayout(Layout.h);
    if (uiButton(size, engineFont, "1")) println(1);
    if (uiButton(size, engineFont, "2")) println(2);
    useUiLayout(Layout.h);
    if (uiButton(size, engineFont, "3")) println(3);
    if (uiButton(size, engineFont, "4")) println(4);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
