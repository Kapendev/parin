/// This example shows how to use the camera structure of Popka.
import popka;

// The game variables.
auto camera = Camera(0, -14);
auto cameraTarget = Vec2(0, -14);
auto cameraSpeed = Vec2(120);

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    // Move the camera.
    cameraTarget += wasd * cameraSpeed * Vec2(dt);
    camera.followPositionWithSlowdown(cameraTarget);

    // Draw the game world.
    auto cameraArea = Rect(camera.position, resolution).area(camera.hook).subAll(3);
    camera.attach();
    drawDebugText("Move with arrow keys.");
    drawRect(cameraArea, Color(50, 50, 40, 130));
    camera.detach();

    // Draw the game UI.
    drawDebugText("I am UI!");
    drawDebugText("+", resolution * Vec2(0.5));
    drawDebugText("+", resolution * Vec2(0.5) + (cameraTarget - camera.position));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
