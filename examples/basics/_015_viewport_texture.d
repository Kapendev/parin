/// This example shows how to use a viewport as a generated texture.

import parin;

auto atlas = TextureId();
auto viewport = ViewportId();

void ready() {
    lockResolution(320, 180);
    atlas = loadTexture("parin_atlas.png");
    viewport = loadViewport(128, 128, blank); // Create a viewport with no background.
}

bool update(float dt) {
    // Generate the viewport texture. Cannot be done in `ready`.
    if (viewport.isFirstUse) {
        println("Updating viewport.");
        viewport.attach();
        foreach_reverse (i; 0 .. 8) {
            auto options = DrawOptions(white.alpha(cast(ubyte) (255 / (i + 1))), Hook.center);
            drawTextureArea(atlas, Rect(16, 128, 16, 16), viewport.size / Vec2(2) + Vec2(i * 8, -i * 2), options);
        }
        viewport.detach();
    }
    // Draw the generated viewport texture.
    auto options = DrawOptions(Vec2(2), Hook.center);
    drawViewport(viewport, resolution / Vec2(2) + Vec2(0, 6 * sin(elapsedTime * 4)), options);
    return false;
}

mixin runGame!(ready, update, null);
