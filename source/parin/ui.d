// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.44
// ---

/// The `ui` module functions as a immediate mode UI library.
module parin.ui;

import rl = parin.rl;
import joka.ascii;
import joka.memory;
import parin.engine;

@safe @nogc nothrow:

UiState* uiState;
UiState* uiPreviousState;

enum defaultUiDisabledColor = 0x202020.toRgb();
enum defaultUiIdleColor = 0x414141.toRgb();
enum defaultUiHotColor = 0x818181.toRgb();
enum defaultUiActiveColor = 0xBABABA.toRgb();
enum defaultUiFontAlphaOffset = 50;
enum defaultUiTextFieldCursorDisabledAlpha = 175;
enum defaultUiTextFieldCursorOffset = 2;

/// A type representing the constraints on drag movement.
enum UiDragLimit: ubyte {
    none,         /// No limits.
    viewport,     /// Limited to the viewport.
    viewportAndX, /// Limited to the viewport and on the X-axis.
    viewportAndY, /// Limited to the viewport and on the Y-axis.
    custom,       /// Limited to custom limits.
    customAndX,   /// Limited to custom limits and on the X-axis.
    customAndY,   /// Limited to custom limits and on the Y-axis.
}

struct UiOptions {
    FontId font = engineFont;
    Rgba fontColor = white;
    ubyte fontScale = 1;
    ubyte fontAlphaOffset = defaultUiFontAlphaOffset;

    Rgba disabledColor = defaultUiDisabledColor;
    Rgba idleColor = defaultUiIdleColor;
    Rgba hotColor = defaultUiHotColor;
    Rgba activeColor = defaultUiActiveColor;

    Alignment alignment = Alignment.center;
    short alignmentOffset = 0;
    UiDragLimit dragLimit = UiDragLimit.viewport;
    Vec2 dragLimitX = Vec2(-100000.0f, 100000.0f);
    Vec2 dragLimitY = Vec2(-100000.0f, 100000.0f);
    bool isDisabled = false;

    @safe @nogc nothrow:

    this(ubyte fontScale) {
        this.fontScale = fontScale;
    }

    this(Alignment alignment, short alignmentOffset = 0) {
        this.alignment = alignment;
        this.alignmentOffset = alignmentOffset;
    }

    this(UiDragLimit dragLimit) {
        this.dragLimit = dragLimit;
    }
}

struct UiState {
    Mouse mouseClickAction = Mouse.left;
    Keyboard keyboardClickAction = Keyboard.enter;
    Gamepad gamepadClickAction = Gamepad.a;
    bool isActOnPress;

    Vec2 viewportPosition;
    Vec2 viewportSize;
    Vec2 viewportScale = Vec2(1.0f);

    Vec2 mouseBuffer;
    Vec2 mousePressedPosition;
    Vec2 itemDragOffset;
    short itemId;
    short hotItemId;
    short activeItemId;
    short clickedItemId;
    short draggedItemId;
    short focusedItemId;
    short previousMaxHotItemId;
    short previousMaxHotItemIdBuffer;
}

bool isSpaceInTextField(char c) {
    return c == ' ' || c == '_' || c == '.';
}

int findSpaceInTextField(IStr text) {
    auto result = text.findEnd(' ');
    auto temp = -1;
    temp = text.findEnd('_');
    if (temp > result) result = temp;
    temp = text.findEnd('.');
    if (temp > result) result = temp;
    return result;
}

@trusted
void prepareUi() {
    if (uiState == null) {
        // NOTE: This leaks. THIS IS SO BAD WHERE IS `Box::leak` IN THIS CODEBASE???
        uiState = jokaMake!UiState();
        uiPreviousState = jokaMake!UiState();
    }
    setUiViewportState(Vec2(), resolution, Vec2(1.0f));
    uiState.itemId = 0;
    uiState.hotItemId = 0;
    uiState.activeItemId = 0;
    uiState.clickedItemId = 0;
    uiState.previousMaxHotItemId = uiState.previousMaxHotItemIdBuffer;
}

Vec2 uiMouse() {
    return uiState.mouseBuffer;
}

