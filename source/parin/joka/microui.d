// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

// TODO: Add more doc comments.
// TODO: work on attributes maybe.

/// Rxi's tiny immediate-mode UI library, but with Joka specific changes.
module parin.joka.microui;

import parin.joka.types;
import parin.joka.math;

enum muVersion            = "2.02";                /// Version of the original microui C library.
enum muCommandSize        = 1024;                  /// Size of the command, in bytes. Commands include extra space for strings. See `muMaxStrSize`.
enum muCommandListSize    = 256 * muCommandSize;   /// Size of the command list, in bytes. Commands include extra space for strings. See `muMaxStrSize`.
enum muRootListSize       = 32;                    /// Maximum number of root containers (windows).
enum muContainerStackSize = 32;                    /// Max depth for container stack.
enum muClipStackSize      = 32;                    /// Max depth for clipping region stack.
enum muIdStackSize        = 32;                    /// Max depth for ID stack.
enum muLayoutStackSize    = 16;                    /// Max depth for layout stack.
enum muContainerPoolSize  = 48;                    /// Number of reusable containers.
enum muTreeNodePoolSize   = 48;                    /// Number of reusable tree nodes.
enum muInputTextSize      = 1024;                  /// Maximum length of input text buffers.
enum muMaxWidths          = 16;                    /// Maximum number of columns per layout row.
enum muNumberFmt          = "{}";                  /// Format string used for numbers.
enum muNumberFmtWithZero  = "{}\0";                /// Format string used for numbers.
enum muMaxFmt             = 127;                   /// Max length of any formatted string.
enum muMaxStrSize = (cast(int) muCommandSize) - (cast(int) MuTextCommand.sizeof) + 1; /// Maximum length of command strings.
static assert(muMaxStrSize > 0, "Type `MuTextCommand` must fit within `muCommandSize` bytes (used for embedded strings).");

private enum relative = 1; // The relative layout type.
private enum absolute = 2; // The absolute layout type.
private enum unclippedRect = IRect(0, 0, 0x1000000, 0x1000000); // Huge.

alias MuId        = uint;  /// The control ID type of microui.
alias MuFont      = void*; /// The font type of microui.
alias MuTexture   = void*; /// The texture type of microui.
alias MuSliceMode = ubyte; /// The slice repeat mode type of microui.

/// The clipping kind.
enum MuClip : ubyte {
    none, /// No clipping.
    part, /// Partial clipping (for scrollable areas).
    all,  /// Full clipping to container bounds.
}

/// The command kind.
enum MuCommand : ubyte {
    none, /// No command.
    jump, /// Jump to another command in the buffer.
    clip, /// Set a clipping region.
    rect, /// Draw a rectangle.
    text, /// Draw text.
    icon, /// Draw an icon.
}

/// The color kind.
enum MuColor : ubyte {
    text,        /// Default text color.
    border,      /// Border color for controls.
    windowBg,    /// Background color of windows.
    titleBg,     /// Background color of window titles.
    titleText,   /// Text color for window titles.
    panelBg,     /// Background color of panels.
    button,      /// Default button color.
    buttonHover, /// Button color on hover.
    buttonFocus, /// Button color when focused.
    base,        /// Base background for text input or sliders.
    baseHover,   /// Hover color for base controls.
    baseFocus,   /// Focus color for base controls.
    scrollBase,  /// Background of scrollbars.
    scrollThumb, /// Scrollbar thumb color.
}

/// The icon kind.
enum MuIcon : ubyte {
    none,      /// No icon.
    close,     /// Close icon.
    check,     /// Checkmark icon.
    collapsed, /// Collapsed tree icon.
    expanded,  /// Expanded tree icon.
}

// TODO(Kapendev): I think it needs more things. Add them when people (mostly me) need them because right now I have no idea what to add.
/// The atlas region kind.
enum MuAtlas : ubyte {
    none,        /// No atlas rectangle.
    button,      /// Default button atlas rectangle.
    buttonHover, /// Button atlas rectangle on hover.
    buttonFocus, /// Button atlas rectangle when focused.
}

/// The type of `MU_RES_*`.
alias MuResFlags = ubyte;
/// The values of `MU_RES_*`.
enum MuResFlag : MuResFlags {
    none   = 0,        /// No result.
    active = (1 << 0), /// Control is active (e.g., active window).
    submit = (1 << 1), /// Control value submitted (e.g., clicked button).
    change = (1 << 2), /// Control value changed (e.g., modified text input).
}

/// The type of `MU_OPT_*`.
alias MuOptFlags = ushort;
/// The values of `MU_OPT_*`.
enum MuOptFlag : MuOptFlags {
    none         = 0,         /// No option.
    alignCenter  = (1 << 0),  /// Center-align control content.
    alignRight   = (1 << 1),  /// Right-align control content.
    noInteract   = (1 << 2),  /// Disable interaction.
    noFrame      = (1 << 3),  /// Draw control without a frame.
    noResize     = (1 << 4),  /// Disable resizing for windows.
    noScroll     = (1 << 5),  /// Disable scrolling for containers.
    noClose      = (1 << 6),  /// Remove close button from window.
    noTitle      = (1 << 7),  /// Remove title bar from window.
    holdFocus    = (1 << 8),  /// Keep control focused after click.
    autoSize     = (1 << 9),  /// Window automatically sizes to content. Implies `noResize` and `noScroll`.
    popup        = (1 << 10), /// Marks window as popup (e.g., closed on mouse click).
    closed       = (1 << 11), /// Window starts closed.
    expanded     = (1 << 12), /// Window starts expanded.
    noName       = (1 << 13), /// Hides window name.
    defaultFocus = (1 << 14), /// Keep focus when no other control is focused.
}

/// The type of `MU_MOUSE_*`.
alias MuMouseFlags = ubyte;
/// The values of `MU_MOUSE_*`.
enum MuMouseFlag : MuMouseFlags {
    none   = 0,        /// No mouse button.
    left   = (1 << 0), /// Left mouse button.
    right  = (1 << 1), /// Right mouse button.
    middle = (1 << 2), /// Middle mouse button.
}

/// The type of `MU_KEY_*`.
alias MuKeyFlags = uint;
/// The values of `MU_KEY_*`.
enum MuKeyFlag : MuKeyFlags {
    none      = 0,         /// No key.
    shift     = (1 << 0),  /// Shift key down.
    ctrl      = (1 << 1),  /// Control key down.
    alt       = (1 << 2),  /// Alt key down.
    backspace = (1 << 3),  /// Backspace key down.
    enter     = (1 << 4),  /// Return key down.
    tab       = (1 << 5),  /// Tab key down.
    left      = (1 << 6),  /// Left key down.
    right     = (1 << 7),  /// Right key down.
    up        = (1 << 8),  /// Up key down.
    down      = (1 << 9),  /// Down key down.
    home      = (1 << 10), /// Home key down.
    end       = (1 << 11), /// End key down.
    pageUp    = (1 << 12), /// Page up key down.
    pageDown  = (1 << 13), /// Page down key down.
    f1        = (1 << 14), /// F1 key down.
    f2        = (1 << 15), /// F2 key down.
    f3        = (1 << 16), /// F3 key down.
    f4        = (1 << 17), /// F4 key down.
}

@safe nothrow @nogc {
    /// Used for getting the width of the text.
    alias MuTextWidthFunc  = int function(MuFont font, IStr str);
    /// Used for getting the height of the text.
    alias MuTextHeightFunc = int function(MuFont font);
    /// Used for drawing a frame.
    alias MuDrawFrameFunc  = void function(MuContext* ctx, IRect rect, MuColor colorid, MuAtlas atlasid = MuAtlas.none);
}

/// A static stack allocated on the stack.
struct MuStack(T, Sz N) {
    int idx;
    StaticArray!(T, N) data = void;
    alias data this;

    @safe nothrow @nogc:

    /// Pushes a value onto the stack.
    void push(T val) {
        items[idx] = val;
        idx += 1; /* incremented after incase `val` uses this value */
    }

    /// Pops a value off the stack.
    void pop() {
        assert(idx > 0);
        idx -= 1;
    }
}

/// A pool item.
struct MuPoolItem    { MuId id; int lastUpdate; }
/// Base structure for all render commands, containing type and size metadata.
struct MuBaseCommand { MuCommand type; int size; }
/// Command to jump to another location in the command buffer.
struct MuJumpCommand { MuBaseCommand base; void* dst; }
/// Command to set a clipping rectangle.
struct MuClipCommand { MuBaseCommand base; IRect rect; }
/// Command to draw a rectangle with a given color.
struct MuRectCommand { MuBaseCommand base; IRect rect; MuAtlas id; Rgba color; }
/// Command to render text at a given position with a font and color. The text is a null-terminated string. Use `str.ptr` to access it.
struct MuTextCommand { MuBaseCommand base; MuFont font; IVec2 pos; Rgba color; int len; char[1] str; }
/// Command to draw an icon inside a rectangle with a given color.
struct MuIconCommand { MuBaseCommand base; IRect rect; MuIcon id; Rgba color; }

