import popka;

// The game variables.
auto atlas = Texture();
auto frame = 0.0;
auto frameCount = 2;
auto frameSpeed = 8;
auto framePosition = Vec2();
auto frameSize = Vec2(16);
auto frameDirection = 1;
auto frameSlowdown = 0.2;

bool gameLoop() {
    // Move the frame around in a smooth way and update the current frame.
    framePosition = framePosition.moveToWithSlowdown(mouseScreenPosition, Vec2(deltaTime), frameSlowdown);
    frame = wrap(frame + deltaTime * frameSpeed, 0, frameCount);

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
    options.flip = frameDirection == 1 ? Flip.x : Flip.none;
    options.scale = Vec2(2);

    // Draw the frame and the mouse position.
    drawTexture(atlas, framePosition, Rect(frameSize.x * floor(frame), 128, frameSize), options);
    drawVec2(mouseScreenPosition, 8, frame == 0 ? blank : white.alpha(150));
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    setBackgroundColor(toRgb(0x0b0b0b));
    togglePixelPerfect();
    hideCursor();

    // Loads the `atlas.png` texture from the assets folder.
    auto result = loadTexture("atlas.png");
    if (result.isSome) {
        atlas = result.unwrap();
    } else {
        printfln("Can not load texture. Fault: `{}`", result.fault);
    }

    updateWindow!gameLoop();
    atlas.free();
}

mixin addGameStart!(gameStart, 640, 360);
