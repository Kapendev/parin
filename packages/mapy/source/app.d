/// A tile map editor for Parin.

// TODO: Fix the variable names and try to clean things.

import parin;

AppState appState;

enum defaultPanelHeight = 48;
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
    GridPair mainPair;
    GridPair tempPair;
}

struct GridPair {
    IVec2 a;
    IVec2 b;

    this(IVec2 a, IVec2 b) {
        this.a = a;
        this.b = b;
    }

    this(IVec2 a) {
        this(a, a);
    }

    int diffX() {
        return b.x - a.x;
    }

    int diffY() {
        return b.y - a.y;
    }

    IVec2 diff() {
        return IVec2(diffX, diffY);
    }

    void fix() {
        if (a.x > b.x) {
            auto temp = a.x;
            a.x = b.x;
            b.x = temp;
        }
        if (a.y > b.y) {
            auto temp = a.y;
            a.y = b.y;
            b.y = temp;
        }
    }
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
    if (Keyboard.n1.isPressed) appState.mode = cast(AppMode) !appState.mode;

    auto windowCenter = windowSize * Vec2(0.5f);
    auto atlasRowCount = appState.atlas.height / appState.map.tileHeight;
    auto atlasColCount = appState.atlas.width / appState.map.tileWidth;
    auto canvasMouse = mouse;
    auto editMouseInfo = MouseInfo();
    auto selectMouseInfo = MouseInfo();
    if (0) {
    } else if (canvasMouse.y <= defaultPanelHeight) {
        canvasMouse.y = -100000.0f;
    } else if (canvasMouse.y >= windowHeight - defaultPanelHeight) {
        canvasMouse.y = 100000.0f;
    }
    editMouseInfo.update(canvasMouse, appState.camera, appState.map.softRowCount, appState.map.softColCount, appState.map.tileSize);
    selectMouseInfo.update(canvasMouse, appState.atlasCamera, atlasRowCount, atlasColCount, appState.map.tileSize);
    appState.camera.update(wasd * Vec2(appState.mode == AppMode.edit), deltaWheel * (appState.mode == AppMode.edit), dt);
    appState.atlasCamera.update(wasd * Vec2(appState.mode == AppMode.select), deltaWheel * (appState.mode == AppMode.select), dt);

    with (AppMode) final switch (appState.mode) {
        case edit:
            if (!appState.atlas.isValid) break;
            if (!editMouseInfo.isInGrid) break;
            if (0) {
            } else if (Mouse.left.isDown) {
                foreach (y; appState.mainPair.a.y .. appState.mainPair.b.y + 1) {
                    foreach (x; appState.mainPair.a.x .. appState.mainPair.b.x + 1) {
                        auto targetPoint = editMouseInfo.gridPoint + IVec2(x - appState.mainPair.a.x, y - appState.mainPair.a.y);
                        if (!appState.map.has(targetPoint)) continue;
                        appState.map[targetPoint] = cast(short) jokaFindGridIndex(y, x, atlasColCount);
                    }
                }
            } else if (Mouse.right.isDown) {
                appState.map[editMouseInfo.gridPoint] = -1;
            }
            break;
        case select:
            if (!appState.atlas.isValid) break;
            if (!selectMouseInfo.isInGrid) break;
            if (0) {
            } else if (Mouse.left.isPressed) {
                appState.tempPair = GridPair(selectMouseInfo.gridPoint);
                appState.mainPair = appState.tempPair;
            } else if (Mouse.left.isDown) {
                appState.tempPair.b = selectMouseInfo.gridPoint;
                appState.mainPair = appState.tempPair;
                appState.mainPair.fix();
            }
            break;
    }

    appState.camera.attach();
    drawRect(Rect(appState.map.size).addAll(4), mapAreaColor);
    if (appState.camera.targetScale >= 1.0f) drawHollowRect(Rect(appState.map.size).addAll(4), 1, mapAreaOutlineColor);
    drawTileMap(appState.atlas, appState.map, appState.camera.data);
    if (appState.mode == AppMode.edit) {
        drawTextureArea(
            appState.atlas,
            Rect(appState.mainPair.a.toVec() * appState.map.tileSize, appState.map.tileSize),
            editMouseInfo.worldGridPoint,
        );
        drawTextureArea(appState.atlas, Rect(appState.mainPair.a.toVec() * appState.map.tileSize, (appState.mainPair.diff + IVec2(1)).toVec() * appState.map.tileSize), editMouseInfo.worldGridPoint);
        drawHollowRect(Rect(editMouseInfo.worldGridPoint, (appState.mainPair.diff + IVec2(1)).toVec() * appState.map.tileSize), 1, mouseAreaColor);
    }
    appState.camera.detach();

    auto tempArea = Rect(windowSize);
    auto topPanelArea    = tempArea.subTop(defaultPanelHeight);
    auto canvasArea      = tempArea.subTop(tempArea.size.y - defaultPanelHeight);
    auto bottomPanelArea = tempArea.subTop(defaultPanelHeight);
    drawRect(topPanelArea, panelColor1);
    drawRect(bottomPanelArea, panelColor1);
    if (appState.camera.targetScale <= 0.5f) {
        drawRect(Rect(windowCenter, 15, 15).centerArea, panelColor1);
    }

    auto textOptions = DrawOptions(panelColor4);
    textOptions.hook = Hook.center;
    auto selectArea = canvasArea;
    selectArea.subTopBottom(defaultPanelHeight * 0.50f);
    selectArea.subLeftRight(windowWidth * 0.15f);
    auto atlasArea = selectArea;
    atlasArea.subAll(8);
    appState.atlasViewport.resize(cast(int) atlasArea.size.x, cast(int) atlasArea.size.y);

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
        drawHollowRect(Rect(appState.mainPair.a.toVec() * appState.map.tileSize, (appState.mainPair.diff + IVec2(1)).toVec() * appState.map.tileSize), 1, mouseAreaColor);
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
