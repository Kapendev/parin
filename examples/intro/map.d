/// This example shows how to use the tile map structure of Parin.

import parin;

auto atlas = TextureId();
auto map = TileMap();
auto camera = Camera(0, 0, true);
auto tile = Tile(16, 16, 145);
auto tileFlip = Flip.none;

void ready() {
    lockResolution(320, 180);
    atlas = loadTexture("atlas.png");
    // Parse a CSV string representing a tile map, where each tile is 16x16 pixels in size.
    map.parse("-1,-1,-1\n21,22,23\n37,38,39\n53,54,55", 16, 16);
}

bool update(float dt) {
    // Create the drawing options for the map and tile.
    auto mapOptions = DrawOptions(Vec2(2));
    auto tileOptions = mapOptions;
    tileOptions.flip = tileFlip;
    if (wasd.x > 0) tileFlip = Flip.x;
    else if (wasd.x < 0) tileFlip = Flip.none;

    // Move the tile and the camera.
    tile.position += wasd * Vec2(120 * dt);
    camera.position = tile.position + tile.size * Vec2(0.5f);
    // Check for collisions between the tile and the map and resolve the collision.
    foreach (position; map.gridPositions(camera.area, mapOptions)) {
        if (map[position] < 0) continue;
        auto area = Rect(map.worldPosition(position, mapOptions), map.tileSize * mapOptions.scale);
        while (area.hasIntersection(Rect(tile.position, tile.size * mapOptions.scale))) {
            tile.position -= wasd * Vec2(dt);
            camera.position = tile.position + tile.size * Vec2(0.5f);
        }
    }

    // Draw the tile and the map.
    camera.attach();
    drawTile(atlas, tile, tileOptions);
    drawTileMap(atlas, map, camera, mapOptions);
    camera.detach();
    drawDebugText("Move with arrow keys.", Vec2(8));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
