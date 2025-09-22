// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// ---

// TODO: Add more doc comments.
// TODO: work on attributes maybe.

/// High-level wrapper around the low-level `core` module.
/// Provides helper functions that use a global context and follow D naming conventions.
module parin.extras.microui.wrapper;

import parin.extras.microui.core;

__gshared UiContext uiContext;

alias UiTextWidthFunc  = mu_TextWidthFunc;  /// Used for getting the width of the text.
alias UiTextHeightFunc = mu_TextHeightFunc; /// Used for getting the height of the text.
alias UiDrawFrameFunc  = mu_DrawFrameFunc;  /// Used for drawing a frame.

alias UiReal      = mu_Real;      /// The floating-point type of microui.
alias UiId        = mu_Id;        /// The control ID type of microui.
alias UiFont      = mu_Font;      /// The font type of microui.
alias UiTexture   = mu_Texture;   /// The texture type of microui.
alias UiSliceMode = mu_SliceMode; /// The slice repeat mode type of microui.

alias UiResFlags   = mu_ResFlags;   /// The type of `UiResFlag`.
alias UiOptFlags   = mu_OptFlags;   /// The type of `UiOptFlag`.
alias UiMouseFlags = mu_MouseFlags; /// The type of `UiMouseFlag`.
alias UiKeyFlags   = mu_KeyFlags;   /// The type of `UiKeyFlag`.

alias UiColor      = mu_Color;      /// A RGBA color using ubytes.
alias UiRect       = mu_Rect;       /// A 2D rectangle using ints.
alias UiVec        = mu_Vec2;       /// A 2D vector using ints.
alias UiFVec       = mu_FVec2;      /// A 2D vector using floats.
alias UiMargin     = mu_Margin;     /// A set of 4 integer margins for left, top, right, and bottom.
alias UiSlicePart  = mu_SlicePart;  /// A part of a 9-slice with source and target rectangles for drawing.
alias UiSliceParts = mu_SliceParts; /// The parts of a 9-slice.

alias UiPoolItem    = mu_PoolItem;    /// A pool item.
alias UiBaseCommand = mu_BaseCommand; /// Base structure for all render commands, containing type and size metadata.
alias UiJumpCommand = mu_JumpCommand; /// Command to jump to another location in the command buffer.
alias UiClipCommand = mu_ClipCommand; /// Command to set a clipping rectangle.
alias UiRectCommand = mu_RectCommand; /// Command to draw a rectangle with a given color.
alias UiTextCommand = mu_TextCommand; /// Command to render text at a given position with a font and color. The text is a null-terminated string. Use `str.ptr` to access it.
alias UiIconCommand = mu_IconCommand; /// Command to draw an icon inside a rectangle with a given color.
alias UiCommand     = mu_Command;     /// A union of all possible render commands.

alias UiLayout    = mu_Layout;    /// Layout state used to position UI controls within a container.
alias UiContainer = mu_Container; /// A UI container holding commands.
alias UiStyle     = mu_Style;     /// UI style settings including font, sizes, spacing, and colors.
alias UiContext   = mu_Context;   /// The main UI context.

alias computeUiSliceParts = mu_compute_slice_parts;

enum UiClipEnum : mu_ClipEnum {
    none = MU_CLIP_NONE, /// No clipping.
    part = MU_CLIP_PART, /// Partial clipping (for scrollable areas).
    all  = MU_CLIP_ALL,  /// Full clipping to container bounds.
}

enum UiCommandEnum : mu_CommandEnum {
    none = MU_COMMAND_NONE, /// No command.
    jump = MU_COMMAND_JUMP, /// Jump to another command in the buffer.
    clip = MU_COMMAND_CLIP, /// Set a clipping region.
    rect = MU_COMMAND_RECT, /// Draw a rectangle.
    text = MU_COMMAND_TEXT, /// Draw text.
    icon = MU_COMMAND_ICON, /// Draw an icon.
}

enum UiColorEnum : mu_ColorEnum {
    text        = MU_COLOR_TEXT,        /// Default text color.
    border      = MU_COLOR_BORDER,      /// Border color for controls.
    windowBg    = MU_COLOR_WINDOWBG,    /// Background color of windows.
    titleBg     = MU_COLOR_TITLEBG,     /// Background color of window titles.
    titleText   = MU_COLOR_TITLETEXT,   /// Text color for window titles.
    panelBg     = MU_COLOR_PANELBG,     /// Background color of panels.
    button      = MU_COLOR_BUTTON,      /// Default button color.
    buttonHover = MU_COLOR_BUTTONHOVER, /// Button color on hover.
    buttonFocus = MU_COLOR_BUTTONFOCUS, /// Button color when focused.
    base        = MU_COLOR_BASE,        /// Base background for text input or sliders.
    baseHover   = MU_COLOR_BASEHOVER,   /// Hover color for base controls.
    baseFocus   = MU_COLOR_BASEFOCUS,   /// Focus color for base controls.
    scrollBase  = MU_COLOR_SCROLLBASE,  /// Background of scrollbars.
    scrollThumb = MU_COLOR_SCROLLTHUMB, /// Scrollbar thumb color.
}

