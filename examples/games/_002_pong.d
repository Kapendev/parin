/// This example shows how to create a Pong-like game with Parin.
/// The game objects in this game are centered.
/// This means that rectangle data is divided into 2 parts, normal and centered.
/// A normal rectangle holds the position of an object.
/// A centered rectangle is used for collision checking and drawing.

import parin;

auto gameCounter = 0;
auto ball = Rect(5, 5);
auto ballDirection = Vec2(1, 1);
auto paddle1 = Rect(2, 45);
auto paddle2 = Rect(2, 45);

void ready() {
    lockResolution(320, 180);
    setWindowBackgroundColor(Nes8.black);
    // Place the game objects.
    auto center = resolution * Vec2(0.5);
    auto offset = Vec2(resolution.x * 0.44, 0);
    ball.position = center;
    paddle1.position = center - offset;
    paddle2.position = center + offset;
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    auto center = resolution * Vec2(0.5);

    // Move the ball.
    ball.position += ballDirection * Vec2(120 * dt);
    // Check if the ball exited the screen.
    if (ball.centerArea.leftPoint.x < 0 || ball.centerArea.rightPoint.x > resolution.x) {
        ball.position = center;
        gameCounter -= 1;
    }
    if (ball.centerArea.topPoint.y < 0 || ball.centerArea.bottomPoint.y > resolution.y) {
        ballDirection.y *= -1;
    }

    // Move paddle1.
    paddle1.y = clamp(
        paddle1.y + wasd.y * 120 * dt,
        paddle1.h * 0.5f,
        resolution.y - paddle1.h * 0.5f,
    );
    // Move paddle2.
    auto paddle2Target = ballDirection.x < 1 ? paddle2.y : ball.y;
    paddle2.y = paddle2.y.moveTo(
        clamp(paddle2Target, paddle2.h * 0.5f, resolution.y - paddle2.h * 0.5f),
        120 * dt
    );
    // Check for collisions.
    if (paddle1.centerArea.hasIntersection(ball.centerArea) || paddle2.centerArea.hasIntersection(ball.centerArea)) {
        ballDirection.x *= -1;
        gameCounter += 1;
    }

    // Draw the game.
    drawRect(ball.centerArea, Nes8.yellow);
    drawRect(paddle1.centerArea, Nes8.blue);
    drawRect(paddle2.centerArea, Nes8.red);
    drawText("[ {} ]".fmt(gameCounter), Vec2(resolution.x * 0.5, 14 + 2 * sin(elapsedTime * 5)), DrawOptions(Nes8.white, Hook.center));
    return false;
}

mixin runGame!(ready, update, null);
