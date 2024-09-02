/// This example shows how to create an animated character that follows the mouse.
import popka;

// The game variables.
auto atlas = TextureId();
auto sprite = Sprite(16, 16, 0, 128, 2, 8);
auto spritePosition = Vec2();
auto spriteSlowdown = 0.2;

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
    spritePosition = spritePosition.moveToWithSlowdown(mouseScreenPosition, Vec2(dt), spriteSlowdown);

    // Update the frame of the sprite.
    auto isWaiting = spritePosition.distanceTo(mouseScreenPosition) < 0.2;
    if (isWaiting) {
        sprite.reset();
    } else {
        sprite.update(dt);
    }

    // Set the drawing options for the sprite.
    auto options = DrawOptions();
    options.scale = Vec2(2);
    options.hook = Hook.center;
    options.flip = (spritePosition.directionTo(mouseScreenPosition).x > 0) ? Flip.x : Flip.none;
    // Draw the sprite and the mouse position.
    drawSprite(atlas, sprite, spritePosition, options);
    drawVec2(mouseScreenPosition, 8, isWaiting ? blank : white.alpha(130));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
