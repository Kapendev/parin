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

enum uiNumberFmt         = muNumberFmt;
enum uiNumberFmtWithZero = muNumberFmtWithZero;

alias UiTextWidthFunc  = MuTextWidthFunc;  /// Used for getting the width of the text.
alias UiTextHeightFunc = MuTextHeightFunc; /// Used for getting the height of the text.
alias UiDrawFrameFunc  = MuDrawFrameFunc;  /// Used for drawing a frame.

alias UiId        = MuId;        /// The control ID type of microui.
alias UiFont      = MuFont;      /// The font type of microui.
alias UiTexture   = MuTexture;   /// The texture type of microui.
alias UiSliceMode = MuSliceMode; /// The slice repeat mode type of microui.

alias UiColor      = Rgba;       /// A RGBA color using ubytes.
alias UiRect       = IRect;      /// A 2D rectangle using ints.
alias UiVec        = IVec2;      /// A 2D vector using ints.
alias UiFVec       = Vec2;       /// A 2D vector using floats.
alias UiMargin     = Margin;     /// A set of 4 integer margins for left, top, right, and bottom.
alias UiSlicePart  = SlicePart;  /// A part of a 9-slice with source and target rectangles for drawing.
alias UiSliceParts = SliceParts; /// The parts of a 9-slice.

alias UiPoolItem    = MuPoolItem;    /// A pool item.
alias UiBaseCommand = MuBaseCommand; /// Base structure for all render commands, containing type and size metadata.
alias UiJumpCommand = MuJumpCommand; /// Command to jump to another location in the command buffer.
alias UiClipCommand = MuClipCommand; /// Command to set a clipping rectangle.
alias UiRectCommand = MuRectCommand; /// Command to draw a rectangle with a given color.
alias UiTextCommand = MuTextCommand; /// Command to render text at a given position with a font and color. The text is a null-terminated string. Use `str.ptr` to access it.
alias UiIconCommand = MuIconCommand; /// Command to draw an icon inside a rectangle with a given color.
alias UiCommandData = MuCommandData;     /// A union of all possible render commands.

alias UiLayout    = MuLayout;    /// Layout state used to position UI controls within a container.
alias UiContainer = MuContainer; /// A UI container holding commands.
alias UiSlice     = MuSlice;
alias UiStyle     = MuStyle;     /// UI style settings including font, sizes, spacing, and colors.
alias UiContext   = MuContext;   /// The main UI context.

alias UiClipEnum  = MuClip;
alias UiCommand   = MuCommand;
alias UiColorEnum = MuColor;
alias UiIconEnum  = MuIcon;
alias UiAtlasEnum = MuAtlas;

alias UiResFlags   = MuResFlags;   /// The type of `UiResFlag`.
alias UiResFlag    = MuResFlag;
alias UiOptFlags   = MuOptFlags;   /// The type of `UiOptFlag`.
alias UiOptFlag    = MuOptFlag;
alias UiMouseFlags = MuMouseFlags; /// The type of `UiMouseFlag`.
alias UiMouseFlag  = MuMouseFlag;
alias UiKeyFlags   = MuKeyFlags;   /// The type of `UiKeyFlag`.
alias UiKeyFlag    = MuKeyFlag;

/// Used by the `members` function to hide data.
struct UiPrivate {}

/// Used by the `members` function to show data in a specific way.
struct UiMember {
    IStr name;  /// The name of the member.
    float low;  /// Used by sliders.
    float high; /// Used by sliders.
    float step; /// Used by sliders.

    @safe nothrow @nogc pure:

    this(float low, float high, float step = float.nan) {
        this.low = low;
        this.high = high;
        this.step = step;
    }

    this(float step) {
        this.step = step;
    }

    this(IStr name, float low, float high, float step = float.nan) {
        this.name = name;
        this.low = low;
        this.high = high;
        this.step = step;
    }

    this(IStr name, float step = float.nan) {
        this.name = name;
        this.step = step;
    }
}

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
    mu_set_focus(&uiContext, id);
}

UiId getUiId(const(void)* data, Sz size) {
    return mu_get_id(&uiContext, data, size);
}

UiId getUiId(IStr str) {
    return mu_get_id_str(&uiContext, str);
}

void pushUiId(const(void)* data, Sz size) {
    mu_push_id(&uiContext, data, size);
}

void pushUiId(IStr str) {
    mu_push_id_str(&uiContext, str);
}

void popUiId() {
    mu_pop_id(&uiContext);
}

void pushUiClipRect(UiRect rect) {
    mu_push_clip_rect(&uiContext, rect);
}

void popUiClipRect() {
    mu_pop_clip_rect(&uiContext);
}

UiRect getUiClipRect() {
    return mu_get_clip_rect(&uiContext);
}

