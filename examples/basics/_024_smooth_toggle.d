/// This example shows how to slide a rectangle in and out of the screen.

import parin;

auto state = SmoothToggle();
enum height = 100;
enum offset = 8;

bool update(float dt) {
    if ('q'.isPressed) state.toggle();
    auto y = smoothstep(-height, offset, state.update(dt * 2));
    auto color = Color(6, 66, 66, cast(ubyte) (state.now * 255));

    drawText("Press Q", resolution * 0.5, DrawOptions(Vec2(6), Hook.center));
    drawRect(Rect(16, y, resolution.x - 32, height), color);
    return false;
}

mixin runGame!(null, update, null);
