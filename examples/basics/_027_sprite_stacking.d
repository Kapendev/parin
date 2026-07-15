/// This example demonstrates how to do sprite stacking with Parin.

import parin;

auto atlas = TextureId();
auto camera = Camera();
auto stacks = List!SpriteStack();
auto layerLighting = SpriteStackLighting();
auto layerCount = 32U;
auto layerScale = 2.0f;

void ready() {
    lockResolution(320, 180);
    setIsPixelSnapped(true);
    atlas = loadTexture("parin_atlas.png");
}

bool update(float dt) {
    if (Key.esc.isPressed) layerLighting.isActive = !layerLighting.isActive;
    if (Key.space.isPressed || stacks.length == 0) {
        stacks.push(SpriteStack(16, 32, 0, 128, SpriteStackDrawMode.pixelRowLayers, 32));
    }

    if (!wasdPressed.isZero) camera.target = camera.target.getOr() + wasdPressed * resolution;
    camera.followTargetWithSlowdown(dt, 0.1f);

    foreach (i, ref stack; stacks) {
        if (i == stacks.length - 1) {
            stack.position = mouse.toScenePoint(camera);
            if ('q'.isDown) stack.rotation -= 4.0f;
            if ('e'.isDown) stack.rotation += 4.0f;
        }
    }

    camera.attach();
    foreach (layer; 0 .. layerCount) {
        auto color = layerLighting.makeColorIfIsActive(layer, layerCount);
        foreach (ref stack; stacks) {
            if (stack.layerCount > layer) drawSpriteStackLayer(atlas, stack, layer, color, layerScale);
        }
    }
    camera.detach();

    drawText("Press ESC to toggle lighting. Q or R to rotate.", Vec2(8));
    drawSpriteStack(
        atlas,
        SpriteStack(16, 13, 192, 19, SpriteStackDrawMode.pixelRowLayers, 13, Vec2(resolutionWidth - 26, resolutionHeight - 23), elapsedTime * 80.0f),
        white,
        2,
    );
    return false;
}

mixin runGame!(ready, update, null);
