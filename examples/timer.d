/// This example shows how to use the timer structure of Popka.
import popka;

// The game variables.
auto counter = 0;
auto timer = Timer(1, true);

void ready() {
    lockResolution(320, 180);
    timer.start();
}

bool update(float dt) {
    timer.update(dt);
    if (timer.hasStopped) {
        counter += 1;
    }

    drawDebugText("Counter: {}".format(counter), Vec2(8));
    drawDebugText("\nTimer: {}".format(timer.time), Vec2(8));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
