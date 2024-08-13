/// This example shows how to use the tile map structure of Popka.
import popka;

// The game variables.
auto atlas = Texture();
auto map = TileMap();
auto camera = Camera();
auto cameraSpeed = Vec2(120);

bool gameLoop() {
    // Move the camera and set up the drawing options of the game.
    camera.position += wasd * cameraSpeed * Vec2(deltaTime);
    auto options = DrawOptions();
    options.scale = Vec2(2);

    // Passing a camera to the tile map drawing function allows for efficient rendering by only drawing the tiles that are currently in view.
    attachCamera(camera);
    drawTileMap(atlas, Vec2(), map, camera, options);
    detachCamera(camera);
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    setBackgroundColor(toRgb(0x0b0b0b));

    // Loads the `atlas.png` texture from the assets folder.
    auto result = loadTexture("atlas.png");
    if (result.isSome) {
        atlas = result.unwrap();
    } else {
        printfln("Can not load texture. Fault: `{}`", result.fault);
    }

    // Parse the tile map data and set the tile size.
    map.parse("145,0,65\n21,22,23\n37,38,39\n53,54,55");
    map.tileWidth = 16;
    map.tileHeight = 16;

    updateWindow!gameLoop();
    atlas.free();
}

mixin addGameStart!(gameStart, 640, 360);
