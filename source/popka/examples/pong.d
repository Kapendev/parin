// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example shows how to create a pong-like game with Popka.

module popka.examples.pong;

import popka;

@safe @nogc nothrow:

// TODO: MAKE THE GAME!
void runPongExample() {
    openWindow(640, 360);
    lockResolution(320, 180);
    changeBackgroundColor(Color(202,178,106));

    // The game variables.
    auto ballSize = Vec2(4);
    auto ballDirection = Vec2(1, 1);
    auto ballStartSpeed = 60;
    auto ballSpeed = ballStartSpeed;
    auto paddleSize = Vec2(ballSize.x, ballSize.x * 4);
    auto paddleOffset = Vec2(resolution.x * 0.35, 0);
    auto ball = Rect(resolution * 0.5, ballSize);
    auto player1 = Rect(resolution * 0.5 - paddleOffset, paddleSize);
    auto player2 = Rect(resolution * 0.5 + paddleOffset, paddleSize);
    auto playerScore1 = 0;
    auto playerScore2 = 0;
    auto gameCounter = 0;

    while (isWindowOpen) {
        // The centered rects are used just for collision checking and drawing.
        auto centeredBall = ball.area(Hook.center);
        auto centeredPlayer1 = player1.area(Hook.center);
        auto centeredPlayer2 = player2.area(Hook.center);

        // Update the ball.
        if (centeredBall.position.x < 0) {
            ball.position = resolution * 0.5;
            ballSpeed = ballStartSpeed;
            playerScore2 += 1;
            player1.position.y = resolution.y * 0.5;
            player2.position.y = resolution.y * 0.5;
            gameCounter = 0;
        } else if (centeredBall.position.x > resolution.x - ball.size.x) {
            ball.position = resolution * 0.5;
            ballSpeed = ballStartSpeed;
            playerScore1 += 1;
            player1.position.y = resolution.y * 0.5;
            player2.position.y = resolution.y * 0.5;
            gameCounter = 0;
        }
        if (centeredBall.position.y < 0 || centeredBall.position.y > resolution.y - ball.size.y) {
            ballDirection.y *= -1;
        }
        ball.position += ballDirection * ballSpeed * deltaTime;

        // Update player1 and player2.
        player1.position.y = clamp(player1.position.y + wasd.y * ballSpeed * deltaTime, paddleSize.y * 0.5, resolution.y - paddleSize.y * 0.5);
        player2.position.y = clamp(ball.position.y, paddleSize.y * 0.5, resolution.y - paddleSize.y * 0.5);

        // Check for collisions.
        if (centeredPlayer1.hasIntersection(centeredBall)) {
            ballDirection.x *= -1;
            ball.position.x = centeredPlayer1.right.x + ball.size.x / 2 + 1;
            gameCounter += 1;
        }
        if (centeredPlayer2.hasIntersection(centeredBall)) {
            ballDirection.x *= -1;
            ball.position.x = centeredPlayer2.left.x - ball.size.x / 2 - 1;
            gameCounter += 1;
        }
        if (gameCounter == 6) {
            ballSpeed *= 2;
            gameCounter = 0;
        }

        // Draw the game.
        draw(centeredBall);
        draw(centeredPlayer1);
        draw(centeredPlayer2);
        draw("{} / {}".fmt(playerScore1, playerScore2));
    }
    freeWindow();
}
