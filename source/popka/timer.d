// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/popka
// Version: v0.0.18
// ---

// TODO: Think about it. Just testing things for now.

/// The `timer` module provides a simple timer.
module popka.timer;

import popka.engine;
public import joka;

@safe @nogc nothrow:

struct Timer {
    float time = 0.0f;
    float duration = 0.0f;
    float prevTime = 0.0f;
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
        return !isPaused && time != duration;
    }

    bool hasStarted() {
        return !isPaused && time != duration && prevTime != time && prevTime == 0.0f;
    }

    bool hasEnded() {
        return !isPaused && time == duration && prevTime != duration;
    }

    void start(float duration = -1.0f) {
        if (duration >= 0.0f) this.duration = duration;
        time = 0.0f;
        prevTime = 0.0f;
        isPaused = false;
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

    void end() {
        time = duration;
        prevTime = duration;
        isPaused = false;
    }

    void update() {
        if (isPaused) return;
        if (canRepeat && hasEnded) start();
        prevTime = time;
        time = min(time + deltaTime, duration);
    }
}
