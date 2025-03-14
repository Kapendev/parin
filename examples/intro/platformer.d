/// This example shows how to use the Parin physics engine.

import parin;

auto world = BoxWorld();
auto platformBoxId = WallBoxId();
auto groundBoxId = WallBoxId();
auto playerBoxId = ActorBoxId();
auto playerMover = BoxMover(2, 4, 0.3, 1);
auto groundY = 140;

void ready() {
    lockResolution(320, 180);
    // Add boxes to the world.
    platformBoxId = world.appendWall(IRect(140, groundY - 20, 64, 16));
    groundBoxId = world.appendWall(IRect(0, groundY, resolutionWidth, resolutionHeight - groundY));
    playerBoxId = world.appendActor(IRect(80, groundY - 16, 16, 16), RideSide.top);
}

bool update(float dt) {
    // Move the platform box.
    world.moveWallX(platformBoxId, sin(elapsedTime * 4) * 1.7);
    // Move the player box.
    playerMover.direction.x = wasd.x;
    playerMover.direction.y = wasdPressed.y;
    playerMover.move();
    world.moveActorX(playerBoxId, playerMover.velocity.x);
    if (world.moveActorY(playerBoxId, playerMover.velocity.y)) {
        playerMover.velocity.y = 0;
    }
    // Draw the world.
    foreach (wall; world.walls) {
        drawRect(wall.toRect(), black.alpha(190));
    }
    foreach (actor; world.actors) {
        drawRect(actor.toRect(), yellow.alpha(190));
    }
    drawDebugText("Move with arrow keys.", Vec2(8));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
