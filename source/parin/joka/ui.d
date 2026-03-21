// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

// NOTE: Last time I was working on buttons, layout and rendering.
//   They work. The buttons are not done.

/// The `ui` module includes a UI library.
module parin.joka.ui;

import parin.joka.math;
import parin.joka.types;

version (JokaSmallFootprint) {
    enum defaultUiCommandsCapacity = 128;
} else {
    enum defaultUiCommandsCapacity = 512;
}

/// The UI font type.
alias UiFont = void*;
/// The UI texture type.
alias UiTexture = void*;
/// A function used for getting the width of the text.
alias UiTextWidthFunc  = int function(UiFont font, IStr text);
/// A function used for getting the height of the text.
alias UiTextHeightFunc = int function(UiFont font);

enum UiColorType : ubyte {
    border,       /// Default border color.
    text,         /// Default text color.
    button,       /// Default button color.
    buttonHover,  /// Button color on hover.
    buttonActive, /// Button color on press.
    buttonFocus,  /// Button color on focus.
}

alias UiColors = StaticArray!(Rgba, UiColorType.max + 1);

/// UI style including things like colors.
struct UiStyle {
    UiFont font;
    UiTexture texture;
    UiColors colors;
    int fontScale;
    int border;
}

alias UiMouseButtonFlags = ubyte;
enum UiMouseButtonFlag : UiMouseButtonFlags {
    none   = 0x0,
    left   = 0x1,
    right  = 0x2,
    middle = 0x4,
}

struct UiInput {
    IVec2 mousePosition;
    UiMouseButtonFlags mouseButtonDown;
    UiMouseButtonFlags mouseButtonPressed;

    @safe nothrow @nogc:

    void clear() {
        this = UiInput();
    }
}

alias UiCommandFlags = ubyte;
enum UiCommandFlag : UiCommandFlags {
    none   = 0x0,
    hover  = 0x1,
    active = 0x2,
    focus  = 0x4,
    border = 0x8,
}

enum UiCommandType : ubyte {
    none,
    rect,
}

struct UiCommandBase {
    UiCommandType type;
}

struct UiCommandRect {
    UiCommandBase base;
    UiCommandFlags flags;
    UiColorType colorType;
    IRect data;
    alias data this;
}

union UiCommand {
    UiCommandType type;
    UiCommandBase base;
    UiCommandRect rect;
}

struct UiCommands {
    StaticArray!(UiCommand, defaultUiCommandsCapacity) data = void;
    Sz length;
    alias items this;

    @safe nothrow @nogc:

    pragma(inline, true) @trusted
    UiCommand[] items() {
        return data.ptr[0 .. length];
    }

    enum capacity = defaultUiCommandsCapacity;

    bool appendBlank() {
        if (length >= capacity) return true;
        length += 1;
        return false;
    }

    @trusted
    bool appendRef(ref UiCommand command) {
        auto error = appendBlank();
        if (!error) data.ptr[length - 1] = command;
        return error;
    }

    void clear() {
        length = 0;
    }

    bool nextIsRectWith(Sz i, UiCommandFlags flags) {
        if (i + 1 >= length) return false;
        auto next = &items[i + 1];
        return next.type == UiCommandType.rect && next.rect.flags & flags;
    }
}

alias UiControlFlags = ubyte;
enum UiControlFlag : UiControlFlags {
    none      = 0x00, /// None.
    active    = 0x01, /// Control is active (e.g. button down).
    submitted = 0x02, /// Control value submitted (e.g. clicked button).
    changed   = 0x04, /// Control value changed (e.g. modified text input).
}

struct UiLayout {
    UiContext* context;
    IRect area;
    short slice;
    short spacing;
    bool isVertical;
    bool isFlipped;

    @safe nothrow @nogc:

    UiControlFlags button(IStr label, bool span = false) {
        if (!area.hasSize) return UiControlFlags();
        if (span) {
            return isVertical ? context.button(area.subTop(area.h), label) : context.button(area.subLeft(area.w), label);
        }
        if (isVertical) {
            return context.button(isFlipped ? area.subBottom(slice, spacing) : area.subTop(slice, spacing), label);
        } else {
            return context.button(isFlipped ? area.subRight(slice, spacing) : area.subLeft(slice, spacing), label);
        }
    }
}

struct UiContext {
    UiCommands commands;
    UiTextWidthFunc textWidth;   /// The function used for getting the width of the text.
    UiTextHeightFunc textHeight; /// The function used for getting the height of the text.
    UiStyle* style;
    UiStyle _style;
    UiInput input;

    @safe nothrow @nogc:

    this(UiTextWidthFunc textWidth, UiTextHeightFunc textHeight, UiFont font, int fontScale = 1) {
        ready(textWidth, textHeight, font, fontScale);
    }

