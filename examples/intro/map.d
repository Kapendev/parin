/// This example shows how to use the tile map structure of Parin.

import parin;

auto atlas = TextureId();
auto map = TileMap();
auto camera = Camera(0, 0, true);
auto tile = Tile(16, 145);
auto tileFlip = Flip.none;

void ready() {
    lockResolution(160, 90);
    atlas = loadTexture("parin_atlas.png");
    // Parse a CSV representing a tile map, where each tile is 16x16 pixels in size.
    map.parse("-1,-1,-1\n21,22,23\n37,38,39\n53,54,55", 16, 16);
}

bool update(float dt) {
    // Move and update the game objects.
    tileFlip = wasd.x ? (wasd.x > 0 ? Flip.x : Flip.none) : tileFlip;
    tile.position += wasd * Vec2(120 * dt);
    camera.position = tile.position + tile.size * Vec2(0.5f);
    // Check for collisions with the map and resolve them.
    foreach (point; map.gridPoints(camera.area)) {
        if (map[point] < 0) continue;
        auto area = Rect(map.toWorldPoint(point), map.tileSize);
        while (area.hasIntersection(Rect(tile.position, tile.size))) {
            tile.position -= wasd * Vec2(dt);
            camera.position = tile.position + tile.size * Vec2(0.5f);
        }
    }
    // Draw the world.
    camera.attach();
    drawTileMap(atlas, map, camera);
    drawTile(atlas, tile, DrawOptions(tileFlip));
    camera.detach();
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
