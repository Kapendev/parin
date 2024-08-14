// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/popka
// Version: v0.0.16
// ---

/// The `tilemap` module provides a simple and fast tile map.
module popka.tilemap;

import popka.engine;
public import joka;

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

    /// Returns the size of the tile map.
    Vec2 size() {
        return tileSize * Vec2(colCount, rowCount);
    }

    Fault parse(IStr csv) {
        data.clear();
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
                    return Fault.invalid;
                }
                data[row, col] = cast(short) value.unwrap();
            }
        }
        return Fault.none;
    }
}

Result!TileMap toTileMap(IStr csv) {
    auto value = TileMap();
    auto fault = value.parse(csv);
    if (fault) {
        value.free();
    }
    return Result!TileMap(value, fault);
}

Result!TileMap loadTileMap(IStr path) {
    auto temp = loadTempText(path);
    if (temp.isNone) {
        return Result!TileMap(temp.fault);
    }
    return toTileMap(temp.unwrap());
}

void drawTile(Texture texture, Vec2 position, int tileID, Vec2 tileSize, DrawOptions options = DrawOptions()) {
    auto gridWidth = cast(int) (texture.size.x / tileSize.x);
    auto gridHeight = cast(int) (texture.size.y / tileSize.y);
    if (gridWidth == 0 || gridHeight == 0) {
        return;
    }
    auto row = tileID / gridWidth;
    auto col = tileID % gridWidth;
    auto area = Rect(col * tileSize.x, row * tileSize.y, tileSize.x, tileSize.y);
    drawTexture(texture, position, area, options);
}

void drawTileMap(Texture texture, Vec2 position, TileMap tileMap, Camera camera, DrawOptions options = DrawOptions()) {
    enum extraTileCount = 1;

    auto cameraArea = Rect(camera.position, resolution).area(camera.hook);
    auto topLeft = cameraArea.point(Hook.topLeft);
    auto bottomRight = cameraArea.point(Hook.bottomRight);
    auto col1 = 0;
    auto col2 = 0;
    auto row1 = 0;
    auto row2 = 0;

    if (camera.isAttached) {
        col1 = cast(int) floor(clamp((topLeft.x - position.x) / tileMap.tileSize.x - extraTileCount, 0, tileMap.colCount));
        col2 = cast(int) floor(clamp((bottomRight.x - position.x) / tileMap.tileSize.x + extraTileCount, 0, tileMap.colCount));
        row1 = cast(int) floor(clamp((topLeft.y - position.y) / tileMap.tileSize.y - extraTileCount, 0, tileMap.rowCount));
        row2 = cast(int) floor(clamp((bottomRight.y - position.y) / tileMap.tileSize.y + extraTileCount, 0, tileMap.rowCount));
    } else {
        col1 = 0;
        col2 = cast(int) tileMap.colCount;
        row1 = 0;
        row2 = cast(int) tileMap.rowCount;
    }
    foreach (row; row1 .. row2) {
        foreach (col; col1 .. col2) {
            if (tileMap[row, col] == -1) {
                continue;
            }
            drawTile(texture, position + Vec2(col, row) * tileMap.tileSize * options.scale, tileMap[row, col], tileMap.tileSize, options);
        }
    }
}