void setUiClickAction(Mouse value) {
    uiState.mouseClickAction = value;
}

void setUiClickAction(Keyboard value) {
    uiState.keyboardClickAction = value;
}

void setUiClickAction(Gamepad value) {
    uiState.gamepadClickAction = value;
}

bool isUiActOnPress() {
    return uiState.isActOnPress;
}

void setIsUiActOnPress(bool value) {
    uiState.isActOnPress = value;
}

void setUiViewportState(Vec2 position, Vec2 size, Vec2 scale) {
    uiState.viewportPosition = position;
    uiState.viewportSize = size;
    uiState.viewportScale = scale;
    if (uiState.mouseClickAction.isPressed) {
        uiState.mousePressedPosition = uiMouse;
    }
    uiState.mouseBuffer = (mouse - position) / scale;
    if (uiState.mouseBuffer.x < 0) uiState.mouseBuffer.x = -100000.0f;
    else if (uiState.mouseBuffer.x > size.x) uiState.mouseBuffer.x = 100000.0f;
    if (uiState.mouseBuffer.y < 0) uiState.mouseBuffer.y = -100000.0f;
    else if (uiState.mouseBuffer.y > size.y) uiState.mouseBuffer.y = 100000.0f;
}

short uiItemId() {
    return uiState.itemId;
}

bool isUiItemHot() {
    return uiState.itemId == uiState.hotItemId;
}

bool isUiHot() {
    return uiState.hotItemId > 0;
}

bool isUiItemActive() {
    return uiState.itemId == uiState.activeItemId;
}

bool isUiActive() {
    return uiState.activeItemId > 0;
}

bool isUiItemClicked() {
    return uiState.itemId == uiState.clickedItemId;
}

bool isUiClicked() {
    return uiState.clickedItemId > 0;
}

bool isUiItemDragged() {
    return uiState.itemId == uiState.draggedItemId && !deltaMouse.isZero;
}

bool isUiDragged() {
    return uiState.draggedItemId > 0 && !deltaMouse.isZero;
}

Vec2 uiDragOffset() {
    return uiState.itemDragOffset;
}

bool isUiItemFocused() {
    return uiState.itemId == uiState.focusedItemId;
}

bool isUiFocused() {
    return uiState.focusedItemId > 0;
}

short uiFocus() {
    return uiState.focusedItemId;
}

void setUiFocus(short id) {
    uiState.focusedItemId = id;
}

void clampUiFocus(short step, Sz length) {
    auto min = cast(short) (uiState.itemId + 1);
    auto max = cast(short) (length - 1 + min);
    auto isOutside = uiState.focusedItemId < min || uiState.focusedItemId > max;
    if (step == 0) {
        uiState.focusedItemId = min;
        return;
    }
    if (isOutside) {
        if (step < 0) {
            uiState.focusedItemId = max;
            return;
        } else {
            uiState.focusedItemId = min;
            return;
        }
    }
    uiState.focusedItemId = clamp(cast(short) (uiState.focusedItemId + step), min, max);
}

void wrapUiFocus(short step, Sz length) {
    auto min = cast(short) (uiState.itemId + 1);
    auto max = cast(short) (length - 1 + min);
    auto isOutside = uiState.focusedItemId < min || uiState.focusedItemId > max;
    if (step == 0) {
        uiState.focusedItemId = min;
        return;
    }
    if (isOutside) {
        if (step < 0) {
            uiState.focusedItemId = max;
            return;
        } else {
            uiState.focusedItemId = min;
            return;
        }
    }
    uiState.focusedItemId = wrap(cast(short) (uiState.focusedItemId + step), min, cast(short) (max + 1));
}

void updateUiState(Rect area, bool isHot, bool isActive, bool isClicked) {
    *uiPreviousState = *uiState;
    uiState.itemId += 1;
    if (isHot) {
        uiState.hotItemId = uiState.itemId;
    }
    if (isActive) {
        uiState.activeItemId = uiState.itemId;
        uiState.focusedItemId = uiState.itemId;
    }
    if (isClicked) uiState.clickedItemId = uiState.itemId;
    if (uiState.mouseClickAction.isPressed && uiState.itemId == uiState.activeItemId) {
        auto m = uiMouse;
        uiState.itemDragOffset = area.position - m;
        uiState.draggedItemId = uiState.itemId;
    }
    if (uiState.draggedItemId) {
        if (uiState.mouseClickAction.isReleased) uiState.draggedItemId = 0;
    }
}

