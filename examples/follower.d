/// This example shows how to create an animated character that follows the mouse.
import popka;

// The game variables.
auto atlas = TextureId();
auto sprite = Sprite(16, 16, 0, 128, SpriteAnimation(0, 2, 6));
auto spritePosition = Vec2();

void ready() {
    lockResolution(320, 180);
    setBackgroundColor(toRgb(0x0b0b0b));
    setIsPixelPerfect(true);
    setIsCursorVisible(false);
    // Load the `atlas.png` file from the assets folder.
    atlas = loadTexture("atlas.png").unwrap();
}

bool update(float dt) {
    // Move the sprite around in a smooth way.
    spritePosition = spritePosition.moveToWithSlowdown(mouseScreenPosition, Vec2(dt), 0.2);

    // Update the frame of the sprite.
    auto isWaiting = spritePosition.distanceTo(mouseScreenPosition) < 0.2;
    if (isWaiting) {
        sprite.reset();
    } else {
        sprite.update(dt);
    }

    // Check if 1, 2, or 3 is pressed and change the character.
    foreach (i, digit; digitChars[1 .. 4]) {
        if (digit.isPressed) {
            sprite.animation.frameRow = cast(ubyte) i;
        }
    }

    // Set the drawing options for the sprite.
    auto options = DrawOptions();
    options.scale = Vec2(2);
    options.hook = Hook.center;
    options.flip = (spritePosition.directionTo(mouseScreenPosition).x > 0) ? Flip.x : Flip.none;

    // Draw the sprite, the mouse position and some info.
    drawSprite(atlas, sprite, spritePosition, options);
    drawVec2(mouseScreenPosition, 8, isWaiting ? blank : white.alpha(150));
    drawDebugText("Press 1, 2 or 3 to change the character.", Vec2(8));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