/// A union of all possible render commands.
/// The `type` and `base` fields are always valid, as all commands begin with a `MuCommand` and `MuBaseCommand`.
/// Use `type` to determine the active command variant.
union MuCommandData {
    MuCommand type;
    MuBaseCommand base;
    MuJumpCommand jump;
    MuClipCommand clip;
    MuRectCommand rect;
    MuTextCommand text;
    MuIconCommand icon;
}

/// Layout state used to position UI controls within a container.
struct MuLayout {
    IRect body;
    IRect next;
    IVec2 pos;
    IVec2 size;
    IVec2 max;
    int[muMaxWidths] widths;
    int items;
    int itemIndex;
    int nextRow;
    int nextType;
    int indent;
}

/// A UI container holding commands.
struct MuContainer {
    MuCommandData* head;
    MuCommandData* tail;
    IRect rect;
    IRect body;
    IVec2 contentSize;
    IVec2 scroll;
    int zIndex;
    bool open;
}

/// UI style settings including font, sizes, spacing, and colors.
struct MuStyle {
    MuFont font;                                        /// The font used for UI controls.
    MuTexture texture;                                  /// the atlas texture used for UI controls.
    IVec2 size;                                         /// The size of UI controls.
    int padding;                                        /// The padding around UI controls.
    int spacing;                                        /// The spacing between UI controls.
    int indent;                                         /// The indent of UI controls.
    int border;                                         /// The border of UI controls.
    int titleHeight;                                    /// The height of the window title bar.
    int scrollbarSize;                                  /// The size of the scrollbar.
    int scrollbarSpeed;                                 /// The speed of the scrollbar.
    int scrollbarKeySpeed;                              /// The speed of the scrollbar key.
    int thumbSize;                                      /// The size of the thumb.
    int fontScale;                                      /// The scale of the font.
    StaticArray!(Rgba, MuColor.max + 1) colors;         /// The array of colors used in the UI.
    StaticArray!(IRect, MuAtlas.max + 1) atlasRects;    /// Optional array of control atlas rectangles used in the UI.
    StaticArray!(IRect, MuIcon.max + 1) iconAtlasRects; /// Optional array of icon atlas rectangles used in the UI.
    StaticArray!(Margin, MuAtlas.max + 1) sliceMargins; /// Optional margins for drawing 9-slices.
    MuSliceMode[MuAtlas.max + 1] sliceModes;            /// Optional repeat modes for drawing 9-slices.
}

/// The main UI context.
struct MuContext {
    // -- Callbacks
    MuTextWidthFunc textWidth;   /// The function used for getting the width of the text.
    MuTextHeightFunc textHeight; /// The function used for getting the height of the text.
    MuDrawFrameFunc drawFrame;   /// The function used for drawing a frame.

    // -- Core State
    MuStyle _style; /// The backup UI style.
    MuStyle* style; /// The UI style.
    MuId hover;
    MuId focus;
    MuId lastId;
    IRect lastRect;
    int lastZIndex;
    bool updatedFocus;
    int frame;
    MuContainer* hoverRoot;
    MuContainer* nextHoverRoot;
    MuContainer* scrollTarget;
    char[muMaxFmt] numberEditBuffer;
    MuId numberEdit;
    bool isExpectingEnd;        // Used for missing `mu_end` call.
    uint buttonCounter;         // Used to avoid id problems.
    MuKeyFlags dragWindowKey;   // Used for window stuff.
    MuKeyFlags resizeWindowKey; // Used for window stuff.

    // -- Stacks
    MuStack!(char, muCommandListSize) commandList;
    MuStack!(MuContainer*, muRootListSize) rootList;
    MuStack!(MuContainer*, muContainerStackSize) containerStack;
    MuStack!(IRect, muClipStackSize) clipStack;
    MuStack!(MuId, muIdStackSize) idStack;
    MuStack!(MuLayout, muLayoutStackSize) layoutStack;

    // -- Retained State Pools
    StaticArray!(MuPoolItem, muContainerPoolSize) containerPool;
    StaticArray!(MuContainer, muContainerPoolSize) containers;
    StaticArray!(MuPoolItem, muTreeNodePoolSize) treeNodePool;

    // -- Input State
    IVec2 mousePos;
    IVec2 lastMousePos;
    IVec2 mouseDelta;
    IVec2 scrollDelta;
    MuMouseFlags mouseDown;
    MuMouseFlags mousePressed;
    MuKeyFlags keyDown;
    MuKeyFlags keyPressed;
    char[muInputTextSize] inputText;
    char[] inputTextSlice;

    @safe nothrow @nogc:

    this(MuTextWidthFunc width, MuTextHeightFunc height, MuFont font, int fontScale = 1) {
        readyWithFuncs(width, height, font, fontScale);
    }

    @trusted
    void ready(MuFont font, int fontScale = 1) {
        jokaMemset(&this, 0, typeof(this).sizeof);
        drawFrame = &defaultMuDrawFrame;
        textWidth = &tempMuTextWidthFunc;
        textHeight = &tempMuTextHeightFunc;
        dragWindowKey = MuKeyFlag.f1;
        resizeWindowKey = MuKeyFlag.f2;
        _style = MuStyle(
            /* font | atlas | size | padding | spacing | indent | border */
            null, null, IVec2(68, 10), 5, 4, 24, 1,
            /* titleHeight | scrollbarSize | scrollbarSpeed | scrollbarKeySpeed | thumbSize | fontScale */
            24, 12, 30, cast(int) (30 * 0.4f), 8, fontScale,
            StaticArray!(Rgba, 14)(
                Rgba(230, 230, 230, 255), /* MuColor.text */
                Rgba(25,  25,  25,  255), /* MuColor.border */
                Rgba(50,  50,  50,  255), /* MuColor.windowBg */
                Rgba(25,  25,  25,  255), /* MuColor.titleBg */
                Rgba(240, 240, 240, 255), /* MuColor.titleText */
                Rgba(0,   0,   0,   0  ), /* MuColor.panelBg */
                Rgba(75,  75,  75,  255), /* MuColor.button */
                Rgba(95,  95,  95,  255), /* MuColor.buttonHover */
                Rgba(115, 115, 115, 255), /* MuColor.buttonFOCUS */
                Rgba(30,  30,  30,  255), /* MuColor.base */
                Rgba(35,  35,  35,  255), /* MuColor.baseHOVER */
                Rgba(40,  40,  40,  255), /* MuColor.baseFOCUS */
                Rgba(43,  43,  43,  255), /* MuColor.scrollBase */
                Rgba(30,  30,  30,  255), /* MuColor.scrollThumb */
            ),
        );
        style = &_style;
        style.font = font;
        inputTextSlice = inputText[0 .. 0];
    }

    void readyWithFuncs(MuTextWidthFunc width, MuTextHeightFunc height, MuFont font, int fontScale = 1) {
        ready(font, fontScale);
        textWidth = width;
        textHeight = height;
    }

    void begin() {
        assert(textWidth && textHeight, "Missing text measurement functions (textWidth, textHeight).");
        assert(!isExpectingEnd,         "Missing call to `end` after `begin` function.");

        commandList.idx = 0;
        rootList.idx = 0;
        scrollTarget = null;
        hoverRoot = nextHoverRoot;
        nextHoverRoot = null;
        mouseDelta.x = mousePos.x - lastMousePos.x;
        mouseDelta.y = mousePos.y - lastMousePos.y;
        frame += 1;
        isExpectingEnd = true;
        buttonCounter = 0;
    }

    @trusted
    void end() {
        /* check stacks */
        assert(containerStack.idx == 0, "Container stack is not empty.");
        assert(clipStack.idx      == 0, "Clip stack is not empty.");
        assert(idStack.idx        == 0, "ID stack is not empty.");
        assert(layoutStack.idx    == 0, "Layout stack is not empty.");
        isExpectingEnd = false;
        buttonCounter = 0;

        /* handle scroll input */
        if (scrollTarget) {
            if (keyDown & MuKeyFlag.shift) scrollTarget.scroll.x += scrollDelta.x;
            else scrollTarget.scroll.y += scrollDelta.y;
        }

        /* unset focus if focus id was not touched this frame */
        if (!updatedFocus) { focus = 0; }
        updatedFocus = false;

        /* bring hover root to front if mouse was pressed */
        if (mousePressed && nextHoverRoot && nextHoverRoot.zIndex < lastZIndex && nextHoverRoot.zIndex >= 0) {
            if (nextHoverRoot.open) { mu_bring_to_front(&this, nextHoverRoot); }
        }

        /* reset input state */
        keyPressed = 0;
        inputText[0] = '\0';
        inputTextSlice = inputText[0 .. 0];
        mousePressed = 0;
        scrollDelta = IVec2(0, 0);
        lastMousePos = mousePos;

        /* Old Sorting Code
            int n = rootList.idx;
            qsort(rootList.items.ptr, n, (MuContainer*).sizeof, &mu_compare_zindex);
        */
        /* sort root containers by z index */
        auto n = rootList.idx;
        auto items = rootList.items[0 .. n];
        foreach (i; 1 .. n) {
            auto tmp = items[i];
            auto j = i;
            while (j > 0 && items[j - 1].zIndex > tmp.zIndex) {
                items[j] = items[j - 1];
                j -= 1;
            }
            items[j] = tmp;
        }

        /* set root container jump commands */
        foreach (i; 0 .. n) {
            MuContainer* cnt = rootList.items[i];
            /* if this is the first container then make the first command jump to it.
            ** otherwise set the previous container's tail to jump to this one */
            if (i == 0) {
                MuCommandData* cmd = cast(MuCommandData*) commandList.items;
                cmd.jump.dst = cast(char*) cnt.head + MuJumpCommand.sizeof;
            } else {
                MuContainer* prev = rootList.items[i - 1];
                prev.tail.jump.dst = cast(char*) cnt.head + MuJumpCommand.sizeof;
            }
            /* make the last container's tail jump to the end of command list */
            if (i == n - 1) {
                cnt.tail.jump.dst = commandList.items.ptr + commandList.idx;
            }
        }
    }