void updateUiText(Rect area, IStr text, UiOptions options = UiOptions()) {
    updateUiState(area, false, false, false);
}

// TODO SOME ALIGNEMENT SHIT WITH SCALING>>>>
void drawUiText(Rect area, IStr text, UiOptions options = UiOptions()) {
    auto extraOptions = TextOptions(options.alignment, cast(int) (area.size.x / options.fontScale));
    auto drawOptions = DrawOptions(options.fontColor);
    drawOptions.scale = Vec2(options.fontScale);

    auto textPosition = area.centerPoint;
    final switch (options.alignment) {
        case Alignment.left:
            drawOptions.hook = Hook.left;
            textPosition.x = area.position.x + options.alignmentOffset; break;
        case Alignment.center:
            drawOptions.hook = Hook.center;
            break;
        case Alignment.right:
            drawOptions.hook = Hook.right;
            textPosition.x = area.position.x + area.size.x - options.alignmentOffset; break;
    }
    textPosition = textPosition.round();
    if (options.isDisabled && drawOptions.color.a >= options.fontAlphaOffset) {
        drawOptions.color.a -= options.fontAlphaOffset;
    }
    drawText(options.font, text, textPosition, drawOptions, extraOptions);
}

void uiText(Rect area, IStr text, UiOptions options = UiOptions()) {
    updateUiText(area, text, options);
    drawUiText(area, text, options);
}

bool updateUiButton(Rect area, IStr text, UiOptions options = UiOptions()) {
    auto m = uiMouse;
    auto id = uiState.itemId + 1;
    auto isHot = area.hasPointInclusive(m);
    if (isHot) {
        uiState.previousMaxHotItemIdBuffer = cast(short) id;
    }
    if (uiState.previousMaxHotItemId) {
        isHot = isHot && id == uiState.previousMaxHotItemId;
    }
    auto isActive = isHot && uiState.mouseClickAction.isDown;
    auto isClicked = isHot;
    if (uiState.isActOnPress) {
        isClicked = isClicked && uiState.mouseClickAction.isPressed;
    } else {
        auto isHotFromMousePressedPosition = area.hasPointInclusive(uiState.mousePressedPosition);
        isClicked = isClicked && isHotFromMousePressedPosition && uiState.mouseClickAction.isReleased;
    }

    if (options.isDisabled) {
        isHot = false;
        isActive = false;
        isClicked = false;
    } else if (id == uiState.focusedItemId) {
        isHot = true;
        if (uiState.keyboardClickAction.isDown || uiState.gamepadClickAction.isDown) isActive = true;
        if (uiState.keyboardClickAction.isPressed || uiState.gamepadClickAction.isPressed) isClicked = true;
    }
    updateUiState(area, isHot, isActive, isClicked);
    return isClicked;
}

void drawUiButton(Rect area, IStr text, bool isHot, bool isActive, UiOptions options = UiOptions()) {
    if (options.isDisabled) drawRect(area, options.disabledColor);
    else if (isActive) drawRect(area, options.activeColor);
    else if (isHot) drawRect(area, options.hotColor);
    else drawRect(area, options.idleColor);
    drawUiText(area, text, options);
}

bool uiButton(Rect area, IStr text, UiOptions options = UiOptions()) {
    auto result = updateUiButton(area, text, options);
    drawUiButton(area, text, isUiItemHot, isUiItemActive, options);
    return result;
}

