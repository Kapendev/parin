/// This example shows how to use the Parin physics engine.

import parin;

auto world = BoxWorld();
auto platformBoxId = BoxWallId();
auto groundBoxId = BoxWallId();
auto playerBoxId = BoxActorId();
auto playerMover = BoxMover(2, 1, 0.3, 4); // Create a mover with: speed=2, acceleration=1, gravity=0.3, jump=4
auto groundY = 140;

void ready() {
    lockResolution(320, 180);
    // Add walls to the world.
    platformBoxId = world.appendWall(IRect(140, groundY - 20, 64, 16));
    groundBoxId = world.appendWall(IRect(0, groundY, resolutionWidth, resolutionHeight - groundY));
    // Add an actor to the world. The `BoxSide.top` allows the actor to ride moving walls.
    playerBoxId = world.appendActor(IRect(80, groundY - 16, 16, 16), BoxSide.top);
}

bool update(float dt) {
    // Move the platform.
    world.moveWallX(platformBoxId, sin(elapsedTime * 4) * 1.7);
    // Move the player.
    playerMover.move(Vec2(wasd.x, wasdPressed.y));
    world.moveActorX(playerBoxId, playerMover.velocity.x);
    // If there is a collision while falling, set the velocity to zero.
    if (world.moveActorY(playerBoxId, playerMover.velocity.y)) {
        playerMover.velocity.y = 0;
    }
    // Draw the world.
    drawDebugBoxWorld(world);
    drawDebugText("Move with arrow keys.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
