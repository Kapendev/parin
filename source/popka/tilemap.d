// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/popka
// Version: v0.0.18
// ---

/// The `tilemap` module provides a simple and fast tile map.
module popka.tilemap;

import joka.ascii;
import popka.engine;
public import joka.containers;
public import joka.faults;
public import joka.math;
public import joka.types;

@safe @nogc nothrow:

struct TileMap {
    Grid!short data;
    int tileWidth;
    int tileHeight;

    alias data this;

    @safe @nogc nothrow:

    /// Returns true if the tile map has not been loaded.
    bool isEmpty() {
        return data.length == 0;
    }

    /// Returns the tile size of the tile map.
    Vec2 tileSize() {
        return Vec2(tileWidth, tileHeight);
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

    Fault parse(IStr csv, int tileWidth, int tileHeight) {
        data.clear();
        this.tileWidth = 0;
        this.tileHeight = 0;

        if (csv.length == 0) {
            return Fault.invalid;
        }

        auto view = csv;
        auto newRowCount = 0;
        auto newColCount = 0;
        while (view.length != 0) {
            auto line = view.skipLine();
            newRowCount += 1;
            newColCount = 0;
            while (line.length != 0) {
                auto value = line.skipValue(',');
                newColCount += 1;
            }
        }
        resize(newRowCount, newColCount);

        view = csv;
        foreach (row; 0 .. newRowCount) {
            auto line = view.skipLine();
            foreach (col; 0 .. newColCount) {
                auto value = line.skipValue(',').toSigned();
                if (value.isNone) {
                    data.clear();
                    this.tileWidth = 0;
                    this.tileHeight = 0;
                    return Fault.invalid;
                }
                data[row, col] = cast(short) value.unwrap();
            }
        }
        this.tileWidth = tileWidth;
        this.tileHeight = tileHeight;
        return Fault.none;
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
    return toTileMap(temp.unwrap(), tileWidth, tileHeight);
}

void drawTile(Texture texture, Vec2 position, int tileID, int tileWidth, int tileHeight, DrawOptions options = DrawOptions()) {
    auto gridWidth = cast(int) (texture.width / tileWidth);
    auto gridHeight = cast(int) (texture.height / tileHeight);
    if (gridWidth == 0 || gridHeight == 0) {
        return;
    }
    auto row = tileID / gridWidth;
    auto col = tileID % gridWidth;
    auto area = Rect(col * tileWidth, row * tileHeight, tileWidth, tileHeight);
    drawTexture(texture, position, area, options);
}

void drawTile(TextureId texture, Vec2 position, int tileID, int tileWidth, int tileHeight, DrawOptions options = DrawOptions()) {
    drawTile(texture.getOr(), position, tileID, tileWidth, tileHeight, options);
}

void drawTileMap(Texture texture, Vec2 position, TileMap map, Camera camera, DrawOptions options = DrawOptions()) {
    auto cameraArea = Rect(camera.position, resolution).area(camera.hook);
    auto topLeft = cameraArea.topLeftPoint;
    auto bottomRight = cameraArea.bottomRightPoint;
    auto targetTileWidth = cast(int) (map.tileWidth * options.scale.x);
    auto targetTileHeight = cast(int) (map.tileHeight * options.scale.y);
    auto targetTileSize = Vec2(targetTileWidth, targetTileHeight);

    auto row1 = 0;
    auto col1 = 0;
    auto row2 = 0;
    auto col2 = 0;
    if (camera.isAttached) {
        row1 = cast(int) floor(clamp((topLeft.y - position.y) / targetTileHeight, 0, map.rowCount));
        col1 = cast(int) floor(clamp((topLeft.x - position.x) / targetTileWidth, 0, map.colCount));
        row2 = cast(int) floor(clamp((bottomRight.y - position.y) / targetTileHeight + 1, 0, map.rowCount));
        col2 = cast(int) floor(clamp((bottomRight.x - position.x) / targetTileWidth + 1, 0, map.colCount));
    } else {
        row1 = cast(int) 0;
        col1 = cast(int) 0;
        row2 = cast(int) map.rowCount;
        col2 = cast(int) map.colCount;
    }

    if (row1 == row2 || col1 == col2) {
        return;
    }

    foreach (row; row1 .. row2) {
        foreach (col; col1 .. col2) {
            if (map[row, col] == -1) continue;
            drawTile(texture, position + Vec2(col, row) * targetTileSize, map[row, col], map.tileWidth, map.tileHeight, options);
        }
    }
}

void drawTileMap(TextureId texture, Vec2 position, TileMap map, Camera camera, DrawOptions options = DrawOptions()) {
    drawTileMap(texture.getOr(), position, map, camera, options);
}
