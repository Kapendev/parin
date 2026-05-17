/// This example shows how to use Parin with microui and textures.
/// The texture support of microui is WIP.
/// Parin ships microui under `parin.addons.microui`.
/// Original repository: https://github.com/Kapendev/microui-d

import parin;
import parin.addons.microui;

auto atlas = TextureId();

void ready() {
    lockResolution(320, 180);
    readyUi();
    atlas = loadTexture("parin_atlas.png");
    uiStyle.texture = &atlas;
    uiStyle.slices[UiAtlas.button] = UiSlice(IRect(80, 16, 48, 48), Margin(16));
    uiStyle.slices[UiAtlas.buttonHover] = uiStyle.slices[UiAtlas.button];
    uiStyle.slices[UiAtlas.buttonFocus] = uiStyle.slices[UiAtlas.button];
}

bool update(float dt) {
    beginUiFrame();
    if (beginWindow("Buttons", 100, 40, 120, 90)) {
        button("Hello");
        button("Hi");
        button("Hey");
        button("Howdy");
        button("Sup");
        endWindow();
    }
    endUiFrame();
    return false;
}

mixin runGame!(ready, update, null);
