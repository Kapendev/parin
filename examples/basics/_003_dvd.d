/// A fun example that makes text bounce inside the window.

import parin;

auto dvd = Rect(0, 0, 6 * 3, 12 * 1); /// The position and size of the text.
auto dvdDirection = Vec2(1, 1);       /// The move direction of the text.

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    if (dvd.x < 0.0f || dvd.x > resolution.x - dvd.w) dvdDirection.x *= -1;
    if (dvd.y < 0.0f || dvd.y > resolution.y - dvd.h) dvdDirection.y *= -1;
    dvd.position += dvdDirection;
    drawDebugText("DVD", dvd.position);
    return false;
}

mixin runGame!(ready, update, null);
