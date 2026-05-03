/// This example demonstrates tweening between two values.

import parin;

auto pulse = Tween2(
    Vec2(6), Vec2(9), 1.3,
    TweenMode.yoyo, Easing.outElastic,
);

bool update(float dt) {
    drawText(
        "Nice!",
        resolution * Vec2(0.5),
        DrawOptions(pulse.update(dt), Hook.center),
    );
    return false;
}

mixin runGame!(null, update, null);
