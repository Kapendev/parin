// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// This example shows how to create a simple game with Popka.

module popka.examples.coins;

import popka;

@safe @nogc nothrow:

void runCoinsExample() {
    openWindow(640, 360);
    lockResolution(320, 180);

    // The game variables.
    auto player = Rect(resolution * 0.5, Vec2(16));
    auto playerSpeed = Vec2(120);
    auto coins = FlagList!Rect();
    auto coinSize = Vec2(8);
    auto maxCoinCount = 8;

    // Change the background color.
    changeBackgroundColor(gray1);

    // Create the coins.
    foreach (i; 0 .. maxCoinCount) {
        auto minPosition = Vec2(0, 40);
        auto maxPosition = resolution - coinSize - minPosition;
        auto coin = Rect(
            randf * maxPosition.x + minPosition.x,
            randf * maxPosition.y + minPosition.y,
            coinSize.x,
            coinSize.y
        );
        coins.append(coin);
    }

    while (isWindowOpen) {
        // Move the player.
        auto playerDirection = Vec2();
        if (Keyboard.left.isDown) {
            playerDirection.x = -1;
        }
        if (Keyboard.right.isDown) {
            playerDirection.x = 1;
        }
        if (Keyboard.up.isDown) {
            playerDirection.y = -1;
        }
        if (Keyboard.down.isDown) {
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
            draw("Coins: {}/{}\nMove with arrow keys.".fmt(maxCoinCount - coins.length, maxCoinCount));
        }
    }
    freeWindow();
}
