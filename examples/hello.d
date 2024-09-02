/// This example serves as a classic hello-world program, introducing the fundamental structure of a Popka program.
import popka;

// The ready function. This is called once when the game starts.
void ready() {
    lockResolution(320, 180);
}

// The update function. This is called every frame while the game is running.
// If true is returned, then the game will stop running.
bool update(float dt) {
    drawDebugText("Hello world!", Vec2(8.0));
    return false;
}

// The finish function. This is called once when the game ends.
void finish() { }

// Creates a main function that calls the given functions.
mixin runGame!(ready, update, finish);
