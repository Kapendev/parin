/// This example shows how to use the Parin physics engine.
/// Collect all the coins. Watch out for the lift and the gap.
/// Press down and jump to fall through the dark walls.

import parin;

auto world = BoxWorld();
auto playerId = BoxActorId();
auto platformId = BoxWallId();
auto liftId = BoxWallId();
auto playerMover = BoxMover(2, 1, 0.3, 4); // Create a mover with: speed=2, acceleration=1, gravity=0.3, jump=4
auto spawnPoint = IVec2(40, 148);
auto wallSpeed = 60;

IVec2[5] coins = [
    IVec2(56, 112),
    IVec2(92, 80),
    IVec2(156, 120),
    IVec2(196, 40),
    IVec2(264, 152),
];

bool[5] isCollected;

void ready() {
    lockResolution(320, 180);
    // Add the ground. There is a gap in the middle.
    world.pushWall(Box(0, 164, 120, 16));
    world.pushWall(Box(200, 164, 120, 16));
    // Add walls that can be jumped through from below. The `BoxSide.top` makes them one-way.
    world.pushWall(Box(32, 128, 56, 6), BoxSide.top);
    world.pushWall(Box(72, 96, 48, 6), BoxSide.top);
    // Add a high ledge and two moving walls.
    world.pushWall(Box(176, 56, 48, 8));
    platformId = world.pushWall(Box(144, 140, 32, 8));
    liftId = world.pushWall(Box(248, 112, 40, 8));
    // Add the player. The `BoxSide.top` allows the player to ride moving walls.
    playerId = world.pushActor(Box(spawnPoint.x, spawnPoint.y, 16, 16), BoxSide.top);
}

// Returns the wall right under the player's feet, or none.
BoxWallId groundWall() {
    auto player = world.actor(playerId);
    auto feet = Box(player.position.x, player.position.y + 1, player.size.x, player.size.y);
    foreach (id; world.wallCollisions(feet)) {
        if (world.wall(id).position.y == player.position.y + player.size.y) return id;
    }
    return BoxWallId();
}

// Returns a value that goes from 0 to `length` and back at the given speed.
float pingPong(float length) {
    auto t = fmod(elapsedTickTime * wallSpeed, length * 2);
    return cast(int) (t < length ? t : length * 2 - t);
}

void respawn() {
    world.actor(playerId).position = spawnPoint;
    playerMover.velocity = Vec2();
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    // Move the platform over the gap and the lift up and down.
    // The lift returns the actors it squished.
    world.moveWallX(platformId, 104 + pingPong(80) - world.wall(platformId).x);
    if (world.moveWallY(liftId, 76 + pingPong(72) - world.wall(liftId).y).length) respawn();
    // Move the player. Jumping is only allowed when standing on something.
    // Pressing down and jump on a one-way wall moves the player one pixel into it.
    // One-way walls ignore actors that are inside them, so the player falls through.
    auto ground = groundWall();
    auto isJumping = ground && Keyboard.space.isPressed;
    if (isJumping && wasd.y > 0 && world.wallProperties(ground).side == BoxSide.top) {
        isJumping = false;
        world.actor(playerId).position.y += 1;
    }
    playerMover.move(Vec2(wasd.x, isJumping ? -1 : 0));
    world.moveActorX(playerId, playerMover.velocity.x);
    if (world.moveActorY(playerId, playerMover.velocity.y)) playerMover.velocity.y = 0;
    auto player = world.actor(playerId).toRect();
    if (player.position.y > resolutionHeight) respawn();
    // Collect the coins.
    auto coinCount = 0;
    foreach (i, coin; coins) {
        if (Rect(coin.toVec(), 8, 8).hasIntersection(player)) isCollected[i] = true;
        coinCount += isCollected[i];
    }
    if (coinCount == coins.length && Keyboard.enter.isPressed) {
        isCollected = false;
        respawn();
    }
    drawDebugBoxWorld(world);
    foreach (i, coin; coins) if (!isCollected[i]) drawRect(Rect(coin.toVec(), 8, 8), yellow);
    drawRect(player, cyan);
    if (coinCount == coins.length) drawText("You got all the coins!\nPress enter to play again.", Vec2(8));
    else drawText("Arrows to move. Space to jump.\nCoins: {}/{}".fmt(coinCount, coins.length), Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
