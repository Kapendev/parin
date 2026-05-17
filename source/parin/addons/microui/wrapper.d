// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// ---

/// High-level wrapper around the low-level `core` module.
/// Provides helper functions that use a global context and follow D naming conventions.
module parin.addons.microui.wrapper;

import parin.joka.microui;
import parin.engine;

UiContext uiContext;

enum uiNumberFmt         = muNumberFmt;         /// Format string used for numbers.
enum uiNumberFmtWithZero = muNumberFmtWithZero; /// Format string used for numbers, with a zero at the end.

alias UiTextWidthFunc  = MuTextWidthFunc;  /// Used for getting the width of the text.
alias UiTextHeightFunc = MuTextHeightFunc; /// Used for getting the height of the text.
alias UiDrawFrameFunc  = MuDrawFrameFunc;  /// Used for drawing a frame.

alias UiId        = MuId;        /// The control ID type of microui.
alias UiFont      = MuFont;      /// The font type of microui.
alias UiTexture   = MuTexture;   /// The texture type of microui.
alias UiSliceMode = MuSliceMode; /// The slice repeat mode type of microui.

deprecated("Use `IRect`. It's the same.")
alias UiRect = IRect; /// A 2D rectangle using ints.
deprecated("Use `IVec2`. It's the same.")
alias UiVec = IVec2; /// A 2D vector using ints.
deprecated("Use `Vec2`. It's the same.")
alias UiFVec = Vec2; /// A 2D vector using floats.
deprecated("Use `Margin`. It's the same.")
alias UiMargin = Margin; /// A set of 4 integer margins for left, top, right, and bottom.
deprecated("Use `SlicePart`. It's the same.")
alias UiSlicePart = SlicePart; /// A part of a 9-slice with source and target rectangles for drawing.
deprecated("Use `SliceParts`. It's the same.")
alias UiSliceParts = SliceParts; /// The parts of a 9-slice.

alias UiPoolItem    = MuPoolItem;    /// A pool item.
alias UiBaseCommand = MuBaseCommand; /// Base structure for all render commands, containing type and size metadata.
alias UiJumpCommand = MuJumpCommand; /// Command to jump to another location in the command buffer.
alias UiClipCommand = MuClipCommand; /// Command to set a clipping rectangle.
alias UiRectCommand = MuRectCommand; /// Command to draw a rectangle with a given color.
alias UiTextCommand = MuTextCommand; /// Command to render text at a given position with a font and color. The text is a null-terminated string. Use `str.ptr` to access it.
alias UiIconCommand = MuIconCommand; /// Command to draw an icon inside a rectangle with a given color.
alias UiCommandData = MuCommandData; /// A union of all possible render commands.

alias UiLayout    = MuLayout;    /// Layout state used to position UI controls within a container.
alias UiContainer = MuContainer; /// A UI container holding commands.
alias UiSlice     = MuSlice;     /// A 9-slice definition for an atlas area, controlling how it is sampled and tiled.
alias UiStyle     = MuStyle;     /// UI style settings including font, sizes, spacing, and colors.
alias UiContext   = MuContext;   /// The UI context.
alias UiCommand   = MuCommand;   /// The command kind.

deprecated("Remove `Enum` from the type name.")
alias UiClipEnum  = MuClip; /// The clipping kind.
alias UiClip      = MuClip; /// The clipping kind.
deprecated("Remove `Enum` from the type name.")
alias UiColorEnum = MuColor; /// The color kind.
alias UiColor     = MuColor; /// The color kind.
deprecated("Remove `Enum` from the type name.")
alias UiIconEnum  = MuIcon; /// The icon kind.
alias UiIcon      = MuIcon; /// The icon kind.
deprecated("Remove `Enum` from the type name.")
alias UiAtlasEnum = MuAtlas; /// The atlas area kind.
alias UiAtlas     = MuAtlas; /// The atlas area kind.

