/// This example shows how to use Parin with microui and textures.
/// The texture support of microui is WIP and will change in the future (probably).
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

    uiStyle.slices[UiAtlasEnum.button] = UiSlice(IRect(80, 16, 48, 48), Margin(16));
    uiStyle.slices[UiAtlasEnum.buttonHover] = uiStyle.slices[UiAtlasEnum.button];
    uiStyle.slices[UiAtlasEnum.buttonFocus] = uiStyle.slices[UiAtlasEnum.button];
}

// The game code.
bool update(float dt) {
    beginUiFrame();
    scope (exit) endUiFrame();

    if (beginWindow("Buttons", UiRect(100, 40, 120, 90))) {
        button("Hello");
        button("Hi");
        button("Hey");
        button("Howdy");
        button("Sup");
        endWindow();
    }
    return false;
}

mixin runGame!(ready, update, null, 960, 540, "Title");