    /*============================================================================
    ** controls
    **============================================================================*/

    /// It handles both D strings and C strings, so you can also pass null-terminated buffers directly.
    // NOTE(Kapendev): Might need checking. I replaced lines without thinking too much. Original code had bugs too btw.
    @trusted
    void text(IStr str) {
        MuFont font = style.font;
        Rgba color = style.colors[MuColor.text];
        mu_layout_begin_column(&this);
        mu_layout_row(&this, textHeight(font), -1);

        if (str.length != 0) {
            IStrz p = str.ptr;
            IStrz start = p;
            IStrz end = p;
            do {
                IRect r = mu_layout_next(&this);
                int w = 0;
                start = p;
                end = p;
                do {
                    IStrz word = p;
                    while (p < str.ptr + str.length && *p && *p != ' ' && *p != '\n') { p += 1; }
                    w += textWidth(font, word[0 .. p - word]);
                    if (w > r.w && end != start) { break; }
                    end = p++;
                } while(end < str.ptr + str.length && *end && *end != '\n');
                mu_draw_text(&this, font, start[0 .. end - start], IVec2(r.x, r.y), color);
                p = end + 1;
            } while(end < str.ptr + str.length && *end);
        }
        mu_layout_end_column(&this);
    }

    void textLegacy(IStrz str) {
        // Old: text(str[0 .. (str ? strzLength(str) : 0)]);
        text(str.toStr());
    }

    void label(IStr str) {
        mu_draw_control_text(&this, str, mu_layout_next(&this), MuColor.text, 0);
    }

    void labelLegacy(IStrz str) {
        // Old: label(str[0 .. (str ? strzLength(str) : 0)]);
        label(str.toStr());
    }

    MuResFlags button(IStr str, MuIcon icon = MuIcon.none, MuOptFlags opt = MuOptFlag.alignCenter) {
        mu_push_id(&this, &buttonCounter, buttonCounter.sizeof);
        auto res = buttonLegacy(str, icon, opt);
        mu_pop_id(&this);
        buttonCounter += 1;
        return res;
    }

    @trusted
    MuResFlags buttonLegacy(IStr str, MuIcon icon, MuOptFlags opt) {
        MuResFlags res = MuResFlag.none;
        MuId id = (str.ptr && str.length)
            ? mu_get_id_str(&this, str)
            : mu_get_id(&this, &icon, icon.sizeof);
        IRect r = mu_layout_next(&this);
        mu_update_control(&this, id, r, opt);
        /* handle click */
        if (focus == id) {
            if (opt & MuOptFlag.defaultFocus) {
                if (keyPressed & MuKeyFlag.enter || (hover == id && mousePressed & MuMouseFlag.left)) { res |= MuResFlag.submit; }
            } else {
                if (mousePressed & MuMouseFlag.left) { res |= MuResFlag.submit; }
            }
        }
        /* draw */
        mu_draw_control_frame(&this, id, r, MuColor.button, opt, MuAtlas.button);
        if (str.ptr) { mu_draw_control_text(&this, str, r, MuColor.text, opt); }
        if (icon) { mu_draw_icon(&this, icon, r, style.colors[MuColor.text]); }
        return res;
    }

    @trusted
    MuResFlags checkbox(ref bool state, IStr str) {
        return checkboxLegacy(&state, str);
    }

    @trusted
    MuResFlags checkboxLegacy(bool* state, IStr str) {
        MuResFlags res = MuResFlag.none;
        MuId id = mu_get_id(&this, &state, state.sizeof);
        IRect r = mu_layout_next(&this);
        IRect box = IRect(r.x, r.y, r.h, r.h);
        mu_update_control(&this, id, box, 0); // NOTE(Kapendev): Why was this r and not box???
        /* handle click */
        if (mousePressed & MuMouseFlag.left && focus == id) {
            res |= MuResFlag.change;
            *state = !*state;
        }
        /* draw */
        mu_draw_control_frame(&this, id, box, MuColor.base, 0);
        if (*state) {
            mu_draw_icon(&this, MuIcon.check, box, style.colors[MuColor.text]);
        }
        r = IRect(r.x + box.w, r.y, r.w - box.w, r.h);
        mu_draw_control_text(&this, str, r, MuColor.text, 0);
        return res;
    }

    @trusted
    MuResFlags textboxRaw(char[] buf, MuId id, IRect r, MuOptFlags opt, Sz* newlen = null) {
        return textboxRawLegacy(buf.ptr, buf.length, id, r, opt, newlen);
    }

    @trusted
    MuResFlags textboxRawLegacy(char* buf, Sz bufsz, MuId id, IRect r, MuOptFlags opt, Sz* newlen = null) {
        MuResFlags res;
        mu_update_control(&this, id, r, opt | MuOptFlag.holdFocus);

        Sz buflen = strzLength(buf);
        if (focus == id) {
            /* handle text input */
            int n = min((cast(int) bufsz) - (cast(int) buflen) - 1, cast(int) inputTextSlice.length);
            if (n > 0) {
                jokaMemcpy(buf + buflen, inputText.ptr, n);
                buflen += n;
                buf[buflen] = '\0';
                res |= MuResFlag.change;
            }
            /* handle backspace */
            if (keyPressed & MuKeyFlag.backspace && buflen > 0) {
                if (keyDown & MuKeyFlag.ctrl) {
                    buflen = 0;
                    buf[buflen] = '\0';
                } else if (keyDown & MuKeyFlag.alt && buflen > 0) {
                    /* skip empty space */
                    while (buf[buflen - 1] == ' ') { buflen -= 1; }
                    while (buflen > 0) {
                        /* skip utf-8 continuation bytes */
                        while ((buf[--buflen] & 0xc0) == 0x80 && buflen > 0) {}
                        if (buflen == 0 || isAutocompleteSep(buf[buflen - 1])) break;
                    }
                    buf[buflen] = '\0';
                } else if (buflen > 0) {
                    /* skip utf-8 continuation bytes */
                    while ((buf[--buflen] & 0xc0) == 0x80 && buflen > 0) {}
                    buf[buflen] = '\0';
                }
                res |= MuResFlag.change;
            }
            /* handle return */
            if (keyPressed & MuKeyFlag.enter) {
                mu_set_focus(&this, 0);
                res |= MuResFlag.submit;
            }
        }

        /* draw */
        mu_draw_control_frame(&this, id, r, MuColor.base, opt);
        if (focus == id) {
            Rgba color = style.colors[MuColor.text];
            MuFont font = style.font;
            int textw = textWidth(font, buf[0 .. buflen]);
            int texth = textHeight(font);
            int ofx = r.w - style.padding - textw - 1;
            int textx = r.x + min(ofx, style.padding);
            int texty = r.y + (r.h - texth) / 2;
            mu_push_clip_rect(&this, r);

            if (opt & MuOptFlag.alignCenter) {
                textx = r.x + (r.w - textw) / 2;
            } else if (opt & MuOptFlag.alignRight) {
                textx = r.x + r.w - textw - style.padding;
            }

            mu_draw_text(&this, font, buf[0 .. buflen], IVec2(textx, texty), color);
            mu_draw_rect(&this, IRect(textx + textw, texty, 1, texth), color);
            mu_pop_clip_rect(&this);
        } else {
            mu_draw_control_text(&this, buf[0 .. buflen], r, MuColor.text, opt);
        }
        if (newlen) *newlen = buflen;
        return res;
    }

    @trusted
    MuResFlags textbox(char[] buf, MuOptFlags opt, Sz* newlen = null) {
        return textboxLegacy(buf.ptr, buf.length, opt, newlen);
    }

    @trusted
    MuResFlags textbox(char[] buf, Sz* newlen = null) {
        return textboxLegacy(buf.ptr, buf.length, 0, newlen);
    }

    @trusted
    MuResFlags textboxLegacy(char* buf, Sz bufsz, MuOptFlags opt, Sz* newlen = null) {
        MuId id = mu_get_id(&this, &buf, buf.sizeof);
        IRect r = mu_layout_next(&this);
        return textboxRawLegacy(buf, bufsz, id, r, opt, newlen);
    }

    @trusted
    MuResFlags slider(ref float value, float low, float high, float step = 0.01f, IStr fmt = muNumberFmt, MuOptFlags opt = MuOptFlag.alignCenter) {
        return sliderLegacy(&value, low, high, step, fmt, opt, false);
    }

