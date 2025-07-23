/// This example shows how to use the sprite structure of Parin.
/// It will create an animated character that follows the mouse.

import parin;

auto atlas = TextureId();
auto sprite = Sprite(16, 16, 0, 128);          // Create a 16x16 sprite with the atlas position (0, 128).
auto spriteFlip = Flip.none;
auto idleAnimation = SpriteAnimation(0, 1, 6); // Create an animation at row 0, with 1 frame and a speed of 6.
auto walkAnimation = SpriteAnimation(0, 2, 6); // Create an animation at row 0, with 2 frames and a speed of 6.

void ready() {
    lockResolution(320, 180);
    atlas = loadTexture("parin_atlas.png");
}

bool update(float dt) {
    // The sprite should be updated every frame, regardless of whether it is running.
    sprite.update(dt);
    auto mouseDistance = sprite.position.distanceTo(mouse);
    auto mouseDirection = sprite.position.directionTo(mouse);
    // Play the correct animation.
    auto isWaiting = mouseDistance < 0.2;
    if (isWaiting) sprite.play(idleAnimation);
    else sprite.play(walkAnimation);
    // Move the sprite and flip it based on the mouse direction.
    sprite.followPositionWithSlowdown(mouse, 0.2);
    if (mouseDirection.x > 0) spriteFlip = Flip.x;
    else if (mouseDirection.x < 0) spriteFlip = Flip.none;
    // Check if 1, 2, or 3 is pressed and change the character.
    foreach (i, digit; digitChars[1 .. 4]) {
        auto row = cast(ubyte) i;
        if (digit.isPressed) {
            idleAnimation.frameRow = row;
            walkAnimation.frameRow = row;
        }
    }
    // Draw the sprite.
    auto options = DrawOptions(Hook.center);
    options.flip = spriteFlip;
    options.scale = Vec2(2);
    drawSprite(atlas, sprite, options);
    drawDebugText("Move the mouse.\nPress 1, 2 or 3 to change the character.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
