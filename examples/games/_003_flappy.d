/// This example shows how to create a Flappy Bird clone with Parin.

import parin;

auto gameCounter = 0;
auto hurtTimer = Timer(1.5);
auto spaceTimer = Timer(1.5);
auto pipes = List!Rect();
auto pipesSpacing = 65;
auto pipesOffset = 40;
auto pipesCount = 3;
auto bird = Rect(14, 14);
auto birdVelocity = Vec2();

Rect topPart(Rect pipe) => Rect(pipe.x, pipe.y - pipe.h - pipesSpacing, pipe.size);
Rect spacePart(Rect pipe) => Rect(pipe.x, pipe.y - pipesSpacing, pipe.w, pipesSpacing);
float randomPipeY() => resolution.y * 0.7 + (randi % 2 ? 1 : -1) * (randi % pipesOffset);

void ready() {
    lockResolution(320, 180);
    setWindowBackgroundColor(Nes8.black);
    // Create the pipes and setup the scene.
    foreach (i; 0 .. pipesCount) {
        pipes.push(Rect(resolution.x + (i + 1) * (resolution.x / pipesCount), randomPipeY, 12, resolution.y));
    }
    bird.position = Vec2(30, resolution.y * 0.3 - bird.h * 0.5);
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    // Move the bird.
    birdVelocity.y = min(birdVelocity.y + 5.5 * dt, 4.3);
    if (Keyboard.space.isPressed || wasdPressed.y < 0) birdVelocity.y = -2.5;
    bird.position += birdVelocity;
    if (bird.y > resolution.y) bird.y = -bird.h;
    if (bird.bottomPoint.y < 0) bird.y = resolution.y;
    // Move the pipes and check for collisions.
    foreach (ref pipe; pipes) {
        pipe.x -= 1;
        if (pipe.rightPoint.x < 0) pipe.position = Vec2(resolution.x, randomPipeY);
        if (pipe.hasIntersection(bird) || pipe.topPart.hasIntersection(bird)) {
            if (!hurtTimer.isActive) {
                gameCounter -= 1;
                hurtTimer.start();
            }
        }
        if (pipe.spacePart.hasIntersection(bird)) {
            if (!spaceTimer.isActive && !hurtTimer.isActive) {
                gameCounter += 1;
                spaceTimer.start();
            }
        }
    }
    // Draw the game.
    foreach (pipe; pipes) {
        drawRect(pipe, Nes8.green);
        drawRect(pipe, Nes8.white, 1);
        drawRect(pipe.topPart, Nes8.green);
        drawRect(pipe.topPart, Nes8.white, 1);
    }
    drawRect(bird, hurtTimer.isActive ? Nes8.red.alpha(cast(ubyte) ((sin(hurtTimer.time * 15) + 1) * 0.5f * 255)) : Nes8.yellow);
    drawRect(bird, Nes8.white, 1);
    drawText("[ {} ]".fmt(gameCounter), Vec2(resolution.x * 0.5, 14 + 2 * sin(elapsedTime * 5)), DrawOptions(Nes8.white, Hook.center));
    return false;
}

mixin runGame!(ready, update, null);