    @trusted
    MuResFlags sliderLegacy(float* value, float low, float high, float step, IStr fmt, MuOptFlags opt, bool isFmtFloatAnInt) {
        /*
        // Used for the `sprintf` function.
        char[muMaxFmt + 1] fmt_buf = void;
        assert(fmt_buf.length > fmt.length);
        jokaMemcpy(fmt_buf.ptr, fmt.ptr, fmt.length);
        fmt_buf[fmt.length] = '\0';
        */

        char[muMaxFmt + 1] buf = void;
        int x, w;
        IRect thumb;
        MuResFlags res = 0;
        float last = *value, v = last;
        MuId id = mu_get_id(&this, &value, value.sizeof);
        IRect base = mu_layout_next(&this);

        /* handle text input mode */
        if (_numberTextbox(&this, &v, base, id)) { return res; }
        /* handle normal mode */
        mu_update_control(&this, id, base, opt);
        /* handle input */
        if (focus == id && (mouseDown | mousePressed) & MuMouseFlag.left) {
            v = low + (mousePos.x - base.x) * (high - low) / base.w;
            if (step) { v = (cast(long) ((v + step / 2) / step)) * step; }
        }
        /* clamp and store value, update res */
        *value = v = clamp(v, low, high);
        if (last != v) { res |= MuResFlag.change; }

        /* draw base */
        mu_draw_control_frame(&this, id, base, MuColor.base, opt);
        /* draw thumb */
        w = style.thumbSize;
        x = cast(int) ((v - low) * (base.w - w) / (high - low));
        thumb = IRect(base.x + x, base.y, w, base.h);
        mu_draw_control_frame(&this, id, thumb, MuColor.button, opt);
        /* draw text  */
        // This original was not checking the result of `sprintf`...
        // Old: int buflen = sprintf(buf.ptr, fmt_buf.ptr, v);
        // Old: if (buflen < 0) buflen = 0;
        // Old: mu_draw_control_text(&this, buf[0 .. buflen], base, MuColor.text, opt);
        // The zero check is there because of `muNumberFmt`.
        mu_draw_control_text(&this, isFmtFloatAnInt ? buf.fmtIntoBuffer(fmt, cast(int) *value) : buf.fmtIntoBuffer(fmt, *value), base, MuColor.text, opt);
        return res;
    }

    @trusted
    MuResFlags slider(ref int value, int low, int high, int step = 1, IStr fmt = muNumberFmt, MuOptFlags opt = MuOptFlag.alignCenter) {
        return sliderLegacy(&value, low, high, step, fmt, opt, true);
    }

    @trusted
    MuResFlags sliderLegacy(int* value, int low, int high, int step, IStr fmt, MuOptFlags opt, bool isFmtFloatAnInt) {
        mu_push_id(&this, &value, value.sizeof);
        float temp = *value;
        MuResFlags res = sliderLegacy(&temp, low, high, step, fmt, opt, isFmtFloatAnInt);
        *value = cast(int) temp;
        mu_pop_id(&this);
        return res;
    }

    @trusted
    MuResFlags number(ref float value, float step = 0.01f, IStr fmt = muNumberFmt, MuOptFlags opt = MuOptFlag.alignCenter) {
        return numberLegacy(&value, step, fmt, opt, false);
    }

    @trusted
    MuResFlags numberLegacy(float* value, float step, IStr fmt, MuOptFlags opt, bool isFmtFloatAnInt) {
        /*
        // Used for the `sprintf` function.
        char[muMaxFmt + 1] fmt_buf = void;
        assert(fmt_buf.length > fmt.length);
        jokaMemcpy(fmt_buf.ptr, fmt.ptr, fmt.length);
        fmt_buf[fmt.length] = '\0';
        */

        char[muMaxFmt + 1] buf = void;
        MuResFlags res = 0;
        MuId id = mu_get_id(&this, &value, value.sizeof);
        IRect base = mu_layout_next(&this);
        float last = *value;

        /* handle text input mode */
        if (_numberTextbox(&this, value, base, id)) { return res; }
        /* handle normal mode */
        mu_update_control(&this, id, base, opt);
        /* handle input */
        if (focus == id && mouseDown & MuMouseFlag.left) { *value += mouseDelta.x * step; }
        /* set flag if value changed */
        if (*value != last) { res |= MuResFlag.change; }

        /* draw base */
        mu_draw_control_frame(&this, id, base, MuColor.base, opt);
        /* draw text  */
        // This original was not checking the result of `sprintf`...
        // Old: int buflen = sprintf(buf.ptr, fmt_buf.ptr, *value);
        // Old: if (buflen < 0) buflen = 0;
        // Old: mu_draw_control_text(ctx, buf[0 .. buflen], base, MuColor.text, opt);
        // The zero check is there because of `muNumberFmt`.
        mu_draw_control_text(&this, isFmtFloatAnInt ? buf.fmtIntoBuffer(fmt, cast(int) *value) : buf.fmtIntoBuffer(fmt, *value), base, MuColor.text, opt);
        return res;
    }

    @trusted
    MuResFlags number(ref int value, int step = 1, IStr fmt = muNumberFmt, MuOptFlags opt = MuOptFlag.alignCenter) {
        return numberLegacy(&value, step, fmt, opt, true);
    }

    @trusted
    MuResFlags numberLegacy(int* value, int step, IStr fmt, MuOptFlags opt, bool isFmtFloatAnInt) {
        mu_push_id(&this, &value, value.sizeof);
        float temp = *value;
        MuResFlags res = numberLegacy(&temp, step, fmt, opt, isFmtFloatAnInt);
        *value = cast(int) temp;
        mu_pop_id(&this);
        return res;
    }

    MuResFlags header(IStr label, MuOptFlags opt = MuOptFlag.none) {
        return _header(&this, label, 0, opt);
    }

    MuResFlags beginTreeNode(IStr label, MuOptFlags opt = MuOptFlag.none) {
        MuResFlags res = _header(&this, label, 1, opt);
        if (res & MuResFlag.active) {
            _getLayout(&this).indent += style.indent;
            idStack.push(lastId);
        }
        return res;
    }

    void endTreeNode() {
        _getLayout(&this).indent -= style.indent;
        mu_pop_id(&this);
    }

    MuResFlags beginWindow(IStr title, IRect rect, MuOptFlags opt = MuOptFlag.none) {
        if (opt & MuOptFlag.autoSize) { opt |= MuOptFlag.noResize | MuOptFlag.noScroll; }

        IRect body;
        MuId id = mu_get_id_str(&this, title);
        MuContainer* cnt = _getContainer(&this, id, opt);
        if (!cnt || !cnt.open) { return MuResFlag.none; }
        idStack.push(id);

        if (cnt.rect.w == 0) { cnt.rect = rect; }
        _beginRootContainer(&this, cnt);
        rect = body = cnt.rect;

        /* draw frame */
        if (~opt & MuOptFlag.noFrame) {
            drawFrame(&this, rect, MuColor.windowBg);
        }

        /* do title bar */
        if (~opt & MuOptFlag.noTitle) {
            IRect tr = rect;
            tr.h = style.titleHeight;
            drawFrame(&this, tr, MuColor.titleBg);
            /* do title text */
            if (~opt & MuOptFlag.noTitle) {
                if (~opt & MuOptFlag.noName) { mu_draw_control_text(&this, title, tr, MuColor.titleText, opt); }
                MuId id2 = mu_get_id_str(&this, "!title"); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
                if (keyDown & dragWindowKey) {
                    mu_update_control(&this, id2, body, opt, true);
                    if (id2 == focus && mouseDown & MuMouseFlag.left) {
                        cnt.rect.x += mouseDelta.x;
                        cnt.rect.y += mouseDelta.y;
                    }
                } else {
                    mu_update_control(&this, id2, tr, opt);
                    if (id2 == focus && mouseDown & MuMouseFlag.left) {
                        cnt.rect.x += mouseDelta.x;
                        cnt.rect.y += mouseDelta.y;
                    }
                }
                body.y += tr.h;
                body.h -= tr.h;
            }
            /* do `close` button */
            if (~opt & MuOptFlag.noClose) {
                MuId id2 = mu_get_id_str(&this, "!close"); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
                IRect r = IRect(tr.x + tr.w - tr.h, tr.y, tr.h, tr.h);
                tr.w -= r.w;
                mu_draw_icon(&this, MuIcon.close, r, style.colors[MuColor.titleText]);
                mu_update_control(&this, id2, r, opt);
                if (mousePressed & MuMouseFlag.left && id2 == focus) { cnt.open = false; }
            }
        }

        _pushContainerBody(&this, cnt, body, opt);

        /* do `resize` handle */
        if (~opt & MuOptFlag.noResize) {
            int sz = style.scrollbarSize; // RXI, WHY WAS THIS USING THE TITLE HEIGHT?
            MuId id2 = mu_get_id_str(&this, "!resize"); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
            IRect r = IRect(rect.x + rect.w - sz, rect.y + rect.h - sz, sz, sz);
            if (keyDown & resizeWindowKey) {
                mu_update_control(&this, id2, body, opt, true);
                if (id2 == focus && mouseDown & MuMouseFlag.left) {
                    cnt.rect.w = max(96, cnt.rect.w + mouseDelta.x);
                    cnt.rect.h = max(64, cnt.rect.h + mouseDelta.y);
                }
            } else {
                mu_update_control(&this, id2, r, opt);
                if (id2 == focus && mouseDown & MuMouseFlag.left) {
                    cnt.rect.w = max(96, cnt.rect.w + mouseDelta.x);
                    cnt.rect.h = max(64, cnt.rect.h + mouseDelta.y);
                }
            }
        }
        /* resize to content size */
        if (opt & MuOptFlag.autoSize) {
            IRect r = _getLayout(&this).body;
            cnt.rect.w = cnt.contentSize.x + (cnt.rect.w - r.w);
            cnt.rect.h = cnt.contentSize.y + (cnt.rect.h - r.h);
        }
        /* close if this is a popup window and elsewhere was clicked */
        if (opt & MuOptFlag.popup && mousePressed && hoverRoot != cnt) { cnt.open = false; }
        mu_push_clip_rect(&this, cnt.body);
        return MuResFlag.active;
    }