alias UiResFlags   = MuResFlags;   /// Bitmask type for result flags.
alias UiResFlag    = MuResFlag;    /// Result flags indicating the outcome of a control interaction.
alias UiOptFlags   = MuOptFlags;   /// Bitmask type for option flags.
alias UiOptFlag    = MuOptFlag;    /// Option flags controlling control and window behaviour.
alias UiMouseFlags = MuMouseFlags; /// Bitmask type for mouse button flags.
alias UiMouseFlag  = MuMouseFlag;  /// Flags representing which mouse buttons are pressed.
alias UiKeyFlags   = MuKeyFlags;   /// Bitmask type for keyboard key flags.
alias UiKeyFlag    = MuKeyFlag;    /// Flags representing which keys are currently held down.

/// Used by the `members` function to hide data.
alias UiPrivate = MuPrivate;
/// Used by the `members` function to show data in a specific way.
alias UiMember = MuMember;

@safe nothrow @nogc:

pragma(inline, true)
ref UiStyle* uiStyle() {
    return uiContext.style;
}

void readyUiCore(UiFont font = null, int fontScale = 1) {
    uiContext.ready(font, fontScale);
}

void readyUiCore(UiTextWidthFunc width, UiTextHeightFunc height, UiFont font = null, int fontScale = 1) {
    uiContext.readyWithFuncs(width, height, font, fontScale);
}

void beginUiCore() {
    uiContext.begin();
}

void endUiCore() {
    uiContext.end();
}

void setUifocus(UiId id) {
    uiContext.setFocus(id);
}

UiId getUiId(const(void)* data, Sz size) {
    return uiContext.getId(data, size);
}

UiId getUiId(IStr str) {
    return uiContext.getIdFromStr(str);
}

void pushUiId(const(void)* data, Sz size) {
    uiContext.pushId(data, size);
}

void pushUiId(IStr str) {
    uiContext.pushIdFromStr(str);
}

void popUiId() {
    uiContext.popId();
}

void pushUiClipRect(IRect rect) {
    uiContext.pushClipRect(rect);
}

void popUiClipRect() {
    uiContext.popClipRect();
}

IRect getUiClipRect() {
    return uiContext.getClipRect();
}

UiClip checkUiClipRect(IRect rect) {
    return uiContext.checkClip(rect);
}

UiContainer* getCurrentUiContainer() {
    return uiContext.getCurrentContainer();
}

UiContainer* getUiContainer(IStr name) {
    return uiContext.getContainer(name);
}

void bringUiContainerToFront(UiContainer* cnt) {
    uiContext.bringToFront(cnt);
}

/*============================================================================
** pool
**============================================================================*/

int readyUiPool(UiPoolItem* items, Sz len, UiId id) {
    return uiContext.poolInit(items, len, id);
}

int getFromUiPool(UiPoolItem* items, Sz len, UiId id) {
    return uiContext.poolGet(items, len, id);
}

void updateUiPool(UiPoolItem* items, Sz idx) {
    uiContext.poolUpdate(items, idx);
}

/*============================================================================
** input handlers
**============================================================================*/

void uiInputMouseMove(int x, int y) {
    uiContext.inputMouseMove(x, y);
}

void uiInputMouseDown(int x, int y, UiMouseFlags input) {
    uiContext.inputMouseDown(x, y, input);
}

void uiInputMouseUp(int x, int y, UiMouseFlags input) {
    uiContext.inputMouseUp(x, y, input);
}

void uiInputScroll(int x, int y) {
    uiContext.inputScroll(x, y);
}

void uiInputKeyDown(UiKeyFlags input) {
    uiContext.inputKeyDown(input);
}

void uiInputKeyUp(UiKeyFlags input) {
    uiContext.inputKeyUp(input);
}

void uiInputText(IStr text) {
    uiContext.inputText(text);
}

/*============================================================================
** commandlist
**============================================================================*/

UiCommandData* pushUiCommand(UiCommand type, Sz size) {
    return uiContext.pushCommand(type, size);
}

bool nextUiCommand(UiCommandData** cmd) {
    return uiContext.nextCommand(cmd);
}

