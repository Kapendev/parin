import parin, parin.addons.microui;

Game game;

struct Game {
    int width = 50;
    int height = 50;
    IVec2 point = IVec2(70, 50);
}

void ready() {
    readyUi(engineFont, 2);
}

bool update(float dt) {
    beginUiFrame();
    scope (exit) endUiFrame();

    drawRect(Rect(game.point.x, game.point.y, game.width, game.height));
    if (beginWindow("Edit", IRect(500, 80, 350, 370))) {
        headerAndMembers(game, 125);
        endWindow();
    }
    return false;
}

mixin runGame!(ready, update, null);