    void endWindow() {
        mu_pop_clip_rect(&this);
        _endRootContainer(&this);
    }

    void openPopup(IStr name) {
        MuContainer* cnt = mu_get_container(&this, name);
        /* set as hover root so popup isn't closed in begin_window_ex() */
        hoverRoot = nextHoverRoot = cnt;
        /* position at mouse cursor, open and bring-to-front */
        cnt.rect = IRect(mousePos.x, mousePos.y, 1, 1);
        cnt.open = true;
        mu_bring_to_front(&this, cnt);
    }

    MuResFlags beginPopup(IStr name) {
        MuOptFlags opt = MuOptFlag.popup | MuOptFlag.autoSize | MuOptFlag.noTitle | MuOptFlag.closed;
        return beginWindow(name, IRect(0, 0, 0, 0), opt);
    }

    void endPopup() {
        endWindow();
    }

    void beginPanel(IStr name, MuOptFlags opt = MuOptFlag.none) {
        MuContainer* cnt;
        mu_push_id_str(&this, name);
        cnt = _getContainer(&this, lastId, opt);
        cnt.rect = mu_layout_next(&this);
        if (~opt & MuOptFlag.noFrame) { drawFrame(&this, cnt.rect, MuColor.panelBg); }
        containerStack.push(cnt);
        _pushContainerBody(&this, cnt, cnt.rect, opt);
        mu_push_clip_rect(&this, cnt.body);
    }

    void endPanel() {
        mu_pop_clip_rect(&this);
        _popContainer(&this);
    }

    void openDmenu() {
        auto cnt = mu_get_container(&this, "!dmenu");
        cnt.open = true;
    }

    @trusted
    MuResFlags beginDmenu(ref IStr selection, const(IStr)[] items, IVec2 canvas, IStr str = "", Vec2 scale = Vec2(0.5f, 0.7f)) {
        static char[muInputTextSize] input_buffer = '\0';

        auto result = MuResFlag.none;
        auto size = IVec2(cast(int) (canvas.x * scale.x), cast(int) (canvas.y * scale.y));
        auto rect = IRect(canvas.x / 2 - size.x / 2, canvas.y / 2 - size.y / 2,  size.x, size.y);
        if (beginWindow("!dmenu", rect, MuOptFlag.noClose | MuOptFlag.noResize | MuOptFlag.noTitle)) {
            result |= MuResFlag.active;
            auto window_cnt = mu_get_current_container(&this);
            if (str.length) {
                mu_layout_row(&this, 0, textWidth(style.font, str) + textWidth(style.font, "  "), -1);
                label(str);
            } else {
                mu_layout_row(&this, 0, -1);
            }

            Sz input_length;
            auto input_result = textbox(input_buffer, MuOptFlag.defaultFocus, &input_length);
            auto input = input_buffer[0 .. input_length];
            auto pick = -1;
            auto first = -1;
            auto buttonCount = 0;
            mu_layout_row(&this, -1, -1);

            beginPanel("!dmenupanel", MuOptFlag.noScroll);
            mu_layout_row(&this, 0, -1);
            foreach (i, item; items) {
                auto starts_with_input = input.length == 0 || (item.length < input.length ? false : item[0 .. input.length] == input);
                // Draw the item.
                if (!starts_with_input) continue;
                buttonCount += 1;
                if (button(item, MuIcon.none, 0)) pick = cast(int) i;
                // Do autocomplete.
                if (buttonCount > 1) continue;
                first = cast(int) i;
                auto autocomplete_length = item.length;
                if (keyPressed & MuKeyFlag.tab) {
                    foreach (j, c; item) {
                        input_buffer[j] = c;
                        if (j > input.length && isAutocompleteSep(c)) {
                            autocomplete_length = j;
                            break;
                        }
                    }
                    input_buffer[autocomplete_length] = '\0';
                }
            }
            endPanel();

            if (items.length && input_result & MuResFlag.submit) pick = first;
            if (pick >= 0) {
                result |= MuResFlag.submit;
                input_buffer[0] = '\0';
                window_cnt.open = false;
                selection = items[pick];
            }
        }
        return result;
    }

    void endDmenu() {
        endWindow();
    }
}

private @safe nothrow @nogc {
    @trusted
    void _pushLayout(MuContext* ctx, IRect body, IVec2 scroll) {
        MuLayout layout;
        jokaMemset(&layout, 0, layout.sizeof);
        layout.body = IRect(body.x - scroll.x, body.y - scroll.y, body.w, body.h);
        layout.max = IVec2(-0x1000000, -0x1000000);
        ctx.layoutStack.push(layout);
        mu_layout_row(ctx, 0, 0);
    }

    MuLayout* _getLayout(MuContext* ctx) {
        assert(ctx.layoutStack.idx != 0, "No layout available, or attempted to add control outside of a window.");
        return &ctx.layoutStack.items[ctx.layoutStack.idx - 1];
    }

    void _popContainer(MuContext* ctx) {
        MuContainer* cnt = mu_get_current_container(ctx);
        MuLayout* layout = _getLayout(ctx);
        cnt.contentSize.x = layout.max.x - layout.body.x;
        cnt.contentSize.y = layout.max.y - layout.body.y;
        /* pop container, layout and id */
        ctx.containerStack.pop();
        ctx.layoutStack.pop();
        mu_pop_id(ctx);
    }

    @trusted
    MuContainer* _getContainer(MuContext* ctx, MuId id, MuOptFlags opt) {
        MuContainer* cnt;
        /* try to get existing container from pool */
        int idx = mu_pool_get(ctx, ctx.containerPool.ptr, muContainerPoolSize, id);
        if (idx >= 0) {
            if (ctx.containers[idx].open || ~opt & MuOptFlag.closed) {
                mu_pool_update(ctx, ctx.containerPool.ptr, idx);
            }
            return &ctx.containers[idx];
        }
        if (opt & MuOptFlag.closed) { return null; }
        /* container not found in pool: init new container */
        idx = mu_pool_init(ctx, ctx.containerPool.ptr, muContainerPoolSize, id);
        cnt = &ctx.containers[idx];
        jokaMemset(cnt, 0, (*cnt).sizeof);
        cnt.open = true;
        mu_bring_to_front(ctx, cnt);
        return cnt;
    }

    @trusted
    MuCommandData* _pushJump(MuContext* ctx, MuCommandData* dst) {
        MuCommandData* cmd;
        cmd = mu_push_command(ctx, MuCommand.jump, MuJumpCommand.sizeof);
        cmd.jump.dst = dst;
        return cmd;
    }

    bool _inHoverRoot(MuContext* ctx) {
        int i = ctx.containerStack.idx;
        while (i--) {
            if (ctx.containerStack.items[i] == ctx.hoverRoot) { return true; }
            /* only root containers have their `head` field set; stop searching if we've
            ** reached the current root container */
            if (ctx.containerStack.items[i].head) { break; }
        }
        return false;
    }

    MuResFlags _numberTextbox(MuContext* ctx, float* value, IRect r, MuId id) {
        if (ctx.mousePressed & MuMouseFlag.left && ctx.keyDown & MuKeyFlag.shift && ctx.hover == id) {
            ctx.numberEdit = id;
            // Old: sprintf(ctx.numberEditBuffer.ptr, MU_REAL_FMT, *value);
            ctx.numberEditBuffer.fmtIntoBuffer(muNumberFmtWithZero, *value);
        }
        if (ctx.numberEdit == id) {
            MuResFlags res = ctx.textboxRaw(ctx.numberEditBuffer, id, r, 0);
            if (res & MuResFlag.submit || ctx.focus != id) {
                // Old: *value = strtod(ctx.numberEditBuffer.ptr, null);
                *value = ctx.numberEditBuffer.ptr.toStr().toFloating().getOr();
                ctx.numberEdit = 0;
            } else {
                return MuResFlag.active;
            }
        }
        return MuResFlag.none;
    }

    @trusted
    MuResFlags _header(MuContext* ctx, IStr label, int istreenode, MuOptFlags opt) {
        IRect r;
        int active, expanded;
        MuId id = mu_get_id_str(ctx, label);
        int idx = mu_pool_get(ctx, ctx.treeNodePool.ptr, muTreeNodePoolSize, id);
        mu_layout_row(ctx, 0, -1);

        active = (idx >= 0);
        expanded = (opt & MuOptFlag.expanded) ? !active : active;
        r = mu_layout_next(ctx);
        mu_update_control(ctx, id, r, 0);

        /* handle click */
        active ^= (ctx.mousePressed & MuMouseFlag.left && ctx.focus == id);
        /* update pool ref */
        if (idx >= 0) {
            if (active) { mu_pool_update(ctx, ctx.treeNodePool.ptr, idx); }
            else { jokaMemset(&ctx.treeNodePool[idx], 0, MuPoolItem.sizeof); }
        } else if (active) {
            mu_pool_init(ctx, ctx.treeNodePool.ptr, muTreeNodePoolSize, id);
        }

        /* draw */
        if (istreenode) {
            if (ctx.hover == id) { ctx.drawFrame(ctx, r, MuColor.buttonHover); }
        } else {
            mu_draw_control_frame(ctx, id, r, MuColor.button, 0);
        }
        mu_draw_icon(ctx, expanded ? MuIcon.expanded : MuIcon.collapsed, IRect(r.x, r.y, r.h, r.h), ctx.style.colors[MuColor.text]);
        r.x += r.h - ctx.style.padding;
        r.w -= r.h - ctx.style.padding;
        mu_draw_control_text(ctx, label, r, MuColor.text, 0);
        return expanded ? MuResFlag.active : 0;
    }

    void _scrollbars(MuContext* ctx, MuContainer* cnt, IRect* body) {
        int sz = ctx.style.scrollbarSize;
        IVec2 cs = cnt.contentSize;
        cs.x += ctx.style.padding * 2;
        cs.y += ctx.style.padding * 2;
        mu_push_clip_rect(ctx, *body);
        /* resize body to make room for scrollbars */
        if (cs.y > cnt.body.h) { body.w -= sz; }
        if (cs.x > cnt.body.w) { body.h -= sz; }
        mu_scrollbar_y(ctx, cnt, body, cs);
        mu_scrollbar_x(ctx, cnt, body, cs);
        mu_pop_clip_rect(ctx);
    }

    @trusted
    void _pushContainerBody(MuContext* ctx, MuContainer* cnt, IRect body, MuOptFlags opt) {
        if (~opt & MuOptFlag.noScroll) { _scrollbars(ctx, cnt, &body); }
        auto layoutBody = body;
        layoutBody.subAll(ctx.style.padding);
        _pushLayout(ctx, layoutBody, cnt.scroll);
        cnt.body = body;
    }

    void _beginRootContainer(MuContext* ctx, MuContainer* cnt) {
        /* push container to roots list and push head command */
        ctx.containerStack.push(cnt);
        ctx.rootList.push(cnt);
        cnt.head = _pushJump(ctx, null);
        /* set as hover root if the mouse is overlapping this container and it has a
        ** higher z index than the current hover root */
        if (cnt.rect.hasPoint(ctx.mousePos) && (!ctx.nextHoverRoot || cnt.zIndex > ctx.nextHoverRoot.zIndex)) {
            ctx.nextHoverRoot = cnt;
        }
        /* clipping is reset here in case a root-container is made within
        ** another root-containers's begin/end block; this prevents the inner
        ** root-container being clipped to the outer */
        ctx.clipStack.push(unclippedRect);
    }

    @trusted
    void _endRootContainer(MuContext* ctx) {
        /* push tail 'goto' jump command and set head 'skip' command. the final steps
        ** on initing these are done in mu_end() */
        MuContainer* cnt = mu_get_current_container(ctx);
        cnt.tail = _pushJump(ctx, null);
        cnt.head.jump.dst = ctx.commandList.items.ptr + ctx.commandList.idx;
        /* pop base clip rect and container */
        mu_pop_clip_rect(ctx);
        _popContainer(ctx);
    }
}