    void ready(UiTextWidthFunc textWidth, UiTextHeightFunc textHeight, UiFont font, int fontScale = 1) {
        restoreDefaultStyle();
        applyDefaultStyle();
        style.font = font;
        style.fontScale = fontScale;
    }

    void applyDefaultStyle() {
        with (UiColorType) {
            style.colors[border]       = Rgba(40,  44,  52,  255);
            style.colors[text]         = Rgba(210, 215, 225, 255);
            style.colors[button]       = Rgba(55,  61,  72,  255);
            style.colors[buttonHover]  = Rgba(70,  78,  92,  255);
            style.colors[buttonActive] = Rgba(79,  140, 255, 255);
            style.colors[buttonFocus]  = Rgba(79,  140, 255, 255);
        }
        style.border = 1;

        // A color palette made by a really nice AI. We trust AI. We love AI. We believe in AI.
        // mu_Array!(mu_Color, 14)(
        //    mu_Color(210, 215, 225, 255), /* MU_COLOR_TEXT - Soft off-white */
        //    mu_Color(40,  44,  52,  255), /* MU_COLOR_BORDER - Darker, integrated border */
        //    mu_Color(28,  32,  40,  255), /* MU_COLOR_WINDOWBG - Deep navy-slate */
        //    mu_Color(35,  39,  48,  255), /* MU_COLOR_TITLEBG - Slightly lighter than window */
        //    mu_Color(255, 255, 255, 255), /* MU_COLOR_TITLETEXT - Pure white for clarity */
        //    mu_Color(0,   0,   0,   0  ), /* MU_COLOR_PANELBG */
        //    mu_Color(55,  61,  72,  255), /* MU_COLOR_BUTTON - Muted slate */
        //    mu_Color(70,  78,  92,  255), /* MU_COLOR_BUTTONHOVER - Subtle highlight */
        //    mu_Color(79,  140, 255, 255), /* MU_COLOR_BUTTONFOCUS - Cobalt Accent */
        //    mu_Color(33,  37,  46,  255), /* MU_COLOR_BASE - Input fields / track */
        //    mu_Color(45,  50,  60,  255), /* MU_COLOR_BASEHOVER */
        //    mu_Color(79,  140, 255, 255), /* MU_COLOR_BASEFOCUS - Cobalt Accent */
        //    mu_Color(38,  42,  51,  255), /* MU_COLOR_SCROLLBASE */
        //    mu_Color(65,  72,  85,  255), /* MU_COLOR_SCROLLTHUMB */
        // )
    }

    void restoreDefaultStyle() {
        style = &_style;
    }

    @trusted
    UiLayout row(IRect area, int count, int spacing, bool isFlipped = false) {
        return UiLayout(&this, area, cast(short) area.sliceX(count, spacing), cast(short) spacing, false, isFlipped);
    }

    @trusted
    UiLayout column(IRect area, int count, int spacing, bool isFlipped = false) {
        return UiLayout(&this, area, cast(short) area.sliceY(count, spacing), cast(short) spacing, true, isFlipped);
    }

    @trusted
    void drawRect(IRect area, UiColorType colorType, bool hover, bool active, bool focus, bool border) {
        auto command = UiCommand();
        command.base.type = UiCommandType.rect;
        command.rect.data = area;
        command.rect.colorType = colorType;
        if (hover)  command.rect.flags |= UiCommandFlag.hover;
        if (active) command.rect.flags |= UiCommandFlag.active;
        if (focus)  command.rect.flags |= UiCommandFlag.focus;
        if (border) command.rect.flags |= UiCommandFlag.border;
        commands.appendRef(command);
    }

    void begin() {
        commands.clear();
    }

    void end() {
        input.clear();
    }

    UiControlFlags button(IRect area, IStr label) {
        auto result = UiControlFlags();
        auto hover = area.hasPoint(input.mousePosition);
        auto active = hover && (input.mouseButtonDown & UiMouseButtonFlag.left);
        auto color = active ? UiColorType.buttonActive : (hover ? UiColorType.buttonHover : UiColorType.button);
        if (style.border) {
            auto borderArea = area;
            borderArea.addAll(style.border);
            drawRect(borderArea, UiColorType.border, false, false, false, true);
        }
        drawRect(area, color, hover, active, false, false);
        return result;
    }

    UiControlFlags button(IVec2 position, IVec2 size, IStr label) {
        return button(IRect(position, size), label);
    }

    UiControlFlags button(int x, int y, int w, int h, IStr label) {
        return button(IRect(x, y, w, h), label);
    }
}

// UI test.
unittest {
    auto ui = UiContext(null, null, null);

    ui.begin();
    ui.button(0, 0, 60, 20, "My Button");
    ui.end();

    assert(ui.commands.length == 2);
    foreach (ref command; ui.commands) {
        with (UiCommandType) final switch (command.type) {
            case none: break;
            case rect: break;
        }
    }
}
