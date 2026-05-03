/// This example shows how to animate a full-screen transition effect.

import parin;

auto state = SmoothToggle();
auto color = cyan;

bool update(float dt) {
    if ('q'.isPressed && !state.isActive) state.toggle();
    auto y = smoothstep(-resolutionHeight, resolutionHeight, state.update(dt));
    if (state.isAtEnd) {
        state.toggleSnap();
        color.r = cast(ubyte) (randi % 255);
        color.g = cast(ubyte) (randi % 255);
        color.b = cast(ubyte) (randi % 255);
    };

    drawText("Press Q", resolution * 0.5, DrawOptions(Vec2(6), Hook.center));
    drawRect(Rect(0, y, resolution), color);
    return false;
}

mixin runGame!(null, update, null);
