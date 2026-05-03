/// This example shows how to animate a full-screen transition effect.

import parin;

auto color = cyan;
auto state = SmoothToggle();

bool update(float dt) {
    if ('q'.isPressed && !state.isActive) state.toggle();
    auto value = smoothstep(-resolutionHeight, resolutionHeight, state.update(dt));
    if (state.isAtEnd) {
        state.toggleSnap();
        color.r = cast(ubyte) (randi % 255);
        color.g = cast(ubyte) (randi % 255);
        color.b = cast(ubyte) (randi % 255);
    };

    drawText("Press Q", resolution * 0.5, DrawOptions(Vec2(6), Hook.center));
    drawRect(Rect(0, value, resolution), color);
    return false;
}

mixin runGame!(null, update, null);
