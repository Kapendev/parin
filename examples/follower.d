/// This example shows how to create an animated character that follows the mouse.
import popka;

// The game variables.
auto atlas = TextureId();
auto frame = 0.0;
auto frameCount = 2;
auto frameSpeed = 8;
auto framePosition = Vec2();
auto frameSize = Vec2(16);
auto frameDirection = 1;
auto frameSlowdown = 0.2;

void ready() {
    lockResolution(320, 180);
    setBackgroundColor(toRgb(0x0b0b0b));
    togglePixelPerfect();
    hideCursor();
    // Load the `atlas.png` file from the assets folder.
    atlas = loadTexture("atlas.png").unwrap();
}

bool update(float dt) {
    // Move the frame around in a smooth way and update the current frame.
    framePosition = framePosition.moveToWithSlowdown(mouseScreenPosition, Vec2(dt), frameSlowdown);
    frame = wrap(frame + dt * frameSpeed, 0, frameCount);

    // Check the mouse move direction and make the sprite look at that direction.
    auto mouseDirection = framePosition.directionTo(mouseScreenPosition);
    if (framePosition.distanceTo(mouseScreenPosition) < 0.2) {
        frame = 0;
    } else if (mouseDirection.x < 0) {
        frameDirection = -1;
    } else if (mouseDirection.x > 0) {
        frameDirection = 1;
    }

    // The drawing options can change the way something is drawn.
    auto options = DrawOptions();
    options.hook = Hook.center;
    options.scale = Vec2(2);
    options.flip = frameDirection == 1 ? Flip.x : Flip.none;

    // Draw the frame and the mouse position.
    drawTexture(atlas, framePosition, Rect(frameSize.x * floor(frame), 128, frameSize), options);
    drawVec2(mouseScreenPosition, 8, frame == 0 ? blank : white.alpha(150));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
