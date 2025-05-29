/// This example shows how to play sound in Parin.

import parin;

auto text = "Press SPACE to toggle playing.\nPress ESC to toggle looping.\nisPlaying: {}\ncanRepeat: {}";
auto sound = SoundId();

void ready() {
    lockResolution(320, 180);
    // Loads a sound with its default volume and pitch.
    sound = loadSound("parin_end.ogg", 1.0, 1.0);
}

bool update(float dt) {
    // Play and stop the sound.
    if (Keyboard.space.isPressed) {
        if (sound.isPlaying) stopSound(sound);
        else playSound(sound);
    }
    // Toggle sound looping.
    if (Keyboard.esc.isPressed) sound.setCanRepeat(!sound.canRepeat);
    // Draw info about the sound.
    drawDebugText(text.fmt(sound.isPlaying, sound.canRepeat), Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
