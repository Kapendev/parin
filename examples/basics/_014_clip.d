/// This example shows how to use clipping regions in Parin.

import parin;

bool update(float dt) {
    // Only draw inside this area. Anything outside is clipped.
    // This can also be done with the `beginClip` and `endClip` functions.
    with (Clip(0, 0, resolution * Vec2(0.5, 1.0))) {
        drawVec2(mouse + 16, black, 64);
        drawVec2(mouse, white, 64);
    }
    drawText("Move your mouse across the screen.", Vec2(12), DrawOptions(Vec2(2)));
    return false;
}

mixin runGame!(null, update, null);
