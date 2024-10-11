/// This example shows how to use the tile map structure of Parin.
import parin;

// The game variables.
auto atlas = TextureId();
auto map = TileMap();
auto playerTile = Tile(145, 16, 16);
auto playerPosition = Vec2();
auto playerSpeed = Vec2(120);

void ready() {
    lockResolution(320, 180);
    setBackgroundColor(toRgb(0x0b0b0b));
    // Load the `atlas.png` file from the assets folder.
    atlas = loadTexture("atlas.png");
    // Parse the tile map CSV file.
    map.parse("-1,-1,-1\n21,22,23\n37,38,39\n53,54,55", 16, 16);
}

bool update(float dt) {
    playerPosition += wasd * playerSpeed * Vec2(dt);
    // Draw the tile map.
    auto options = DrawOptions(Vec2(2));
    drawTileMap(atlas, map, Vec2(), Camera(), options);
    drawTile(atlas, playerTile, playerPosition, options);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
