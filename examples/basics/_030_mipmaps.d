/// This example shows how trilinear filtering makes textures look better when they are drawn much smaller.
/// Trilinear filtering uses mipmaps, which are smaller versions of a texture that are created when the filter is set.

import parin;

auto linearPortrait = TextureId();
auto trilinearPortrait = TextureId();
float[4] heights = [144, 72, 36, 18]; // The heights the portrait is drawn at, in pixels.

void ready() {
    lockResolution(640, 360);
    // Load the same texture twice so each copy can use a different filter.
    linearPortrait = loadTexture("parin_portrait28.png");
    linearPortrait.setFilter(Filter.linear);
    trilinearPortrait = loadTexture("parin_portrait28.png");
    trilinearPortrait.setFilter(Filter.trilinear);
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    // Find where to start drawing so the portraits end up in the middle of the screen.
    auto gap = 24.0f;
    auto width = -gap;
    foreach (height; heights) width += linearPortrait.width * height / linearPortrait.height + gap;
    auto x = (resolution.x - width) * 0.5f;
    // Draw both textures at the same sizes, lined up at the bottom of each row.
    // The difference is clear at the small ones.
    drawText("Linear", Vec2(x, 8));
    drawText("Trilinear", Vec2(x, 184));
    foreach (height; heights) {
        auto scale = Vec2(height / linearPortrait.height);
        drawTexture(linearPortrait, Vec2(x, 172 - height), DrawOptions(scale));
        drawTexture(trilinearPortrait, Vec2(x, 348 - height), DrawOptions(scale));
        x += linearPortrait.width * scale.x + gap;
    }
    return false;
}

mixin runGame!(ready, update, null);
