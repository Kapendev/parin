/// This example shows how to create a simple collect-the-coins game with Parin.

import parin;

auto player = Rect(16, 16);
auto coins = SparseList!Rect();
auto coinSize = Vec2(8);
auto coinCount = 8;

void ready() {
    lockResolution(320, 180);
    setWindowBackgroundColor(Nes8.black);
    // Place the player at the center of the window.
    player.position = resolution * Vec2(0.5);
    // Create the coins. Every coin will have a random starting position.
    foreach (i; 0 .. coinCount) {
        auto a = Vec2(0, 40);
        auto b = resolution - coinSize - a;
        auto coin = Rect(
            randf * b.x + a.x,
            randf * b.y + a.y,
            coinSize,
        );
        coins.append(coin);
    }
}

bool update(float dt) {
    // Move and draw the player.
    player.position += wasd * Vec2(120 * dt);
    drawRect(player, Nes8.blue);
    // Collect and draw the coins.
    foreach (id; coins.ids) {
        drawRect(coins[id], Nes8.yellow);
        if (coins[id].hasIntersection(player)) coins.remove(id);
    }
    // Draw text about the game.
    auto text = coins.length == 0 ? "You collected all the coins!" : "Coins: {}/{}\nMove with arrow keys.".fmt(coinCount - coins.length, coinCount);
    drawText(text, Vec2(8), DrawOptions(Nes8.white));
    return false;
}

mixin runGame!(ready, update, null);
