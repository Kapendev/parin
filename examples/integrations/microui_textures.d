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

    uiStyle.atlasRects[UiAtlasEnum.button]      = IRect(80, 16, 48, 48);
    uiStyle.atlasRects[UiAtlasEnum.buttonHover] = IRect(80, 16, 48, 48);
    uiStyle.atlasRects[UiAtlasEnum.buttonFocus] = IRect(80, 16, 48, 48);

    uiStyle.sliceMargins[UiAtlasEnum.button]      = UiMargin(16);
    uiStyle.sliceMargins[UiAtlasEnum.buttonHover] = UiMargin(16);
    uiStyle.sliceMargins[UiAtlasEnum.buttonFocus] = UiMargin(16);

    uiStyle.sliceModes[UiAtlasEnum.button]      = 1;
    uiStyle.sliceModes[UiAtlasEnum.buttonHover] = 1;
    uiStyle.sliceModes[UiAtlasEnum.buttonFocus] = 1;
}

// The game code.
bool update(float dt) {
    beginUiFrame();
    scope (exit) endUiFrame();

    if (beginWindow("Window", UiRect(60, 20, 200, 100), UiOptFlag.noClose)) {
        button("Hello");
        button("Hi");
        endWindow();
    }
    return false;
}

mixin runGame!(ready, update, null, 960, 540, "Title");
