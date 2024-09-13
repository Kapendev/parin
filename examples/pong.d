/// This example shows how to create a pong-like game with Popka.
import popka;

// The game variables.
auto gameCounter = 0;

auto paddle1 = Rect(2, 30);
auto paddle2 = Rect(2, 30);

auto ball = Rect(5, 5);
auto ballSpeed = Vec2(120);
auto ballDirection = Vec2(1, 1);

void ready() {
    lockResolution(320, 180);
    // Place the game objects.
    auto center = resolution * Vec2(0.5);
    auto offset = Vec2(resolutionWidth * 0.4, 0);
    paddle1.position = center - offset;
    paddle2.position = center + offset;
    ball.position = center;
}

bool update(float dt) {
    // The objects in this game are centered.
    // This means that rectangle data is divided into 2 parts, normal and centered.
    // A normal rectangle holds the position of an object.
    // A centered rectangle is used for collision checking and drawing.

    // Move the ball.
    ball.position += ballDirection * ballSpeed * Vec2(dt);
    // Check if the ball exited the screen from the left or right side.
    if (ball.centerArea.leftPoint.x < 0) {
        ball.position = resolution * Vec2(0.5);
        paddle1.position.y = resolutionHeight * 0.5;
        paddle2.position.y = resolutionHeight * 0.5;
        gameCounter = 0;
    } else if (ball.centerArea.rightPoint.x > resolutionWidth) {
        ball.position = resolution * Vec2(0.5);
        paddle1.position.y = resolutionHeight * 0.5;
        paddle2.position.y = resolutionHeight * 0.5;
        gameCounter = 0;
    }
    // Check if the ball exited the screen from the top or bottom side.
    if (ball.centerArea.topPoint.y < 0) {
        ballDirection.y *= -1;
        ball.position.y = ball.size.y * 0.5;
    } else if (ball.centerArea.bottomPoint.y > resolutionHeight) {
        ballDirection.y *= -1;
        ball.position.y = resolutionHeight - ball.size.y * 0.5;
    }

    // Move paddle1.
    paddle1.position.y = clamp(paddle1.position.y + wasd.y * ballSpeed.y * dt, paddle1.size.y * 0.5f, resolutionHeight - paddle1.size.y * 0.5f);
    // Move paddle2.
    auto paddle2Target = ball.position.y;
    if (ballDirection.x < 1) {
        paddle2Target = paddle2.position.y;
    }
    paddle2.position.y = paddle2.position.y.moveTo(clamp(paddle2Target, paddle2.size.y * 0.5f, resolutionHeight - paddle2.size.y * 0.5f), ballSpeed.y * dt);

    // Check for paddle and ball collisions.
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

    // Draw the objects.
    drawRect(ball.centerArea);
    drawRect(paddle1.centerArea);
    drawRect(paddle2.centerArea);

    // Draw the counter.
    auto textOptions = DrawOptions(Hook.center);
    textOptions.scale = Vec2(2);
    drawDebugText("{}".format(gameCounter), Vec2(resolutionWidth * 0.5, 16), textOptions);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
