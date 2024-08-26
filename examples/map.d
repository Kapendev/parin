/// This example shows how to use the tile map structure of Popka.
import popka;

// The game variables.
auto atlas = Texture();
auto map = TileMap();

void ready() {
    lockResolution(320, 180);
    setBackgroundColor(toRgb(0x0b0b0b));
    atlas = loadTexture("atlas.png").unwrap();
    map.parse("145,0,65\n21,22,23\n37,38,39\n53,54,55", 16, 16);
}

bool update() {
    auto options = DrawOptions();
    options.scale = Vec2(2.0f);
    drawTileMap(atlas, Vec2(), map, Camera(), options);
    return false;
}

void finish() {
    atlas.free();
    map.free();
}

mixin runGame!(ready, update, finish);
