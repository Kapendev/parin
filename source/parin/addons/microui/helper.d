// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// ---

// TODO: work on attributes maybe.

/// Equivalent to `import wrapper`, with additional helper functions for Parin.
module parin.addons.microui.helper;

import parin.engine;
import parin.addons.microui.wrapper;

@trusted:

// Temporary text measurement function for prototyping.
private nothrow @nogc
int tempTextWidthFunc(UiFont font, const(char)[] str) {
    auto data = cast(FontId*) font;
    return cast(int) measureTextSize(
        *data,
        str,
        DrawOptions(Vec2(uiStyle.fontScale, uiStyle.fontScale)),
        TextOptions()
    ).x;
}
// Temporary text measurement function for prototyping.

private nothrow @nogc
int tempTextHeightFunc(UiFont font) {
    auto data = cast(FontId*) font;
    return data.size * uiStyle.fontScale;
}

/// Initializes the microui context and sets temporary text size functions. Value `font` should be a `FontId*`.
nothrow @nogc
void readyUi(UiFont font = null, int fontScale = 1) {
    auto data = font ? cast(FontId*) font : &_engineState.defaultFont;
    readyUiCore(&tempTextWidthFunc, &tempTextHeightFunc, data, fontScale);
    if (data) {
        auto size = data.size * uiStyle.fontScale;
        // No idea, these values just look good sometimes.
        // TODO: Should find a better way to do that haha.
        uiStyle.size = UiVec(size * 6, size);
        uiStyle.titleHeight = cast(int) (size * 1.5f);
        if (size <= 8) {
            uiStyle.size = UiVec(size * 6, size - 4);
            uiStyle.titleHeight = cast(int) (size * 2.0f);
        } else if (size <= 16) {
            // Nothing LOLOLOLO.
        } else if (size <= 38) {
            uiStyle.border = 2;
            uiStyle.spacing += 4;
            uiStyle.padding += 4;
            uiStyle.scrollbarSize += 4;
            uiStyle.scrollbarSpeed += 4;
            uiStyle.thumbSize += 4;
        } else {
            uiStyle.border = 3;
            uiStyle.spacing += 8;
            uiStyle.padding += 8;
            uiStyle.scrollbarSize += 8;
            uiStyle.scrollbarSpeed += 8;
            uiStyle.thumbSize += 8;
        }
    }
}

/// Initializes the microui context and sets temporary text size functions.
nothrow @nogc
void readyUi(int fontScale) {
    readyUi(null, fontScale);
}

/// Initializes the microui context and sets temporary text size functions.
nothrow @nogc
void readyUi(FontId font, int fontScale = 1) {
    static readyUiFont = FontId();
    readyUiFont = font;
    readyUi(&readyUiFont, fontScale);
}

/// Initializes the microui context and sets custom text size functions. Value `font` should be a `FontId*`.
nothrow @nogc
void readyUi(UiTextWidthFunc width, UiTextHeightFunc height, UiFont font = null, int fontScale = 1) {
    readyUi(font, fontScale);
    uiContext.textWidth = width;
    uiContext.textHeight = height;
}

