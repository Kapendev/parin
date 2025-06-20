// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.48
// ---

// TODO: Update all the doc comments here.
// TODO: Try to make some stuff simpler maybe.
// NOTE: Maybe the map could return `Tile` as info for something.

/// The `map` module provides a simple and fast tile map.
module parin.map;

import joka.ascii;
import parin.engine;

@safe nothrow:

struct Tile {
    short width;
    short height;
    short id;
    ubyte idOffset;
    Vec2 position;

    @safe nothrow @nogc:

    this(short width, short height, short id, Vec2 position = Vec2()) {
        this.width = width;
        this.height = height;
        this.id = id;
        this.position = position;
    }

    this(short width, short height, short id, float x, float y) {
        this(width, height, id, Vec2(x, y));
    }

    deprecated("Will be replaced with width and height.")
    int widthHeight() => width;

    /// The X position of the tile.
    pragma(inline, true) @trusted
    ref float x() => position.x;

    /// The Y position of the tile.
    pragma(inline, true) @trusted
    ref float y() => position.y;

    /// The size of the tile.
    pragma(inline, true)
    Vec2 size() => Vec2(width, height);

    pragma(inline, true)
    Sz row(Sz colCount) => (id + idOffset) / colCount;

    pragma(inline, true)
    Sz col(Sz colCount) => (id + idOffset) % colCount;

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

// NOTE: Things like changing the grid row count might be interesting.
struct TileMap {
    Grid!short data;
    Sz softRowCount;
    Sz softColCount;
    int tileWidth;
    int tileHeight;
    Vec2 position;

    @safe nothrow:

    this(Sz rowCount, Sz colCount, int tileWidth, int tileHeight) {
        this.tileWidth = tileWidth;
        this.tileHeight = tileHeight;
        resizeHard(rowCount, colCount);
    }

    this(int tileWidth, int tileHeight) {
        this(128, 128, tileWidth, tileHeight);
    }

    @nogc
    ref short opIndex(Sz row, Sz col) {
        if (!has(row, col)) assert(0, "Tile `[{}, {}]` does not exist.".fmt(row, col));
        return data[row, col];
    }

    @nogc
    ref short opIndex(IVec2 position) {
        return opIndex(position.y, position.x);
    }

    @nogc
    void opIndexAssign(short rhs, Sz row, Sz col) {
        if (!has(row, col)) assert(0, "Tile `[{}, {}]` does not exist.".fmt(row, col));
        data[row, col] = rhs;
    }

    @nogc
    void opIndexAssign(short rhs, IVec2 position) {
        return opIndexAssign(rhs, position.y, position.x);
    }

    @nogc
    void opIndexOpAssign(IStr op)(T rhs, Sz row, Sz col) {
        if (!has(row, col)) assert(0, "Tile `[{}, {}]` does not exist.".fmt(row, col));
        mixin("data[colCount * row + col]", op, "= rhs;");
    }

    @nogc
    void opIndexOpAssign(IStr op)(T rhs, IVec2 position) {
        return opIndexOpAssign!(op)(rhs, position.y, position.x);
    }

    @nogc
    Sz opDollar(Sz dim)() {
        return data.opDollar!dim();
    }

    /// The X position of the map.
    pragma(inline, true) @trusted @nogc
    ref float x() => position.x;

    /// The Y position of the map.
    pragma(inline, true) @trusted @nogc
    ref float y() => position.y;

    @nogc
    Sz length() {
        return data.length;
    }

    @nogc
    short* ptr() {
        return data.ptr;
    }

    @nogc
    Sz capacity() {
        return data.capacity;
    }

    @nogc
    bool isEmpty() {
        return data.isEmpty;
    }

    @nogc
    bool has(Sz row, Sz col) {
        return row < softRowCount && col < softColCount;
    }

    @nogc
    bool has(IVec2 position) {
        return has(position.y, position.x);
    }

    @nogc
    Sz hardRowCount() {
        return data.rowCount;
    }

    @nogc
    Sz hardColCount() {
        return data.colCount;
    }

    void resizeHard(Sz newHardRowCount, Sz newHardColCount) {
        data.resizeBlank(newHardRowCount, newHardColCount);
        data.fill(-1);
        softRowCount = newHardRowCount;
        softColCount = newHardColCount;
    }