void setUiClipRect(IRect rect) {
    uiContext.setClip(rect);
}

void drawUiRect(IRect rect, Rgba color, UiAtlas id = UiAtlas.none) {
    uiContext.drawRect(rect, color, id);
}

void drawUibox(IRect rect, Rgba color) {
    uiContext.drawBox(rect, color);
}

void drawUiText(UiFont font, IStr str, IVec2 point, Rgba color) {
    uiContext.drawText(font, str, point, color);
}

void drawUiIcon(UiIcon id, IRect rect, Rgba color) {
    uiContext.drawIcon(id, rect, color);
}

/*============================================================================
** layout
**============================================================================*/

void beginColumn() {
    uiContext.beginColumn();
}

void endColumn() {
    uiContext.endColumn();
}

void row(int height, const(int)[] widths...) {
    uiContext.row(height, widths);
}

void setLayoutWidth(int width) {
    uiContext.setLayoutWidth(width);
}

void setLayoutHeight(int height) {
    uiContext.setLayoutHeight(height);
}

void setNextLayout(IRect rect, bool relative) {
    uiContext.setNextLayout(rect, relative);
}

IRect nextLayout() {
    return uiContext.nextLayout();
}

/*============================================================================
** controls
**============================================================================*/

void drawControlFrame(UiId id, IRect rect, UiColor colorId, UiOptFlags opt, UiAtlas atlasId = UiAtlas.none) {
    uiContext.drawControlFrame(id, rect, colorId, opt, atlasId);
}

void drawControlText(IStr text, IRect rect, UiColor colorId, UiOptFlags opt) {
    uiContext.drawControlText(text, rect, colorId, opt);
}

bool isUiMouseOver(IRect rect) {
    return uiContext.mouseOver(rect);
}

void updateControl(UiId id, IRect rect, UiOptFlags opt) {
    uiContext.updateControl(id, rect, opt);
}

void text(IStr text) {
    uiContext.text(text);
}

void label(IStr text) {
    uiContext.label(text);
}

UiResFlags button(IStr label, UiIcon icon = UiIcon.none, UiOptFlags opt = UiOptFlag.alignCenter) {
    return uiContext.button(label, icon, opt);
}

UiResFlags checkbox(ref bool state, IStr label = "") {
    return uiContext.checkbox(state, label);
}

UiResFlags textBox(Str buffer, ref Sz newlen, UiOptFlags opt = UiOptFlag.none) {
    return uiContext.textBox(buffer, newlen, opt);
}

MuResFlags textBox(Str buffer, ref IStr newslice, UiOptFlags opt = UiOptFlag.none) {
    return uiContext.textBox(buffer, newslice, opt);
}

MuResFlags textBox(Sz N = 128, IStr file = __FILE__, Sz line = __LINE__)(ref IStr newslice, UiOptFlags opt = UiOptFlag.none) {
    return uiContext.textBox!(N, file, line)(newslice, opt);
}

UiResFlags slider(ref float value, float low, float high, float step = 0.01f, IStr fmt = uiNumberFmt, UiOptFlags opt = UiOptFlag.alignCenter) {
    return uiContext.slider(value, low, high, step, fmt, opt);
}

UiResFlags slider(ref int value, int low, int high, int step = 1, IStr fmt = uiNumberFmt, UiOptFlags opt = UiOptFlag.alignCenter) {
    return uiContext.slider(value, low, high, step, fmt, opt);
}

UiResFlags number(ref float value, float step = 0.01f, IStr fmt = uiNumberFmt, UiOptFlags opt = UiOptFlag.alignCenter) {
    return uiContext.number(value, step, fmt, opt);
}

UiResFlags number(ref int value, int step = 1, IStr fmt = uiNumberFmt, UiOptFlags opt = UiOptFlag.alignCenter) {
    return uiContext.number(value, step, fmt, opt);
}

UiResFlags header(IStr label, UiOptFlags opt = UiOptFlag.none) {
    return uiContext.header(label, opt);
}

