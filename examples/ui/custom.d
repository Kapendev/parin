/// This example shows how to create custom UI items.

import parin;

auto atlas = TextureId();

bool myButton(IStr text) {
    // Create a button without drawing anything.
    auto result = updateUiButton(Vec2(80, 30), text);
    // Draw the button above.
    if (isUiItemActive) {
        drawTextureArea(atlas, Rect(uiItemSize), uiItemPoint, DrawOptions(gray3));
    } else if (isUiItemHot) {
        drawTextureArea(atlas, Rect(uiItemSize), uiItemPoint, DrawOptions(gray2));
    } else {
        drawTextureArea(atlas, Rect(uiItemSize), uiItemPoint, DrawOptions(gray1));
    }
    drawUiText(uiItemSize, text, uiItemPoint, UiOptions(Alignment.left, 6));
    return result;
}

void ready() {
    lockResolution(320, 180);
    atlas = loadTexture("atlas.png");
}

bool update(float dt) {
    prepareUi();
    setUiFocus(0);
    setUiStartPoint(Vec2(8));
    if (myButton("My Button 1")) println("Boom 1!");
    if (myButton("My Button 2")) println("Boom 2!");
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
