// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

// TODO: Update all the doc comments here.
// NOTE: Tiles can't be scaled. Maybe a bad idea, but who cares. I do the same for 9-slices too and it works fine.

/// The `map` module provides a simple and fast tile map.
module parin.map;

import joka.ascii;
import parin.engine;

@safe nothrow:

alias TileMapLayer = Grid!short;
alias TileMapLayers = List!TileMapLayer;

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

    pragma(inline, true) {
        @trusted ref float x() => position.x;
        @trusted ref float y() => position.y;
        Sz row(Sz colCount) => (id + idOffset) / colCount;
        Sz col(Sz colCount) => (id + idOffset) % colCount;
        Vec2 size() => Vec2(width, height);
        Rect area() => Rect(position, width, height);
        Rect textureArea(Sz colCount) => Rect(col(colCount) * width, row(colCount) * height, width, height);
        bool isEmpty() => !hasId;
        bool hasId() => id + idOffset >= 0;
        bool hasSize() => width != 0 && height != 0;
        bool hasIntersection(Rect otherArea) => area.hasIntersection(otherArea);
        bool hasIntersection(Tile otherTile) => hasIntersection(otherTile.area);
        bool hasIntersectionInclusive(Rect otherArea) => area.hasIntersectionInclusive(otherArea);
        bool hasIntersectionInclusive(Tile otherTile) => hasIntersectionInclusive(otherTile.area);
        Rect intersection(Rect otherArea) => area.intersection(otherArea);
        Rect intersection(Tile otherTile) => intersection(otherTile.area);
        Rect merger(Rect otherArea) => area.merger(otherArea);
        Rect merger(Tile otherTile) => merger(otherTile.area);
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
    TileMapLayers layers;
    Sz rowCount;
    Sz colCount;
    short tileWidth;
    short tileHeight;
    Vec2 position;

    enum defaultRowColCount = 256;
    enum extraTileCount = 1;

    @safe nothrow:

    this(Sz rowCount, Sz colCount, short tileWidth, short tileHeight) {
        this.tileWidth = tileWidth;
        this.tileHeight = tileHeight;
        resizeHard(rowCount, colCount);
    }

    this(short tileWidth, short tileHeight) {
        this(defaultRowColCount, defaultRowColCount, tileWidth, tileHeight);
    }

    pragma(inline, true) @nogc {
        ref short opIndex(Sz row, Sz col, Sz layerId = 0) {
            if (!has(row, col)) assert(0, "Tile `[{}, {}]` does not exist.".fmt(row, col));
            return layers[layerId][row, col];
        }

        ref short opIndex(IVec2 position, Sz layerId = 0) {
            return opIndex(position.y, position.x, layerId);
        }

        void opIndexAssign(short rhs, Sz row, Sz col, Sz layerId = 0) {
            if (!has(row, col)) assert(0, "Tile `[{}, {}]` does not exist.".fmt(row, col));
            layers[layerId][row, col] = rhs;
        }

        void opIndexAssign(short rhs, IVec2 position, Sz layerId = 0) {
            return opIndexAssign(rhs, position.y, position.x, layerId);
        }

        void opIndexOpAssign(IStr op)(T rhs, Sz row, Sz col, Sz layerId = 0) {
            if (!has(row, col)) assert(0, "Tile `[{}, {}]` does not exist.".fmt(row, col));
            mixin("layers[layerId][colCount * row + col]", op, "= rhs;");
        }

        void opIndexOpAssign(IStr op)(T rhs, IVec2 position, Sz layerId = 0) {
            return opIndexOpAssign!(op)(rhs, position.y, position.x, layerId);
        }

        @trusted ref float x() => position.x;
        @trusted ref float y() => position.y;
        int width() => cast(int) (colCount * tileWidth);
        int height() => cast(int) (rowCount * tileHeight);
        Vec2 size() => Vec2(width, height);
        Vec2 tileSize() => Vec2(tileWidth, tileHeight);
        Sz hardRowCount() => layers[0].rowCount;
        Sz hardColCount() => layers[0].colCount;

        bool isEmpty() => layers.isEmpty;
        bool has(Sz row, Sz col) => row < rowCount && col < colCount;
        bool has(IVec2 position) => has(position.y, position.x);
        bool hasTileSize() => tileWidth != 0 && tileHeight != 0;
        bool hasSize() => hasTileSize && rowCount != 0 && colCount != 0;
        Vec2 worldPointAt(int gridX, int gridY) => Vec2(position.x + gridX * tileWidth, position.y + gridY * tileHeight);
        Vec2 worldPointAt(IVec2 gridPoint) => worldPointAt(gridPoint.x, gridPoint.y);
        IVec2 gridPointAt(float worldX, float worldY) => IVec2(cast(int) floor((worldX - position.x) / tileWidth), cast(int) floor((worldY - position.y) / tileHeight));
        IVec2 gridPointAt(Vec2 worldPoint) => gridPointAt(worldPoint.x, worldPoint.y);
    }

    @nogc
    void resizeTileSize(short newTileWidth, short newTileHeight) {
        tileWidth = newTileWidth;
        tileHeight = newTileHeight;
    }

    void resizeHard(Sz newHardRowCount, Sz newHardColCount) {
        if (isEmpty) layers.append(TileMapLayer());
        rowCount = newHardRowCount;
        colCount = newHardColCount;
        foreach (ref layer; layers) layer.resizeBlank(newHardRowCount, newHardColCount);
    }

    @nogc
    void resize(Sz newRowCount, Sz newColCount) {
        if (newRowCount > hardRowCount || newColCount > hardColCount) assert(0, "Count must be smaller than hard count.");
        rowCount = newRowCount;
        colCount = newColCount;
    }

    @nogc
    void clear() {
        foreach (ref layer; layers) layer.fill(-1);
    }

    @nogc
    void clear(Sz layerId) {
        layers[layerId].fill(-1);
    }

    void free() {
        foreach (ref layer; layers) layer.free();
        layers.free();
    }

    @nogc
    void followPosition(Vec2 target, float speed) {
        position = position.moveTo(target, Vec2(speed));
    }

    @nogc
    void followPositionWithSlowdown(Vec2 target, float slowdown) {
        position = position.moveToWithSlowdown(target, Vec2(deltaTime), slowdown);
    }

    @nogc
    auto gridPoints(Vec2 topLeftViewPoint, Vec2 bottomRightViewPoint) {
        alias T = ushort;
        static struct Range {
            T colCount;
            GVec2!T first;
            GVec2!T last;
            GVec2!T position;

            bool empty() {
                return position.x > last.x || position.y > last.y;
            }

            IVec2 front() {
                return IVec2(position.x, position.y);
            }

            void popFront() {
                position.x += 1;
                if (position.x >= colCount) {
                    position.x = first.x;
                    position.y += 1;
                }
            }
        }

        if (!hasSize) return Range();
        auto firstGridPoint = GVec2!T(
            cast(T) clamp((topLeftViewPoint.x - position.x) / tileWidth, 0, colCount - 1),
            cast(T) clamp((topLeftViewPoint.y - position.y) / tileHeight, 0, rowCount - 1),
        );
        auto lastGridPoint = GVec2!T(
            cast(T) clamp((bottomRightViewPoint.x - position.x) / tileWidth + extraTileCount, 0, colCount - 1),
            cast(T) clamp((bottomRightViewPoint.y - position.y) / tileHeight + extraTileCount, 0, rowCount - 1),
        );
        return Range(
            cast(T) colCount,
            firstGridPoint,
            lastGridPoint,
            firstGridPoint,
        );
    }

    @nogc
    auto gridPoints(Rect viewArea) {
        return gridPoints(viewArea.topLeftPoint, viewArea.bottomRightPoint);
    }

    @nogc
    auto gridPoints(Camera camera) {
        return gridPoints(camera.area);
    }

    @nogc
    auto tiles(Vec2 topLeftViewPoint, Vec2 bottomRightViewPoint, Sz layerId = 0) {
        alias T = ushort;
        static struct Range {
            T colCount;
            GVec2!T first;
            GVec2!T last;
            GVec2!T position;
            short width;
            short height;
            TileMapLayer* layer;

            bool empty() {
                return position.x > last.x || position.y > last.y;
            }

            Tile front() {
                return Tile(width, height, (*layer)[position.y, position.x], Vec2(position.x * width, position.y * height));
            }

            void popFront() {
                position.x += 1;
                if (position.x >= colCount) {
                    position.x = first.x;
                    position.y += 1;
                }
            }
        }

        if (!hasSize) return Range();
        auto firstGridPoint = GVec2!T(
            cast(T) clamp((topLeftViewPoint.x - position.x) / tileWidth, 0, colCount - 1),
            cast(T) clamp((topLeftViewPoint.y - position.y) / tileHeight, 0, rowCount - 1),
        );
        auto lastGridPoint = GVec2!T(
            cast(T) clamp((bottomRightViewPoint.x - position.x) / tileWidth + extraTileCount, 0, colCount - 1),
            cast(T) clamp((bottomRightViewPoint.y - position.y) / tileHeight + extraTileCount, 0, rowCount - 1),
        );
        return Range(
            cast(T) colCount,
            firstGridPoint,
            lastGridPoint,
            firstGridPoint,
            tileWidth,
            tileHeight,
            &layers[layerId],
        );
    }

    @nogc
    auto tiles(Rect viewArea, Sz layerId = 0) {
        return tiles(viewArea.topLeftPoint, viewArea.bottomRightPoint, layerId);
    }

    @nogc
    auto tiles(Camera camera, Sz layerId = 0) {
        return tiles(camera.area, layerId);
    }

    Fault parseCsv(IStr csv, short newTileWidth, short newTileHeight, Sz layerId = 0, bool isMinZero = false) {
        if (csv.length == 0) return Fault.cantParse;
        if (layerId >= layers.length) {
            foreach (i; 0 .. layerId - layers.length + 1) layers.append(TileMapLayer());
            resizeHard(defaultRowColCount, defaultRowColCount);
        }
        resize(0, 0);
        resizeTileSize(newTileWidth, newTileHeight);
        auto view = csv;
        while (view.length) {
            rowCount += 1;
            colCount = 0;
            if (rowCount > hardRowCount) return Fault.cantParse;
            auto line = view.skipLine();
            while (line.length) {
                colCount += 1;
                auto tile = line.skipValue(',').toSigned();
                if (tile.isNone || colCount > hardColCount) return Fault.cantParse;
                layers[layerId][rowCount - 1, colCount - 1] = cast(short) (tile.value - isMinZero);
            }
        }
        return Fault.none;
    }

    Fault parseCsv(IStr csv, Sz layerId = 0, bool isMinZero = false) {
        return parseCsv(csv, tileWidth, tileHeight, layerId, isMinZero);
    }

    // NOTE: Doesn't support inf maps.
    @trusted
    Fault parseTmx(IStr tmx) {
        auto layerId = 0;
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
                    if (isWidthWord) tileWidth = cast(short) value.value;
                    if (isHeightWord) tileHeight = cast(short) value.value;
                }
            } else if (isDataStartLine) {
                Sz csvStart, csvEnd;
                line = view.skipLine();
                csvStart = line.ptr - tmx.ptr;
                while (view.length) {
                    line = view.skipLine(); // NOTE: No trim because it's already trimmed by Tiled.
                    if (line.startsWith("</")) {
                        csvEnd = line.ptr - tmx.ptr;
                        break;
                    }
                }
                if (parseCsv(tmx[csvStart .. csvEnd], layerId, true)) return Fault.cantParse;
                layerId += 1;
            }
        }
        return Fault.none;
    }
}

