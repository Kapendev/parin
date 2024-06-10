// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example shows how to create a pong-like game with Popka.

import popka;

// The game variables.
auto gameCounter = 0;
auto ballDirection = Vec2(1, 1);
auto ballSpeed = 120;
auto ball = Rect(5, 5);
auto paddle1 = Rect(5 * 0.35, 5 * 5);
auto paddle2 = Rect(5 * 0.35, 5 * 5);

bool gameLoop() {
    // The normal rects hold the real position of a game object.
    // The centered rects are used for collision checking and drawing.

    // Move the ball.
    if (ball.centerArea.leftPoint.x < 0) {
        ball.position = resolution * 0.5;
        paddle1.position.y = resolution.y * 0.5;
        paddle2.position.y = resolution.y * 0.5;
        gameCounter = 0;
    } else if (ball.centerArea.rightPoint.x > resolution.x) {
        ball.position = resolution * 0.5;
        paddle1.position.y = resolution.y * 0.5;
        paddle2.position.y = resolution.y * 0.5;
        gameCounter = 0;
    }
    if (ball.centerArea.topPoint.y < 0) {
        ballDirection.y *= -1;
        ball.position.y = ball.size.y * 0.5;
    } else if (ball.centerArea.bottomPoint.y > resolution.y) {
        ballDirection.y *= -1;
        ball.position.y = resolution.y - ball.size.y * 0.5;
    }
    ball.position += ballDirection * ballSpeed * deltaTime;

    // Move paddle1 and paddle2.
    paddle1.position.y = clamp(paddle1.position.y + wasd.y * ballSpeed * deltaTime, paddle1.size.y * 0.5, resolution.y - paddle1.size.y * 0.5);
    auto paddle2Target = ball.position.y;
    if (ballDirection.x < 1) {
        paddle2Target = paddle2.position.y;
    }
    paddle2.position.y = paddle2.position.y.moveTo(clamp(paddle2Target, paddle2.size.y * 0.5, resolution.y - paddle2.size.y * 0.5), ballSpeed * deltaTime);

    // Check for collisions.
    if (paddle1.centerArea.hasIntersection(ball.centerArea)) {
        ballDirection.x *= -1;
        ball.position.x = paddle1.centerArea.rightPoint.x + ball.size.x * 0.5;
        gameCounter += 1;
    }
    if (paddle2.centerArea.hasIntersection(ball.centerArea)) {
        ballDirection.x *= -1;
        ball.position.x = paddle2.centerArea.leftPoint.x - ball.size.x * 0.5;
        gameCounter += 1;
    }

    // Draw the game.
    auto textOptions = DrawOptions();
    textOptions.scale = Vec2(2);
    textOptions.hook = Hook.center;
    draw(ball.centerArea);
    draw(paddle1.centerArea);
    draw(paddle2.centerArea);
    draw("{}".fmt(gameCounter), Vec2(resolution.x * 0.5, 16), textOptions);
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    changeBackgroundColor(Color(202,178,106));

    // Place the game objects.
    auto paddleOffset = Vec2(resolution.x * 0.4, 0);
    ball.position = resolution * 0.5;
    paddle1.position = resolution * 0.5 - paddleOffset;
    paddle2.position = resolution * 0.5 + paddleOffset;
    updateWindow!gameLoop();
}

mixin addGameStart!(gameStart, 640, 360);
