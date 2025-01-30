// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.37
// ---

// TODO: Think about gaps in an atlas texture.
// TODO: Update all the doc comments here.

/// The `map` module provides a simple and fast tile map.
module parin.map;

import joka.ascii;
import parin.engine;

@safe @nogc nothrow:

struct Tile {
    int width = 16;
    int height = 16;
    short id;
    Vec2 position;

    @safe @nogc nothrow:

    this(int width, int height, short id, Vec2 position = Vec2()) {
        this.width = width;
        this.height = height;
        this.id = id;
        this.position = position;
    }

    Vec2 size() {
        return Vec2(width, height);
    }

    Sz row(Sz colCount) {
        return id / colCount;
    }

    Sz col(Sz colCount) {
        return id % colCount;
    }

    Rect textureArea(Sz colCount) {
        return Rect(col(colCount) * width, row(colCount) * height, width, height);
    }

    /// Moves the tile to follow the target position at the specified speed.
    void followPosition(Vec2 target, float speed) {
        position = position.moveTo(target, Vec2(speed));
    }

    /// Moves the tile to follow the target position with gradual slowdown.
    void followPositionWithSlowdown(Vec2 target, float slowdown) {
        position = position.moveToWithSlowdown(target, Vec2(deltaTime), slowdown);
    }
}

struct TileMap {
    Grid!short data;
    Sz softMaxRowCount;
    Sz softMaxColCount;
    int tileWidth = 16;
    int tileHeight = 16;
    Vec2 position;

    enum maxRowCount = data.maxRowCount;
    enum maxColCount = data.maxColCount;
    enum maxCapacity = data.maxCapacity;

    @safe @nogc nothrow:

    this(int tileWidth, int tileHeight, Vec2 position = Vec2()) {
        this.tileWidth = tileWidth;
        this.tileHeight = tileHeight;
        this.softMaxRowCount = maxRowCount;
        this.softMaxColCount = maxColCount;
        this.position = position;
        this.data.fill(-1);
    }

    ref short opIndex(Sz row, Sz col) {
        if (!has(row, col)) {
            assert(0, "Tile `[{}, {}]` does not exist.".format(row, col));
        }
        return data[row, col];
    }

    ref short opIndex(IVec2 position) {
        return opIndex(position.y, position.x);
    }

    void opIndexAssign(short rhs, Sz row, Sz col) {
        if (!has(row, col)) {
            assert(0, "Tile `[{}, {}]` does not exist.".format(row, col));
        }
        data[row, col] = rhs;
    }

    void opIndexAssign(short rhs, IVec2 position) {
        return opIndexAssign(rhs, position.y, position.x);
    }

    void opIndexOpAssign(IStr op)(T rhs, Sz row, Sz col) {
        if (!has(row, col)) {
            assert(0, "Tile `[{}, {}]` does not exist.".format(row, col));
        }
        mixin("tiles[colCount * row + col]", op, "= rhs;");
    }

    void opIndexOpAssign(IStr op)(T rhs, IVec2 position) {
        return opIndexOpAssign!(op)(rhs, position.y, position.x);
    }

    Sz opDollar(Sz dim)() {
        static if (dim == 0) {
            return rowCount;
        } else static if (dim == 1) {
            return colCount;
        } else {
            assert(0, "WTF!");
        }
    }

    Sz rowCount() {
        return data.length ? softMaxRowCount : 0;
    }

    Sz colCount() {
        return data.length ? softMaxColCount : 0;
    }

    bool isEmpty() {
        return data.isEmpty;
    }

    bool has(Sz row, Sz col) {
        return row < rowCount && col < colCount;
    }

    bool has(IVec2 position) {
        return has(position.y, position.x);
    }

    @trusted
    void fill(short value) {
        data.fill(value);
    }

    @trusted
    void free() {
        data.free();
    }

    int width() {
        return cast(int) (colCount * tileWidth);
    }

    int height() {
        return cast(int) (rowCount * tileHeight);
    }

    /// Returns the size of the tile map.
    Vec2 size() {
        return Vec2(width, height);
    }

    /// Returns the tile size of the tile map.
    Vec2 tileSize() {
        return Vec2(tileWidth, tileHeight);
    }

    Fault parse(IStr csv, int tileWidth, int tileHeight) {
        if (csv.length == 0) return Fault.invalid;
        this.tileWidth = tileWidth;
        this.tileHeight = tileHeight;
        this.softMaxRowCount = 0;
        this.softMaxColCount = 0;
        this.data.fill(-1);
        auto view = csv;
        while (view.length != 0) {
            softMaxRowCount += 1;
            softMaxColCount = 0;
            if (softMaxRowCount > maxRowCount) return Fault.invalid;
            auto line = view.skipLine();
            while (line.length != 0) {
                softMaxColCount += 1;
                if (softMaxColCount > maxColCount) return Fault.invalid;
                auto tile = line.skipValue(',').toSigned();
                if (tile.isNone) return Fault.invalid;
                data[softMaxRowCount - 1, softMaxColCount - 1] = cast(short) tile.get();
            }
        }
        return Fault.none;
    }

    /// Moves the tile map to follow the target position at the specified speed.
    void followPosition(Vec2 target, float speed) {
        position = position.moveTo(target, Vec2(speed));
    }

    /// Moves the tile map to follow the target position with gradual slowdown.
    void followPositionWithSlowdown(Vec2 target, float slowdown) {
        position = position.moveToWithSlowdown(target, Vec2(deltaTime), slowdown);
    }

