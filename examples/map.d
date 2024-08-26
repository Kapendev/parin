/// This example shows how to use the tile map structure of Popka.
import popka;

// The game variables.
auto atlas = Texture();
auto map = TileMap();

bool gameLoop() {
    // Passing a camera to the tile map drawing function allows for efficient rendering by only drawing the tiles that are currently in view.
    auto options = DrawOptions();
    options.scale = Vec2(2.0f);
    drawTileMap(atlas, Vec2(), map, Camera(), options);
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    setBackgroundColor(toRgb(0x0b0b0b));

    // Loads the `atlas.png` file from the assets folder and parses the tile map data.
    atlas = loadTexture("atlas.png").unwrap();
    map.parse("145,0,65\n21,22,23\n37,38,39\n53,54,55", 16, 16);

    updateWindow!gameLoop();
    atlas.free();
    map.free();
}

mixin callGameStart!(gameStart, 640, 360);
