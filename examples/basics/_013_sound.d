/// This example shows how to play sound in Parin.

import parin;

auto text = "Press SPACE to toggle the active state.\nPress ESC to toggle the pause state.\nisActive: {}\nisPaused: {}";
auto sound = SoundId();

void ready() {
    lockResolution(320, 180);
    // Loads a loopable sound with its default volume and pitch.
    sound = loadSound("parin_end.ogg", 1.0, 1.0, true);
}

bool update(float dt) {
    if (Keyboard.space.isPressed) toggleSoundIsActive(sound);
    if (Keyboard.esc.isPressed) toggleSoundIsPaused(sound);
    // Draw info about the sound.
    drawDebugText(text.fmt(sound.isActive, sound.isPaused), Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