void members(T)(ref T data, int labelWidth, bool canShowPrivateMembers = false) {
    uiContext.members(data, labelWidth, canShowPrivateMembers);
}

UiResFlags headerAndMembers(T)(ref T data, int labelWidth, IStr label = "", bool canShowPrivateMembers = false) {
    return uiContext.headerAndMembers(data, labelWidth, label, canShowPrivateMembers);
}

UiResFlags beginTreeNode(IStr label, UiOptFlags opt = UiOptFlag.none) {
    return uiContext.beginTreeNode(label, opt);
}

void endTreeNode() {
    uiContext.endTreeNode();
}

UiResFlags beginWindow(IStr title, IRect rect, UiOptFlags opt = UiOptFlag.none) {
    return uiContext.beginWindow(title, rect, opt);
}

UiResFlags beginWindow(IStr title, int x, int y, int w, int h, UiOptFlags opt = UiOptFlag.none) {
    return uiContext.beginWindow(title, x, y, w, h, opt);
}

void endWindow() {
    uiContext.endWindow();
}

void openPopup(IStr name) {
    uiContext.openPopup(name);
}

UiResFlags beginPopup(IStr name) {
    return uiContext.beginPopup(name);
}

void endPopup() {
    uiContext.endPopup();
}

void beginPanel(IStr name, UiOptFlags opt = UiOptFlag.none) {
    uiContext.beginPanel(name, opt);
}

void endPanel() {
    uiContext.endPanel();
}

void openDMenu() {
    uiContext.openDmenu();
}

UiResFlags beginDMenu(ref IStr selection, const(IStr)[] items, IVec2 canvas, IStr label = "", Vec2 scale = Vec2(0.5f, 0.7f)) {
    return uiContext.beginDmenu(selection, items, canvas, label, scale);
}

void endDMenu() {
    uiContext.endDmenu();
}

@trusted
int tempMuUiTextWidthFunc(UiFont font, IStr str) {
    auto data = cast(FontId*) font;
    return cast(int) measureTextSize(
        *data,
        str,
        DrawOptions(Vec2(uiStyle.fontScale, uiStyle.fontScale)),
        TextOptions()
    ).x;
}

@trusted
int tempMuUiTextHeightFunc(UiFont font) {
    auto data = cast(FontId*) font;
    return data.size * uiStyle.fontScale;
}

/// Initializes the microui context and sets temporary text size functions. Value `font` should be a `FontId*`.
@trusted
void readyUi(UiFont font = null, int fontScale = 1) {
    auto data = font ? cast(FontId*) font : &_engineState.defaultFont;
    readyUiCore(&tempMuUiTextWidthFunc, &tempMuUiTextHeightFunc, data, fontScale);
    if (data) {
        auto size = data.size * uiStyle.fontScale;
        auto t = (size - 8.0f) / (38.0f - 8.0f);
        uiStyle.titleHeight = size + size / 2 + 4;
        if (t > 0.0f) {
            // Scale factor: 0.0 at size=8, 1.0 at size=38.
            uiStyle.size = IVec2(cast(int) (size * 6), cast(int) (size + lerp(-4, 0, t)));
            uiStyle.border = cast(int) lerp(1, 3, t);
            uiStyle.spacing += cast(int) lerp(0, 8, t);
            uiStyle.padding += cast(int) lerp(0, 8, t);
            uiStyle.scrollbarSize += cast(int) lerp(0, 8, t);
            uiStyle.scrollbarSpeed += cast(int) lerp(0, 8, t);
            uiStyle.thumbSize += cast(int) lerp(0, 8, t);
        }
    }
}

/// Initializes the microui context and sets temporary text size functions.
void readyUi(int fontScale) {
    readyUi(null, fontScale);
}

/// Initializes the microui context and sets temporary text size functions.
void readyUi(FontId font, int fontScale = 1) {
    static readyUiFont = FontId();
    readyUiFont = font;
    readyUi(&readyUiFont, fontScale);
}

