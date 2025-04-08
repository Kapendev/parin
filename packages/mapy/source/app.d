/// A tile map editor for Parin.

import parin;

AppState appState;

enum defaultCameraMoveSpeed = 300;
enum defaultCameraZoomSpeed = 60;
enum defaultCameraSlowdown = 0.07f;

enum panelColor1 = toRgb(0xd7d6d6);
enum panelColor2 = toRgb(0xb0afaf);
enum panelColor3 = toRgb(0x4a4b4c);
enum panelColor4 = toRgb(0x262626);

enum canvasColor = toRgb(0x484d51);
enum mapAreaColor = toRgb(0x2d2f34);
enum mapAreaOutlineColor = toRgb(0x161a1f);

enum mouseAreaColor = toRgb(0x5ca4cf);

enum AppMode {
    edit,
    select,
}

struct AppCamera {
    Camera data;
    Vec2 targetPosition;
    float targetScale = 1.0f;

    void setPosition(Vec2 value) {
        data.position = value;
        targetPosition = value;
    }

    void setScale(float value) {
        data.scale = value;
        targetScale = value;
    }

    void update(Vec2 moveDelta, float scaleDelta, float dt) {
        targetPosition += moveDelta.normalize() * Vec2(dt * defaultCameraMoveSpeed * (Keyboard.shift.isDown + 1) * (1.0f / min(targetScale, 1.0f)));
        targetScale = max(targetScale + (scaleDelta * dt * defaultCameraZoomSpeed), 0.25f);
        data.followPositionWithSlowdown(targetPosition, defaultCameraSlowdown);
        data.followScaleWithSlowdown(targetScale, defaultCameraSlowdown);
    }

    void attach() {
        data.attach();
    }

    void detach() {
        data.detach();
    }
}

struct AppState {
    TextureId atlas;
    Viewport atlasViewport;
    AppCamera atlasCamera;
    FontId font;
    TileMap map;
    AppCamera camera;
    IStr mapFile;
    IStr atlasFile;
    AppMode mode;
    short currentTileId; // TODO: Look at the old code and see how we did it there.
}

struct MouseInfo {
    Vec2 worldPoint;
    Vec2 worldGridPoint;
    IVec2 gridPoint;
    Sz gridIndex;
    bool isInGrid;

    this(Vec2 mouse, AppCamera camera, Sz rowCount, Sz colCount, Vec2 tileSize) {
        update(mouse, camera, rowCount, colCount, tileSize);
    }

    void update(Vec2 mouse, AppCamera camera, Sz rowCount, Sz colCount, Vec2 tileSize) {
        worldPoint = mouse.toWorldPoint(camera.data);
        gridPoint = floor(worldPoint / tileSize).toIVec();
        gridIndex = colCount * gridPoint.y + gridPoint.x;
        worldGridPoint = gridPoint.toVec() * tileSize;
        isInGrid = gridPoint.y < colCount && gridPoint.x < rowCount;
    }
}

void drawText(IStr text, Vec2 position, DrawOptions options = DrawOptions()) {
    auto font = appState.font.isValid ? appState.font.get() : engineFont;
    if (font == engineFont) options.scale = Vec2(2);
    parin.drawText(font, text, position, options);
}

