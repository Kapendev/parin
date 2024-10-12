/// This example shows how to use the tile map structure of Parin.
import parin;

// The game variables.
auto atlas = TextureId();
auto map = TileMap();
auto camera = Camera(0, 0, true);
auto tile = Tile(145, 16, 16);
auto tileSpeed = 120;
auto tileLookDirection = -1;

void ready() {
    lockResolution(320, 180);
    setBackgroundColor(toRgb(0x0b0b0b));
    // Load the `atlas.png` file from the assets folder.
    atlas = loadTexture("atlas.png");
    // Parse the tile map CSV file.
    map.parse("-1,-1,-1\n21,22,23\n37,38,39\n53,54,55", 16, 16);
}

bool update(float dt) {
    // Make some options.
    auto mapOptions = DrawOptions(Hook.center);
    mapOptions.scale = Vec2(2);
    auto tileOptions = mapOptions;
    tileOptions.flip = tileLookDirection > 0 ? Flip.x : Flip.none;

    // Move tile and camera.
    tile.position += wasd * Vec2(tileSpeed * dt);
    camera.followPosition(tile.position, tileSpeed);
    if (wasd.x != 0) tileLookDirection = cast(int) wasd.normalize.round.x;
    // Check for collisions.
    auto colRow1 = map.firstMapPosition(camera.area.topLeftPoint, mapOptions);
    auto colRow2 = map.lastMapPosition(camera.area.bottomRightPoint, mapOptions);
    foreach (row; colRow1.y .. colRow2.y) {
        foreach (col; colRow1.x .. colRow2.x) {
            if (map[row, col] == -1) continue;
            // TODO: Yeah, maybe change it to something better...
            auto mapTileRect = Rect(map.worldPosition(row, col, mapOptions), Vec2(16) * mapOptions.scale);
            auto myTileRect = Rect(tile.position, tile.size * mapOptions.scale).area(Hook.center);
            if (mapTileRect.hasIntersection(myTileRect)) {
                tile.position -= wasd * Vec2(tileSpeed * dt);
                camera.followPosition(tile.position, tileSpeed);
                break;
            }
        }
    }

    // Draw game.
    camera.attach();
    drawTileMap(atlas, map, camera, mapOptions);
    drawTile(atlas, tile, tileOptions);
    camera.detach();
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