enum UiIconEnum : mu_IconEnum {
    none      = MU_ICON_NONE,      /// No icon.
    close     = MU_ICON_CLOSE,     /// Close icon.
    check     = MU_ICON_CHECK,     /// Checkmark icon.
    collapsed = MU_ICON_COLLAPSED, /// Collapsed tree icon.
    expanded  = MU_ICON_EXPANDED,  /// Expanded tree icon.
}

enum UiAtlasEnum : mu_AtlasEnum {
    none        = MU_ATLAS_NONE,        /// No atlas rectangle.
    button      = MU_ATLAS_BUTTON,      /// Default button atlas rectangle.
    buttonHover = MU_ATLAS_BUTTONHOVER, /// Button atlas rectangle on hover.
    buttonFocus = MU_ATLAS_BUTTONFOCUS, /// Button atlas rectangle when focused.
}

enum UiResFlag : UiResFlags {
    none   = MU_RES_NONE,   /// No result.
    active = MU_RES_ACTIVE, /// Control is active (e.g., active window).
    submit = MU_RES_SUBMIT, /// Control value submitted (e.g., clicked button).
    change = MU_RES_CHANGE, /// Control value changed (e.g., modified text input).
}

enum UiOptFlag : UiOptFlags {
    none         = MU_OPT_NONE,         /// No option.
    alignCenter  = MU_OPT_ALIGNCENTER,  /// Center-align control content.
    alignRight   = MU_OPT_ALIGNRIGHT,   /// Right-align control content.
    noInteract   = MU_OPT_NOINTERACT,   /// Disable interaction.
    noFrame      = MU_OPT_NOFRAME,      /// Draw control without a frame.
    noResize     = MU_OPT_NORESIZE,     /// Disable resizing for windows.
    noScroll     = MU_OPT_NOSCROLL,     /// Disable scrolling for containers.
    noClose      = MU_OPT_NOCLOSE,      /// Remove close button from window.
    noTitle      = MU_OPT_NOTITLE,      /// Remove title bar from window.
    holdFocus    = MU_OPT_HOLDFOCUS,    /// Keep control focused after click.
    autoSize     = MU_OPT_AUTOSIZE,     /// Window automatically sizes to content. Implies `MU_OPT_NORESIZE` and `MU_OPT_NOSCROLL`.
    popup        = MU_OPT_POPUP,        /// Marks window as popup (e.g., closed on mouse click).
    closed       = MU_OPT_CLOSED,       /// Window starts closed.
    expanded     = MU_OPT_EXPANDED,     /// Window starts expanded.
    noName       = MU_OPT_NONAME,       /// Hides window name.
    defaultFocus = MU_OPT_DEFAULTFOCUS, /// Keep focus when no other control is focused.
}

enum UiMouseFlag : UiMouseFlags {
    none   = MU_MOUSE_NONE,   /// No mouse button.
    left   = MU_MOUSE_LEFT,   /// Left mouse button.
    right  = MU_MOUSE_RIGHT,  /// Right mouse button.
    middle = MU_MOUSE_MIDDLE, /// Middle mouse button.
}

enum UiKeyFlag : mu_KeyFlags {
    none      = MU_KEY_NONE,      /// No key.
    shift     = MU_KEY_SHIFT,     /// Shift key down.
    ctrl      = MU_KEY_CTRL,      /// Control key down.
    alt       = MU_KEY_ALT,       /// Alt key down.
    backspace = MU_KEY_BACKSPACE, /// Backspace key down.
    enter     = MU_KEY_RETURN,    /// Return key down.
    tab       = MU_KEY_TAB,       /// Tab key down.
    left      = MU_KEY_LEFT,      /// Left key down.
    right     = MU_KEY_RIGHT,     /// Right key down.
    up        = MU_KEY_UP,        /// Up key down.
    down      = MU_KEY_DOWN,      /// Down key down.
    home      = MU_KEY_HOME,      /// Home key down.
    end       = MU_KEY_END,       /// End key down.
    pageUp    = MU_KEY_PAGEUP,    /// Page up key up.
    pageDown  = MU_KEY_PAGEDOWN,  /// Page down key down.
    f1        = MU_KEY_F1,        /// F1 key down.
    f2        = MU_KEY_F2,        /// F2 key down.
    f3        = MU_KEY_F3,        /// F3 key down.
    f4        = MU_KEY_F4,        /// F4 key down.
}

