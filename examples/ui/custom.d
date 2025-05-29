/// This example shows how to create a custom UI button.

import parin;

auto atlas = TextureId();

bool myButton(Rect area, IStr text) {
    // Create a button without drawing anything.
    auto result = updateUiButton(area, text);
    // Draw the button above.
    if (isUiItemActive) {
        drawTextureArea(atlas, Rect(area.size), area.position, DrawOptions(gray3));
    } else if (isUiItemHot) {
        drawTextureArea(atlas, Rect(area.size), area.position, DrawOptions(gray2));
    } else {
        drawTextureArea(atlas, Rect(area.size), area.position, DrawOptions(gray1));
    }
    drawUiText(area, text, UiOptions(Alignment.left, 4));
    return result;
}

void ready() {
    lockResolution(320, 180);
    atlas = loadTexture("parin_atlas.png");
}

bool update(float dt) {
    prepareUi();
    setUiFocus(0);
    if (myButton(Rect(8, 8, 100, 25), "My Button")) println("Boom!");
    return false;
}

mixin runGame!(ready, update, null);