    /// Returns the top left world position of a grid position.
    Vec2 worldPosition(Sz row, Sz col, DrawOptions options = DrawOptions()) {
        auto targetTileWidth = cast(int) (tileWidth * options.scale.x);
        auto targetTileHeight = cast(int) (tileHeight * options.scale.y);
        auto temp = Rect(
            position.x + col * targetTileWidth,
            position.y + row * targetTileHeight,
            targetTileWidth,
            targetTileHeight,
        );
        return temp.area(options.hook).position;
    }

    /// Returns the top left world position of a grid position.
    Vec2 worldPosition(IVec2 gridPosition, DrawOptions options = DrawOptions()) {
        return worldPosition(gridPosition.y, gridPosition.x, options);
    }

    IVec2 firstGridPosition(Vec2 topLeftWorldPosition, DrawOptions options = DrawOptions()) {
        if (rowCount == 0 || colCount == 0) return IVec2();
        auto result = IVec2();
        auto targetTileWidth = cast(int) (tileWidth * options.scale.x);
        auto targetTileHeight = cast(int) (tileHeight * options.scale.y);
        result.y = cast(int) floor(clamp((topLeftWorldPosition.y - position.y) / targetTileHeight, 0, rowCount - 1));
        result.x = cast(int) floor(clamp((topLeftWorldPosition.x - position.x) / targetTileWidth, 0, colCount - 1));
        return result;
    }

    IVec2 lastGridPosition(Vec2 bottomRightWorldPosition, DrawOptions options = DrawOptions()) {
        if (rowCount == 0 || colCount == 0) return IVec2();
        auto result = IVec2();
        auto targetTileWidth = cast(int) (tileWidth * options.scale.x);
        auto targetTileHeight = cast(int) (tileHeight * options.scale.y);
        auto extraTileCount = options.hook == Hook.topLeft ? 1 : 2;
        result.y = cast(int) floor(clamp((bottomRightWorldPosition.y - position.y) / targetTileHeight + extraTileCount, 0, rowCount - 1));
        result.x = cast(int) floor(clamp((bottomRightWorldPosition.x - position.x) / targetTileWidth + extraTileCount, 0, colCount - 1));
        return result;
    }

    auto gridPositions(Vec2 topLeftWorldPosition, Vec2 bottomRightWorldPosition, DrawOptions options = DrawOptions()) {
        static struct Range {
            Sz colCount;
            IVec2 first;
            IVec2 last;
            IVec2 position;

            bool empty() {
                return position.x > last.x || position.y > last.y;
            }

            IVec2 front() {
                return position;
            }

            void popFront() {
                position.x += 1;
                if (position.x >= colCount) {
                    position.x = first.x;
                    position.y += 1;
                }
            }
        }

        auto result = Range(
            colCount,
            firstGridPosition(topLeftWorldPosition, options),
            lastGridPosition(bottomRightWorldPosition, options),
        );
        result.position = result.first;
        return result;
    }

    auto gridPositions(Rect worldArea, DrawOptions options = DrawOptions()) {
        return gridPositions(worldArea.topLeftPoint, worldArea.bottomRightPoint, options);
    }
}

Result!TileMap toTileMap(IStr csv, int tileWidth, int tileHeight) {
    auto value = TileMap();
    auto fault = value.parse(csv, tileWidth, tileHeight);
    if (fault) {
        value.free();
    }
    return Result!TileMap(value, fault);
}

Result!TileMap loadRawTileMap(IStr path, int tileWidth, int tileHeight) {
    auto temp = loadTempText(path);
    if (temp.isNone) {
        return Result!TileMap(temp.fault);
    }
    return toTileMap(temp.get(), tileWidth, tileHeight);
}

Fault saveTileMap(IStr path, TileMap map) {
    auto csv = prepareTempText();
    foreach (row; 0 .. map.rowCount) {
        foreach (col; 0 .. map.colCount) {
            csv.append(map[row, col].toStr());
            if (col != map.colCount - 1) csv.append(',');
        }
        csv.append('\n');
    }
    return saveText(path, csv.items);
}

void drawTile(Texture texture, Tile tile, DrawOptions options = DrawOptions()) {
    if (texture.isEmpty || tile.id < 0 || tile.width <= 0 || tile.height <= 0) return;
    drawTextureArea(texture, tile.textureArea(texture.width / tile.width), tile.position, options);
}

void drawTile(TextureId texture, Tile tile, DrawOptions options = DrawOptions()) {
    drawTile(texture.getOr(), tile, options);
}

void drawTileMap(Texture texture, TileMap map, Camera camera, DrawOptions options = DrawOptions()) {
    if (texture.isEmpty || map.tileWidth <= 0 || map.tileHeight <= 0) return;

    auto textureColCount = texture.width / map.tileWidth;
    auto targetTileWidth = cast(int) (map.tileWidth * options.scale.x);
    auto targetTileHeight = cast(int) (map.tileHeight * options.scale.y);
    auto colRow1 = map.firstGridPosition(camera.topLeftPoint, options);
    auto colRow2 = map.lastGridPosition(camera.bottomRightPoint, options);
    if (colRow1.x == colRow2.x || colRow1.y == colRow2.y) return;

    auto textureArea = Rect(map.tileWidth, map.tileHeight);
    foreach (row; colRow1.y .. colRow2.y + 1) {
        foreach (col; colRow1.x .. colRow2.x + 1) {
            auto id = map[row, col];
            if (id < 0) continue;
            textureArea.position.x = (id % textureColCount) * map.tileWidth;
            textureArea.position.y = (id / textureColCount) * map.tileHeight;
            drawTextureArea(
                texture,
                textureArea,
                map.position + Vec2(col * targetTileWidth, row * targetTileHeight),
                options,
            );
        }
    }
}

void drawTileMap(TextureId texture, TileMap map, Camera camera, DrawOptions options = DrawOptions()) {
    drawTileMap(texture.getOr(), map, camera, options);
}
