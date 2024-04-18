// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// A collect-the-coins example.

module popka.examples.coins;

import popka;

@safe @nogc nothrow:

void runCoinsExample() {
    openWindow(640, 480);
    lockResolution(320, 180);

    // The game variables.
    auto player = Rectangle(resolution * Vector2(0.5), Vector2(16));
    auto playerSpeed = Vector2(120);
    auto coins = FlagList!Rectangle();
    auto coinSize = Vector2(8);
    auto maxCoinCount = 8;

    // Create the coins.
    foreach (i; 0 .. maxCoinCount) {
        auto maxPosition = resolution - coinSize;
        auto coin = Rectangle(randf * maxPosition.x, randf * maxPosition.y, coinSize.x, coinSize.y);
        coins.append(coin);
    }

    while (isWindowOpen) {
        // Move the player.
        auto playerDirection = Vector2();
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
        player.position += playerDirection * playerSpeed * Vector2(deltaTime);

        // Check if the player is touching some coins and remove those coins.
        foreach (id; coins.ids) {
            if (coins[id].hasIntersection(player)) {
                coins.remove(id);
            }
        }

        // Draw the game.
        foreach (coin; coins.items) {
            draw(coin, lightGray);
        }
        draw(player, lightGray);
        if (coins.length == 0) {
            draw("You collected all the coins!");
        } else {
            draw("Coins: {}/{}".fmt(maxCoinCount - coins.length, maxCoinCount));
        }
    }
    freeWindow();
}
