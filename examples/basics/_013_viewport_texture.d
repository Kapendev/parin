/// This example shows how to use a viewport as a generated texture.

import parin;

auto atlas = TextureId();
auto viewport = ViewportId();
auto isViewportEmpty = true;

void ready() {
    lockResolution(320, 180);
    viewport = loadViewport(128, 128, blank); // Create a viewport with no background.
    atlas = loadTexture("parin_atlas.png");
}

bool update(float dt) {
    // Generate the viewport texture. Can't ne done in the `ready` function.
    if (isViewportEmpty) {
        viewport.attach();
        foreach_reverse (i; 0 .. 8) {
            auto options = DrawOptions(white.alpha(cast(ubyte) (255 / (i + 1))), Hook.center);
            drawTextureArea(atlas, Rect(16, 128, 16, 16), viewport.size / Vec2(2) + Vec2(i * 8, -i * 2), options);
        }
        viewport.detach();
        isViewportEmpty = false;
    }
    // Draw the generated viewport texture.
    auto options = DrawOptions(Vec2(2), Hook.center);
    drawViewport(viewport, resolution / Vec2(2) + Vec2(0, 6 * sin(elapsedTime * 4)), options);
    return false;
}

mixin runGame!(ready, update, null);