@nogc {
    void drawTileX(Texture texture, Tile tile, DrawOptions options = DrawOptions()) {
        if (!tile.hasId || !tile.hasSize) return;
        drawTextureAreaX(texture, tile.textureArea(texture.width / tile.width), tile.position, options);
    }

    void drawTile(TextureId texture, Tile tile, DrawOptions options = DrawOptions()) {
        drawTileX(texture.getOr(), tile, options);
    }

    void drawTileMapX(Texture texture, TileMap map, Rect viewArea = Rect(), DrawOptions options = DrawOptions()) {
        if (!map.hasSize) return;
        if (texture.isEmpty) {
            if (isEmptyTextureVisible) {
                auto rect = Rect(map.position, map.size);
                drawRect(rect, defaultEngineEmptyTextureColor);
                drawHollowRect(rect, 1, black);
            }
            return;
        }

        auto hasAreaSize = viewArea.hasSize;
        auto topLeftPoint = viewArea.topLeftPoint;
        auto bottomRightPoint = viewArea.bottomRightPoint;
        auto textureColCount = texture.width / map.tileWidth;
        auto textureArea = Rect(map.tileWidth, map.tileHeight);
        auto colRow1 = !hasAreaSize ? IVec2() : IVec2(
            cast(int) clamp((topLeftPoint.x - map.position.x) / map.tileWidth, 0, map.colCount - 1),
            cast(int) clamp((topLeftPoint.y - map.position.y) / map.tileHeight, 0, map.rowCount - 1),
        );
        auto colRow2 = !hasAreaSize ? IVec2(cast(int) map.colCount - 1, cast(int) map.rowCount - 1) : IVec2(
            cast(int) clamp((bottomRightPoint.x - map.position.x) / map.tileWidth + map.extraTileCount, 0, map.colCount - 1),
            cast(int) clamp((bottomRightPoint.y - map.position.y) / map.tileHeight + map.extraTileCount, 0, map.rowCount - 1),
        );
        foreach (layer; map.layers) {
            foreach (row; colRow1.y .. colRow2.y + 1) {
                foreach (col; colRow1.x .. colRow2.x + 1) {
                    auto id = layer[row, col];
                    if (id < 0) continue;
                    textureArea.position.x = (id % textureColCount) * map.tileWidth;
                    textureArea.position.y = (id / textureColCount) * map.tileHeight;
                    drawTextureAreaX(
                        texture,
                        textureArea,
                        map.position + Vec2(col * map.tileWidth, row * map.tileHeight),
                        options,
                    );
                }
            }
        }
    }

    void drawTileMap(TextureId texture, TileMap map, Rect viewArea = Rect(), DrawOptions options = DrawOptions()) {
        drawTileMapX(texture.getOr(), map, viewArea, options);
    }

    void drawTileMap(TextureId texture, TileMap map, Camera camera, DrawOptions options = DrawOptions()) {
        drawTileMapX(texture.getOr(), map, camera.area, options);
    }
}