/// Handles input events and updates the microui context accordingly.
nothrow @nogc
void handleUiInput() {
    with (UiMouseFlag) {
        uiInputScroll(cast(int) deltaWheel, cast(int) deltaWheel);
        uiInputMouseDown(cast(int) mouse.x, cast(int) mouse.y, Mouse.left.isPressed ? left : none);
        uiInputMouseDown(cast(int) mouse.x, cast(int) mouse.y, Mouse.middle.isPressed ? middle : none);
        uiInputMouseDown(cast(int) mouse.x, cast(int) mouse.y, Mouse.right.isPressed ? right : none);
        uiInputMouseUp(cast(int) mouse.x, cast(int) mouse.y, Mouse.left.isReleased ? left : none);
        uiInputMouseUp(cast(int) mouse.x, cast(int) mouse.y, Mouse.middle.isReleased ? middle : none);
        uiInputMouseUp(cast(int) mouse.x, cast(int) mouse.y, Mouse.right.isReleased ? right : none);
    }

    with (UiKeyFlag) {
        uiInputKeyDown(Keyboard.shift.isPressed ? shift : none);
        uiInputKeyDown(Keyboard.ctrl.isPressed ? ctrl : none);
        uiInputKeyDown(Keyboard.alt.isPressed ? alt : none);
        uiInputKeyDown(Keyboard.backspace.isPressed ? backspace : none);
        uiInputKeyDown(Keyboard.enter.isPressed ? enter : none);
        uiInputKeyDown(Keyboard.tab.isPressed ? tab : none);
        uiInputKeyDown(Keyboard.left.isPressed ? left : none);
        uiInputKeyDown(Keyboard.right.isPressed ? right : none);
        uiInputKeyDown(Keyboard.up.isPressed ? up : none);
        uiInputKeyDown(Keyboard.down.isPressed ? down : none);
        uiInputKeyDown(Keyboard.home.isPressed ? home : none);
        uiInputKeyDown(Keyboard.end.isPressed ? end : none);
        uiInputKeyDown(Keyboard.pageUp.isPressed ? pageUp : none);
        uiInputKeyDown(Keyboard.pageDown.isPressed ? pageDown : none);
        uiInputKeyDown(Keyboard.f1.isPressed ? f1 : none);
        uiInputKeyDown(Keyboard.f2.isPressed ? f2 : none);
        uiInputKeyDown(Keyboard.f3.isPressed ? f3 : none);
        uiInputKeyDown(Keyboard.f4.isPressed ? f4 : none);

        uiInputKeyUp(Keyboard.shift.isReleased ? shift : none);
        uiInputKeyUp(Keyboard.ctrl.isReleased ? ctrl : none);
        uiInputKeyUp(Keyboard.alt.isReleased ? alt : none);
        uiInputKeyUp(Keyboard.backspace.isReleased ? backspace : none);
        uiInputKeyUp(Keyboard.enter.isReleased ? enter : none);
        uiInputKeyUp(Keyboard.tab.isReleased ? tab : none);
        uiInputKeyUp(Keyboard.left.isReleased ? left : none);
        uiInputKeyUp(Keyboard.right.isReleased ? right : none);
        uiInputKeyUp(Keyboard.up.isReleased ? up : none);
        uiInputKeyUp(Keyboard.down.isReleased ? down : none);
        uiInputKeyUp(Keyboard.home.isReleased ? home : none);
        uiInputKeyUp(Keyboard.end.isReleased ? end : none);
        uiInputKeyUp(Keyboard.pageUp.isReleased ? pageUp : none);
        uiInputKeyUp(Keyboard.pageDown.isReleased ? pageDown : none);
        uiInputKeyUp(Keyboard.f1.isReleased ? f1 : none);
        uiInputKeyUp(Keyboard.f2.isReleased ? f2 : none);
        uiInputKeyUp(Keyboard.f3.isReleased ? f3 : none);
        uiInputKeyUp(Keyboard.f4.isReleased ? f4 : none);
    }

    char[128] charBuffer = void;
    size_t charBufferLength = 0;
    foreach (i, ref c; charBuffer) {
        // TODO: This does only work with ASCII lol. Change that when I add UTF8 stuff to Joka.
        c = cast(char) dequeuePressedRune();
        if (c == '\0') { charBufferLength = i; break; }
    }
    if (charBufferLength) uiInputText(charBuffer[0 .. charBufferLength]);
}

