// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example shows how to create a simple game with Popka.

import popka;

// The game variables.
auto player = Rect(16, 16);
auto playerSpeed = Vec2(120);
auto coins = FlagList!Rect();
auto coinSize = Vec2(8);
auto maxCoinCount = 8;

void gameLoop() {
    // Move the player.
    auto playerDirection = Vec2();
    if ('a'.isDown) {
        playerDirection.x = -1;
    }
    if ('d'.isDown) {
        playerDirection.x = 1;
    }
    if ('w'.isDown) {
        playerDirection.y = -1;
    }
    if ('s'.isDown) {
        playerDirection.y = 1;
    }
    player.position += playerDirection * playerSpeed * deltaTime;

    // Check if the player is touching some coins and remove those coins.
    foreach (id; coins.ids) {
        if (coins[id].hasIntersection(player)) {
            coins.remove(id);
        }
    }

    // Draw the game.
    foreach (coin; coins.items) {
        draw(coin, gray2);
    }
    draw(player, gray2);
    if (coins.length == 0) {
        draw("You collected all the coins!");
    } else {
        draw("Coins: {}/{}\nMove with wasd keys.".fmt(maxCoinCount - coins.length, maxCoinCount));
    }
}

void gameStart(string path) {
    openWindow(640, 360);
    lockResolution(320, 180);
    changeBackgroundColor(gray1);

    // Place the player and create the coins.
    player.position = resolution * 0.5;
    foreach (i; 0 .. maxCoinCount) {
        auto minPosition = Vec2(0, 40);
        auto maxPosition = resolution - coinSize - minPosition;
        auto coin = Rect(
            randf * maxPosition.x + minPosition.x,
            randf * maxPosition.y + minPosition.y,
            coinSize,
        );
        coins.append(coin);
    }

    updateWindow!gameLoop();
    closeWindow();
}

mixin addGameStart!gameStart;
