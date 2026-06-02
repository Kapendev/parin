/// This example shows how to use Parin with microui.
/// Parin ships microui under `parin.addons.microui`.
/// Original repository: https://github.com/Kapendev/microui-d

import parin;
import parin.addons.microui;

Game game;

struct Game {
    IStr text;
    int width = 50;
    int height = 50;

    @UiMember(0, 255) float color = 0;
    @UiMember(1)      Vec2 world = Vec2(70, 50);
    @UiMember("flag") bool reallyCoolFlag;

    @UiPrivate:
    bool secret1;
    bool secret2;
}

void ready() {
    readyUi(engineFont, 2);
}

bool update(float dt) {
    setWindowBackgroundColor(Rgba(cast(ubyte) game.color, 90, 90));
    drawRect(Rect(game.world, game.width, game.height), game.reallyCoolFlag ? green : white);

    beginUiFrame();
    if (beginWindow("Edit", 500, 80, 350, 370)) {
        headerAndMembers(game, 125);
        if (header("Text Box")) {
            label("Write Something");
            if (textBox(game.text)) println(game.text);
        }
        endWindow();
    }
    endUiFrame();
    return false;
}

mixin runGame!(ready, update, null);
