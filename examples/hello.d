/// This example serves as a classic hello-world program, introducing the fundamental structure of a Popka program.
import popka;

// The loop function. This is called every frame.
// If true is returned, then the game will stop.
bool gameLoop() {
    drawDebugText("Hello world!");
    return false;
}

// The start function. This is called once.
void gameStart() {
    lockResolution(320, 180);
    updateWindow!gameLoop();
}

// Creates a main function that calls the given function and creates a game window that is 640 pixels wide and 360 pixels tall.
mixin callGameStart!(gameStart, 640, 360);
