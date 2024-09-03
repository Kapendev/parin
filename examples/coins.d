/// This example shows how to create a simple game with Popka.
import popka;

// The game variables.
auto player = Rect(16, 16);
auto playerSpeed = Vec2(120);

auto coins = SparseList!Rect();
auto coinSize = Vec2(8);
auto maxCoinCount = 8;

void ready() {
    lockResolution(320, 180);

    // Place the player and create the coins. Every coin will have a random starting position.
    player.position = resolution * Vec2(0.5);
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
    auto playerDirection = Vec2();
    if (Keyboard.left.isDown || 'a'.isDown) playerDirection.x = -1;
    if (Keyboard.right.isDown || 'd'.isDown) playerDirection.x = 1;
    if (Keyboard.up.isDown || 'w'.isDown)  playerDirection.y = -1;
    if (Keyboard.down.isDown || 's'.isDown) playerDirection.y = 1;
    player.position += playerDirection * playerSpeed * Vec2(dt);

    // Check if the player is touching some coins and remove those coins.
    foreach (id; coins.ids) {
        if (coins[id].hasIntersection(player)) {
            coins.remove(id);
        }
    }

    // Draw the game.
    foreach (coin; coins.items) {
        drawRect(coin);
    }
    drawRect(player);
    if (coins.length == 0) {
        drawDebugText("You collected all the coins!", Vec2(8));
    } else {
        drawDebugText("Coins: {}/{}\nMove with arrow keys.".format(maxCoinCount - coins.length, maxCoinCount), Vec2(8));
    }
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
