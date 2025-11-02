/// This example shows how to create a Flappy Bird clone with Parin. (WIP)

import parin;

auto pipes = FixedList!(Rect, 32)();
auto bird = Rect(16, 16);
auto birdVelocity = Vec2();

void ready() {
    lockResolution(320, 180);
    setWindowBackgroundColor(Nes8.black);

    pipes.resize(4);
    foreach (i, ref pipe; pipes) {
        pipe = Rect(resolution.x + (i + 1) * (resolution.x / pipes.length), resolution.y * 0.7, 10, resolution.y);
    }
    bird.position = Vec2(30, resolution.y * 0.3 - bird.h * 0.5);
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();

    foreach (ref pipe; pipes) {
        pipe.x -= 1;
        if (pipe.rightPoint.x < 0) pipe.x = resolution.x;
    }

    birdVelocity.y = min(birdVelocity.y + 5.5 * dt, 5.0);
    if (wasdPressed.y < 0) birdVelocity.y = -2.5;
    bird.position += birdVelocity;
    if (bird.y > resolution.y) bird.y = -bird.h;

    foreach (ref pipe; pipes) drawRect(pipe, red);
    drawRect(bird);
    return false;
}

mixin runGame!(ready, update, null);