UiClipEnum checkUiClipRect(UiRect rect) {
    return cast(UiClipEnum) mu_check_clip(&uiContext, rect);
}

UiContainer* getCurrentUiContainer() {
    return mu_get_current_container(&uiContext);
}

UiContainer* getUiContainer(IStr name) {
    return mu_get_container(&uiContext, name);
}

void bringUiContainerToFront(UiContainer* cnt) {
    mu_bring_to_front(&uiContext, cnt);
}

/*============================================================================
** pool
**============================================================================*/

int readyUiPool(UiPoolItem* items, Sz len, UiId id) {
    return mu_pool_init(&uiContext, items, len, id);
}

int getFromUiPool(UiPoolItem* items, Sz len, UiId id) {
    return mu_pool_get(&uiContext, items, len, id);
}

void updateUiPool(UiPoolItem* items, Sz idx) {
    mu_pool_update(&uiContext, items, idx);
}

/*============================================================================
** input handlers
**============================================================================*/

void uiInputMouseMove(int x, int y) {
    mu_input_mousemove(&uiContext, x, y);
}

void uiInputMouseDown(int x, int y, UiMouseFlags input) {
    mu_input_mousedown(&uiContext, x, y, input);
}

void uiInputMouseUp(int x, int y, UiMouseFlags input) {
    mu_input_mouseup(&uiContext, x, y, input);
}

void uiInputScroll(int x, int y) {
    mu_input_scroll(&uiContext, x, y);
}

void uiInputKeyDown(UiKeyFlags input) {
    mu_input_keydown(&uiContext, input);
}

void uiInputKeyUp(UiKeyFlags input) {
    mu_input_keyup(&uiContext, input);
}

void uiInputText(IStr text) {
    mu_input_text(&uiContext, text);
}

/*============================================================================
** commandlist
**============================================================================*/

UiCommandData* pushUiCommand(UiCommand type, Sz size) {
    return mu_push_command(&uiContext, type, size);
}

bool nextUiCommand(UiCommandData** cmd) {
    return mu_next_command(&uiContext, cmd);
}

void setUiClipRect(UiRect rect) {
    mu_set_clip(&uiContext, rect);
}

void drawUiRect(UiRect rect, UiColor color, UiAtlasEnum id = UiAtlasEnum.none) {
    mu_draw_rect(&uiContext, rect, color, id);
}

void drawUibox(UiRect rect, UiColor color) {
    mu_draw_box(&uiContext, rect, color);
}

void drawUiText(UiFont font, IStr str, UiVec point, UiColor color) {
    mu_draw_text(&uiContext, font, str, point, color);
}

