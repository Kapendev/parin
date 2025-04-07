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
    FontId font;
    TileMap map;
    AppCamera camera;
    IStr mapFile;
    IStr atlasFile;
    AppMode mode;
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
//    drawTileMap(appState.atlas, appState.map, appState.camera);
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    if (Keyboard.n1.isPressed) appState.mode = cast(AppMode) !appState.mode;
    appState.camera.update(wasd, deltaWheel, dt);

    auto panelHeight = 48;
    auto windowCenter = windowSize * Vec2(0.5f);
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

    auto worldMouse = canvasMouse.toWorldPoint(appState.camera.data);
    auto gridMouse = floor(worldMouse / appState.map.tileSize).toIVec();
    auto gridMouseIndex = appState.map.softColCount * gridMouse.y + gridMouse.x;
    auto worldGridMouse = gridMouse.toVec() * appState.map.tileSize;
    auto isGridMouseInMap = appState.map.has(gridMouse);

    with (AppMode) final switch (appState.mode) {
        case edit:
            if (appState.atlas.isValid && isGridMouseInMap) {
                if (0) {
                } else if (Mouse.left.isDown) {
                    appState.map[gridMouse] = 0;
                } else if (Mouse.right.isDown) {
                    appState.map[gridMouse] = -1;
                }
            }
            break;
        case select:
            break;
    }

    appState.camera.attach();
    drawRect(Rect(appState.map.size).addAll(4), mapAreaColor);
    if (appState.camera.targetScale >= 1.0f) drawHollowRect(Rect(appState.map.size).addAll(4), 1, mapAreaOutlineColor);
    drawTileMap(appState.atlas, appState.map, appState.camera.data);
    if (appState.mode == AppMode.edit) drawHollowRect(Rect(worldGridMouse, appState.map.tileSize), 1, mouseAreaColor);
    appState.camera.detach();

    auto tempArea = Rect(windowSize);
    auto topPanelArea    = tempArea.subTop(panelHeight);
    auto canvasArea      = tempArea.subTop(tempArea.size.y - panelHeight);
    auto bottomPanelArea = tempArea.subTop(panelHeight);
    drawRect(topPanelArea, panelColor1);
    drawRect(bottomPanelArea, panelColor1);
    if (appState.camera.targetScale <= 0.5f) drawRect(Rect(windowCenter, 11, 11).centerArea, panelColor1);

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
            isGridMouseInMap ? gridMouse.x : 0,
            isGridMouseInMap ? gridMouse.y : 0,
            isGridMouseInMap ? gridMouseIndex : 0,
        ),
        tempArea.leftPoint.floor(),
        textOptions,
    );
    textOptions.hook = Hook.center;
    drawText(appState.atlasFile.length ? appState.atlasFile.pathBaseNameNoExt : "Empty", tempArea.centerPoint.floor(), textOptions);
    textOptions.hook = Hook.right;
    drawText("{}x{}".format(appState.map.tileWidth, appState.map.tileHeight), tempArea.rightPoint.floor(), textOptions);

    if (appState.mode == AppMode.select) {
        auto selectArea = canvasArea;
        selectArea.subTopBottom(panelHeight * 0.50f);
        selectArea.subLeftRight(windowWidth * 0.17f);
        auto atlasArea = selectArea;
        atlasArea.subAll(8);
        drawRect(selectArea, panelColor1);
        drawTextureArea(appState.atlas, Rect(appState.atlas.size), atlasArea.position);
    }
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish, 666, 666);
