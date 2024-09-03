/// This example shows how to create an animated character that follows the mouse.
import popka;

// The game variables.
auto atlas = TextureId();
auto sprite = Sprite(16, 16, 0, 128);
auto spritePosition = Vec2();
auto spriteFlip = Flip.none;
auto idleAnimation = SpriteAnimation(0, 1, 6);
auto walkAnimation = SpriteAnimation(0, 2, 6);

void ready() {
    lockResolution(320, 180);
    setBackgroundColor(toRgb(0x0b0b0b));
    setIsPixelPerfect(true);
    setIsCursorVisible(false);
    // Load the `atlas.png` file from the assets folder.
    atlas = loadTexture("atlas.png").get();
}

bool update(float dt) {
    // Get some basic info about the mouse.
    auto mouseDistance = spritePosition.distanceTo(mouseScreenPosition);
    auto mouseDirection = spritePosition.directionTo(mouseScreenPosition);

    // Move the sprite around in a smooth way.
    spritePosition = spritePosition.moveToWithSlowdown(mouseScreenPosition, Vec2(dt), 0.2);

    // Play the right animation and update the sprite.
    auto isWaiting = mouseDistance < 0.2;
    if (isWaiting) {
        sprite.play(idleAnimation);
    } else {
        sprite.play(walkAnimation);
    }
    sprite.update(dt);

    // Flip the sprite based on the mouse direction.
    if (mouseDirection.x > 0) {
        spriteFlip = Flip.x;
    } else if (mouseDirection.x < 0) {
        spriteFlip = Flip.none;
    }

    // Check if 1, 2, or 3 is pressed and change the character.
    foreach (i, digit; digitChars[1 .. 4]) {
        if (digit.isPressed) {
            idleAnimation.frameRow = cast(ubyte) i;
            walkAnimation.frameRow = cast(ubyte) i;
        }
    }

    // Set the drawing options for the sprite.
    auto options = DrawOptions();
    options.scale = Vec2(2);
    options.hook = Hook.center;
    options.flip = spriteFlip;

    // Draw the sprite, the mouse position and some info.
    drawSprite(atlas, sprite, spritePosition, options);
    drawVec2(mouseScreenPosition, 8, isWaiting ? blank : white.alpha(150));
    drawDebugText("Press 1, 2 or 3 to change the character.", Vec2(8));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
