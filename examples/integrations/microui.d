/// This example shows how to use Parin with microui.
/// Parin ships microui under `addons.microui`.
/// Original repository: https://github.com/Kapendev/microui-d

import parin;
import addons.microui;

Game game;
FontId font = engineFont;

struct Game {
    int width = 50;
    int height = 50;

    @UiMember(0, 255) float color = 0;
    @UiMember(1)      Vec2  world = Vec2(70, 50);
    @UiMember("flag") bool  reallyCoolFlag;

    @UiPrivate:
    bool secret1;
    bool secret2;
}

void ready() {
    readyUi(&font, 2);
    toggleIsDebugMode();
}

bool update(float dt) {
    setBackgroundColor(Color(cast(ubyte) game.color, 90, 90));
    drawRect(
        Rect(game.world, game.width, game.height),
        game.reallyCoolFlag ? green : white,
    );
    return false;
}

void inspect() {
    if (beginWindow("Window", UiRect(200, 80, 350, 370), UiOptFlag.noClose)) {
        headerAndMembers(game, 125);
        endWindow();
    }
}

mixin runGame!(ready, update, null, 960, 540, "Parin", inspect, beginUi, endUi);