void drawUiIcon(UiIconEnum id, UiRect rect, UiColor color) {
    mu_draw_icon(&uiContext, id, rect, color);
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

void setNextLayout(UiRect rect, bool relative) {
    uiContext.setNextLayout(rect, relative);
}

UiRect nextLayout() {
    return uiContext.nextLayout();
}

/*============================================================================
** controls
**============================================================================*/

void drawControlFrame(UiId id, UiRect rect, UiColorEnum colorId, UiOptFlags opt, UiAtlasEnum atlasId = UiAtlasEnum.none) {
    uiContext.drawControlFrame(id, rect, colorId, opt, atlasId);
}

void drawControlText(IStr text, UiRect rect, UiColorEnum colorId, UiOptFlags opt) {
    uiContext.drawControlText(text, rect, colorId, opt);
}

bool isUiMouseOver(UiRect rect) {
    return uiContext.mouseOver(rect);
}

void updateControl(UiId id, UiRect rect, UiOptFlags opt) {
    uiContext.updateControl(id, rect, opt);
}

void text(IStr text) {
    uiContext.text(text);
}

void label(IStr text) {
    uiContext.label(text);
}

UiResFlags button(IStr label, UiIconEnum icon = UiIconEnum.none, UiOptFlags opt = UiOptFlag.alignCenter) {
    return uiContext.button(label, icon, opt);
}

@trusted
UiResFlags checkbox(ref bool state, IStr label = "") {
    return uiContext.checkbox(state, label);
}

UiResFlags textbox(char[] buffer, UiOptFlags opt, Sz* newlen = null) {
    return uiContext.textbox(buffer, opt, newlen);
}

UiResFlags textbox(char[] buffer, Sz* newlen = null) {
    return uiContext.textbox(buffer, newlen);
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

// TODO: Needs cleaning. It looks likes this because I just wanted to get something to work and original microui could not use Joka.
void members(T)(ref T data, int labelWidth, bool canShowPrivateMembers = false) {
    auto window = getCurrentUiContainer();
    row(0, labelWidth, -1);
    static foreach (member; data.tupleof) {
        // With data.
        static if (is(typeof(__traits(getAttributes, member)[0]) == UiMember)) {
            static if (__traits(hasMember, typeof(member), "x") && __traits(hasMember, typeof(member), "y") && __traits(hasMember, typeof(member), "z") && __traits(hasMember, typeof(member), "w")) {
                row(0, labelWidth,
                    (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 4 - uiStyle.spacing - uiStyle.border,
                    (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 4 - uiStyle.spacing - uiStyle.border,
                    (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 4 - uiStyle.spacing - uiStyle.border,
                    -1,
                );
                static if (is(typeof(mixin("data.", member.stringof, ".x")) == float)) {
                    label(__traits(getAttributes, member)[0].name.length ? __traits(getAttributes, member)[0].name : member.stringof);
                    number(mixin("data.", member.stringof, ".x"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".y"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".z"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".w"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step);
                } else static if (is(typeof(mixin("data.", member.stringof, ".x")) == int)) {
                    label(__traits(getAttributes, member)[0].name.length ? __traits(getAttributes, member)[0].name : member.stringof);
                    number(mixin("data.", member.stringof, ".x"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 1 : cast(int) __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".y"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 1 : cast(int) __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".z"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 1 : cast(int) __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".w"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 1 : cast(int) __traits(getAttributes, member)[0].step);
                }
                row(0, labelWidth, -1);
            } else static if (__traits(hasMember, typeof(member), "x") && __traits(hasMember, typeof(member), "y") && __traits(hasMember, typeof(member), "z")) {
                row(0, labelWidth,
                    (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 3 - uiStyle.spacing - uiStyle.border,
                    (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 3 - uiStyle.spacing - uiStyle.border,
                    -1,
                );
                static if (is(typeof(mixin("data.", member.stringof, ".x")) == float)) {
                    label(__traits(getAttributes, member)[0].name.length ? __traits(getAttributes, member)[0].name : member.stringof);
                    number(mixin("data.", member.stringof, ".x"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".y"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".z"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step);
                } else static if (is(typeof(mixin("data.", member.stringof, ".x")) == int)) {
                    label(__traits(getAttributes, member)[0].name.length ? __traits(getAttributes, member)[0].name : member.stringof);
                    number(mixin("data.", member.stringof, ".x"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 1 : cast(int) __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".y"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 1 : cast(int) __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".z"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 1 : cast(int) __traits(getAttributes, member)[0].step);
                }
                row(0, labelWidth, -1);
            } else static if (__traits(hasMember, typeof(member), "x") && __traits(hasMember, typeof(member), "y")) {
                row(0, labelWidth,
                    (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 2 - uiStyle.spacing - uiStyle.border,
                    -1,
                );
                static if (is(typeof(mixin("data.", member.stringof, ".x")) == float)) {
                    label(__traits(getAttributes, member)[0].name.length ? __traits(getAttributes, member)[0].name : member.stringof);
                    number(mixin("data.", member.stringof, ".x"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".y"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step);
                } else static if (is(typeof(mixin("data.", member.stringof, ".x")) == int)) {
                    label(__traits(getAttributes, member)[0].name.length ? __traits(getAttributes, member)[0].name : member.stringof);
                    number(mixin("data.", member.stringof, ".x"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 1 : cast(int) __traits(getAttributes, member)[0].step);
                    number(mixin("data.", member.stringof, ".y"), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 1 : cast(int) __traits(getAttributes, member)[0].step);
                }
                row(0, labelWidth, -1);
            } else static if (is(typeof(member) == bool)) {
                label(__traits(getAttributes, member)[0].name.length ? __traits(getAttributes, member)[0].name : member.stringof);
                checkbox(mixin("data.", member.stringof));
            } else static if (is(typeof(member) == float)) {
                label(__traits(getAttributes, member)[0].name.length ? __traits(getAttributes, member)[0].name : member.stringof);
                static if (!(__traits(getAttributes, member)[0].low == __traits(getAttributes, member)[0].low)) {
                    number(mixin("data.", member.stringof), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step);
                } else {
                    slider(
                        mixin("data.", member.stringof),
                        __traits(getAttributes, member)[0].low,
                        __traits(getAttributes, member)[0].high,
                        !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step,
                        muNumberFmt,
                        MuOptFlag.alignCenter,
                    );
                }
            } else static if (is(typeof(member) == int)) {
                label(__traits(getAttributes, member)[0].name.length ? __traits(getAttributes, member)[0].name : member.stringof);
                static if (!(__traits(getAttributes, member)[0].low == __traits(getAttributes, member)[0].low)) {
                    number(mixin("data.", member.stringof), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 1 : cast(int) __traits(getAttributes, member)[0].step);
                } else {
                    slider(
                        mixin("data.", member.stringof),
                        cast(int) __traits(getAttributes, member)[0].low,
                        cast(int) __traits(getAttributes, member)[0].high,
                        !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 1 : cast(int) __traits(getAttributes, member)[0].step,
                        muNumberFmt,
                        MuOptFlag.alignCenter,
                    );
                }
            }
        // Without data.
        } else {
            if (canShowPrivateMembers || (!is(__traits(getAttributes, member)[0] == UiPrivate) && !is(typeof(__traits(getAttributes, member)[0]) == UiPrivate))) {
                static if (__traits(hasMember, typeof(member), "x") && __traits(hasMember, typeof(member), "y") && __traits(hasMember, typeof(member), "z") && __traits(hasMember, typeof(member), "w")) {
                    static if (is(typeof(mixin("data.", member.stringof, ".x")) == float) || is(typeof(mixin("data.", member.stringof, ".x")) == int)) {
                        row(0, labelWidth,
                            (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 4 - uiStyle.spacing - uiStyle.border,
                            (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 4 - uiStyle.spacing - uiStyle.border,
                            (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 4 - uiStyle.spacing - uiStyle.border,
                            -1,
                        );
                        label(member.stringof);
                        number(mixin("data.", member.stringof, ".x"));
                        number(mixin("data.", member.stringof, ".y"));
                        number(mixin("data.", member.stringof, ".z"));
                        number(mixin("data.", member.stringof, ".w"));
                        row(0, labelWidth, -1);
                    }
                } else static if (__traits(hasMember, typeof(member), "x") && __traits(hasMember, typeof(member), "y") && __traits(hasMember, typeof(member), "z")) {
                    static if (is(typeof(mixin("data.", member.stringof, ".x")) == float) || is(typeof(mixin("data.", member.stringof, ".x")) == int)) {
                        row(0, labelWidth,
                            (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 3 - uiStyle.spacing - uiStyle.border,
                            (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 3 - uiStyle.spacing - uiStyle.border,
                            -1,
                        );
                        label(member.stringof);
                        number(mixin("data.", member.stringof, ".x"));
                        number(mixin("data.", member.stringof, ".y"));
                        number(mixin("data.", member.stringof, ".z"));
                        row(0, labelWidth, -1);
                    }
                } else static if (__traits(hasMember, typeof(member), "x") && __traits(hasMember, typeof(member), "y")) {
                    static if (is(typeof(mixin("data.", member.stringof, ".x")) == float) || is(typeof(mixin("data.", member.stringof, ".x")) == int)) {
                        row(0, labelWidth,
                            (window.rect.w - labelWidth - uiStyle.spacing - uiStyle.border) / 2 - uiStyle.spacing - uiStyle.border,
                            -1,
                        );
                        label(member.stringof);
                        number(mixin("data.", member.stringof, ".x"));
                        number(mixin("data.", member.stringof, ".y"));
                        row(0, labelWidth, -1);
                    }
                } else static if (is(typeof(member) == bool)) {
                    label(member.stringof);
                    checkbox(mixin("data.", member.stringof));
                } else static if (is(typeof(member) == float) || is(typeof(member) == int)) {
                    label(member.stringof);
                    number(mixin("data.", member.stringof));
                }
            }
        }
    }
    row(0, 0);
}

UiResFlags headerAndMembers(T)(ref T data, int labelWidth, IStr label = "", bool canShowPrivateMembers = false) {
    auto result = header(label.length ? label : typeof(data).stringof);
    if (result) members(data, labelWidth, canShowPrivateMembers);
    row(0, 0);
    return result;
}

UiResFlags beginTreeNode(IStr label, UiOptFlags opt = UiOptFlag.none) {
    return uiContext.beginTreeNode(label, opt);
}

void endTreeNode() {
    uiContext.endTreeNode();
}

UiResFlags beginWindow(IStr title, UiRect rect, UiOptFlags opt = UiOptFlag.none) {
    return uiContext.beginWindow(title, rect, opt);
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

UiResFlags beginDMenu(ref IStr selection, const(IStr)[] items, UiVec canvas, IStr label = "", UiFVec scale = UiFVec(0.5f, 0.7f)) {
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
            uiStyle.size = UiVec(cast(int) (size * 6), cast(int) (size + lerp(-4, 0, t)));
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
                    cmd.text.str.ptr[0 .. cmd.text.len],
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
                auto iconDiff = UiVec(cmd.icon.rect.w - iconAtlasArea.w, cmd.icon.rect.h - iconAtlasArea.h);
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
alias beginUi = beginUiFrame;

/// Ends UI processing and performs drawing.
void endUiFrame() {
    endUiCore();
    drawUiState();
}

/// The old name of the `endUiFrame` function.
alias endUi = endUiFrame;
