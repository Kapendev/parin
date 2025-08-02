// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
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
    byte idOffset;
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
    Sz rowCount;
    Sz colCount;
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
        return row < rowCount && col < colCount;
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
        rowCount = newHardRowCount;
        colCount = newHardColCount;
    }

    deprecated("Will be replaced with resize.")
    alias resizeSoft = resize;

    @nogc
    void resize(Sz newRowCount, Sz newColCount) {
        if (newRowCount > hardRowCount || newColCount > hardColCount) {
            assert(0, "Soft count must be smaller than hard count.");
        }
        rowCount = newRowCount;
        colCount = newColCount;
    }

    void resizeTileSize(int newTileWidth, int newTileHeight) {
        tileWidth = newTileWidth;
        tileHeight = newTileHeight;
    }

    @nogc
    void fillHard(short value) {
        data.fill(value);
    }

    deprecated("Will be replaced with fill.")
    alias fillSoft = fill;

    @nogc
    void fill(short value) {
        foreach (row; 0 .. rowCount) {
            foreach (col; 0 .. colCount) {
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
        return cast(int) (colCount * tileWidth);
    }

    @nogc
    int height() {
        return cast(int) (rowCount * tileHeight);
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

        if (rowCount == 0 || colCount == 0) return Range();
        auto targetTileWidth = cast(int) (tileWidth * options.scale.x);
        auto targetTileHeight = cast(int) (tileHeight * options.scale.y);
        auto extraTileCount = options.hook == Hook.topLeft ? 1 : 2;
        auto firstGridPoint = IVec2(
            cast(int) clamp((topLeftWorldPoint.x - position.x) / targetTileWidth, 0, colCount - 1),
            cast(int) clamp((topLeftWorldPoint.y - position.y) / targetTileHeight, 0, rowCount - 1),
        );
        auto lastGridPoint = IVec2(
            cast(int) clamp((bottomRightWorldPoint.x - position.x) / targetTileWidth + extraTileCount, 0, colCount - 1),
            cast(int) clamp((bottomRightWorldPoint.y - position.y) / targetTileHeight + extraTileCount, 0, rowCount - 1),
        );
        return Range(
            colCount,
            firstGridPoint,
            lastGridPoint,
            firstGridPoint,
        );
    }

    @nogc
    auto gridPoints(Rect worldArea, DrawOptions options = DrawOptions()) {
        return gridPoints(worldArea.topLeftPoint, worldArea.bottomRightPoint, options);
    }

    deprecated("Will be replaced with `parseCsv`.")
    alias parse = parseCsv;

    Fault parseCsv(IStr csv, int newTileWidth, int newTileHeight, bool zeroMode = false) {
        if (csv.length == 0) return Fault.cantParse;
        if (data.isEmpty) data.resizeBlank(128, 128);
        resize(0, 0);
        resizeTileSize(newTileWidth, newTileHeight);
        auto view = csv;
        while (view.length) {
            rowCount += 1;
            colCount = 0;
            if (rowCount > data.rowCount) return Fault.cantParse;
            auto line = view.skipLine();
            while (line.length) {
                colCount += 1;
                auto tile = line.skipValue(',').toSigned();
                if (tile.isNone || colCount > data.colCount) return Fault.cantParse;
                data[rowCount - 1, colCount - 1] = cast(short) (tile.value - zeroMode);
            }
        }
        return Fault.none;
    }

    Fault parseCsv(IStr csv, bool zeroMode = false) {
        return parseCsv(csv, tileWidth, tileHeight, zeroMode);
    }

    // TODO: NEEDS A COMMENT ABOUT ONLY PARSING THE FIRST DATA PART.
    @trusted
    Fault parseTmx(IStr tmx) {
        Sz csvStart, csvEnd;
        auto view = tmx;
        while (view.length) {
            auto line = view.skipLine().trim();
            auto isMapLine = line.startsWith("<map");
            auto isDataStartLine = isMapLine ? false : line.startsWith("<data");
            if (isMapLine) {
                while (line.length && (tileWidth == 0 || tileHeight == 0)) {
                    auto word = line.skipValue(" ").trim();
                    auto isWidthWord = word.startsWith("tilewidth");
                    auto isHeightWord = word.startsWith("tileheight");
                    if (!isWidthWord && !isHeightWord) continue;
                    auto value = word.split("=")[1][1 .. $ - 1].toSigned(); // NOTE: Removes `"` with `[1 .. $ - 1]`.
                    if (value.isNone) return Fault.cantParse;
                    if (isWidthWord) tileWidth = cast(int) value.value;
                    if (isHeightWord) tileHeight = cast(int) value.value;
                }
            } else if (isDataStartLine) {
                line = view.skipLine();
                csvStart = line.ptr - tmx.ptr; // NOTE: I think there should be a way to have better access to the index. Maybe a range? I kinda hate that idea.
                while (view.length) {
                    line = view.skipLine(); // NOTE: No trim because it's already trimmed.
                    if (line.startsWith("</")) {
                        csvEnd = line.ptr - tmx.ptr;
                        break;
                    }
                }
                return parseCsv(tmx[csvStart .. csvEnd], true);
            }
        }
        return Fault.none;
    }
}

// TODO: MAYBE I SHOULD ALSO KINDA TELL THAT THIS IS A CSV THINGY!!!
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

// TODO: CLEAN CLEAN CLEAN BROOOOO TOOO COMPLEX OR SOMETHING
@nogc
void drawTileMapX(Texture texture, TileMap map, Camera camera = Camera(), DrawOptions options = DrawOptions()) {
    if (map.rowCount == 0 || map.colCount == 0 || map.tileWidth <= 0 || map.tileHeight <= 0) return;
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
    auto colRow1 = !camera.isAttached ? IVec2() : IVec2(
        cast(int) clamp((topLeftWorldPoint.x - map.position.x) / targetTileWidth, 0, map.colCount - 1),
        cast(int) clamp((topLeftWorldPoint.y - map.position.y) / targetTileHeight, 0, map.rowCount - 1),
    );
    auto colRow2 = !camera.isAttached ? IVec2(cast(int) map.colCount - 1, cast(int) map.rowCount - 1) : IVec2(
        cast(int) clamp((bottomRightWorldPoint.x - map.position.x) / targetTileWidth + extraTileCount, 0, map.colCount - 1),
        cast(int) clamp((bottomRightWorldPoint.y - map.position.y) / targetTileHeight + extraTileCount, 0, map.rowCount - 1),
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