@safe nothrow @nogc:

// Default microui draw frame function.
void defaultMuDrawFrame(MuContext* ctx, IRect rect, MuColor colorid, MuAtlas atlasid = MuAtlas.none) {
    mu_draw_rect(ctx, rect, ctx.style.colors[colorid], atlasid);
    if (colorid == MuColor.scrollBase || colorid == MuColor.scrollThumb || colorid == MuColor.titleBg) return;
    /* draw border */
    if (ctx.style.border && rect.hasSize) {
        auto borderRect = rect;
        foreach (i; 1 .. ctx.style.border + 1) {
            borderRect.addAll(1);
            mu_draw_box(ctx, borderRect, ctx.style.colors[MuColor.border]);
        }
    }
}

// Temporary text measurement function for prototyping.
int tempMuTextWidthFunc(MuFont font, IStr str) {
    return 200;
}

// Temporary text measurement function for prototyping.
int tempMuTextHeightFunc(MuFont font) {
    return 20;
}

void mu_set_focus(MuContext* ctx, MuId id) {
    ctx.focus = id;
    ctx.updatedFocus = true;
}

@trusted
MuId mu_get_id(MuContext *ctx, const(void)* data, Sz size) {
    // NOTE: It's using `hashFnv32a`.
    MuId result = (ctx.idStack.idx > 0) ? ctx.idStack.items[ctx.idStack.idx - 1] : 2166136261U;
    auto p = cast(const(ubyte)*) data;
    while (size--) result = (result ^ *p++) * 16777619U;
    ctx.lastId = result;
    return result;
}

@trusted
MuId mu_get_id_str(MuContext *ctx, IStr str) {
    return mu_get_id(ctx, str.ptr, str.length);
}

@trusted
void mu_push_id(MuContext* ctx, const(void)* data, Sz size) {
    ctx.idStack.push(mu_get_id(ctx, data, size));
}

@trusted
void mu_push_id_str(MuContext* ctx, IStr str) {
    ctx.idStack.push(mu_get_id(ctx, str.ptr, str.length));
}

void mu_pop_id(MuContext* ctx) {
    ctx.idStack.pop();
}

@trusted
void mu_push_clip_rect(MuContext* ctx, IRect rect) {
    IRect last = mu_get_clip_rect(ctx);
    ctx.clipStack.push(rect.intersection(last));
}

void mu_pop_clip_rect(MuContext* ctx) {
    ctx.clipStack.pop();
}

IRect mu_get_clip_rect(MuContext* ctx) {
    assert(ctx.clipStack.idx > 0);
    return ctx.clipStack.items[ctx.clipStack.idx - 1];
}

MuClip mu_check_clip(MuContext* ctx, IRect r) {
    IRect cr = mu_get_clip_rect(ctx);
    if (r.x > cr.x + cr.w || r.x + r.w < cr.x || r.y > cr.y + cr.h || r.y + r.h < cr.y) { return MuClip.all; }
    if (r.x >= cr.x && r.x + r.w <= cr.x + cr.w && r.y >= cr.y && r.y + r.h <= cr.y + cr.h) { return MuClip.none; }
    return MuClip.part;
}

MuContainer* mu_get_current_container(MuContext* ctx) {
    assert(ctx.containerStack.idx > 0);
    return ctx.containerStack.items[ctx.containerStack.idx - 1];
}

MuContainer* mu_get_container(MuContext* ctx, IStr name) {
    MuId id = mu_get_id_str(ctx, name);
    return _getContainer(ctx, id, 0);
}

void mu_bring_to_front(MuContext* ctx, MuContainer* cnt) {
    cnt.zIndex = ++ctx.lastZIndex;
}

/*============================================================================
** pool
**============================================================================*/

@trusted
int mu_pool_init(MuContext* ctx, MuPoolItem* items, Sz len, MuId id) {
    int n = -1;
    int f = ctx.frame;
    foreach (i; 0 .. len) {
        if (items[i].lastUpdate < f) {
            f = items[i].lastUpdate;
            n = cast(int) i;
        }
    }
    assert(n > -1);
    items[n].id = id;
    mu_pool_update(ctx, items, n);
    return n;
}

@trusted
int mu_pool_get(MuContext* ctx, MuPoolItem* items, Sz len, MuId id) {
    foreach (i; 0 .. len) {
        if (items[i].id == id) { return cast(int) i; }
    }
    return -1;
}

@trusted
void mu_pool_update(MuContext* ctx, MuPoolItem* items, Sz idx) {
    items[idx].lastUpdate = ctx.frame;
}

/*============================================================================
** input handlers
**============================================================================*/

void mu_input_mousemove(MuContext* ctx, int x, int y) {
    ctx.mousePos = IVec2(x, y);
}

void mu_input_mousedown(MuContext* ctx, int x, int y, MuMouseFlags btn) {
    mu_input_mousemove(ctx, x, y);
    ctx.mouseDown |= btn;
    ctx.mousePressed |= btn;
}

void mu_input_mouseup(MuContext* ctx, int x, int y, MuMouseFlags btn) {
    mu_input_mousemove(ctx, x, y);
    ctx.mouseDown &= ~btn;
}

void mu_input_scroll(MuContext* ctx, int x, int y) {
    ctx.scrollDelta.x += x * ctx.style.scrollbarSpeed;
    ctx.scrollDelta.y += y * ctx.style.scrollbarSpeed;
}

