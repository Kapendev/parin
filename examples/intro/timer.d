/// This example shows how to use the timer structure of Parin.

import parin;

auto text = "Counter: {}\nTimer Duration: {}\nTimer (A-B): {}\nTimer (B-A): {}";
auto counter = 0;
auto timer = Timer(5, true); // Create a timer that repeats every 5 seconds.

// TODO: Try to write timer with elapsedTime and maybe also remove the need for update.

void ready() {
    lockResolution(320, 180);
    timer.start(); // Start the timer when the game starts.
}

bool update(float dt) {
    // The timer should be updated every frame, regardless of whether it is running.
    timer.update(dt);
    // Check if the timer has stopped and add 1 to the counter.
    if (timer.hasStopped) counter += 1;
    drawDebugText(text.fmt(counter, timer.duration, timer.time, timer.duration - timer.time), Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
