/// This example shows how to use the tile map structures of Parin.

import parin;

auto atlas = TextureId();
auto map = TileMap();
auto camera = Camera(0, 0, true); // Create a centered camera at position (0, 0).
auto tile = Tile(16, 16, 145);        // Create a 16x16 tile that has the ID 145.
auto tileFlip = Flip.none;

void ready() {
    lockResolution(320, 180);
    atlas = loadTexture("parin_atlas.png");
    // Parse a CSV, where each tile is 16x16 in size.
    map.parseCsv("-1,-1,-1\n21,22,23\n37,38,39\n53,54,55\n", 16, 16);
}

bool update(float dt) {
    // Update the tile and camera.
    tileFlip = wasd.x ? (wasd.x > 0 ? Flip.x : Flip.none) : tileFlip;
    tile.position += wasd * Vec2(120 * dt);
    camera.position = tile.position + tile.size * Vec2(0.5);
    // Check for collisions with the map and resolve them.
    foreach (point; map.gridPoints(camera.area)) {
        if (map[point] < 0) continue;
        auto area = Rect(map.toWorldPoint(point), map.tileSize);
        while (area.hasIntersection(Rect(tile.position, tile.size))) {
            tile.position -= wasd * Vec2(dt);
            camera.position = tile.position + tile.size * Vec2(0.5);
        }
    }
    // Draw the world.
    camera.attach();
    drawTileMap(atlas, map, camera);
    drawTile(atlas, tile, DrawOptions(tileFlip));
    camera.detach();
    drawDebugText("Move with arrow keys.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
