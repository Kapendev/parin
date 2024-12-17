// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.29
// ---

// TODO: Clean maybe the UiState struct and prepareUi func.
// TODO: Think about overlapping UI items.
// TODO: Add way to get item point for some stuff. This is nice when making lists.
// TODO: Add focus style.
// TODO: Add way to align text in buttons.
// TODO: Look at the API again.
// TODO: Test the ui code and think how to make it better while working on real stuff.

/// The `ui` module functions as a immediate mode UI library.
module parin.ui;

import parin.engine;

UiState uiState;
UiState uiPreviousState;

enum defaultUiAlpha = 230;
enum defaultUiDisabledColor = 0x202020.toRgb().alpha(defaultUiAlpha);
enum defaultUiIdleColor = 0x414141.toRgb().alpha(defaultUiAlpha);
enum defaultUiHotColor = 0x818181.toRgb().alpha(defaultUiAlpha);
enum defaultUiActiveColor = 0xBABABA.toRgb().alpha(defaultUiAlpha);

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

struct UiButtonOptions {
    Color disabledColor = defaultUiDisabledColor;
    Color idleColor = defaultUiIdleColor;
    Color hotColor = defaultUiHotColor;
    Color activeColor = defaultUiActiveColor;
    Font font;

    bool isDisabled;
    UiDragLimit dragLimit;
    Vec2 dragLimitX = Vec2(-100000.0f, 100000.0f);
    Vec2 dragLimitY = Vec2(-100000.0f, 100000.0f);

    @safe @nogc nothrow:

    this(bool isDisabled) {
        this.isDisabled = isDisabled;
    }

    this(UiDragLimit dragLimit) {
        this.dragLimit = dragLimit;
    }
}

struct UiState {
    Mouse mouseClickAction = Mouse.left;
    Keyboard keyboardClickAction = Keyboard.space;
    Gamepad gamepadClickAction = Gamepad.a;
    bool isActOnPress;

    Vec2 viewportPoint;
    Vec2 viewportSize;
    Vec2 viewportScale = Vec2(1);
    Vec2 startPoint;
    short margin;
    Layout layout;
    Vec2 layoutStartPoint;
    Vec2 layoutStartPointOffest;
    Vec2 layoutMaxItemSize;

    Vec2 mousePressedPoint;
    Vec2 itemDragOffset;
    Vec2 itemPoint;
    Vec2 itemSize;
    short itemId;
    short hotItemId;
    short activeItemId;
    short clickedItemId;
    short draggedItemId;
    short focusedItemId;
}

void prepareUi() {
    setUiViewportState(Vec2(), resolution, Vec2(1.0f));
    uiState.startPoint = Vec2();
    uiState.margin = 0;
    uiState.layout = Layout.v;
    uiState.layoutStartPoint = Vec2();
    uiState.layoutStartPointOffest = Vec2();
    uiState.layoutMaxItemSize = Vec2();
    uiState.itemPoint = Vec2();
    uiState.itemSize = Vec2();
    uiState.itemId = 0;
    uiState.hotItemId = 0;
    uiState.activeItemId = 0;
    uiState.clickedItemId = 0;
}

