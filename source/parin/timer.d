// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `timer` module provides a simple timer.
module parin.timer;

import parin.engine;

@safe nothrow @nogc:

/// A timer with pause/resume and repeat support.
struct Timer {
    float duration = 1.0f;                  /// The duration of the timer, in seconds.
    float pauseTime = 0.0f;                 /// The elapsed time when the timer was paused.
    float startTime = 0.0f;                 /// The elapsed time when the timer was started.
    float stopTimeElapsedTimeBuffer = 0.0f; /// Buffer storing the elapsed time after stopping.
    bool canRepeat;                         /// Whether the timer restarts automatically after completion.

    @safe nothrow @nogc:

    /// Initializes the timer with the specified duration and repeat behavior.
    this(float duration, bool canRepeat = false) {
        this.duration = duration;
        this.canRepeat = canRepeat;
    }

    /// Returns true if the timer is currently paused.
    bool isPaused() {
        time(); // We need to update the state before checking.
        return pauseTime != 0.0f;
    }

    /// Returns true if the timer is currently active (running).
    bool isActive() {
        time(); // We need to update the state before checking.
        return startTime != 0.0f;
    }

    /// Returns true if the timer has just started.
    bool hasStarted() {
        time(); // We need to update the state before checking.
        return startTime.fequals(elapsedTime);
    }

    /// Returns true if the timer has just stopped.
    bool hasStopped() {
        time(); // We need to update the state before checking.
        return stopTimeElapsedTimeBuffer.fequals(elapsedTime);
    }

    /// Starts the timer with an optional new duration.
    void start(float newDuration = -1.0f) {
        if (newDuration >= 0.0f) duration = newDuration;
        startTime = elapsedTime;
        stopTimeElapsedTimeBuffer = 0.0f;
        pauseTime = 0.0f;
    }

    /// Stops the timer and records the time at which it stopped.
    void stop() {
        startTime = 0.0f;
        stopTimeElapsedTimeBuffer = elapsedTime;
        pauseTime = 0.0f;
    }

    /// Toggles the active state of the timer.
    void toggleIsActive() {
        if (isActive) stop();
        else start();
    }

    /// Pauses the time.
    void pause() {
        if (!isActive) return;
        pauseTime = time;
    }

    /// Resumes the timer from the paused state.
    void resume() {
        if (!isActive || pauseTime == 0.0f) return;
        startTime = elapsedTime - pauseTime;
        pauseTime = 0.0f;
    }

    /// Toggles the paused state of the timer.
    void toggleIsPaused() {
        if (isPaused) resume();
        else pause();
    }

    /// Returns the current time of the timer and handles stop/repeat logic.
    float time() {
        if (startTime == 0.0f) return 0.0f;
        if (pauseTime != 0.0f) return pauseTime;
        auto result = max(elapsedTime - startTime, 0.0f);
        if (result >= duration) {
            stop();
            if (canRepeat) startTime = elapsedTime;
        }
        result = min(result, duration);
        return result;
    }

    /// Returns the remaining time of the timer and handles stop/repeat logic.
    float timeLeft() {
        return duration - time;
    }

    /// Returns the remaining time, or zero if inactive.
    float timeLeftOrZero() {
        return isActive ? timeLeft : 0.0f;
    }

    /// Sets the current time of the timer.
    /// If the given value is non-zero, the timer becomes active.
    void setTime(float newTime) {
        startTime = max(elapsedTime - newTime, 0.0f);
        if (isPaused) {
            pauseTime = 0.0f;
            pauseTime = time;
        }
    }

    /// Returns the current progress (between 0.0 to 1.0).
    float progress() {
        return duration  == 0.0f ? 0.0f : time / duration;
    }

    /// Returns the remaining progress (between 0.0 to 1.0).
    float progressLeft() {
        return 1.0f - progress;
    }

    /// Returns the remaining progress (between 0.0 to 1.0), or zero if inactive.
    float progressLeftOrZero() {
        return isActive ? progressLeft : 0.0f;
    }

    /// Sets the progress to a specific value (between 0.0 to 1.0).
    void setProgress(float value) {
        setTime(duration * clamp(value, 0.0f, 1.0f));
    }

    /// Sets the remaining progress to a specific value (between 0.0 to 1.0).
    void setProgressLeft(float value) {
        setProgress(1.0f - value);
    }
}