    deprecated("Will be replaced with resize.")
    alias resizeSoft = resize;

    void resize(Sz newSoftRowCount, Sz newSoftColCount) {
        if (newSoftRowCount > hardRowCount || newSoftColCount > hardColCount) {
            assert(0, "Soft count must be smaller than hard count.");
        }
        softRowCount = newSoftRowCount;
        softColCount = newSoftColCount;
    }

    @nogc
    void fillHard(short value) {
        data.fill(value);
    }

    deprecated("Will be replaced with fill.")
    alias fillSoft = fill;

    @nogc
    void fill(short value) {
        foreach (row; 0 .. softRowCount) {
            foreach (col; 0 .. softColCount) {
                data[row, col] = value;
            }
        }
    }

    @nogc
    void clearHard() {
        fillHard(-1);
    }

    deprecated("Will be replaced with clear.")
    alias clearSoft = clear;

    @nogc
    void clear() {
        fill(-1);
    }

    void free() {
        data.free();
    }

    @nogc
    int width() {
        return cast(int) (softColCount * tileWidth);
    }

    @nogc
    int height() {
        return cast(int) (softRowCount * tileHeight);
    }

    /// Returns the size of the tile map.
    @nogc
    Vec2 size() {
        return Vec2(width, height);
    }

    /// Returns the tile size of the tile map.
    @nogc
    Vec2 tileSize() {
        return Vec2(tileWidth, tileHeight);
    }

    /// Moves the tile map to follow the target position at the specified speed.
    @nogc
    void followPosition(Vec2 target, float speed) {
        position = position.moveTo(target, Vec2(speed));
    }

    /// Moves the tile map to follow the target position with gradual slowdown.
    @nogc
    void followPositionWithSlowdown(Vec2 target, float slowdown) {
        position = position.moveToWithSlowdown(target, Vec2(deltaTime), slowdown);
    }

