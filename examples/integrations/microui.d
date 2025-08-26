/// This example shows how to use Parin with microui.
/// Repository: https://github.com/Kapendev/microui-d

import parin;
import mupr; // Equivalent to `import microuid`, with additional helper functions for Parin.

Game game;

struct Game {
    FontId font = engineFont;
    bool secretBool;

    @UiMember          int   size = 45;
    @UiMember(0, 255)  float color = 0;
    @UiMember(1)       Vec2  world = Vec2(70, 50);
    @UiMember("debug") bool  debugMode;
}

void ready() {
    readyUi(&game.font, 2);
}

bool update(float dt) {
    beginUi();
    if (beginWindow("Window", UiRect(200, 80, 350, 300))) {
        headerAndMembers(game, 125); // You can also shift+click to edit a member.
        endWindow();
    }
    endUi();

    setBackgroundColor(Color(cast(ubyte) game.color, 90, 90));
    drawRect(
        Rect(game.world.x, game.world.y, game.size, game.size),
        game.debugMode ? green : white,
    );
    return false;
}

mixin runGame!(ready, update, null);
