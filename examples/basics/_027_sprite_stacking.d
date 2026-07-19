/// This example demonstrates how to do sprite stacking with Parin.

import parin;

auto car = TextureId();
auto atlas = TextureId();
auto camera = Camera();
auto stacks = List!SpriteStack();
auto layerLighting = SpriteStackLighting();
auto layerCount = 32U;
auto layerScale = 2.0f;

void ready() {
    lockResolution(320, 180);
    setIsPixelSnapped(true);
    car = loadTexture("parin_car.png");     // Used for a 3D model.
    atlas = loadTexture("parin_atlas.png"); // Used for a 2D item that will be drawn in a 3D way.
}

bool update(float dt) {
    if (Key.esc.isPressed) layerLighting.isActive = !layerLighting.isActive;
    if (Key.space.isPressed || stacks.length == 0) {
        // The `SpriteStackDrawMode` controls how a sprite stack is drawn.
        // This depends on the program that was used to create the stack.
        // For example, Magica Voxel stacks follow a diffrent layout than Goxel stacks.
        // The first four numbers are: width, height, atlasTop, atlasLeft.
        // The last number is the layer count of this 3D object.
        stacks.push(SpriteStack(15, 34, 0, 0, SpriteStackDrawMode.magicaVoxelLayers, 13));
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
    // Draw 3D models in a way that gives them depth.
    foreach (layer; 0 .. layerCount) {
        auto color = layerLighting.makeColorIfIsActive(layer, layerCount);
        foreach (ref stack; stacks) {
            if (stack.layerCount > layer) drawSpriteStackLayer(car, stack, layer, color, layerScale);
        }
    }
    camera.detach();

    // Draw a 3D model as an item on the screen, without depth.
    // The `pixelRowLayers` value can be used to draw 2D items as 3D objects.
    // The layer count for objects like this is always the same as the height. 13 in this case.
    drawText("Press ESC to toggle lighting. Q or E to rotate.\nSpace to paste.", Vec2(8));
    drawSpriteStack(
        atlas,
        SpriteStack(16, 13, 192, 19, SpriteStackDrawMode.pixelRowLayers, 13, Vec2(resolutionWidth - 26, resolutionHeight - 23), elapsedTime * 80.0f),
        white,
        2,
    );
    return false;
}

mixin runGame!(ready, update, null);