/// Used by the `members` function to hide data.
struct UiPrivate {}

/// Used by the `members` function to show data in a specific way.
struct UiMember {
    const(char)[] name; /// The name of the member.
    UiReal low;         /// Used by sliders.
    UiReal high;        /// Used by sliders.
    UiReal step;        /// Used by sliders.

    @safe nothrow @nogc pure:

    this(UiReal low, UiReal high, UiReal step = UiReal.nan) {
        this.low = low;
        this.high = high;
        this.step = step;
    }

    this(UiReal step) {
        this.step = step;
    }

    this(const(char)[] name, UiReal low, UiReal high, UiReal step = UiReal.nan) {
        this.name = name;
        this.low = low;
        this.high = high;
        this.step = step;
    }

    this(const(char)[] name, UiReal step = UiReal.nan) {
        this.name = name;
        this.step = step;
    }
}

@trusted:

nothrow @nogc
ref UiStyle* uiStyle() {
    return uiContext.style;
}

nothrow @nogc
void readyUiCore(UiFont font = null, int fontScale = 1) {
    mu_init(&uiContext, font, fontScale);
}

nothrow @nogc
void readyUiCore(UiTextWidthFunc width, UiTextHeightFunc height, UiFont font = null, int fontScale = 1) {
    mu_init_with_funcs(&uiContext, width, height, font, fontScale);
}

void beginUiCore() {
    mu_begin(&uiContext);
}

void endUiCore() {
    mu_end(&uiContext);
}

void setUifocus(UiId id) {
    mu_set_focus(&uiContext, id);
}

UiId getUiId(const(void)* data, size_t size) {
    return mu_get_id(&uiContext, data, size);
}

UiId getUiId(const(char)[] str) {
    return mu_get_id_str(&uiContext, str);
}

