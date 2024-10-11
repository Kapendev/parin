// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.23
// ---

// TODO: Think about gaps in an atlas texture.
// TODO: Add simple collision check in the tile map example.
// TODO: Think about the tile struct a bit.
// TODO: Update all the doc comments here.

/// The `tilemap` module provides a simple and fast tile map.
module parin.tilemap;

import joka.ascii;
import parin.engine;
public import joka.containers;
public import joka.faults;
public import joka.math;
public import joka.types;

@safe:

struct Tile {
    Sz id;
    int width;
    int height;
    Vec2 position;

    @safe:

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
    Sz estimatedMaxRowCount;
    Sz estimatedMaxColCount;
    int tileWidth;
    int tileHeight;
    Vec2 position;
    alias data this;

    @safe:

    this(short value, int tileWidth, int tileHeight) {
        this.tileWidth = tileWidth;
        this.tileHeight = tileHeight;
        this.estimatedMaxRowCount = data.maxRowCount;
        this.estimatedMaxColCount = data.maxColCount;
        this.data.fill(value);
    }

    /// Returns true if the tile map has not been loaded.
    bool isEmpty() {
        return data.length == 0;
    }

    int width() {
        return cast(int) (estimatedMaxColCount * tileWidth);
    }

    int height() {
        return cast(int) (estimatedMaxRowCount * tileHeight);
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
        this.estimatedMaxRowCount = 0;
        this.estimatedMaxColCount = 0;
        this.data.fill(-1);
        auto view = csv;
        while (view.length != 0) {
            estimatedMaxRowCount += 1;
            estimatedMaxColCount = 0;
            if (estimatedMaxRowCount > maxRowCount) return Fault.invalid;
            auto line = view.skipLine();
            while (line.length != 0) {
                estimatedMaxColCount += 1;
                if (estimatedMaxColCount > maxColCount) return Fault.invalid;
                auto tile = line.skipValue(',').toSigned();
                if (tile.isNone) return Fault.invalid;
                data[estimatedMaxRowCount - 1, estimatedMaxColCount - 1] = cast(short) tile.get();
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
}

Vec2 findTilePosition(TileMap map, Vec2 position, Sz row, Sz col, DrawOptions options = DrawOptions()) {
    return Vec2(position.x + col * map.tileWidth * options.scale.x, position.y + row * map.tileHeight * options.scale.y);
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

void drawTile(Texture texture, Tile tile, DrawOptions options = DrawOptions()) {
    drawTextureArea(texture, tile.textureArea(texture.width / tile.width), tile.position, options);
}

void drawTile(TextureId texture, Tile tile, DrawOptions options = DrawOptions()) {
    drawTile(texture.getOr(), tile, options);
}

void drawTileMap(Texture texture, TileMap map, Camera camera, DrawOptions options = DrawOptions()) {
    auto area = camera.area;
    auto topLeft = area.topLeftPoint;
    auto bottomRight = area.bottomRightPoint;

    auto targetTileWidth = cast(int) (map.tileWidth * options.scale.x);
    auto targetTileHeight = cast(int) (map.tileHeight * options.scale.y);

    auto row1 = cast(int) floor(clamp((topLeft.y - map.position.y) / targetTileHeight, 0, map.rowCount));
    auto col1 = cast(int) floor(clamp((topLeft.x - map.position.x) / targetTileWidth, 0, map.colCount));
    auto row2 = cast(int) floor(clamp((bottomRight.y - map.position.y) / targetTileHeight + 2, 0, map.rowCount));
    auto col2 = cast(int) floor(clamp((bottomRight.x - map.position.x) / targetTileWidth + 2, 0, map.colCount));
    if (row1 == row2 || col1 == col2) return;

    foreach (row; row1 .. row2) {
        foreach (col; col1 .. col2) {
            if (map[row, col] == -1) continue;
            auto tile = Tile(map[row, col], map.tileWidth, map.tileHeight);
            tile.position = map.position + Vec2(col * targetTileWidth, row * targetTileHeight);
            drawTile(texture, tile, options);
        }
    }
}

void drawTileMap(TextureId texture, TileMap map, Camera camera, DrawOptions options = DrawOptions()) {
    drawTileMap(texture.getOr(), map, camera, options);
}
