// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// ---

// TODO: Add more doc comments.
// TODO: work on attributes maybe.

/// High-level wrapper around the low-level `core` module.
/// Provides helper functions that use a global context and follow D naming conventions.
module parin.addons.microui.wrapper;

import parin.joka.microui;
import parin.engine;

UiContext uiContext;

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
    const(char)[] name; /// The name of the member.
    float low;         /// Used by sliders.
    float high;        /// Used by sliders.
    float step;        /// Used by sliders.

    @safe nothrow @nogc pure:

    this(float low, float high, float step = float.nan) {
        this.low = low;
        this.high = high;
        this.step = step;
    }

    this(float step) {
        this.step = step;
    }

    this(const(char)[] name, float low, float high, float step = float.nan) {
        this.name = name;
        this.low = low;
        this.high = high;
        this.step = step;
    }

    this(const(char)[] name, float step = float.nan) {
        this.name = name;
        this.step = step;
    }
}

@safe nothrow @nogc:

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

UiId getUiId(const(char)[] str) {
    return mu_get_id_str(&uiContext, str);
}

void pushUiId(const(void)* data, Sz size) {
    mu_push_id(&uiContext, data, size);
}

void pushUiId(const(char)[] str) {
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

UiContainer* getUiContainer(const(char)[] name) {
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

void uiInputText(const(char)[] text) {
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

void drawUiText(UiFont font, const(char)[] str, UiVec point, UiColor color) {
    mu_draw_text(&uiContext, font, str, point, color);
}

void drawUiIcon(UiIconEnum id, UiRect rect, UiColor color) {
    mu_draw_icon(&uiContext, id, rect, color);
}

/*============================================================================
** layout
**============================================================================*/

void beginColumn() {
    mu_layout_begin_column(&uiContext);
}

void endColumn() {
    mu_layout_end_column(&uiContext);
}

void row(int height, const(int)[] widths...) {
    mu_layout_row(&uiContext, height, widths);
}

void setLayoutWidth(int width) {
    mu_layout_width(&uiContext, width);
}

void setLayoutHeight(int height) {
    mu_layout_height(&uiContext, height);
}

void setNextLayout(UiRect rect, bool relative) {
    mu_layout_set_next(&uiContext, rect, relative);
}

UiRect nextLayout() {
    return mu_layout_next(&uiContext);
}

/*============================================================================
** controls
**============================================================================*/

void drawControlFrame(UiId id, UiRect rect, UiColorEnum colorId, UiOptFlags opt, UiAtlasEnum atlasId = UiAtlasEnum.none) {
    mu_draw_control_frame(&uiContext, id, rect, colorId, opt, atlasId);
}

void drawControlText(const(char)[] text, UiRect rect, UiColorEnum colorId, UiOptFlags opt) {
    mu_draw_control_text(&uiContext, text, rect, colorId, opt);
}

bool isUiMouseOver(UiRect rect) {
    return mu_mouse_over(&uiContext, rect);
}

void updateControl(UiId id, UiRect rect, UiOptFlags opt) {
    mu_update_control(&uiContext, id, rect, opt);
}

void text(const(char)[] text) {
    mu_text(&uiContext, text);
}

void label(const(char)[] text) {
    mu_label(&uiContext, text);
}

UiResFlags button(const(char)[] label, UiIconEnum icon, UiOptFlags opt) {
    return mu_button_ex(&uiContext, label, icon, opt);
}

UiResFlags button(const(char)[] label) {
    return mu_button(&uiContext, label);
}

@trusted
UiResFlags checkbox(ref bool state, const(char)[] label = "") {
    return mu_checkbox(&uiContext, label, &state);
}

UiResFlags textbox(char[] buffer, UiOptFlags opt, Sz* newlen = null) {
    return mu_textbox_ex(&uiContext, buffer, opt, newlen);
}

UiResFlags textbox(char[] buffer, Sz* newlen = null) {
    return mu_textbox(&uiContext, buffer, newlen);
}

@trusted
UiResFlags slider(ref float value, float low, float high, float step, const(char)[] fmt, UiOptFlags opt) {
    return mu_slider_ex(&uiContext, &value, low, high, step, fmt, opt);
}

@trusted
UiResFlags slider(ref int value, int low, int high, int step, const(char)[] fmt, UiOptFlags opt) {
    return mu_slider_ex_int(&uiContext, &value, low, high, step, fmt, opt);
}

@trusted
UiResFlags slider(ref float value, float low, float high) {
    return mu_slider(&uiContext, &value, low, high);
}

@trusted
UiResFlags slider(ref int value, int low, int high) {
    return mu_slider_int(&uiContext, &value, low, high);
}

@trusted
UiResFlags number(ref float value, float step, const(char)[] fmt, UiOptFlags opt) {
    return mu_number_ex(&uiContext, &value, step, fmt, opt);
}

@trusted
UiResFlags number(ref int value, int step, const(char)[] fmt, UiOptFlags opt) {
    return mu_number_ex_int(&uiContext, &value, step, fmt, opt);
}

@trusted
UiResFlags number(ref float value, float step = 0.01f) {
    return mu_number(&uiContext, &value, step);
}

@trusted
UiResFlags number(ref int value, int step = 1) {
    return mu_number_int(&uiContext, &value, step);
}

UiResFlags header(const(char)[] label, UiOptFlags opt) {
    return mu_header_ex(&uiContext, label, opt);
}

UiResFlags header(const(char)[] label) {
    return mu_header(&uiContext, label);
}

// TODO: Needs cleaning. It looks likes this because I just wanted to get something to work.
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

UiResFlags headerAndMembers(T)(ref T data, int labelWidth, const(char)[] label = "", bool canShowPrivateMembers = false) {
    auto result = header(label.length ? label : typeof(data).stringof);
    if (result) members(data, labelWidth, canShowPrivateMembers);
    row(0, 0);
    return result;
}

UiResFlags beginTreeNode(const(char)[] label, UiOptFlags opt) {
    return mu_begin_treenode_ex(&uiContext, label, opt);
}

UiResFlags beginTreeNode(const(char)[] label) {
    return mu_begin_treenode(&uiContext, label);
}

void endTreeNode() {
    mu_end_treenode(&uiContext);
}

UiResFlags beginWindow(const(char)[] title, UiRect rect, UiOptFlags opt) {
    return mu_begin_window_ex(&uiContext, title, rect, opt);
}

UiResFlags beginWindow(const(char)[] title, UiRect rect) {
    return mu_begin_window(&uiContext, title, rect);
}

void endWindow() {
    mu_end_window(&uiContext);
}

void openPopup(const(char)[] name) {
    mu_open_popup(&uiContext, name);
}

UiResFlags beginPopup(const(char)[] name) {
    return mu_begin_popup(&uiContext, name);
}

void endPopup() {
    mu_end_popup(&uiContext);
}

void beginPanel(const(char)[] name, UiOptFlags opt) {
    mu_begin_panel_ex(&uiContext, name, opt);
}

void beginPanel(const(char)[] name) {
    mu_begin_panel(&uiContext, name);
}

void endPanel() {
    mu_end_panel(&uiContext);
}

void openDMenu() {
    mu_open_dmenu(&uiContext);
}

@trusted
UiResFlags beginDMenu(ref const(char)[] selection, const(const(char)[])[] items, UiVec canvas, const(char)[] label = "", UiFVec scale = UiFVec(0.5f, 0.7f)) {
    return mu_begin_dmenu(&uiContext, &selection, items, canvas, label, scale);
}

void endDMenu() {
    mu_end_dmenu(&uiContext);
}

@trusted
int microuiTempUiTextWidthFunc(UiFont font, const(char)[] str) {
    auto data = cast(FontId*) font;
    return cast(int) measureTextSize(
        *data,
        str,
        DrawOptions(Vec2(uiStyle.fontScale, uiStyle.fontScale)),
        TextOptions()
    ).x;
}

@trusted
int microuiTempUiTextHeightFunc(UiFont font) {
    auto data = cast(FontId*) font;
    return data.size * uiStyle.fontScale;
}

/// Initializes the microui context and sets temporary text size functions. Value `font` should be a `FontId*`.
@trusted
void readyUi(UiFont font = null, int fontScale = 1) {
    auto data = font ? cast(FontId*) font : &_engineState.defaultFont;
    readyUiCore(&microuiTempUiTextWidthFunc, &microuiTempUiTextHeightFunc, data, fontScale);
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
void readyUi(int fontScale) {
    readyUi(null, fontScale);
}

/// Initializes the microui context and sets temporary text size functions.
void readyUi(FontId font, int fontScale = 1) {
    static readyUiFont = FontId();
    readyUiFont = font;
    readyUi(&readyUiFont, fontScale);
}

/// Initializes the microui context and sets custom text size functions. Value `font` should be a `FontId*`.
void readyUi(UiTextWidthFunc width, UiTextHeightFunc height, UiFont font = null, int fontScale = 1) {
    readyUi(font, fontScale);
    uiContext.textWidth = width;
    uiContext.textHeight = height;
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
                auto atlasRect = uiStyle.atlasRects[cmd.rect.id];
                if (styleTexture && atlasRect.hasSize) {
                    auto sliceMargin = uiStyle.sliceMargins[cmd.rect.id];
                    auto sliceMode = uiStyle.sliceModes[cmd.rect.id];
                    foreach (i, ref part; computeSliceParts(atlasRect, cmd.rect.rect, sliceMargin)) {
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
            case UiCommand.icon:
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