bool updateUiDragHandle(ref Rect area, UiOptions options = UiOptions()) {
    auto dragLimitX = Vec2(-100000.0f, 100000.0f);
    auto dragLimitY = Vec2(-100000.0f, 100000.0f);
    // NOTE: There is a potential bug here when size is bigger than the limit/viewport. I will ignore it for now.
    final switch (options.dragLimit) {
        case UiDragLimit.none: break;
        case UiDragLimit.viewport:
            dragLimitX = Vec2(0.0f, uiState.viewportSize.x);
            dragLimitY = Vec2(0.0f, uiState.viewportSize.y);
            break;
        case UiDragLimit.viewportAndX:
            area.position.y = clamp(area.position.y, 0.0f, uiState.viewportSize.y - area.size.y);
            dragLimitX = Vec2(0.0f, uiState.viewportSize.x);
            dragLimitY = Vec2(area.position.y, area.position.y + area.size.y);
            break;
        case UiDragLimit.viewportAndY:
            area.position.x = clamp(area.position.x, 0.0f, uiState.viewportSize.x - area.size.x);
            dragLimitX = Vec2(area.position.x, area.position.x + area.size.x);
            dragLimitY = Vec2(0.0f, uiState.viewportSize.y);
            break;
        case UiDragLimit.custom:
            dragLimitX = options.dragLimitX;
            dragLimitY = options.dragLimitY;
            break;
        case UiDragLimit.customAndX:
            area.position.y = clamp(area.position.y, 0.0f, options.dragLimitY.y - area.size.y);
            dragLimitX = options.dragLimitX;
            dragLimitY = Vec2(area.position.y, area.position.y + area.size.y);
            break;
        case UiDragLimit.customAndY:
            area.position.x = clamp(area.position.x, 0.0f, options.dragLimitX.y - area.size.x);
            dragLimitX = Vec2(area.position.x, area.position.x + area.size.x);
            dragLimitY = options.dragLimitY;
            break;
    }

    area.position.x = clamp(area.position.x, dragLimitX.x, dragLimitX.y - area.size.x);
    area.position.y = clamp(area.position.y, dragLimitY.x, dragLimitY.y - area.size.y);
    updateUiButton(area, "", options);
    if (isUiItemDragged) {
        auto m = (mouse - uiState.viewportPosition) / uiState.viewportScale; // NOTE: Maybe this should be a function?
        area.position.y = clamp(m.y + uiDragOffset.y, dragLimitY.x, dragLimitY.y - area.size.y);
        area.position.x = clamp(m.x + uiDragOffset.x, dragLimitX.x, dragLimitX.y - area.size.x);
        *uiState = *uiPreviousState;
        updateUiButton(area, "", options);
        return true;
    } else {
        return false;
    }
}

void drawUiDragHandle(Rect area, bool isHot, bool isActive, UiOptions options = UiOptions()) {
    drawUiButton(area, "", isHot, isActive, options);
}

bool uiDragHandle(ref Rect area, UiOptions options = UiOptions()) {
    auto result = updateUiDragHandle(area, options);
    drawUiDragHandle(area, isUiItemHot, isUiItemActive, options);
    return result;
}

