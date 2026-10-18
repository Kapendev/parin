/// This example shows how to find paths on a tile map with A*.
/// Left click to move and right click to add or remove a wall.

import parin;

auto map = TileMap();
auto astar = Astar();
auto player = IVec2(2, 5);
auto target = IVec2(2, 5);
auto wall = short(0);
auto moveTime = 0.0f;

IVec2[256] buffer;

void ready() {
    lockResolution(320, 180);
    // Create a map with 11 rows and 20 columns of 16x16 tiles, then add some walls.
    map = TileMap(11, 20, 16, 16);
    map.clear();
    foreach (row; 0 .. 8) map[row, 6] = wall;
    foreach (row; 3 .. 11) map[row, 13] = wall;
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    // Set the target or add and remove a wall.
    auto cell = map.gridPointAt(mouse);
    if (map.has(cell)) {
        if (Mouse.left.isPressed) target = cell;
        if (Mouse.right.isPressed && cell != player) map[cell] = (map[cell] == wall) ? map.emptyTileId : wall;
    }
    // Find the path and take one step along it every 0.1 seconds.
    auto path = astar.find(map, player, target, buffer);
    moveTime += dt;
    if (moveTime >= 0.1) {
        moveTime = 0;
        if (path.length) {
            player = path[0];
            path = path[1 .. $];
        }
    }
    // Draw the walls, the path, the target and the player.
    foreach (row; 0 .. map.rowCount) {
        foreach (col; 0 .. map.colCount) {
            if (map[row, col] == wall) {
                drawRect(Rect(map.worldPointAt(cast(int) col, cast(int) row), map.tileSize), gray3);
            }
        }
    }
    foreach (point; path) {
        drawRect(Rect(map.worldPointAt(point) + map.tileSize * Vec2(0.375), map.tileSize * Vec2(0.25)), yellow);
    }
    drawRect(Rect(map.worldPointAt(target), map.tileSize), pink, 1);
    drawRect(Rect(map.worldPointAt(player), map.tileSize), cyan);
    drawText("Left click to move.\nRight click to add a wall.", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