void ready() {
    setBackgroundColor(canvasColor);
    setIsUsingAssetsPath(false);
    appState.camera.data = Camera(0, 0, true);
    appState.map = TileMap(256, 256, 0, 0);
    appState.atlasViewport = Viewport(panelColor1);
    // Parse args.
    foreach (arg; envArgs[1 .. $]) {
        if (0) {
        } else if (arg.endsWith(".ttf")) {
            appState.font = loadFont(arg, 24, 0, 24);
            appState.font.setFilter(Filter.linear);
        } else if (arg.endsWith(".png")) {
            appState.atlas = loadTexture(arg);
            if (appState.atlas.isValid) appState.atlasFile = arg;
        } else if (arg.endsWith(".csv")) {
            appState.mapFile = arg;
        } else {
            if (appState.map.tileWidth) {
                appState.map.tileHeight = cast(int) arg.toSigned().getOr(16);
            } else {
                appState.map.tileWidth = cast(int) arg.toSigned().getOr(16);
                appState.map.tileHeight = appState.map.tileWidth;
            }
        }
    }
    appState.atlasCamera.data = Camera(0, 0, true);
    if (appState.atlas.isValid) {
        appState.atlasCamera.setPosition(appState.atlas.size * Vec2(0.5f));
    }
    if (appState.map.tileWidth == 0) {
        appState.map.tileWidth = 16;
        appState.map.tileHeight = 16;
    }
    auto value = loadTempText(appState.mapFile);
    if (value.isSome) {
        appState.map.parse(value.get());
        appState.map.resizeSoft(appState.map.hardColCount, appState.map.hardRowCount);
    } else {
        appState.mapFile = "";
    }
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    if (Keyboard.n1.isPressed) {
        appState.mode = cast(AppMode) !appState.mode;
    }
    if (appState.mode == AppMode.edit) appState.camera.update(wasd, deltaWheel, dt);
    if (appState.mode == AppMode.select) appState.atlasCamera.update(wasd, deltaWheel, dt);

    auto panelHeight = 48;
    auto windowCenter = windowSize * Vec2(0.5f);
    auto atlasRowCount = appState.atlas.height / appState.map.tileHeight;
    auto atlasColCount = appState.atlas.width / appState.map.tileWidth;
    auto appMouse = mouse;
    auto canvasMouse = appMouse;
    with (AppMode) final switch (appState.mode) {
        case edit:
            if (0) {
            } else if (canvasMouse.y <= panelHeight) {
                canvasMouse.y = -100000;
            } else if (canvasMouse.y >= windowHeight - panelHeight) {
                canvasMouse.y = 100000;
            }
            break;
        case select:
            if (0) {
            } else if (canvasMouse.y <= panelHeight) {
                canvasMouse.y = -100000;
            } else if (canvasMouse.y >= windowHeight - panelHeight) {
                canvasMouse.y = 100000;
            }
            break;
    }

    auto editMouseInfo = MouseInfo(canvasMouse, appState.camera, appState.map.softRowCount, appState.map.softColCount, appState.map.tileSize);
    auto selectMouseInfo = MouseInfo(canvasMouse, appState.atlasCamera, atlasRowCount, atlasColCount, appState.map.tileSize);

    with (AppMode) final switch (appState.mode) {
        case edit:
            if (appState.atlas.isValid && editMouseInfo.isInGrid) {
                if (0) {
                } else if (Mouse.left.isDown) {
                    appState.map[editMouseInfo.gridPoint] = appState.currentTileId;
                } else if (Mouse.right.isDown) {
                    appState.map[editMouseInfo.gridPoint] = -1;
                }
            }
            break;
        case select:
            if (appState.atlas.isValid && selectMouseInfo.isInGrid) {
                if (0) {
                } else if (Mouse.left.isDown) {
                    appState.currentTileId = cast(short) selectMouseInfo.gridIndex;
                } else if (Mouse.right.isDown) {

                }
            }
            break;
    }

    appState.camera.attach();
    drawRect(Rect(appState.map.size).addAll(4), mapAreaColor);
    if (appState.camera.targetScale >= 1.0f) drawHollowRect(Rect(appState.map.size).addAll(4), 1, mapAreaOutlineColor);
    drawTileMap(appState.atlas, appState.map, appState.camera.data);
    if (appState.mode == AppMode.edit) {
        drawTextureArea(appState.atlas, Rect(
            (appState.currentTileId % atlasColCount) * appState.map.tileWidth,
            (appState.currentTileId / atlasColCount) * appState.map.tileHeight,
            appState.map.tileWidth,
            appState.map.tileHeight),
            editMouseInfo.worldGridPoint,
        );
        drawHollowRect(Rect(editMouseInfo.worldGridPoint, appState.map.tileSize), 1, mouseAreaColor);
    }
    appState.camera.detach();

    auto tempArea = Rect(windowSize);
    auto topPanelArea    = tempArea.subTop(panelHeight);
    auto canvasArea      = tempArea.subTop(tempArea.size.y - panelHeight);
    auto bottomPanelArea = tempArea.subTop(panelHeight);
    drawRect(topPanelArea, panelColor1);
    drawRect(bottomPanelArea, panelColor1);
    if (appState.camera.targetScale <= 0.5f) {
        drawRect(Rect(windowCenter, 15, 15).centerArea, panelColor1);
    }

    auto selectArea = canvasArea;
    selectArea.subTopBottom(panelHeight * 0.50f);
    selectArea.subLeftRight(windowWidth * 0.15f);
    auto atlasArea = selectArea;
    atlasArea.subAll(8);
    appState.atlasViewport.resize(cast(int) atlasArea.size.x, cast(int) atlasArea.size.y);

    auto textOptions = DrawOptions(panelColor4);
    textOptions.hook = Hook.center;

    tempArea = topPanelArea;
    tempArea.subLeftRight(16);
    tempArea.subTopBottom(8);
    drawRect(tempArea.subLeft(48 - 16), panelColor2); // Menu
    tempArea.subLeft(6);
    drawRect(tempArea.subLeft(48 - 16), panelColor3); // Pencil
    tempArea.subLeft(6);
    drawRect(tempArea.subLeft(48 - 16), panelColor2); // Eraser
    tempArea.subLeft(6);
    drawRect(tempArea.subLeft(48 - 16), panelColor2); // Set
    tempArea.subLeft(16);
    auto mapButtonArea = tempArea.subLeft(200);
    drawRect(mapButtonArea, panelColor2); // Map 1
    drawText(appState.mapFile.length ? appState.mapFile.pathBaseNameNoExt : "Empty", mapButtonArea.centerPoint.floor(), textOptions);

    tempArea = bottomPanelArea;
    tempArea.subLeftRight(16);
    tempArea.subTopBottom(8);
    textOptions.hook = Hook.left;
    drawText(
        "({},{})({})".format(
            editMouseInfo.isInGrid ? editMouseInfo.gridPoint.x : 0,
            editMouseInfo.isInGrid ? editMouseInfo.gridPoint.y : 0,
            editMouseInfo.isInGrid ? editMouseInfo.gridIndex : 0,
        ),
        tempArea.leftPoint.floor(),
        textOptions,
    );
    textOptions.hook = Hook.center;
    drawText(appState.atlasFile.length ? appState.atlasFile.pathBaseNameNoExt : "Empty", tempArea.centerPoint.floor(), textOptions);
    textOptions.hook = Hook.right;
    drawText("{}x{}".format(appState.map.tileWidth, appState.map.tileHeight), tempArea.rightPoint.floor(), textOptions);

    if (appState.mode == AppMode.select) {
        drawRect(selectArea, panelColor1);
        appState.atlasViewport.attach();
        appState.atlasCamera.attach();
        drawTexture(appState.atlas, Vec2(0));
        drawHollowRect(Rect(selectMouseInfo.worldGridPoint, appState.map.tileSize), 1, mouseAreaColor);
        appState.atlasCamera.detach();
        appState.atlasViewport.detach();
        drawViewport(appState.atlasViewport, atlasArea.position);
        if (appState.atlasCamera.targetScale <= 0.5f) {
            drawRect(Rect(windowCenter, 15, 15).centerArea, panelColor3);
        }
    }
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish, 666, 666);