Vec2 uiMouse() {
    auto result = (mouse - uiState.viewportPoint) / uiState.viewportScale;
    if (result.x < 0) result.x = -100000.0f;
    else if (result.x > uiState.viewportSize.x) result.x = 100000.0f;
    if (result.y < 0) result.y = -100000.0f;
    else if (result.y > uiState.viewportSize.y) result.y = 100000.0f;
    return result;
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

void setUiViewportState(Vec2 point, Vec2 size, Vec2 scale) {
    uiState.viewportPoint = point;
    uiState.viewportSize = size;
    uiState.viewportScale = scale;

    if (uiState.mouseClickAction.isPressed) {
        uiState.mousePressedPoint = uiMouse;
    }
}

Vec2 uiStartPoint() {
    return uiState.startPoint;
}

void setUiStartPoint(Vec2 value) {
    uiState.itemSize = Vec2();
    uiState.startPoint = value;
    uiState.layoutStartPoint = value;
    uiState.layoutStartPointOffest = Vec2();
    uiState.layoutMaxItemSize = Vec2();
}

short uiMargin() {
    return uiState.margin;
}

void setUiMargin(short value) {
    uiState.margin = value;
}

void useUiLayout(Layout value) {
    if (uiState.layoutStartPointOffest) {
        final switch (value) {
            case Layout.v:
                if (uiState.layoutStartPointOffest.x > uiState.layoutMaxItemSize.x) {
                    uiState.layoutStartPoint.x = uiState.layoutStartPoint.x + uiState.layoutStartPointOffest.x + uiState.margin;
                } else {
                    uiState.layoutStartPoint.x += uiState.layoutMaxItemSize.x + uiState.margin;
                }
                uiState.layoutStartPointOffest = Vec2();
                uiState.layoutMaxItemSize.x = 0.0f;
                break;
            case Layout.h:
                uiState.layoutStartPoint.x = uiState.startPoint.x;
                if (uiState.layoutStartPointOffest.y > uiState.layoutMaxItemSize.y) {
                    uiState.layoutStartPoint.y = uiState.layoutStartPoint.y + uiState.layoutStartPointOffest.y + uiState.margin;
                } else {
                    uiState.layoutStartPoint.y += uiState.layoutMaxItemSize.y + uiState.margin;
                }
                uiState.layoutStartPointOffest = Vec2();
                uiState.layoutMaxItemSize.y = 0.0f;
                break;
        }
    }
    uiState.layout = value;
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
    return uiState.itemId == uiState.draggedItemId && deltaMouse;
}

bool isUiDragged() {
    return uiState.draggedItemId > 0 && deltaMouse;
}

Vec2 uiDragOffset() {
    return uiState.itemDragOffset;
}

int uiFocus() {
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

void updateUiState(Vec2 itemPoint, Vec2 itemSize, bool isHot, bool isActive, bool isClicked) {
    uiPreviousState = uiState;
    uiState.itemPoint = itemPoint;
    uiState.itemSize = itemSize;
    uiState.itemId += 1;
    if (itemSize.x > uiState.layoutMaxItemSize.x) uiState.layoutMaxItemSize.x = itemSize.x;
    if (itemSize.y > uiState.layoutMaxItemSize.y) uiState.layoutMaxItemSize.y = itemSize.y;
    final switch (uiState.layout) {
        case Layout.v: uiState.layoutStartPointOffest.y += uiState.itemSize.y + uiState.margin; break;
        case Layout.h: uiState.layoutStartPointOffest.x += uiState.itemSize.x + uiState.margin; break;
    }
    if (isHot) uiState.hotItemId = uiState.itemId;
    if (isActive) {
        uiState.activeItemId = uiState.itemId;
        uiState.focusedItemId = uiState.itemId;
    }
    if (isClicked) uiState.clickedItemId = uiState.itemId;
    if (uiState.mouseClickAction.isPressed && uiState.itemId == uiState.activeItemId) {
        auto m = uiMouse;
        uiState.itemDragOffset = uiState.itemPoint - m;
        uiState.draggedItemId = uiState.itemId;
    }
    if (uiState.draggedItemId) {
        if (uiState.mouseClickAction.isReleased) uiState.draggedItemId = 0;
    }
}

bool updateUiButton(Vec2 size, IStr text, UiButtonOptions options = UiButtonOptions()) {
    if (options.font.isEmpty) options.font = engineFont;
    auto m = uiMouse;
    auto id = uiState.itemId + 1;
    auto area = Rect(uiState.layoutStartPoint + uiState.layoutStartPointOffest, size);
    // auto isHot = area.hasPoint(uiMouse)
    auto isHot = m.x >= area.position.x && m.x < area.position.x + area.size.x && m.y >= area.position.y && m.y < area.position.y + area.size.y;
    auto isActive = isHot && uiState.mouseClickAction.isDown;
    auto isClicked = isHot;
    if (uiState.isActOnPress) {
        isClicked = isClicked && uiState.mouseClickAction.isPressed;
    } else {
        auto isHotFromMousePressedPoint =
            uiState.mousePressedPoint.x >= area.position.x &&
            uiState.mousePressedPoint.x < area.position.x + area.size.x &&
            uiState.mousePressedPoint.y >= area.position.y &&
            uiState.mousePressedPoint.y < area.position.y + area.size.y;
        isClicked = isClicked && isHotFromMousePressedPoint && uiState.mouseClickAction.isReleased;
    }

    if (options.isDisabled) {
        isHot = false;
        isActive = false;
        isClicked = false;
    } else if (id == uiState.focusedItemId) {
        isHot = true;
        if (uiState.keyboardClickAction.isDown || uiState.gamepadClickAction.isDown) isActive = true;
        if (uiState.isActOnPress) {
            if (uiState.keyboardClickAction.isPressed || uiState.gamepadClickAction.isPressed) isClicked = true;
        } else {
            if (uiState.keyboardClickAction.isReleased || uiState.gamepadClickAction.isReleased) isClicked = true;
        }
    }
    updateUiState(area.position, size, isHot, isActive, isClicked);
    return isClicked;
}

void drawUiButton(Vec2 size, IStr text, Vec2 point, bool isHot, bool isActive, UiButtonOptions options = UiButtonOptions()) {
    if (options.font.isEmpty) options.font = engineFont;
    auto area = Rect(point, size);
    if (options.isDisabled) {
        drawRect(area, options.disabledColor);
    } else if (isActive) {
        drawRect(area, options.activeColor);
    } else if (isHot) {
        drawRect(area, options.hotColor);
    } else {
        drawRect(area, options.idleColor);
    }
    if (options.isDisabled) {
        auto tempOptions = DrawOptions(Hook.center);
        tempOptions.color.a = defaultUiAlpha / 2;
        drawText(options.font, text, area.centerPoint, tempOptions);
    } else {
        drawText(options.font, text, area.centerPoint, DrawOptions(Hook.center));
    }
}

bool uiButton(Vec2 size, IStr text, UiButtonOptions options = UiButtonOptions()) {
    auto result = updateUiButton(size, text, options);
    drawUiButton(size, text, uiState.itemPoint, isUiItemHot, isUiItemActive, options);
    return result;
}

bool uiDragHandle(Vec2 size, ref Vec2 point, UiButtonOptions options = UiButtonOptions()) {
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
            point.y = clamp(point.y, 0.0f, uiState.viewportSize.y - size.y);
            dragLimitX = Vec2(0.0f, uiState.viewportSize.x);
            dragLimitY = Vec2(point.y, point.y + size.y);
            break;
        case UiDragLimit.viewportAndY:
            point.x = clamp(point.x, 0.0f, uiState.viewportSize.x - size.x);
            dragLimitX = Vec2(point.x, point.x + size.x);
            dragLimitY = Vec2(0.0f, uiState.viewportSize.y);
            break;
        case UiDragLimit.custom:
            dragLimitX = options.dragLimitX;
            dragLimitY = options.dragLimitY;
            break;
        case UiDragLimit.customAndX:
            point.y = clamp(point.y, 0.0f, options.dragLimitY.y - size.y);
            dragLimitX = options.dragLimitX;
            dragLimitY = Vec2(point.y, point.y + size.y);
            break;
        case UiDragLimit.customAndY:
            point.x = clamp(point.x, 0.0f, options.dragLimitX.y - size.x);
            dragLimitX = Vec2(point.x, point.x + size.x);
            dragLimitY = options.dragLimitY;
            break;
    }

    size.x = clamp(size.x, 0.0f, dragLimitX.y - dragLimitX.x);
    size.y = clamp(size.y, 0.0f, dragLimitY.y - dragLimitY.x);
    point.x = clamp(point.x, dragLimitX.x, dragLimitX.y - size.x);
    point.y = clamp(point.y, dragLimitY.x, dragLimitY.y - size.y);
    setUiStartPoint(point);
    updateUiButton(size, "", options);
    if (isUiItemDragged) {
        auto m = (mouse - uiState.viewportPoint) / uiState.viewportScale; // NOTE: Maybe this should be a function?
        point.y = clamp(m.y + uiDragOffset.y, dragLimitY.x, dragLimitY.y - size.y);
        point.x = clamp(m.x + uiDragOffset.x, dragLimitX.x, dragLimitX.y - size.x);
        uiState = uiPreviousState;  
        setUiStartPoint(point);
        updateUiButton(size, "", options);
        drawUiButton(size, "", uiState.itemPoint, isUiItemHot, isUiItemActive, options);
        return true;
    } else {
        drawUiButton(size, "", uiState.itemPoint, isUiItemHot, isUiItemActive, options);
        return false;
    }
}

void uiTexture(Texture texture, UiButtonOptions options = UiButtonOptions()) {
    auto point = uiState.layoutStartPoint + uiState.layoutStartPointOffest;
    drawRect(Rect(point, texture.size), black);
    drawTexture(texture, point);
    updateUiState(point, texture.size, false, false, false);
}

void uiTexture(TextureId texture, UiButtonOptions options = UiButtonOptions()) {
    uiTexture(texture.get(), options);
}

void uiText(IStr text, UiButtonOptions options = UiButtonOptions()) {
    if (options.font.isEmpty) options.font = engineFont;
    auto point = uiState.layoutStartPoint + uiState.layoutStartPointOffest;
    auto size = measureTextSize(options.font, text);
    drawText(options.font, text, point);
    updateUiState(point, size, false, false, false);
}
