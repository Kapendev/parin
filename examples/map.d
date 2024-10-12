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
    // Make the drawing options.
    auto mapOptions = DrawOptions(Hook.center);
    mapOptions.scale = Vec2(2);
    auto tileOptions = mapOptions;
    tileOptions.flip = tileLookDirection > 0 ? Flip.x : Flip.none;

    // Move the tile and camera.
    tile.position += wasd * Vec2(tileSpeed * dt);
    camera.position = tile.position;
    if (wasd.x != 0) tileLookDirection = cast(int) wasd.normalize.round.x;

    // Check for collisions.
    auto collisionArea = Rect();
    foreach (gridPosition; map.gridPositions(camera.topLeftPoint, camera.bottomRightPoint, mapOptions)) {
        if (map[gridPosition] == -1) continue;
        auto gridTileArea = Rect(map.worldPosition(gridPosition, mapOptions), Vec2(16) * mapOptions.scale);
        while (gridTileArea.hasIntersection(Rect(tile.position, tile.size * mapOptions.scale).area(tileOptions.hook))) {
            tile.position -= wasd * Vec2(dt);
            camera.position = tile.position;
            collisionArea = gridTileArea;
        }
    }

    // Draw the game.
    camera.attach();
    drawTileMap(atlas, map, camera, mapOptions);
    drawTile(atlas, tile, tileOptions);
    drawRect(collisionArea, yellow.alpha(120));
    camera.detach();
    drawDebugText("Move with arrow keys.", Vec2(8));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
