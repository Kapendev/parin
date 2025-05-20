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

import joka.math;

@safe @nogc nothrow:

struct Timer {
    float time = 1.0f;
    float duration = 1.0f;
    float prevTime = 1.0f;
    bool isPaused;
    bool canRepeat;

    @safe @nogc nothrow:

    this(float duration, bool canRepeat = false) {
        this.time = duration;
        this.duration = duration;
        this.prevTime = duration;
        this.canRepeat = canRepeat;
    }

    bool isRunning() {
        return !isPaused && time != duration && prevTime != duration;
    }

    bool hasFirstTime() {
        return time == 0.0f;
    }

    bool hasLastTime() {
        return time == duration;
    }

    bool hasStarted() {
        return !isPaused && time != duration && prevTime != time && prevTime == 0.0f;
    }

    bool hasStopped() {
        return !isPaused && time == duration && prevTime != duration;
    }

    void start(float duration = -1.0f) {
        if (duration >= 0.0f) this.duration = duration;
        time = 0.0f;
        prevTime = 0.0f;
    }

    void stop() {
        time = duration;
        prevTime = duration - 0.1f;
    }

    void pause() {
        isPaused = true;
    }

    void resume() {
        isPaused = false;
    }

    void toggleIsPaused() {
        isPaused = !isPaused;
    }

    void update(float dt) {
        if (isPaused || (time == duration && prevTime == duration)) return;
        if (canRepeat && hasStopped) start();
        prevTime = time;
        time = min(time + dt, duration);
    }
}
