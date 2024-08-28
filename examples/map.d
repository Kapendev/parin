/// This example shows how to use the tile map structure of Popka.
import popka;

// The game variables.
auto atlas = TextureId();
auto map = TileMap();

void ready() {
    lockResolution(320, 180);
    setBackgroundColor(toRgb(0x0b0b0b));
    // Load the `atlas.png` file from the assets folder.
    atlas = loadTexture("atlas.png").unwrap();
    // Parse the map CSV file.
    map.parse("145,0,65\n21,22,23\n37,38,39\n53,54,55", 16, 16);
}

bool update(float dt) {
    auto options = DrawOptions();
    options.scale = Vec2(2.0f);
    drawTileMap(atlas, Vec2(), map, Camera(), options);
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
