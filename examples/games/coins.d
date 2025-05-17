/// This example shows how to create a simple collect-the-coins game with Parin.

import parin;

auto player = Rect(16, 16);
auto coins = SparseList!Rect();
auto maxCoinCount = 8;

void ready() {
    lockResolution(320, 180);
    // Place the player at the center of the window.
    player.position = resolution * Vec2(0.5);
    // Create the coins. Every coin will have a random starting position.
    auto coinSize = Vec2(8);
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
}

bool update(float dt) {
    // Move the player.
    auto playerDirection = Vec2(
        Keyboard.right.isDown - Keyboard.left.isDown,
        Keyboard.down.isDown - Keyboard.up.isDown,
    );
    player.position += playerDirection * Vec2(120 * dt);
    // Check if the player is touching coins and remove them.
    foreach (id; coins.ids) {
        if (coins[id].hasIntersection(player)) coins.remove(id);
    }
    // Draw the game.
    foreach (coin; coins.items) drawRect(coin);
    drawRect(player);
    if (coins.length == 0) {
        drawDebugText("You collected all the coins!", Vec2(8));
    } else {
        drawDebugText("Coins: {}/{}\nMove with arrow keys.".fmt(maxCoinCount - coins.length, maxCoinCount), Vec2(8));
    }
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
