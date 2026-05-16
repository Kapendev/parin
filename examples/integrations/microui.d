/// This example shows how to use Parin with microui.
/// Parin ships microui under `parin.addons.microui`.
/// Original repository: https://github.com/Kapendev/microui-d

import parin;
import parin.addons.microui;

Game game;

struct Game {
    char[64] textBuffer = '\0';
    char[] text;

    int width = 50;
    int height = 50;

    @UiMember(0, 255) float color = 0;
    @UiMember(1) Vec2 world = Vec2(70, 50);
    @UiMember("flag") bool reallyCoolFlag;

    @UiPrivate:
    bool secret1;
    bool secret2;
}

void ready() {
    toggleIsDebugMode();
    readyUi(engineFont, 2);
}

// The game code.
bool update(float dt) {
    setWindowBackgroundColor(Color(cast(ubyte) game.color, 90, 90));
    drawRect(Rect(game.world, game.width, game.height), game.reallyCoolFlag ? green : white);
    return false;
}

// The editor code.
void inspect() {
    beginUiFrame();
    scope (exit) endUiFrame();

    if (beginWindow("Edit", IRect(500, 80, 350, 370))) {
        headerAndMembers(game, 125);
        if (header("Text Box")) {
            label("Write Something");
            if (textBox(game.textBuffer, game.text)) {
                println(game.text);
            }
        }
        endWindow();
    }
}

mixin runGame!(ready, update, null, 960, 540, "Title", inspect);
