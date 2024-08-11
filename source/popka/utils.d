// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// io stuff TODO.
module popka.utils;

import ray = popka.ray;

public import joka;
public import popka.types;

@safe @nogc nothrow:

IStr toAssetsPath(IStr path) {
    return pathConcat(engineState.assetsPath.items, path).pathFormat();
}

/// Loads a text file from the assets folder and returns its contents as a list.
/// Can handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.
Result!LStr loadText(IStr path) {
    return readText(path.toAssetsPath());
}

/// Loads a text file from the assets folder and returns its contents as a slice.
/// The slice can be safely used until this function is called again.
/// Can handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.
Result!IStr loadTempText(IStr path) {
    auto fault = readTextIntoBuffer(path.toAssetsPath(), engineState.tempText);
    return Result!IStr(engineState.tempText.items, fault);
}

Result!TileMap loadTileMap(IStr path) {
    auto value = TileMap();
    auto fault = value.parse(loadTempText(path).unwrapOr());
    if (fault) {
        value.free();
    }
    return Result!TileMap(value, fault);
}

/// Loads an image file from the assets folder.
/// Can handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.
@trusted
Result!Texture loadTexture(IStr path) {
    auto value = ray.LoadTexture(path.toAssetsPath().toCStr().unwrapOr()).toPopka();
    return Result!Texture(value, value.isEmpty.toFault());
}

@trusted
Result!Viewport loadViewport(int width, int height) {
    auto value = ray.LoadRenderTexture(width, height).toPopka();
    return Result!Viewport(value, value.isEmpty.toFault());
}

@trusted
Result!Font loadFont(IStr path, uint size, const(dchar)[] runes = []) {
    auto value = ray.LoadFontEx(path.toAssetsPath.toCStr().unwrapOr(), size, cast(int*) runes.ptr, cast(int) runes.length).toPopka();
    return Result!Font(value, value.isEmpty.toFault());
}

/// Saves a text file to the assets folder.
/// Can handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.
Fault saveText(IStr path, IStr text) {
    return writeText(path.toAssetsPath(), text);
}
