/// This example shows how to use Parin with microui.
/// Repository: https://github.com/Kapendev/microui-d

import parin;
import mupr; // Equivalent to `import microuid`, with additional helper functions for Parin.

Game game;

struct Game {
    FontId font = engineFont;
    bool secretBool;

    @UiMember          int   size = 32;
    @UiMember(0, 640)  float worldX = 52;
    @UiMember(0, 320)  float worldY = 52;
    @UiMember("Debug") bool  debugMode;
}

void ready() {
    readyUi(&game.font, 2);
}

bool update(float dt) {
    beginUi();
    if (beginWindow("Game", UiRect(160, 80, 400, 300))) {
        headerAndMembers(game, 200);
        endWindow();
    }
    endUi();
    drawRect(
        Rect(game.worldX, game.worldY, game.size, game.size),
        game.debugMode ? green : white,
    );
    return false;
}

mixin runGame!(ready, update, null);
