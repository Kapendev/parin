/// This example shows how to use the timer structure of Popka.
import popka;

// The game variables.
auto counter = 0;
auto timer = Timer(1, true);

void ready() {
    lockResolution(320, 180);
    // Start the timer when the game starts.
    timer.start();
}

bool update(float dt) {
    // The timer should be updated every frame, regardless of whether it is running.
    timer.update(dt);
    // Check if the timer has stopped and add 1 to the counter.
    if (timer.hasStopped) {
        counter += 1;
    }

    drawDebugText("Counter: {}".format(counter), Vec2(8));
    drawDebugText("\nTimer: {}".format(timer.time), Vec2(8));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
