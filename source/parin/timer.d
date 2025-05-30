// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.44
// ---

// TODO: Update all the doc comments here.

/// The `timer` module provides a simple and extensible timer.
module parin.timer;

import parin.engine;

@safe @nogc nothrow:

struct Timer {
    float duration = 1.0f;
    float pausedTime = 0.0f;
    float startTime = 0.0f;
    float startTimeElapsedTimeBuffer = 0.0f;
    bool canRepeat;

    @safe @nogc nothrow:

    this(float duration, bool canRepeat = false) {
        this.duration = duration;
        this.canRepeat = canRepeat;
    }

    bool isPaused() {
        time(); // We need to update the state before checking.
        return pausedTime != 0.0f;
    }

    bool isActive() {
        time(); // We need to update the state before checking.
        return startTime != 0.0f;
    }

    bool hasStarted() {
        time(); // We need to update the state before checking.
        return startTime.fequals(elapsedTime);
    }

    bool hasStopped() {
        time(); // We need to update the state before checking.
        return startTimeElapsedTimeBuffer.fequals(elapsedTime);
    }

    void start(float duration = -1.0f) {
        if (duration >= 0.0f) this.duration = duration;
        startTime = elapsedTime;
        startTimeElapsedTimeBuffer = 0.0f;
    }

    void stop() {
        startTime = 0.0f;
        startTimeElapsedTimeBuffer = elapsedTime;
    }

    void toggleIsActive() {
        if (isActive) stop();
        else start();
    }

    void pause() {
        pausedTime = time;
    }

    void resume() {
        startTime = elapsedTime - pausedTime;
        pausedTime = 0.0f;
    }

    void toggleIsPaused() {
        if (isPaused) resume();
        else pause();
    }

    float time() {
        if (startTime == 0.0f) return 0.0f;
        if (pausedTime != 0.0f) return pausedTime;
        auto result = max(elapsedTime - startTime, 0.0f);
        if (result >= duration) {
            stop();
            if (canRepeat) startTime = elapsedTime;
        }
        result = min(result, duration);
        return result;
    }

    float timeLeft() {
        return duration - time;
    }

    deprecated("Will be replaced with isActive.")
    alias isRunning = isActive;
    deprecated("Will be removed because it does nothing now.")
    void update(float dt) {};
    deprecated("Will be removed because it's not really possible to set the timer now. Passing `0.0f` will stop the timer.")
    void time(float newTime) { if (newTime == 0.0f) stop(); }
}
