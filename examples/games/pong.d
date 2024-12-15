/// This example shows how to create a pong-like game with Parin.

import parin;

auto gameCounter = 0;
auto paddle1 = Rect(2, 25);
auto paddle2 = Rect(2, 25);
auto ball = Rect(5, 5);
auto ballDirection = Vec2(1, 1);
auto ballSpeed = 120;

void ready() {
    lockResolution(320, 180);
    // Place the game objects.
    auto center = resolution * Vec2(0.5);
    auto offset = Vec2(resolutionWidth * 0.4, 0);
    paddle1.position = center - offset;
    paddle2.position = center + offset;
    ball.position = center;
}

// The objects in this game are centered.
// This means that rectangle data is divided into 2 parts, normal and centered.
// A normal rectangle holds the position of an object.
// A centered rectangle is used for collision checking and drawing.
bool update(float dt) {
    // Move the ball.
    ball.position += ballDirection * Vec2(ballSpeed * dt);
    // Check if the ball exited the screen from the left or right side.
    if (ball.centerArea.leftPoint.x < 0 || ball.centerArea.rightPoint.x > resolutionWidth) {
        ball.position = resolution * Vec2(0.5);
        paddle1.position.y = resolutionHeight * 0.5;
        paddle2.position.y = resolutionHeight * 0.5;
        gameCounter = 0;
    }
    // Check if the ball exited the screen from the top or bottom side.
    if (ball.centerArea.topPoint.y < 0 || ball.centerArea.bottomPoint.y > resolutionHeight) {
        ballDirection.y *= -1;
    }

    // Move paddle1.
    paddle1.position.y = clamp(
        paddle1.position.y + wasd.y * ballSpeed * dt,
        paddle1.size.y * 0.5f,
        resolutionHeight - paddle1.size.y * 0.5f
    );
    // Move paddle2.
    auto paddle2Target = ballDirection.x < 1 ? paddle2.position.y : ball.position.y;
    paddle2.position.y = paddle2.position.y.moveTo(
        clamp(paddle2Target, paddle2.size.y * 0.5f, resolutionHeight - paddle2.size.y * 0.5f),
        ballSpeed * dt
    );

    // Check for collisions.
    if (paddle1.centerArea.hasIntersection(ball.centerArea)) {
        ballDirection.x *= -1;
        gameCounter += 1;
    }
    if (paddle2.centerArea.hasIntersection(ball.centerArea)) {
        ballDirection.x *= -1;
        gameCounter += 1;
    }

    // Draw the game.
    drawRect(ball.centerArea);
    drawRect(paddle1.centerArea);
    drawRect(paddle2.centerArea);
    auto textOptions = DrawOptions(Hook.center);
    textOptions.scale = Vec2(2);
    drawDebugText("{}".format(gameCounter), Vec2(resolutionWidth * 0.5, 16), textOptions);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
