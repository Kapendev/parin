/// This example shows how to use the timer structure of Parin.

import parin;

auto text = "Press SPACE to toggle the timer.\nCounter: {}\nTimer Duration: {}\nTimer (A-B): {}\nTimer (B-A): {}";
auto counter = 0;
auto timer = Timer(3, true); // Create a timer that repeats every 3 seconds.

void ready() {
    lockResolution(320, 180);
    // Start the timer when the game starts.
    timer.start();
}

bool update(float dt) {
    if (Keyboard.space.isPressed) timer.toggleIsActive();
    // Check if the timer has stopped and add 1 to the counter.
    if (timer.hasStopped) counter += 1;
    drawDebugText(text.fmt(counter, timer.duration, timer.time, timer.timeLeft), Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