void mu_input_keydown(MuContext* ctx, MuKeyFlags key) {
    ctx.keyPressed |= key;
    ctx.keyDown |= key;
}

void mu_input_keyup(MuContext* ctx, MuKeyFlags key) {
    ctx.keyDown &= ~key;
}

@trusted
void mu_input_text(MuContext* ctx, IStr text) {
    Sz len = ctx.inputTextSlice.length;
    Sz size = text.length;
    assert(len + size < ctx.inputText.sizeof);
    jokaMemcpy(ctx.inputText.ptr + len, text.ptr, size);
    // Added this to make it work with slices.
    ctx.inputText[len + size] = '\0';
    ctx.inputTextSlice = ctx.inputText[0 .. len + size];
}

/*============================================================================
** commandlist
**============================================================================*/

// NOTE(Kapendev): Should maybe zero the memory?
@trusted
MuCommandData* mu_push_command(MuContext* ctx, MuCommand type, Sz size) {
    MuCommandData* cmd = cast(MuCommandData*) (ctx.commandList.items.ptr + ctx.commandList.idx);
    assert(ctx.commandList.idx + size < muCommandListSize);
    cmd.base.type = type;
    cmd.base.size = cast(int) size;
    ctx.commandList.idx += size;
    return cmd;
}

@trusted
bool mu_next_command(MuContext* ctx, MuCommandData** cmd) {
    if (*cmd) {
        *cmd = cast(MuCommandData*) ((cast(char*) *cmd) + (*cmd).base.size);
    } else {
        *cmd = cast(MuCommandData*) ctx.commandList.items;
    }
    while (cast(char*) *cmd != ctx.commandList.items.ptr + ctx.commandList.idx) {
        if ((*cmd).type != MuCommand.jump) { return true; }
        *cmd = cast(MuCommandData*) (*cmd).jump.dst;
    }
    return false;
}

void mu_set_clip(MuContext* ctx, IRect rect) {
    MuCommandData* cmd;
    cmd = mu_push_command(ctx, MuCommand.clip, MuClipCommand.sizeof);
    cmd.clip.rect = rect;
}

@trusted
void mu_draw_rect(MuContext* ctx, IRect rect, Rgba color, MuAtlas atlasid = MuAtlas.none) {
    MuCommandData* cmd;
    MuClip clipped;
    auto intersect_rect = rect.intersection(mu_get_clip_rect(ctx));
    auto is_atlas_rect = atlasid != MuAtlas.none && ctx.style.atlasRects[atlasid].hasSize;
    auto target_rect = is_atlas_rect ? rect : intersect_rect;

    if (target_rect.hasSize) {
        if (is_atlas_rect) {
            clipped = mu_check_clip(ctx, target_rect);
            if (clipped == MuClip.all ) { return; }
            if (clipped == MuClip.part) { mu_set_clip(ctx, mu_get_clip_rect(ctx)); }
        }

        // See `draw_frame` for more info.
        cmd = mu_push_command(ctx, MuCommand.rect, MuRectCommand.sizeof);
        cmd.rect.rect = target_rect;
        cmd.rect.color = color;
        cmd.rect.id = atlasid;

        if (is_atlas_rect) {
            if (clipped) { mu_set_clip(ctx, unclippedRect); }
        }
    }
}

void mu_draw_box(MuContext* ctx, IRect rect, Rgba color) {
    mu_draw_rect(ctx, IRect(rect.x + 1, rect.y, rect.w - 2, 1), color);
    mu_draw_rect(ctx, IRect(rect.x + 1, rect.y + rect.h - 1, rect.w - 2, 1), color);
    mu_draw_rect(ctx, IRect(rect.x, rect.y, 1, rect.h), color);
    mu_draw_rect(ctx, IRect(rect.x + rect.w - 1, rect.y, 1, rect.h), color);
}

@trusted
void mu_draw_text(MuContext* ctx, MuFont font, IStr str, IVec2 pos, Rgba color) {
    MuCommandData* cmd;
    IRect rect = IRect(pos.x, pos.y, ctx.textWidth(font, str), ctx.textHeight(font));
    MuClip clipped = mu_check_clip(ctx, rect);
    if (clipped == MuClip.all ) { return; }
    if (clipped == MuClip.part) { mu_set_clip(ctx, mu_get_clip_rect(ctx)); }
    /* add command */
    cmd = mu_push_command(ctx, MuCommand.text, MuTextCommand.sizeof + str.length);
    assert(str.length < muMaxStrSize, "String is too big. See `muMaxStrSize`.");
    jokaMemcpy(cmd.text.str.ptr, str.ptr, str.length);
    cmd.text.str.ptr[str.length] = '\0';
    cmd.text.len = cast(int) str.length;
    cmd.text.pos = pos;
    cmd.text.color = color;
    cmd.text.font = font;
    /* reset clipping if it was set */
    if (clipped) { mu_set_clip(ctx, unclippedRect); }
}

void mu_draw_icon(MuContext* ctx, MuIcon id, IRect rect, Rgba color) {
    MuCommandData* cmd;
    /* do clip command if the rect isn't fully contained within the cliprect */
    MuClip clipped = mu_check_clip(ctx, rect);
    if (clipped == MuClip.all ) { return; }
    if (clipped == MuClip.part) { mu_set_clip(ctx, mu_get_clip_rect(ctx)); }
    /* do icon command */
    cmd = mu_push_command(ctx, MuCommand.icon, MuIconCommand.sizeof);
    cmd.icon.id = id;
    cmd.icon.rect = rect;
    cmd.icon.color = color;
    /* reset clipping if it was set */
    if (clipped) { mu_set_clip(ctx, unclippedRect); }
}

/*============================================================================
** layout
**============================================================================*/

void mu_layout_begin_column(MuContext* ctx) {
    _pushLayout(ctx, mu_layout_next(ctx), IVec2(0, 0));
}

void mu_layout_end_column(MuContext* ctx) {
    MuLayout* a, b;
    b = _getLayout(ctx);
    ctx.layoutStack.pop();
    /* inherit position/nextRow/max from child layout if they are greater */
    a = _getLayout(ctx);
    a.pos.x = max(a.pos.x, b.pos.x + b.body.x - a.body.x);
    a.nextRow = max(a.nextRow, b.nextRow + b.body.y - a.body.y);
    a.max.x = max(a.max.x, b.max.x);
    a.max.y = max(a.max.y, b.max.y);
}

@trusted
void mu_layout_row_legacy(MuContext* ctx, int items, const(int)* widths, int height) {
    MuLayout* layout = _getLayout(ctx);
    if (widths) {
        assert(items <= muMaxWidths);
        jokaMemcpy(layout.widths.ptr, widths, items * widths[0].sizeof);
    }
    layout.items = items;
    layout.pos = IVec2(layout.indent, layout.nextRow);
    layout.size.y = height;
    layout.itemIndex = 0;
}

@trusted
void mu_layout_row(MuContext* ctx, int height, const(int)[] widths...) {
    mu_layout_row_legacy(ctx, cast(int) widths.length, widths.ptr, height);
}

void mu_layout_width(MuContext* ctx, int width) {
    _getLayout(ctx).size.x = width;
}

void mu_layout_height(MuContext* ctx, int height) {
    _getLayout(ctx).size.y = height;
}

void mu_layout_set_next(MuContext* ctx, IRect r, bool relative) {
    MuLayout* layout = _getLayout(ctx);
    layout.next = r;
    layout.nextType = relative ? relative : absolute;
}

IRect mu_layout_next(MuContext* ctx) {
    MuLayout* layout = _getLayout(ctx);
    MuStyle* style = ctx.style;
    IRect res;

    if (layout.nextType) {
        /* handle rect set by `mu_layout_set_next` */
        int type = layout.nextType;
        layout.nextType = 0;
        res = layout.next;
        if (type == absolute) { return (ctx.lastRect = res); }
    } else {
        /* handle next row */
        if (layout.itemIndex == layout.items) { mu_layout_row_legacy(ctx, layout.items, null, layout.size.y); }
        /* position */
        res.x = layout.pos.x;
        res.y = layout.pos.y;
        /* size */
        res.w = layout.items > 0 ? layout.widths[layout.itemIndex] : layout.size.x;
        res.h = layout.size.y;
        if (res.w == 0) { res.w = style.size.x + style.padding * 2; }
        if (res.h == 0) { res.h = style.size.y + style.padding * 2; }
        if (res.w <  0) { res.w += layout.body.w - res.x + 1; }
        if (res.h <  0) { res.h += layout.body.h - res.y + 1; }
        layout.itemIndex++;
    }
    /* update position */
    layout.pos.x += res.w + style.spacing;
    layout.nextRow = max(layout.nextRow, res.y + res.h + style.spacing);
    /* apply body offset */
    res.x += layout.body.x;
    res.y += layout.body.y;
    /* update max position */
    layout.max.x = max(layout.max.x, res.x + res.w);
    layout.max.y = max(layout.max.y, res.y + res.h);
    ctx.lastRect = res;
    return ctx.lastRect;
}

/*============================================================================
** controls
**============================================================================*/