/// Draws the microui context to the screen.
void drawUi() {
    auto styleFont = cast(FontId*) uiStyle.font;
    auto styleTexture = cast(TextureId*) uiStyle.texture;
    auto parinOptions = DrawOptions(); // NOTE: Can be weird, but works if you are not a noob.
    beginClip(Rect(windowSize));
    UiCommand* cmd;
    while (nextUiCommand(&cmd)) {
        switch (cmd.type) {
            case UiCommandEnum.text:
                auto textFont = cast(FontId*) cmd.text.font;
                parinOptions.color = *(cast(Rgba*) (&cmd.text.color));
                parinOptions.scale = Vec2(uiStyle.fontScale);
                drawText(
                    *textFont,
                    cmd.text.str.ptr[0 .. cmd.text.len],
                    Vec2(cmd.text.pos.x, cmd.text.pos.y),
                    parinOptions,
                );
                parinOptions.scale = Vec2(1);
                break;
            case UiCommandEnum.rect:
                parinOptions.color = *(cast(Rgba*) (&cmd.rect.color));
                auto atlasRect = uiStyle.atlasRects[cmd.rect.id];
                if (styleTexture && atlasRect.hasSize) {
                    auto sliceMargin = uiStyle.sliceMargins[cmd.rect.id];
                    auto sliceMode = uiStyle.sliceModes[cmd.rect.id];
                    foreach (i, ref part; computeUiSliceParts(atlasRect, cmd.rect.rect, sliceMargin)) {
                        if (sliceMode && part.canTile) {
                            parinOptions.scale = Vec2(1, 1);
                            foreach (y; 0 .. part.tileCount.y) {
                                foreach (x; 0 .. part.tileCount.x) {
                                    auto sourceW = (x != part.tileCount.x - 1) ? part.source.w : max(0, part.target.w - x * part.source.w);
                                    auto sourceH = (y != part.tileCount.y - 1) ? part.source.h : max(0, part.target.h - y * part.source.h);
                                    drawTextureArea(
                                        *styleTexture,
                                        Rect(part.source.x, part.source.y, sourceW, sourceH),
                                        Vec2(part.target.x + x * part.source.w, part.target.y + y * part.source.h),
                                        parinOptions,
                                    );
                                }
                            }
                        } else {
                            parinOptions.scale = Vec2(
                                part.target.w / cast(float) part.source.w,
                                part.target.h / cast(float) part.source.h,
                            );
                            drawTextureArea(
                                *styleTexture,
                                Rect(part.source.x, part.source.y, part.source.w, part.source.h),
                                Vec2(part.target.x, part.target.y),
                                parinOptions,
                            );
                        }
                    }
                    parinOptions.scale = Vec2(1, 1);
                } else {
                    drawRect(
                        Rect(cmd.rect.rect.x, cmd.rect.rect.y, cmd.rect.rect.w, cmd.rect.rect.h),
                        parinOptions.color,
                    );
                }
                break;
            case UiCommandEnum.icon:
                parinOptions.color = *(cast(Rgba*) (&cmd.icon.color));
                auto iconAtlasRect = uiStyle.iconAtlasRects[cmd.icon.id];
                auto iconDiff = UiVec(cmd.icon.rect.w - iconAtlasRect.w, cmd.icon.rect.h - iconAtlasRect.h);
                if (styleTexture && iconAtlasRect.hasSize) {
                    drawTextureArea(
                        *styleTexture,
                        Rect(iconAtlasRect.x, iconAtlasRect.y, iconAtlasRect.w, iconAtlasRect.h),
                        Vec2(cmd.icon.rect.x + iconDiff.x / 2, cmd.icon.rect.y + iconDiff.y / 2),
                        parinOptions,
                    );
                } else {
                    parinOptions.scale = Vec2(uiStyle.fontScale, uiStyle.fontScale);
                    const(char)[] icon = "?";
                    switch (cmd.icon.id) {
                        case UiIconEnum.close: icon = "x"; break;
                        case UiIconEnum.check: icon = "*"; break;
                        case UiIconEnum.collapsed: icon = "+"; break;
                        case UiIconEnum.expanded: icon = "-"; break;
                        default: break;
                    }
                    auto iconWidth = uiContext.textWidth(styleFont, icon);
                    auto iconHeight = uiContext.textHeight(styleFont);
                    iconDiff = UiVec(cmd.icon.rect.w - iconWidth, cmd.icon.rect.h - iconHeight);
                    drawText(
                        *styleFont,
                        icon,
                        Vec2(cmd.icon.rect.x + iconDiff.x / 2, cmd.icon.rect.y + iconDiff.y / 2),
                        parinOptions,
                    );
                    parinOptions.scale = Vec2(1);
                }
                break;
            case UiCommandEnum.clip:
                endClip();
                beginClip(Rect(cmd.clip.rect.x, cmd.clip.rect.y, cmd.clip.rect.w, cmd.clip.rect.h));
                break;
            default:
                break;
        }
    }
    endClip();
}

/// Begins input handling and UI processing.
void beginUi() {
    handleUiInput();
    beginUiCore();
}

/// Ends UI processing and performs drawing.
void endUi() {
    endUiCore();
    drawUi();
}