void pushUiId(const(void)* data, size_t size) {
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

int readyUiPool(UiPoolItem* items, size_t len, UiId id) {
    return mu_pool_init(&uiContext, items, len, id);
}

int getFromUiPool(UiPoolItem* items, size_t len, UiId id) {
    return mu_pool_get(&uiContext, items, len, id);
}

void updateUiPool(UiPoolItem* items, size_t idx) {
    mu_pool_update(&uiContext, items, idx);
}

/*============================================================================
** input handlers
**============================================================================*/

nothrow @nogc {
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
}

/*============================================================================
** commandlist
**============================================================================*/

UiCommand* pushUiCommand(UiCommandEnum type, size_t size) {
    return mu_push_command(&uiContext, type, size);
}

bool nextUiCommand(UiCommand** cmd) {
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

void drawUiText(mu_Font font, const(char)[] str, UiVec point, UiColor color) {
    mu_draw_text(&uiContext, font, str, point, color);
}

void drawUiIcon(UiIconEnum id, UiRect rect, UiColor color) {
    mu_draw_icon(&uiContext, id, rect, color);
}

/*============================================================================
** layout
**============================================================================*/

deprecated("Use `beginColumn` instead.") alias beginUiColumn = beginColumn;
void beginColumn() {
    mu_layout_begin_column(&uiContext);
}

deprecated("Use `endColumn` instead.") alias endUiColumn = endColumn;
void endColumn() {
    mu_layout_end_column(&uiContext);
}

deprecated("Use `row` instead.") alias uiRow = row;
void row(int height, const(int)[] widths...) {
    mu_layout_row(&uiContext, height, widths);
}

deprecated("Use `setLayoutWidth` instead.") alias setUiLayoutWidth = setLayoutWidth;
void setLayoutWidth(int width) {
    mu_layout_width(&uiContext, width);
}

deprecated("Use `setLayoutHeight` instead.") alias setUiLayoutHeight = setLayoutHeight;
void setLayoutHeight(int height) {
    mu_layout_height(&uiContext, height);
}

deprecated("Use `setNextLayout` instead.") alias setNextUiLayout = setNextLayout;
void setNextLayout(UiRect rect, bool relative) {
    mu_layout_set_next(&uiContext, rect, relative);
}

deprecated("Use `nextLayout` instead.") alias nextUiLayout = nextLayout;
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

UiResFlags checkbox(ref bool state, const(char)[] label = "") {
    return mu_checkbox(&uiContext, label, &state);
}

UiResFlags textbox(char[] buffer, UiOptFlags opt, size_t* newlen = null) {
    return mu_textbox_ex(&uiContext, buffer, opt, newlen);
}

UiResFlags textbox(char[] buffer, size_t* newlen = null) {
    return mu_textbox(&uiContext, buffer, newlen);
}

UiResFlags slider(ref UiReal value, UiReal low, UiReal high, UiReal step, const(char)[] fmt, UiOptFlags opt) {
    return mu_slider_ex(&uiContext, &value, low, high, step, fmt, opt);
}

UiResFlags slider(ref int value, int low, int high, int step, const(char)[] fmt, UiOptFlags opt) {
    return mu_slider_ex_int(&uiContext, &value, low, high, step, fmt, opt);
}

UiResFlags slider(ref UiReal value, UiReal low, UiReal high) {
    return mu_slider(&uiContext, &value, low, high);
}

UiResFlags slider(ref int value, int low, int high) {
    return mu_slider_int(&uiContext, &value, low, high);
}

UiResFlags number(ref UiReal value, UiReal step, const(char)[] fmt, UiOptFlags opt) {
    return mu_number_ex(&uiContext, &value, step, fmt, opt);
}

UiResFlags number(ref int value, int step, const(char)[] fmt, UiOptFlags opt) {
    return mu_number_ex_int(&uiContext, &value, step, fmt, opt);
}

UiResFlags number(ref UiReal value, UiReal step = 0.01f) {
    return mu_number(&uiContext, &value, step);
}

UiResFlags number(ref int value, int step = 1) {
    return mu_number_int(&uiContext, &value, step);
}

UiResFlags header(const(char)[] label, UiOptFlags opt) {
    return mu_header_ex(&uiContext, label, opt);
}

UiResFlags header(const(char)[] label) {
    return mu_header(&uiContext, label);
}

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
                static if (is(typeof(mixin("data.", member.stringof, ".x")) == UiReal)) {
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
                static if (is(typeof(mixin("data.", member.stringof, ".x")) == UiReal)) {
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
                static if (is(typeof(mixin("data.", member.stringof, ".x")) == UiReal)) {
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
            } else static if (is(typeof(member) == UiReal)) {
                label(__traits(getAttributes, member)[0].name.length ? __traits(getAttributes, member)[0].name : member.stringof);
                static if (!(__traits(getAttributes, member)[0].low == __traits(getAttributes, member)[0].low)) {
                    number(mixin("data.", member.stringof), !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step);
                } else {
                    slider(
                        mixin("data.", member.stringof),
                        __traits(getAttributes, member)[0].low,
                        __traits(getAttributes, member)[0].high,
                        !(__traits(getAttributes, member)[0].step == __traits(getAttributes, member)[0].step) ? 0.01f : __traits(getAttributes, member)[0].step,
                        MU_SLIDER_FMT,
                        MU_OPT_ALIGNCENTER,
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
                        MU_SLIDER_INT_FMT,
                        MU_OPT_ALIGNCENTER,
                    );
                }
            }
        // Without data.
        } else {
            if (canShowPrivateMembers || (!is(__traits(getAttributes, member)[0] == UiPrivate) && !is(typeof(__traits(getAttributes, member)[0]) == UiPrivate))) {
                static if (__traits(hasMember, typeof(member), "x") && __traits(hasMember, typeof(member), "y") && __traits(hasMember, typeof(member), "z") && __traits(hasMember, typeof(member), "w")) {
                    static if (is(typeof(mixin("data.", member.stringof, ".x")) == UiReal) || is(typeof(mixin("data.", member.stringof, ".x")) == int)) {
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
                    static if (is(typeof(mixin("data.", member.stringof, ".x")) == UiReal) || is(typeof(mixin("data.", member.stringof, ".x")) == int)) {
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
                    static if (is(typeof(mixin("data.", member.stringof, ".x")) == UiReal) || is(typeof(mixin("data.", member.stringof, ".x")) == int)) {
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
                } else static if (is(typeof(member) == UiReal) || is(typeof(member) == int)) {
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

UiResFlags beginDMenu(ref const(char)[] selection, const(const(char)[])[] items, UiVec canvas, const(char)[] label = "", UiFVec scale = UiFVec(0.5f, 0.7f)) {
    return mu_begin_dmenu(&uiContext, &selection, items, canvas, label, scale);
}

void endDMenu() {
    mu_end_dmenu(&uiContext);
}
