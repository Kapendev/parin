// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `ui2` module functions as a immediate mode UI library.
/// It will replace the old UI module.
module parin.ui2;

import parin.engine;
public import parin.joka.ui;

auto ui = UiContext();

@safe nothrow @nogc:

@trusted
IVec2 parinTempUiTextSizeFunc(UiFont font, const(char)[] text) {
    auto data = cast(FontId*) font;
    return measureTextSize(
        *data,
        text,
        DrawOptions(Vec2(ui.style.fontScale, ui.style.fontScale)),
        TextOptions(),
    ).toIVec();
}

/// Initializes the microui context and sets temporary text size functions. Value `font` should be a `FontId*`.
@trusted
void readyUiWithEngine(ref UiContext ui, UiFont font = null, int fontScale = 1, UiIconIdSizeFunc iconSizeFunc = null) {
    auto data = font ? cast(FontId*) font : &_engineState.defaultFont;
    ui.ready(&parinTempUiTextSizeFunc, data, fontScale, iconSizeFunc);
    if (data) {
        auto size = data.size * ui.style.fontScale;
        // No idea, these values just look good sometimes.
        // TODO: Should find a better way to do that haha.
        if (size <= 16) {
            // Nothing LOLOLOLO.
        } else if (size <= 38) {
            ui.style.border = 2;
            ui.style.padding += 4;
        } else {
            ui.style.border = 3;
            ui.style.padding += 8;
        }
    }
}

/// Initializes the microui context and sets temporary text size functions.
void readyUiWithEngine(ref UiContext ui, int fontScale, UiIconIdSizeFunc iconSizeFunc = null) {
    ui.readyUiWithEngine(null, fontScale, iconSizeFunc);
}

/// Handles input events and updates the microui context accordingly.
void handleUiInput(ref UiContext ui) {
    ui.input.mousePosition = mouse.toIVec();
    ui.input.mouseButtonDown |= Mouse.left.isDown ? UiMouseButtonFlag.left : 0;
    ui.input.mouseButtonPressed |= Mouse.left.isPressed ? UiMouseButtonFlag.left : 0;
    ui.input.mouseButtonReleased |= Mouse.left.isReleased ? UiMouseButtonFlag.left : 0;
    ui.input.mouseButtonDown |= Mouse.right.isDown ? UiMouseButtonFlag.right : 0;
    ui.input.mouseButtonPressed |= Mouse.right.isPressed ? UiMouseButtonFlag.right : 0;
    ui.input.mouseButtonReleased |= Mouse.right.isReleased ? UiMouseButtonFlag.right : 0;
    ui.input.mouseButtonDown |= Mouse.middle.isDown ? UiMouseButtonFlag.middle : 0;
    ui.input.mouseButtonPressed |= Mouse.middle.isPressed ? UiMouseButtonFlag.middle : 0;
    ui.input.mouseButtonReleased |= Mouse.middle.isReleased ? UiMouseButtonFlag.middle : 0;

    ui.input.keyDown |= Key.left.isDown ? UiKeyFlag.left : 0;
    ui.input.keyPressed |= Key.left.isPressed ? UiKeyFlag.left : 0;
    ui.input.keyReleased |= Key.left.isReleased ? UiKeyFlag.left : 0;

    ui.input.keyDown |= Key.right.isDown ? UiKeyFlag.right : 0;
    ui.input.keyPressed |= Key.right.isPressed ? UiKeyFlag.right : 0;
    ui.input.keyReleased |= Key.right.isReleased ? UiKeyFlag.right : 0;

    ui.input.keyDown |= Key.up.isDown ? UiKeyFlag.up : 0;
    ui.input.keyPressed |= Key.up.isPressed ? UiKeyFlag.up : 0;
    ui.input.keyReleased |= Key.up.isReleased ? UiKeyFlag.up : 0;

    ui.input.keyDown |= Key.down.isDown ? UiKeyFlag.down : 0;
    ui.input.keyPressed |= Key.down.isPressed ? UiKeyFlag.down : 0;
    ui.input.keyReleased |= Key.down.isReleased ? UiKeyFlag.down : 0;

    ui.input.keyDown |= Key.tab.isDown ? UiKeyFlag.tab : 0;
    ui.input.keyPressed |= Key.tab.isPressed ? UiKeyFlag.tab : 0;
    ui.input.keyReleased |= Key.tab.isReleased ? UiKeyFlag.tab : 0;

    ui.input.keyDown |= Key.enter.isDown ? UiKeyFlag.enter : 0;
    ui.input.keyPressed |= Key.enter.isPressed ? UiKeyFlag.enter : 0;
    ui.input.keyReleased |= Key.enter.isReleased ? UiKeyFlag.enter : 0;

    ui.input.keyDown |= Key.esc.isDown ? UiKeyFlag.esc : 0;
    ui.input.keyPressed |= Key.esc.isPressed ? UiKeyFlag.esc : 0;
    ui.input.keyReleased |= Key.esc.isReleased ? UiKeyFlag.esc : 0;

    ui.input.keyDown |= Key.shift.isDown ? UiKeyFlag.shift : 0;
    ui.input.keyPressed |= Key.shift.isPressed ? UiKeyFlag.shift : 0;
    ui.input.keyReleased |= Key.shift.isReleased ? UiKeyFlag.shift : 0;
}

/// Draws the microui context to the screen.
@trusted
void drawUiState(ref UiContext ui) {
    auto styleFont = cast(FontId*) ui.style.font;
    auto styleTexture = cast(TextureId*) ui.style.texture;
    auto parinOptions = DrawOptions(); // NOTE: Can be weird, but works if you are not a noob.

    foreach (ref command; ui.commands) {
        auto color = ui.style.colors[command.base.colorType];
        parinOptions.color = color;
        parinOptions.scale = Vec2(1);
        with (UiCommandType) final switch (command.type) {
            case none:
                break;
            case rect:
                drawRect(command.rect.toRect(), color);
                break;
            case text:
                parinOptions.scale = Vec2(ui.style.fontScale);
                drawText(*styleFont, command.text, command.text.area.position.toVec(), parinOptions);
                break;
            case icon:
                break; // TODO: Probably needs a function pointer??
        }
    }
}

/// Begins input handling and UI processing.
void beginUiFrame(ref UiContext ui) {
    ui.handleUiInput();
    ui.begin();
}

/// Ends UI processing and performs drawing.
void endUiFrame(ref UiContext ui) {
    ui.end();
    ui.drawUiState();
}
