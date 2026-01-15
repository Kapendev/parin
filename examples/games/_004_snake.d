/// This example shows how to create a simple snake game with Parin.

import parin;

auto player = Circ(4);
auto playerDirection = Vec2(0, -1);
auto playerParts = List!Vec2();
auto playerNewPartTimer = Timer(0.2);

void addPart() {
    if (playerParts.length) {
        playerParts.push(playerParts[$ - 1]);
    } else {
        playerParts.push(player.position);
    }
    playerNewPartTimer.start();
}

void updateParts() {
    enum gap = 12.0;

    foreach (i, ref part; playerParts) {
        if (playerNewPartTimer.isActive && i == playerParts.length - 1) continue;
        auto targetPos = (i == 0) ? player.position : playerParts[i - 1];
        if (part.distanceTo(targetPos) > gap) {
            part = part.moveTo(targetPos, Vec2(1));
        }
    }
}

void ready() {
    lockResolution(300, 300);
    setWindowBackgroundColor(Nes8.black);
    setWindowBorderColor(Nes8.brown);
    player.position = resolution * Vec2(0.5);
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();

    if ('q'.isPressed) addPart();
    if (wasd.x < 0) {
        playerDirection = playerDirection.rotate(-0.08);
    } else if (wasd.x > 0) {
        playerDirection = playerDirection.rotate(0.08);
    }
    player.position += (playerDirection + GVec2!float(-playerDirection.y, playerDirection.x) * sin(elapsedTime * 5) * 0.25).normalize();
    updateParts();

    foreach (part; playerParts) {
        drawCirc(Circ(part, player.radius), Nes8.green);
        drawCirc(Circ(part, player.radius), Nes8.white, 1);
    }
    drawCirc(player, Nes8.green);
    drawCirc(player, Nes8.white, 2);
    return false;
}

mixin runGame!(ready, update, null);
