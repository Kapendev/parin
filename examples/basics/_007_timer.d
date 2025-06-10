/// This example shows how to use the timer structure of Parin.

import parin;

auto text = "Press SPACE to toggle the active state.\nPress ESC to toggle the pause state.\nCounter: {}\nTimer Duration: {}\nTimer (A-B): {}\nTimer (B-A): {}";
auto counter = 0;
auto timer = Timer(4, true); // Create a timer that repeats every 4 seconds.

void ready() {
    lockResolution(320, 180);
    // Start the timer when the game starts.
    timer.start();
}

bool update(float dt) {
    if (Keyboard.space.isPressed) timer.toggleIsActive();
    if (Keyboard.esc.isPressed) timer.toggleIsPaused();
    // Check if the timer has stopped and add 1 to the counter.
    if (timer.hasStopped) counter += 1;
    drawDebugText(text.fmt(counter, timer.duration, timer.time, timer.timeLeft), Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
