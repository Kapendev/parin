import parin;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    drawText("Hello world!\nYep.\nHAHAHAHAHHAHA...", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