    /// Returns the top left world position of a grid position.
    @nogc
    Vec2 toWorldPoint(Sz row, Sz col, DrawOptions options = DrawOptions()) {
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
    @nogc
    Vec2 toWorldPoint(IVec2 gridPosition, DrawOptions options = DrawOptions()) {
        return toWorldPoint(gridPosition.y, gridPosition.x, options);
    }

    @nogc
    auto gridPoints(Vec2 topLeftWorldPoint, Vec2 bottomRightWorldPoint, DrawOptions options = DrawOptions()) {
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

        if (softRowCount == 0 || softColCount == 0) return Range();
        auto targetTileWidth = cast(int) (tileWidth * options.scale.x);
        auto targetTileHeight = cast(int) (tileHeight * options.scale.y);
        auto extraTileCount = options.hook == Hook.topLeft ? 1 : 2;
        auto firstGridPoint = IVec2(
            cast(int) clamp((topLeftWorldPoint.x - position.x) / targetTileWidth, 0, softColCount - 1),
            cast(int) clamp((topLeftWorldPoint.y - position.y) / targetTileHeight, 0, softRowCount - 1),
        );
        auto lastGridPoint = IVec2(
            cast(int) clamp((bottomRightWorldPoint.x - position.x) / targetTileWidth + extraTileCount, 0, softColCount - 1),
            cast(int) clamp((bottomRightWorldPoint.y - position.y) / targetTileHeight + extraTileCount, 0, softRowCount - 1),
        );
        return Range(
            softColCount,
            firstGridPoint,
            lastGridPoint,
            firstGridPoint,
        );
    }

    @nogc
    auto gridPoints(Rect worldArea, DrawOptions options = DrawOptions()) {
        return gridPoints(worldArea.topLeftPoint, worldArea.bottomRightPoint, options);
    }

    Fault parse(IStr csv, int newTileWidth, int newTileHeight) {
        resize(0, 0);
        if (csv.length == 0) return Fault.invalid;
        if (data.isEmpty) data.resizeBlank(128, 128);
        tileWidth = newTileWidth;
        tileHeight = newTileHeight;
        while (csv.length != 0) {
            softRowCount += 1;
            softColCount = 0;
            if (softRowCount > data.rowCount) return Fault.invalid;
            auto line = csv.skipLine();
            while (line.length != 0) {
                softColCount += 1;
                if (softColCount > data.colCount) return Fault.invalid;
                auto tile = line.skipValue(',').toSigned();
                if (tile.isNone) {
                    resize(0, 0);
                    return Fault.invalid;
                }
                data[softRowCount - 1, softColCount - 1] = cast(short) tile.value;
            }
        }
        return Fault.none;
    }

    Fault parse(IStr csv) {
        return parse(csv, tileWidth, tileHeight);
    }
}

Fault saveTileMap(IStr path, TileMap map) {
    auto csv = prepareTempText();
    foreach (row; 0 .. map.softRowCount) {
        foreach (col; 0 .. map.softColCount) {
            csv.append(map[row, col].toStr());
            if (col != map.softColCount - 1) csv.append(',');
        }
        csv.append('\n');
    }
    return saveText(path, csv.items);
}

@nogc
void drawTileX(Texture texture, Tile tile, DrawOptions options = DrawOptions()) {
    if (tile.id < 0 || tile.width <= 0 || tile.height <= 0) return;
    if (texture.isEmpty) {
        if (isEmptyTextureVisible) {
            auto rect = Rect(tile.position, tile.size * options.scale).area(options.hook);
            drawRect(rect, defaultEngineEmptyTextureColor);
            drawHollowRect(rect, 1, black);
        }
        return;
    }
    drawTextureAreaX(texture, tile.textureArea(texture.width / tile.width), tile.position, options);
}

@nogc
void drawTile(TextureId texture, Tile tile, DrawOptions options = DrawOptions()) {
    drawTileX(texture.getOr(), tile, options);
}

@nogc
void drawTileMapX(Texture texture, TileMap map, Camera camera = Camera(), DrawOptions options = DrawOptions()) {
    if (map.softRowCount == 0 || map.softColCount == 0 || map.tileWidth <= 0 || map.tileHeight <= 0) return;
    if (texture.isEmpty) {
        if (isEmptyTextureVisible) {
            auto rect = Rect(map.position, map.size * options.scale).area(options.hook);
            drawRect(rect, defaultEngineEmptyTextureColor);
            drawHollowRect(rect, 1, black);
        }
        return;
    }

    auto topLeftWorldPoint = camera.topLeftPoint;
    auto bottomRightWorldPoint = camera.bottomRightPoint;
    auto textureColCount = texture.width / map.tileWidth;
    auto targetTileWidth = cast(int) (map.tileWidth * options.scale.x);
    auto targetTileHeight = cast(int) (map.tileHeight * options.scale.y);
    auto extraTileCount = options.hook == Hook.topLeft ? 1 : 2;
    auto colRow1 = IVec2(
        cast(int) clamp((topLeftWorldPoint.x - map.position.x) / targetTileWidth, 0, map.softColCount - 1),
        cast(int) clamp((topLeftWorldPoint.y - map.position.y) / targetTileHeight, 0, map.softRowCount - 1),
    );
    auto colRow2 = IVec2(
        cast(int) clamp((bottomRightWorldPoint.x - map.position.x) / targetTileWidth + extraTileCount, 0, map.softColCount - 1),
        cast(int) clamp((bottomRightWorldPoint.y - map.position.y) / targetTileHeight + extraTileCount, 0, map.softRowCount - 1),
    );
    auto textureArea = Rect(map.tileWidth, map.tileHeight);
    foreach (row; colRow1.y .. colRow2.y + 1) {
        foreach (col; colRow1.x .. colRow2.x + 1) {
            auto id = map[row, col];
            if (id < 0) continue;
            textureArea.position.x = (id % textureColCount) * map.tileWidth;
            textureArea.position.y = (id / textureColCount) * map.tileHeight;
            drawTextureAreaX(
                texture,
                textureArea,
                map.position + Vec2(col * targetTileWidth, row * targetTileHeight),
                options,
            );
        }
    }
}

@nogc
void drawTileMap(TextureId texture, TileMap map, Camera camera = Camera(), DrawOptions options = DrawOptions()) {
    drawTileMapX(texture.getOr(), map, camera, options);
}