// TODO: Add support for right-to-left text.
@trusted
bool updateUiTextField(Rect area, ref Str text, Str textBuffer, UiOptions options = UiOptions()) {
    if (options.isDisabled) {
        // Look, I am funny.
    } else if (Keyboard.x.isPressed && (Keyboard.ctrl.isDown || Keyboard.alt.isDown)) {
        text = text[0 .. 0];
    } else if (Keyboard.backspace.isPressed && text.length > 0) {
        if (Keyboard.ctrl.isDown || Keyboard.alt.isDown) {
            auto spaceIndex = findSpaceInTextField(text);
            while (text.length > 0 && spaceIndex == text.length - 1) {
                text = text[0 .. $ - 1];
                spaceIndex = findSpaceInTextField(text);
            }
            if (spaceIndex != -1) {
                auto rightIndex = spaceIndex + 1;
                if (rightIndex < text.length && !isSpaceInTextField(text[rightIndex])) {
                    text = textBuffer[0 .. spaceIndex + 1];
                }
            } else {
                text = text[0 .. 0];
            }
        } else {
            auto codepointSize = 0;
            auto codepoint = rl.GetCodepointPrevious(&text.ptr[text.length], &codepointSize);
            text = text[0 .. $ - codepointSize];
        }
    } else {
        // NOTE: Doing codepoint to bytes conversion here. Maybe add something like that to joka one day.
        auto rune = dequeuePressedRune();
        auto newLength = text.length;
        if (rune <= 0x7F) {
            newLength += 1;
        } else if (rune <= 0x7FF) {
            newLength += 2;
        } else if (rune <= 0xFFFF) {
            newLength += 3;
        } else if (rune <= 0x10FFFF) {
            newLength += 4;
        } else {
            assert(0, "WTF!");
        }
        while (rune && newLength <= textBuffer.length) {
            text = textBuffer[0 .. newLength];
            if (rune <= 0x7F) {
                text[$ - 1] = cast(char) rune;
            } else if (rune <= 0x7FF) {
                text[$ - 2] = cast(char) (0xC0 | (rune >> 6));
                text[$ - 1] = cast(char) (0x80 | (rune & 0x3F));
            } else if (rune <= 0xFFFF) {
                text[$ - 3] = cast(char) (0xE0 | (rune >> 12));
                text[$ - 2] = cast(char) (0x80 | ((rune >> 6) & 0x3F));
                text[$ - 1] = cast(char) (0x80 | (rune & 0x3F));
            } else if (rune <= 0x10FFFF) {
                text[$ - 4] = cast(char) (0xF0 | (rune >> 18));
                text[$ - 3] = cast(char) (0x80 | ((rune >> 12) & 0x3F));
                text[$ - 2] = cast(char) (0x80 | ((rune >> 6) & 0x3F));
                text[$ - 1] = cast(char) (0x80 | (rune & 0x3F));
            } else {
                assert(0, "WTF!");
            }
            rune = dequeuePressedRune();
            newLength = text.length;
            if (rune <= 0x7F) {
                newLength += 1;
            } else if (rune <= 0x7FF) {
                newLength += 2;
            } else if (rune <= 0xFFFF) {
                newLength += 3;
            } else if (rune <= 0x10FFFF) {
                newLength += 4;
            } else {
                assert(0, "WTF!");
            }
        }
    }
    updateUiState(area, false, false, false);
    return uiState.keyboardClickAction.isPressed;
}

// TODO: Add support for right-to-left text.
void drawUiTextField(Rect area, Str text, UiOptions options = UiOptions()) {
    drawUiText(area, text, options);
    // TODO: Make that text position thing a function bro!!!
    // ---
    auto textPosition = area.centerPoint;
    final switch (options.alignment) {
        case Alignment.left:
            textPosition.x = area.position.x + options.alignmentOffset; break;
        case Alignment.center:
            break;
        case Alignment.right:
            textPosition.x = area.position.x + area.size.x - options.alignmentOffset; break;
    }
    textPosition = textPosition.round();
    // ---
    auto textSize = measureTextSize(options.font, text);
    auto cursorPosition = textPosition;
    final switch (options.alignment) {
        case Alignment.left: cursorPosition.x += textSize.x * options.fontScale + defaultUiTextFieldCursorOffset; break;
        case Alignment.center: cursorPosition.x += textSize.x * options.fontScale * 0.5f + defaultUiTextFieldCursorOffset; break;
        case Alignment.right: cursorPosition.x += defaultUiTextFieldCursorOffset; break;
    }
    if (!options.isDisabled) {
        auto rect = Rect(
            cursorPosition,
            options.font.size * options.fontScale * 0.08f,
            options.font.size * options.fontScale,
        ).area(Hook.center);
        if (rect.size.x <= 1.0f) rect.size.x = 1.0f;
        drawRect(rect, options.disabledColor.alpha(defaultUiTextFieldCursorDisabledAlpha));
    }
}

// Combos:
//  ctrl|alt + backsapce : Remove word.
//  ctrl|alt + x         : Remove everything.
bool uiTextField(Rect area, ref Str text, Str textBuffer, UiOptions options = UiOptions()) {
    auto result = updateUiTextField(area, text, textBuffer, options);
    drawUiTextField(area, text, options);
    return result;
}
