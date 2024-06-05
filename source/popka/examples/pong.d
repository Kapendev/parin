// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example shows how to create a pong-like game with Popka.

module popka.examples.pong;

import popka;

@safe @nogc nothrow:

void runPongExample() {
    openWindow(640, 360);
    lockResolution(320, 180);
    changeBackgroundColor(Color(202,178,106));

    // The game variables.
    auto gameCounter = 0;

    auto ballSize = Vec2(5);
    auto ballDirection = Vec2(1, 1);
    auto ballSpeed = 120;
    auto ball = Rect(resolution * 0.5, ballSize);

    auto paddleSize = Vec2(ballSize.x * 0.35, ballSize.x * 5);
    auto paddleOffset = Vec2(resolution.x * 0.4, 0);
    auto paddle1 = Rect(resolution * 0.5 - paddleOffset, paddleSize);
    auto paddle2 = Rect(resolution * 0.5 + paddleOffset, paddleSize);

    while (isWindowOpen) {
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
        if (ball.centerArea.topPoint.y < 0 || ball.centerArea.bottomPoint.y > resolution.y) {
            ballDirection.y *= -1;
        }
        ball.position += ballDirection * ballSpeed * deltaTime;

        // Move paddle1 and paddle2.
        paddle1.position.y = clamp(paddle1.position.y + wasd.y * ballSpeed * deltaTime, paddleSize.y * 0.5, resolution.y - paddleSize.y * 0.5);
        auto paddle2Target = ball.position.y;
        if (ballDirection.x < 1) {
            paddle2Target = paddle2.position.y;
        }
        paddle2.position.y = paddle2.position.y.moveTo(clamp(paddle2Target, paddleSize.y * 0.5, resolution.y - paddleSize.y * 0.5), ballSpeed * deltaTime);

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
    }
    freeWindow();
}