/// Handles input events and updates the microui context accordingly.
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
    Sz charBufferLength = 0;
    foreach (i, ref c; charBuffer) {
        // TODO: This does only work with ASCII lol. Change that when I add UTF8 stuff to Joka.
        c = cast(char) dequeuePressedRune();
        if (c == '\0') { charBufferLength = i; break; }
    }
    if (charBufferLength) uiInputText(charBuffer[0 .. charBufferLength]);
}

/// Draws the microui context to the screen.
@trusted
void drawUiState() {
    auto styleFont = cast(FontId*) uiStyle.font;
    auto styleTexture = cast(TextureId*) uiStyle.texture;
    auto parinOptions = DrawOptions(); // NOTE: Can be weird, but works if you are not a noob.
    beginClip(Rect(windowSize));
    UiCommandData* cmd;
    while (nextUiCommand(&cmd)) {
        switch (cmd.type) {
            case UiCommand.text:
                auto textFont = cast(FontId*) cmd.text.font;
                parinOptions.color = *(cast(Rgba*) (&cmd.text.color));
                parinOptions.scale = Vec2(uiStyle.fontScale);
                drawText(
                    *textFont,
                    cmd.text.toStr(),
                    Vec2(cmd.text.pos.x, cmd.text.pos.y),
                    parinOptions,
                );
                parinOptions.scale = Vec2(1);
                break;
            case UiCommand.rect:
                parinOptions.color = *(cast(Rgba*) (&cmd.rect.color));
                auto rectSlice = uiStyle.slices[cmd.rect.id];
                if (styleTexture && rectSlice.area.hasSize) {
                    foreach (i, ref part; computeSliceParts(rectSlice.area, cmd.rect.rect, rectSlice.margin)) {
                        if (rectSlice.mode && part.canTile) {
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
            case UiCommand.icon:
                parinOptions.color = *(cast(Rgba*) (&cmd.icon.color));
                auto iconAtlasArea = uiStyle.iconAtlasAreas[cmd.icon.id];
                auto iconDiff = IVec2(cmd.icon.rect.w - iconAtlasArea.w, cmd.icon.rect.h - iconAtlasArea.h);
                if (styleTexture && iconAtlasArea.hasSize) {
                    drawTextureArea(
                        *styleTexture,
                        Rect(iconAtlasArea.x, iconAtlasArea.y, iconAtlasArea.w, iconAtlasArea.h),
                        Vec2(cmd.icon.rect.x + iconDiff.x / 2, cmd.icon.rect.y + iconDiff.y / 2),
                        parinOptions,
                    );
                } else {
                    parinOptions.scale = Vec2(uiStyle.fontScale, uiStyle.fontScale);
                    IStr icon = "?";
                    switch (cmd.icon.id) {
                        case UiIcon.close:     icon = "x"; break;
                        case UiIcon.check:     icon = "*"; break;
                        case UiIcon.collapsed: icon = "+"; break;
                        case UiIcon.expanded:  icon = "-"; break;
                        default: break;
                    }
                    auto iconWidth = uiContext.textWidth(styleFont, icon);
                    auto iconHeight = uiContext.textHeight(styleFont);
                    iconDiff = IVec2(cmd.icon.rect.w - iconWidth, cmd.icon.rect.h - iconHeight);
                    drawText(
                        *styleFont,
                        icon,
                        Vec2(cmd.icon.rect.x + iconDiff.x / 2, cmd.icon.rect.y + iconDiff.y / 2),
                        parinOptions,
                    );
                    parinOptions.scale = Vec2(1);
                }
                break;
            case UiCommand.clip:
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
void beginUiFrame() {
    handleUiInput();
    beginUiCore();
}

/// The old name of the `beginUiFrame` function.
deprecated("Use `beginUiFrame`. It's a better name.")
alias beginUi = beginUiFrame;

/// Ends UI processing and performs drawing.
void endUiFrame() {
    endUiCore();
    drawUiState();
}

/// The old name of the `endUiFrame` function.
deprecated("Use `endUiFrame`. It's a better name.")
alias endUi = endUiFrame;