@trusted
void mu_draw_control_frame(MuContext* ctx, MuId id, IRect rect, MuColor colorid, MuOptFlags opt, MuAtlas atlasid = MuAtlas.none) {
    if (opt & MuOptFlag.noFrame) { return; }
    colorid += (ctx.focus == id) ? 2 : (ctx.hover == id) ? 1 : 0;
    atlasid += (ctx.focus == id) ? 2 : (ctx.hover == id) ? 1 : 0;
    ctx.drawFrame(ctx, rect, colorid, atlasid);
}

@trusted
void mu_draw_control_text_legacy(MuContext* ctx, IStrz str, IRect rect, MuColor colorid, MuOptFlags opt) {
    mu_draw_control_text(ctx, str[0 .. (str ? strzLength(str) : 0)], rect, colorid, opt);
}

@trusted
void mu_draw_control_text(MuContext* ctx, IStr str, IRect rect, MuColor colorid, MuOptFlags opt) {
    IVec2 pos;
    MuFont font = ctx.style.font;
    int tw = ctx.textWidth(font, str);
    mu_push_clip_rect(ctx, rect);
    pos.y = rect.y + (rect.h - ctx.textHeight(font)) / 2;
    if (opt & MuOptFlag.alignCenter) {
        pos.x = rect.x + (rect.w - tw) / 2;
    } else if (opt & MuOptFlag.alignRight) {
        pos.x = rect.x + rect.w - tw - ctx.style.padding;
    } else {
        pos.x = rect.x + ctx.style.padding;
    }
    mu_draw_text(ctx, font, str, pos, ctx.style.colors[colorid]);
    mu_pop_clip_rect(ctx);
}

bool mu_mouse_over(MuContext* ctx, IRect rect) {
    return rect.hasPoint(ctx.mousePos) && mu_get_clip_rect(ctx).hasPoint(ctx.mousePos) && _inHoverRoot(ctx);
}

void mu_update_control(MuContext* ctx, MuId id, IRect rect, MuOptFlags opt, bool isDragOrResizeControl = false, MuMouseFlags action = MuMouseFlag.left) {
    if (!isDragOrResizeControl) {
        if (ctx.keyDown & ctx.dragWindowKey || ctx.keyDown & ctx.resizeWindowKey) { return; }
    }

    bool mouseover = mu_mouse_over(ctx, rect);
    if (ctx.focus == 0 && opt & MuOptFlag.defaultFocus) { mu_set_focus(ctx, id); }

    if (ctx.focus == id) { ctx.updatedFocus = true; }
    if (opt & MuOptFlag.noInteract) { return; }
    if (mouseover && !(ctx.mouseDown & action)) { ctx.hover = id; }
    if (ctx.focus == id && ~opt & MuOptFlag.defaultFocus) {
        if (ctx.mousePressed & action && !mouseover) { mu_set_focus(ctx, 0); }
        if (!(ctx.mouseDown & action) && ~opt & MuOptFlag.holdFocus) { mu_set_focus(ctx, 0); }
    }
    if (ctx.hover == id) {
        if (ctx.mousePressed & action) {
            mu_set_focus(ctx, id);
        } else if (!mouseover) {
            ctx.hover = 0;
        }
    }
}

@trusted
void mu_scrollbar_y(MuContext* ctx, MuContainer* cnt, IRect* b, IVec2 cs) {
    /* only add scrollbar if content size is larger than body */
    int maxscroll = cs.y - b.h;
    if (maxscroll > 0 && b.h > 0) {
        IRect base, thumb, mouse_area;
        MuId id = mu_get_id_str(ctx, "!scrollbary");
        /* get sizing/positioning */
        base = *b;
        base.x = b.x + b.w;
        base.w = ctx.style.scrollbarSize;
        thumb = base;
        thumb.h = max(ctx.style.thumbSize, base.h * b.h / cs.y);
        thumb.y += cnt.scroll.y * (base.h - thumb.h) / maxscroll;
        mouse_area = *b;
        mouse_area.w += ctx.style.scrollbarSize;
        mouse_area.h += ctx.style.scrollbarSize;
        /* handle input */
        mu_update_control(ctx, id, base, 0);
        if (ctx.focus == id && ctx.mouseDown & MuMouseFlag.left) {
            if (ctx.mousePressed & MuMouseFlag.left) {
                cnt.scroll.y = ((ctx.mousePos.y - base.y - thumb.h / 2) * maxscroll) / (base.h - thumb.h);
            } else {
                cnt.scroll.y += ctx.mouseDelta.y * cs.y / base.h;
            }
        }
        // TODO: Containers inside containers don't work that well. Fix later.
        if ((ctx.focus == id || cnt.zIndex >= ctx.lastZIndex) && ~ctx.keyDown & MuKeyFlag.shift) {
            if (ctx.keyPressed & MuKeyFlag.home) {
                cnt.scroll.y = 0;
            } else if (ctx.keyPressed & MuKeyFlag.end) {
                cnt.scroll.y = maxscroll;
            }
            if (ctx.keyDown & MuKeyFlag.pageUp) {
                cnt.scroll.y -= ctx.style.scrollbarKeySpeed;
            } else if (ctx.keyDown & MuKeyFlag.pageDown) {
                cnt.scroll.y += ctx.style.scrollbarKeySpeed;
            }
        }
        /* clamp scroll to limits */
        cnt.scroll.y = clamp(cnt.scroll.y, 0, maxscroll);
        thumb.y = clamp(thumb.y, base.y, base.y + base.h - thumb.h);
        /* draw base and thumb */
        ctx.drawFrame(ctx, base, MuColor.scrollBase);
        ctx.drawFrame(ctx, thumb, MuColor.scrollThumb);
        /* set this as the scroll target (will get scrolled on mousewheel) */
        /* if the mouse is over it */
        if (mu_mouse_over(ctx, mouse_area)) { ctx.scrollTarget = cnt; }
    } else {
        cnt.scroll.y = 0;
    }
}

@trusted
void mu_scrollbar_x(MuContext* ctx, MuContainer* cnt, IRect* b, IVec2 cs) {
    /* only add scrollbar if content size is larger than body */
    int maxscroll = cs.x - b.w;
    if (maxscroll > 0 && b.w > 0) {
        IRect base, thumb, mouse_area;
        MuId id = mu_get_id_str(ctx, "!scrollbarx");
        /* get sizing/positioning */
        base = *b;
        base.y = b.y + b.h;
        base.h = ctx.style.scrollbarSize;
        thumb = base;
        thumb.w = max(ctx.style.thumbSize, base.w * b.w / cs.x);
        thumb.x += cnt.scroll.x * (base.w - thumb.w) / maxscroll;
        mouse_area = *b;
        mouse_area.w += ctx.style.scrollbarSize;
        mouse_area.h += ctx.style.scrollbarSize;
        /* handle input */
        mu_update_control(ctx, id, base, 0);
        if (ctx.focus == id && ctx.mouseDown & MuMouseFlag.left) {
            if (ctx.mousePressed & MuMouseFlag.left) {
                cnt.scroll.x = ((ctx.mousePos.x - base.x - thumb.w / 2) * maxscroll) / (base.w - thumb.w);
            } else {
                cnt.scroll.x += ctx.mouseDelta.x * cs.x / base.w;
            }
        }
        // TODO: Containers inside containers don't work that well. Fix later.
        if ((ctx.focus == id || cnt.zIndex >= ctx.lastZIndex) && ctx.keyDown & MuKeyFlag.shift) {
            if (ctx.keyPressed & MuKeyFlag.home) {
                cnt.scroll.x = 0;
            } else if (ctx.keyPressed & MuKeyFlag.end) {
                cnt.scroll.x = maxscroll;
            }
            if (ctx.keyDown & MuKeyFlag.pageUp) {
                cnt.scroll.x -= ctx.style.scrollbarKeySpeed;
            } else if (ctx.keyDown & MuKeyFlag.pageDown) {
                cnt.scroll.x += ctx.style.scrollbarKeySpeed;
            }
        }
        /* clamp scroll to limits */
        cnt.scroll.x = clamp(cnt.scroll.x, 0, maxscroll);
        thumb.x = clamp(thumb.x, base.x, base.x + base.w - thumb.w);
        /* draw base and thumb */
        ctx.drawFrame(ctx, base, MuColor.scrollBase);
        ctx.drawFrame(ctx, thumb, MuColor.scrollThumb);
        /* set this as the scroll_target (will get scrolled on mousewheel) */
        /* if the mouse is over it */
        if (mu_mouse_over(ctx, mouse_area)) { ctx.scrollTarget = cnt; }
    } else {
        cnt.scroll.x = 0;
    }
}

// ORIGINAL MICROUI LICENSE
/*
** Copyright (c) 2024 rxi
**
** Permission is hereby granted, free of charge, to any person obtaining a copy
** of this software and associated documentation files (the "Software"), to
** deal in the Software without restriction, including without limitation the
** rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
** sell copies of the Software, and to permit persons to whom the Software is
** furnished to do so, subject to the following conditions:
**
** The above copyright notice and this permission notice shall be included in
** all copies or substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
** FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
** IN THE SOFTWARE.
*/
