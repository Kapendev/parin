// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

// TODO: Add more doc comments.

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
enum muNumberFmtWithZero  = "{}\0";                /// Format string used for numbers, with a zero at the end.
enum muMaxFmt             = 127;                   /// Max length of any formatted string.

enum muMaxStrSize = (cast(int) muCommandSize) - (cast(int) MuTextCommand.sizeof); /// Maximum length of command strings.
static assert(muMaxStrSize > 0, "Type `MuTextCommand` must fit within `muCommandSize` bytes (used for embedded strings).");

private {
    enum relative = 1; // The relative layout type.
    enum absolute = 2; // The absolute layout type.
    enum unclippedRect = IRect(0, 0, 0x1000000, 0x1000000); // Huge.
}

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
/// The atlas area kind.
enum MuAtlas : ubyte {
    none,        /// No atlas rectangle.
    button,      /// Default button atlas rectangle.
    buttonHover, /// Button atlas rectangle on hover.
    buttonFocus, /// Button atlas rectangle when focused.
}

/// Bitmask type for result flags.
alias MuResFlags = ubyte;
/// Result flags indicating the outcome of a control interaction.
enum MuResFlag : MuResFlags {
    none   = 0,        /// No result.
    active = (1 << 0), /// Control is active (e.g., active window).
    submit = (1 << 1), /// Control value submitted (e.g., clicked button).
    change = (1 << 2), /// Control value changed (e.g., modified text input).
}

/// Bitmask type for option flags.
alias MuOptFlags = ushort;
/// Option flags controlling control and window behaviour.
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

/// Bitmask type for mouse button flags.
alias MuMouseFlags = ubyte;
/// Flags representing which mouse buttons are pressed.
enum MuMouseFlag : MuMouseFlags {
    none   = 0,        /// No mouse button.
    left   = (1 << 0), /// Left mouse button.
    right  = (1 << 1), /// Right mouse button.
    middle = (1 << 2), /// Middle mouse button.
}

/// Bitmask type for keyboard key flags.
alias MuKeyFlags = uint;
/// Flags representing which keys are currently held down.
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
    alias MuDrawFrameFunc  = void function(MuContext* ctx, IRect rect, MuColor colorId, MuAtlas atlasId = MuAtlas.none);
}

/// A static stack.
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
        if (idx > 0) idx -= 1;
    }
}

/// A pool item.
struct MuPoolItem {
    MuId id;         /// Unique identifier for this pool slot.
    int lastUpdate;  /// Frame index of the last time this slot was accessed.
}

/// Base structure for all render commands, containing type and size metadata.
struct MuBaseCommand {
    MuCommand type; /// The command type tag.
    int size;       /// Total size of the full command struct in bytes.
}

/// Command to jump to another location in the command buffer.
struct MuJumpCommand {
    MuBaseCommand base; /// Inherited base command fields.
    void* dst;          /// Pointer to the destination in the command buffer.
}

/// Command to set a clipping rectangle.
struct MuClipCommand {
    MuBaseCommand base; /// Inherited base command fields.
    IRect rect;         /// The clipping rectangle to apply.
}

/// Command to draw a rectangle with a given color.
struct MuRectCommand {
    MuBaseCommand base; /// Inherited base command fields.
    IRect rect;         /// The rectangle to draw.
    MuAtlas id;         /// Atlas region to use for drawing.
    Rgba color;         /// Fill color of the rectangle.
}

/// Command to render text at a given position with a font and color.
/// The text is a null-terminated string stored inline. Use `str.ptr` to access it.
struct MuTextCommand {
    MuBaseCommand base; /// Inherited base command fields.
    MuFont font;        /// Font to render the text with.
    IVec2 pos;          /// Top-left position of the text.
    Rgba color;         /// Text color.
    int len;            /// Length of the text in bytes, excluding the null terminator.
    char[1] str;        /// Inline null-terminated string (variable-length in practice).
}

/// Command to draw an icon inside a rectangle with a given color.
struct MuIconCommand {
    MuBaseCommand base; /// Inherited base command fields.
    IRect rect;         /// The bounding rectangle for the icon.
    MuIcon id;          /// Icon identifier.
    Rgba color;         /// Tint color for the icon.
}

/// A union of all possible render commands.
/// The `type` and `base` fields are always valid, as all commands begin with a `MuCommand` and `MuBaseCommand`.
/// Use `type` to determine the active command variant.
union MuCommandData {
    MuCommand type;     /// Type tag, always valid regardless of active variant.
    MuBaseCommand base; /// Base fields, always valid regardless of active variant.
    MuJumpCommand jump; /// Active when `type` is `MuCommand.jump`.
    MuClipCommand clip; /// Active when `type` is `MuCommand.clip`.
    MuRectCommand rect; /// Active when `type` is `MuCommand.rect`.
    MuTextCommand text; /// Active when `type` is `MuCommand.text`.
    MuIconCommand icon; /// Active when `type` is `MuCommand.icon`.
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

/// A 9-slice definition for an atlas area, controlling how it is sampled and tiled.
struct MuSlice {
    IRect area;           /// The atlas area to sample from.
    Margin margin;        /// The margins defining the 9-slice border widths.
    MuSliceMode mode = 1; /// How the center and edge segments are tiled or stretched.
}

/// UI style settings including font, sizes, spacing, and colors.
struct MuStyle {
    MuFont font;                                        /// The font used for UI controls.
    MuTexture texture;                                  /// The atlas texture used for UI controls.
    IVec2 size;                                         /// The default size of UI controls.
    int padding;                                        /// Inner padding within UI controls.
    int spacing;                                        /// Gap between adjacent UI controls.
    int indent;                                         /// Horizontal indent applied to nested controls.
    int border;                                         /// Border thickness for UI controls.
    int titleHeight;                                    /// Height of the window title bar.
    int scrollbarSize;                                  /// Thickness of the scrollbar track.
    int scrollbarSpeed;                                 /// The speed of the scrollbar.
    int scrollbarKeySpeed;                              /// The speed of the scrollbar key.
    int thumbSize;                                      /// The size of the thumb.
    int fontScale;                                      /// Scale factor applied to font rendering.
    StaticArray!(Rgba, MuColor.max + 1) colors;         /// UI control colors, indexed by `MuColor`.
    StaticArray!(MuSlice, MuAtlas.max + 1) slices;      /// 9-slice definitions for control atlas areas, indexed by `MuAtlas`.
    StaticArray!(IRect, MuIcon.max + 1) iconAtlasAreas; /// Atlas areas for icon rendering, indexed by `MuIcon`.
}

/// Used by the `members` function to hide data.
struct MuPrivate {}

/// Used by the `members` function to show data in a specific way.
struct MuMember {
    IStr name;  /// Display name override for the member. If empty, the field name is used.
    float low;  /// Lower bound for slider controls.
    float high; /// Upper bound for slider controls.
    float step; /// Step size for slider controls. If `float.nan`, a default step is used.

    @safe nothrow @nogc pure:

    /// Constructs a member with a slider range and optional step size.
    this(float low, float high, float step = float.nan) {
        this.low = low;
        this.high = high;
        this.step = step;
    }

    /// Constructs a member with only a step size.
    this(float step) {
        this.step = step;
    }

    /// Constructs a member with a display name, slider range, and optional step size.
    this(IStr name, float low, float high, float step = float.nan) {
        this.name = name;
        this.low = low;
        this.high = high;
        this.step = step;
    }

    /// Constructs a member with a display name and optional step size.
    this(IStr name, float step = float.nan) {
        this.name = name;
        this.step = step;
    }
}

/// The UI context.
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
    bool isExpectingEnd;        // Used for missing `end` call.
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
    char[muInputTextSize] inputTextData;
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
            null, null, IVec2(68, 10), 6, 5, 24, 1,
            /* titleHeight | scrollbarSize | scrollbarSpeed | scrollbarKeySpeed | thumbSize | fontScale */
            24, 8, 30, cast(int) (30.0f * 0.4f), 6, fontScale,
            StaticArray!(Rgba, 14)(
                Rgba(220, 220, 220, 255), /* MuColor.text */
                Rgba(15,  15,  20,  255), /* MuColor.border */
                Rgba(30,  30,  38,  255), /* MuColor.windowBg */
                Rgba(20,  20,  26,  255), /* MuColor.titleBg */
                Rgba(220, 220, 220, 255), /* MuColor.titleText */
                Rgba(0,   0,   0,   0  ), /* MuColor.panelBg */
                Rgba(55,  55,  70,  255), /* MuColor.button */
                Rgba(75,  75,  95,  255), /* MuColor.buttonHover */
                Rgba(70,  100, 160, 255), /* MuColor.buttonFOCUS */
                Rgba(22,  22,  30,  255), /* MuColor.base */
                Rgba(28,  28,  38,  255), /* MuColor.baseHOVER */
                Rgba(35,  35,  48,  255), /* MuColor.baseFOCUS */
                Rgba(20,  20,  28,  255), /* MuColor.scrollBase */
                Rgba(70,  70,  90,  255), /* MuColor.scrollThumb */
            ),
        );
        style = &_style;
        style.font = font;
        inputTextSlice = inputTextData[0 .. 0];
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
            if (nextHoverRoot.open) bringToFront(nextHoverRoot);
        }

        /* reset input state */
        keyPressed = 0;
        inputTextData[0] = '\0';
        inputTextSlice = inputTextData[0 .. 0];
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

    void drawControlFrame(MuId id, IRect rect, MuColor colorId, MuOptFlags opt, MuAtlas atlasId = MuAtlas.none) {
        if (opt & MuOptFlag.noFrame) return;
        colorId += (focus == id) ? 2 : (hover == id) ? 1 : 0;
        atlasId += (focus == id) ? 2 : (hover == id) ? 1 : 0;
        drawFrame(&this, rect, colorId, atlasId);
    }

    void drawControlText(IStr str, IRect rect, MuColor colorId, MuOptFlags opt) {
        auto pos = IVec2();
        auto font = style.font;
        auto tw = textWidth(font, str);
        pushClipRect(rect);
        pos.y = rect.y + (rect.h - textHeight(font)) / 2;
        if (opt & MuOptFlag.alignCenter) {
            pos.x = rect.x + (rect.w - tw) / 2;
        } else if (opt & MuOptFlag.alignRight) {
            pos.x = rect.x + rect.w - tw - style.padding;
        } else {
            pos.x = rect.x + style.padding;
        }
        drawText(font, str, pos, style.colors[colorId]);
        popClipRect();
    }

    void drawControlTextLegacy(IStrz str, IRect rect, MuColor colorId, MuOptFlags opt) {
        drawControlText(str.toStr(), rect, colorId, opt);
    }

    bool mouseOver(IRect rect) {
        return rect.hasPoint(mousePos) && getClipRect().hasPoint(mousePos) && _inHoverRoot(&this);
    }

    void updateControl(MuId id, IRect rect, MuOptFlags opt, bool isDragOrResizeControl = false, MuMouseFlags action = MuMouseFlag.left) {
        if (!isDragOrResizeControl) {
            if (keyDown & dragWindowKey || keyDown & resizeWindowKey) return;
        }

        bool mouseover = mouseOver(rect);
        if (focus == 0 && opt & MuOptFlag.defaultFocus) setFocus(id);

        if (focus == id) updatedFocus = true;
        if (opt & MuOptFlag.noInteract) return;
        if (mouseover && !(mouseDown & action)) hover = id;
        if (focus == id && ~opt & MuOptFlag.defaultFocus) {
            if (mousePressed & action && !mouseover) setFocus(0);
            if (!(mouseDown & action) && ~opt & MuOptFlag.holdFocus) setFocus(0);
        }
        if (hover == id) {
            if (mousePressed & action) {
                setFocus(id);
            } else if (!mouseover) {
                hover = 0;
            }
        }
    }

    void scrollbarY(MuContainer* cnt, IRect* b, IVec2 cs) {
        /* only add scrollbar if content size is larger than body */
        int maxscroll = cs.y - b.h;
        if (maxscroll > 0 && b.h > 0) {
            IRect base, thumb, mouse_area;
            MuId id = getIdFromStr("!scrollbary");
            /* get sizing/positioning */
            base = *b;
            base.x = b.x + b.w;
            base.w = style.scrollbarSize;
            thumb = base;
            thumb.h = max(style.thumbSize, base.h * b.h / cs.y);
            thumb.y += cnt.scroll.y * (base.h - thumb.h) / maxscroll;
            mouse_area = *b;
            mouse_area.w += style.scrollbarSize;
            mouse_area.h += style.scrollbarSize;
            /* handle input */
            updateControl(id, base, 0);
            if (focus == id && mouseDown & MuMouseFlag.left) {
                if (mousePressed & MuMouseFlag.left) {
                    cnt.scroll.y = ((mousePos.y - base.y - thumb.h / 2) * maxscroll) / (base.h - thumb.h);
                } else {
                    cnt.scroll.y += mouseDelta.y * cs.y / base.h;
                }
            }
            // TODO: Containers inside containers don't work that well. Fix later.
            if ((focus == id || cnt.zIndex >= lastZIndex) && ~keyDown & MuKeyFlag.shift) {
                if (keyPressed & MuKeyFlag.home) {
                    cnt.scroll.y = 0;
                } else if (keyPressed & MuKeyFlag.end) {
                    cnt.scroll.y = maxscroll;
                }
                if (keyDown & MuKeyFlag.pageUp) {
                    cnt.scroll.y -= style.scrollbarKeySpeed;
                } else if (keyDown & MuKeyFlag.pageDown) {
                    cnt.scroll.y += style.scrollbarKeySpeed;
                }
            }
            /* clamp scroll to limits */
            cnt.scroll.y = clamp(cnt.scroll.y, 0, maxscroll);
            thumb.y = clamp(thumb.y, base.y, base.y + base.h - thumb.h);
            /* draw base and thumb */
            drawFrame(&this, base, MuColor.scrollBase);
            drawFrame(&this, thumb, MuColor.scrollThumb);
            /* set this as the scroll target (will get scrolled on mousewheel) */
            /* if the mouse is over it */
            if (mouseOver(mouse_area)) scrollTarget = cnt;
        } else {
            cnt.scroll.y = 0;
        }
    }

    void scrollbarX(MuContainer* cnt, IRect* b, IVec2 cs) {
        /* only add scrollbar if content size is larger than body */
        int maxscroll = cs.x - b.w;
        if (maxscroll > 0 && b.w > 0) {
            IRect base, thumb, mouse_area;
            MuId id = getIdFromStr("!scrollbarx");
            /* get sizing/positioning */
            base = *b;
            base.y = b.y + b.h;
            base.h = style.scrollbarSize;
            thumb = base;
            thumb.w = max(style.thumbSize, base.w * b.w / cs.x);
            thumb.x += cnt.scroll.x * (base.w - thumb.w) / maxscroll;
            mouse_area = *b;
            mouse_area.w += style.scrollbarSize;
            mouse_area.h += style.scrollbarSize;
            /* handle input */
            updateControl(id, base, 0);
            if (focus == id && mouseDown & MuMouseFlag.left) {
                if (mousePressed & MuMouseFlag.left) {
                    cnt.scroll.x = ((mousePos.x - base.x - thumb.w / 2) * maxscroll) / (base.w - thumb.w);
                } else {
                    cnt.scroll.x += mouseDelta.x * cs.x / base.w;
                }
            }
            // TODO: Containers inside containers don't work that well. Fix later.
            if ((focus == id || cnt.zIndex >= lastZIndex) && keyDown & MuKeyFlag.shift) {
                if (keyPressed & MuKeyFlag.home) {
                    cnt.scroll.x = 0;
                } else if (keyPressed & MuKeyFlag.end) {
                    cnt.scroll.x = maxscroll;
                }
                if (keyDown & MuKeyFlag.pageUp) {
                    cnt.scroll.x -= style.scrollbarKeySpeed;
                } else if (keyDown & MuKeyFlag.pageDown) {
                    cnt.scroll.x += style.scrollbarKeySpeed;
                }
            }
            /* clamp scroll to limits */
            cnt.scroll.x = clamp(cnt.scroll.x, 0, maxscroll);
            thumb.x = clamp(thumb.x, base.x, base.x + base.w - thumb.w);
            /* draw base and thumb */
            drawFrame(&this, base, MuColor.scrollBase);
            drawFrame(&this, thumb, MuColor.scrollThumb);
            /* set this as the scroll_target (will get scrolled on mousewheel) */
            /* if the mouse is over it */
            if (mouseOver(mouse_area)) scrollTarget = cnt;
        } else {
            cnt.scroll.x = 0;
        }
    }

    // NOTE(Kapendev): Might need checking. I replaced lines without thinking too much. Original code had bugs too btw.
    /// It handles both D strings and C strings, so you can also pass null-terminated buffers directly.
    @trusted
    void text(IStr str) {
        MuFont font = style.font;
        Rgba color = style.colors[MuColor.text];
        beginColumn();
        row(textHeight(font), -1);

        if (str.length != 0) {
            IStrz p = str.ptr;
            IStrz start = p;
            IStrz end = p;
            do {
                IRect r = nextLayout();
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
                drawText(font, start[0 .. end - start], IVec2(r.x, r.y), color);
                p = end + 1;
            } while(end < str.ptr + str.length && *end);
        }
        endColumn();
    }

    void textLegacy(IStrz str) {
        text(str.toStr());
    }

    void label(IStr str) {
        drawControlText(str, nextLayout(), MuColor.text, 0);
    }

    void labelLegacy(IStrz str) {
        label(str.toStr());
    }

    MuResFlags button(IStr str, MuIcon icon = MuIcon.none, MuOptFlags opt = MuOptFlag.alignCenter) {
        pushId(&buttonCounter, buttonCounter.sizeof);
        auto res = buttonLegacy(str, icon, opt);
        popId();
        buttonCounter += 1;
        return res;
    }

    @trusted
    MuResFlags buttonLegacy(IStr str, MuIcon icon, MuOptFlags opt) {
        MuResFlags res = MuResFlag.none;
        MuId id = (str.ptr && str.length)
            ? getIdFromStr(str)
            : getId(&icon, icon.sizeof);
        IRect r = nextLayout();
        updateControl(id, r, opt);
        /* handle click */
        if (focus == id) {
            if (opt & MuOptFlag.defaultFocus) {
                if (keyPressed & MuKeyFlag.enter || (hover == id && mousePressed & MuMouseFlag.left)) { res |= MuResFlag.submit; }
            } else {
                if (mousePressed & MuMouseFlag.left) { res |= MuResFlag.submit; }
            }
        }
        /* draw */
        drawControlFrame(id, r, MuColor.button, opt, MuAtlas.button);
        if (str.ptr) drawControlText(str, r, MuColor.text, opt);
        if (icon) drawIcon(icon, r, style.colors[MuColor.text]);
        return res;
    }

    @trusted
    MuResFlags checkbox(ref bool state, IStr str = "") {
        return checkboxLegacy(&state, str);
    }

    @trusted
    MuResFlags checkboxLegacy(bool* state, IStr str) {
        MuResFlags res = MuResFlag.none;
        MuId id = getId(&state, state.sizeof);
        IRect r = nextLayout();
        IRect box = IRect(r.x, r.y, r.h, r.h);
        updateControl(id, box, 0); // NOTE(Kapendev): Why was this r and not box???
        /* handle click */
        if (mousePressed & MuMouseFlag.left && focus == id) {
            res |= MuResFlag.change;
            *state = !*state;
        }
        /* draw */
        drawControlFrame(id, box, MuColor.base, 0);
        if (*state) {
            drawIcon(MuIcon.check, box, style.colors[MuColor.text]);
        }
        r = IRect(r.x + box.w, r.y, r.w - box.w, r.h);
        drawControlText(str, r, MuColor.text, 0);
        return res;
    }

    @trusted
    MuResFlags textBoxRaw(char[] buf, MuId id, IRect r, ref Sz newlen, MuOptFlags opt) {
        return textBoxRawLegacy(buf.ptr, buf.length, id, r, &newlen, opt);
    }

    @trusted
    MuResFlags textBoxRawLegacy(char* buf, Sz bufsz, MuId id, IRect r, Sz* newlen, MuOptFlags opt) {
        MuResFlags res;
        updateControl(id, r, opt | MuOptFlag.holdFocus);

        Sz buflen = 0;
        if (buf && bufsz) {        // NOTE: Because the original code was doing stuff yolo mode.
            buf[bufsz - 1] = '\0'; // NOTE: Because it's common in D to not zero char buffers.
            buflen = strzLength(buf);
        }
        if (focus == id) {
            /* handle text input */
            int n = min((cast(int) bufsz) - (cast(int) buflen) - 1, cast(int) inputTextSlice.length);
            if (n > 0) {
                jokaMemcpy(buf + buflen, inputTextData.ptr, n);
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
                setFocus(0);
                res |= MuResFlag.submit;
            }
        }

        /* draw */
        drawControlFrame(id, r, MuColor.base, opt);
        if (focus == id) {
            Rgba color = style.colors[MuColor.text];
            MuFont font = style.font;
            int textw = textWidth(font, buf[0 .. buflen]);
            int texth = textHeight(font);
            int ofx = r.w - style.padding - textw - 1;
            int textx = r.x + min(ofx, style.padding);
            int texty = r.y + (r.h - texth) / 2;
            pushClipRect(r);

            if (opt & MuOptFlag.alignCenter) {
                textx = r.x + (r.w - textw) / 2;
            } else if (opt & MuOptFlag.alignRight) {
                textx = r.x + r.w - textw - style.padding;
            }

            drawText(font, buf[0 .. buflen], IVec2(textx, texty), color);
            drawRect(IRect(textx + textw, texty, 1, texth), color);
            popClipRect();
        } else {
            drawControlText(buf[0 .. buflen], r, MuColor.text, opt);
        }
        if (newlen) *newlen = buflen;
        return res;
    }

    @trusted
    MuResFlags textBox(char[] buf, ref Sz newlen, MuOptFlags opt = MuOptFlag.none) {
        return textBoxLegacy(buf.ptr, buf.length, &newlen, opt);
    }

    @trusted
    MuResFlags textBox(char[] buf, ref char[] newslice, MuOptFlags opt = MuOptFlag.none) {
        Sz tempLength = void;
        auto result = textBoxLegacy(buf.ptr, buf.length, &tempLength, opt);
        newslice = buf[0 .. tempLength];
        return result;
    }

    @trusted
    MuResFlags textBoxLegacy(char* buf, Sz bufsz, Sz* newlen, MuOptFlags opt) {
        MuId id = getId(&buf, buf.sizeof);
        IRect r = nextLayout();
        return textBoxRawLegacy(buf, bufsz, id, r, newlen, opt);
    }

    @trusted
    MuResFlags slider(ref float value, float low, float high, float step = 0.01f, IStr fmt = muNumberFmt, MuOptFlags opt = MuOptFlag.alignCenter) {
        return sliderLegacy(&value, low, high, step, fmt, opt, false);
    }

    @trusted
    MuResFlags sliderLegacy(float* value, float low, float high, float step, IStr fmt, MuOptFlags opt, bool isFmtFloatAnInt) {
        char[muMaxFmt + 1] buf = void;
        int x, w;
        IRect thumb;
        MuResFlags res = 0;
        float last = *value, v = last;
        MuId id = getId(&value, value.sizeof);
        IRect base = nextLayout();

        /* handle text input mode */
        if (_numberTextbox(&this, &v, base, id)) { return res; }
        /* handle normal mode */
        updateControl(id, base, opt);
        /* handle input */
        if (focus == id && (mouseDown | mousePressed) & MuMouseFlag.left) {
            v = low + (mousePos.x - base.x) * (high - low) / base.w;
            if (step) { v = (cast(long) ((v + step / 2) / step)) * step; }
        }
        /* clamp and store value, update res */
        *value = v = clamp(v, low, high);
        if (last != v) { res |= MuResFlag.change; }

        /* draw base */
        drawControlFrame(id, base, MuColor.base, opt);
        /* draw thumb */
        w = style.thumbSize;
        x = cast(int) ((v - low) * (base.w - w) / (high - low));
        thumb = IRect(base.x + x, base.y, w, base.h);
        drawControlFrame(id, thumb, MuColor.button, opt);
        /* draw text  */
        // This original was not checking the result of `sprintf`...
        // Old: int buflen = sprintf(buf.ptr, fmt_buf.ptr, v);
        // Old: if (buflen < 0) buflen = 0;
        // Old: mu_draw_control_text(&this, buf[0 .. buflen], base, MuColor.text, opt);
        // The zero check is there because of `muNumberFmt`.
        drawControlText(isFmtFloatAnInt ? buf.fmtIntoBuffer(fmt, cast(int) *value) : buf.fmtIntoBuffer(fmt, *value), base, MuColor.text, opt);
        return res;
    }

    @trusted
    MuResFlags slider(ref int value, int low, int high, int step = 1, IStr fmt = muNumberFmt, MuOptFlags opt = MuOptFlag.alignCenter) {
        return sliderLegacy(&value, low, high, step, fmt, opt, true);
    }

    @trusted
    MuResFlags sliderLegacy(int* value, int low, int high, int step, IStr fmt, MuOptFlags opt, bool isFmtFloatAnInt) {
        pushId(&value, value.sizeof);
        float temp = *value;
        MuResFlags res = sliderLegacy(&temp, low, high, step, fmt, opt, isFmtFloatAnInt);
        *value = cast(int) temp;
        popId();
        return res;
    }

    @trusted
    MuResFlags number(ref float value, float step = 0.01f, IStr fmt = muNumberFmt, MuOptFlags opt = MuOptFlag.alignCenter) {
        return numberLegacy(&value, step, fmt, opt, false);
    }

    @trusted
    MuResFlags numberLegacy(float* value, float step, IStr fmt, MuOptFlags opt, bool isFmtFloatAnInt) {
        char[muMaxFmt + 1] buf = void;
        MuResFlags res = 0;
        MuId id = getId(&value, value.sizeof);
        IRect base = nextLayout();
        float last = *value;

        /* handle text input mode */
        if (_numberTextbox(&this, value, base, id)) { return res; }
        /* handle normal mode */
        updateControl(id, base, opt);
        /* handle input */
        if (focus == id && mouseDown & MuMouseFlag.left) { *value += mouseDelta.x * step; }
        /* set flag if value changed */
        if (*value != last) { res |= MuResFlag.change; }

        /* draw base */
        drawControlFrame(id, base, MuColor.base, opt);
        /* draw text  */
        // This original was not checking the result of `sprintf`...
        // Old: int buflen = sprintf(buf.ptr, fmt_buf.ptr, *value);
        // Old: if (buflen < 0) buflen = 0;
        // Old: mu_draw_control_text(ctx, buf[0 .. buflen], base, MuColor.text, opt);
        // The zero check is there because of `muNumberFmt`.
        drawControlText(isFmtFloatAnInt ? buf.fmtIntoBuffer(fmt, cast(int) *value) : buf.fmtIntoBuffer(fmt, *value), base, MuColor.text, opt);
        return res;
    }

    @trusted
    MuResFlags number(ref int value, int step = 1, IStr fmt = muNumberFmt, MuOptFlags opt = MuOptFlag.alignCenter) {
        return numberLegacy(&value, step, fmt, opt, true);
    }

    @trusted
    MuResFlags numberLegacy(int* value, int step, IStr fmt, MuOptFlags opt, bool isFmtFloatAnInt) {
        pushId(&value, value.sizeof);
        float temp = *value;
        MuResFlags res = numberLegacy(&temp, step, fmt, opt, isFmtFloatAnInt);
        *value = cast(int) temp;
        popId();
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
        popId();
    }

    MuResFlags beginWindow(IStr title, IRect rect, MuOptFlags opt = MuOptFlag.none) {
        if (opt & MuOptFlag.autoSize) { opt |= MuOptFlag.noResize | MuOptFlag.noScroll; }

        IRect body;
        MuId id = getIdFromStr(title);
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
                if (~opt & MuOptFlag.noName) drawControlText(title, tr, MuColor.titleText, opt);
                MuId id2 = getIdFromStr("!title"); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
                if (keyDown & dragWindowKey) {
                    updateControl(id2, body, opt, true);
                    if (id2 == focus && mouseDown & MuMouseFlag.left) {
                        cnt.rect.x += mouseDelta.x;
                        cnt.rect.y += mouseDelta.y;
                    }
                } else {
                    updateControl(id2, tr, opt);
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
                MuId id2 = getIdFromStr("!close"); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
                IRect r = IRect(tr.x + tr.w - tr.h, tr.y, tr.h, tr.h);
                tr.w -= r.w;
                drawIcon(MuIcon.close, r, style.colors[MuColor.titleText]);
                updateControl(id2, r, opt);
                if (mousePressed & MuMouseFlag.left && id2 == focus) { cnt.open = false; }
            }
        }

        _pushContainerBody(&this, cnt, body, opt);

        /* do `resize` handle */
        if (~opt & MuOptFlag.noResize) {
            int sz = style.scrollbarSize; // RXI, WHY WAS THIS USING THE TITLE HEIGHT?
            MuId id2 = getIdFromStr("!resize"); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
            IRect r = IRect(rect.x + rect.w - sz, rect.y + rect.h - sz, sz, sz);
            if (keyDown & resizeWindowKey) {
                updateControl(id2, body, opt, true);
                if (id2 == focus && mouseDown & MuMouseFlag.left) {
                    cnt.rect.w = max(96, cnt.rect.w + mouseDelta.x);
                    cnt.rect.h = max(64, cnt.rect.h + mouseDelta.y);
                }
            } else {
                updateControl(id2, r, opt);
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
        pushClipRect(cnt.body);
        return MuResFlag.active;
    }

    void endWindow() {
        popClipRect();
        _endRootContainer(&this);
    }

    void openPopup(IStr name) {
        MuContainer* cnt = getContainer(name);
        /* set as hover root so popup isn't closed in begin_window_ex() */
        hoverRoot = nextHoverRoot = cnt;
        /* position at mouse cursor, open and bring-to-front */
        cnt.rect = IRect(mousePos.x, mousePos.y, 1, 1);
        cnt.open = true;
        bringToFront(cnt);
    }

    MuResFlags beginPopup(IStr name) {
        MuOptFlags opt = MuOptFlag.popup | MuOptFlag.autoSize | MuOptFlag.noTitle | MuOptFlag.closed;
        return beginWindow(name, IRect(0, 0, 0, 0), opt);
    }

    alias endPopup = endWindow;

    void beginPanel(IStr name, MuOptFlags opt = MuOptFlag.none) {
        MuContainer* cnt;
        pushIdFromStr(name);
        cnt = _getContainer(&this, lastId, opt);
        cnt.rect = nextLayout();
        if (~opt & MuOptFlag.noFrame) { drawFrame(&this, cnt.rect, MuColor.panelBg); }
        containerStack.push(cnt);
        _pushContainerBody(&this, cnt, cnt.rect, opt);
        pushClipRect(cnt.body);
    }

    void endPanel() {
        popClipRect();
        _popContainer(&this);
    }

    void openDmenu() {
        auto cnt = getContainer("!dmenu");
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
            auto window_cnt = getCurrentContainer();
            if (str.length) {
                row(0, textWidth(style.font, str) + textWidth(style.font, "  "), -1);
                label(str);
            } else {
                row(0, -1);
            }

            Sz input_length;
            auto input_result = textBox(input_buffer, input_length, MuOptFlag.defaultFocus);
            auto input = input_buffer[0 .. input_length];
            auto pick = -1;
            auto first = -1;
            auto buttonCount = 0;
            row(-1, -1);

            beginPanel("!dmenupanel", MuOptFlag.noScroll);
            row(0, -1);
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

    alias endDmenu = endWindow;

    // TODO: Needs cleaning. It looks likes this because I just wanted to get something to work and original microui could not use Joka.
    void members(T)(ref T data, int labelWidth, bool canShowPrivateMembers = false) {
        auto window = getCurrentContainer();
        row(0, labelWidth, -1);
        static foreach (member; data.tupleof) {
            // With data.
            static if (is(typeof(__traits(getAttributes, member)[0]) == MuMember)) {
                static if (__traits(hasMember, typeof(member), "x") && __traits(hasMember, typeof(member), "y") && __traits(hasMember, typeof(member), "z") && __traits(hasMember, typeof(member), "w")) {
                    row(0, labelWidth,
                        (window.rect.w - labelWidth - style.spacing - style.border) / 4 - style.spacing - style.border,
                        (window.rect.w - labelWidth - style.spacing - style.border) / 4 - style.spacing - style.border,
                        (window.rect.w - labelWidth - style.spacing - style.border) / 4 - style.spacing - style.border,
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
                        (window.rect.w - labelWidth - style.spacing - style.border) / 3 - style.spacing - style.border,
                        (window.rect.w - labelWidth - style.spacing - style.border) / 3 - style.spacing - style.border,
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
                        (window.rect.w - labelWidth - style.spacing - style.border) / 2 - style.spacing - style.border,
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
                if (canShowPrivateMembers || (!is(__traits(getAttributes, member)[0] == MuPrivate) && !is(typeof(__traits(getAttributes, member)[0]) == UiPrivate))) {
                    static if (__traits(hasMember, typeof(member), "x") && __traits(hasMember, typeof(member), "y") && __traits(hasMember, typeof(member), "z") && __traits(hasMember, typeof(member), "w")) {
                        static if (is(typeof(mixin("data.", member.stringof, ".x")) == float) || is(typeof(mixin("data.", member.stringof, ".x")) == int)) {
                            row(0, labelWidth,
                                (window.rect.w - labelWidth - style.spacing - style.border) / 4 - style.spacing - style.border,
                                (window.rect.w - labelWidth - style.spacing - style.border) / 4 - style.spacing - style.border,
                                (window.rect.w - labelWidth - style.spacing - style.border) / 4 - style.spacing - style.border,
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
                                (window.rect.w - labelWidth - style.spacing - style.border) / 3 - style.spacing - style.border,
                                (window.rect.w - labelWidth - style.spacing - style.border) / 3 - style.spacing - style.border,
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
                                (window.rect.w - labelWidth - style.spacing - style.border) / 2 - style.spacing - style.border,
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

    MuResFlags headerAndMembers(T)(ref T data, int labelWidth, IStr label = "", bool canShowPrivateMembers = false) {
        auto result = header(label.length ? label : typeof(data).stringof);
        if (result) members(data, labelWidth, canShowPrivateMembers);
        row(0, 0);
        return result;
    }

    /*============================================================================
    ** layout
    **============================================================================*/

    void beginColumn() {
        _pushLayout(&this, nextLayout(), IVec2(0, 0));
    }

    void endColumn() {
        MuLayout* a, b;
        b = _getLayout(&this);
        layoutStack.pop();
        /* inherit position/nextRow/max from child layout if they are greater */
        a = _getLayout(&this);
        a.pos.x = max(a.pos.x, b.pos.x + b.body.x - a.body.x);
        a.nextRow = max(a.nextRow, b.nextRow + b.body.y - a.body.y);
        a.max.x = max(a.max.x, b.max.x);
        a.max.y = max(a.max.y, b.max.y);
    }

    @trusted
    void row(int height, const(int)[] widths...) {
        rowLegacy(cast(int) widths.length, widths.ptr, height);
    }

    @trusted
    void rowLegacy(int items, const(int)* widths, int height) {
        auto layout = _getLayout(&this);
        if (widths) {
            if (items > muMaxWidths) assert(0, "Too many items. See `muMaxWidths`.");
            jokaMemcpy(layout.widths.ptr, widths, items * widths[0].sizeof);
        }
        layout.items = items;
        layout.pos = IVec2(layout.indent, layout.nextRow);
        layout.size.y = height;
        layout.itemIndex = 0;
    }

    void setLayoutWidth(int width) {
        _getLayout(&this).size.x = width;
    }

    void setLayoutHeight(int height) {
        _getLayout(&this).size.y = height;
    }

    void setNextLayout(IRect r, bool relative) {
        auto layout = _getLayout(&this);
        layout.next = r;
        layout.nextType = relative ? relative : absolute;
    }

    IRect nextLayout() {
        auto layout = _getLayout(&this);
        auto res = IRect();

        if (layout.nextType) {
            /* handle rect set by `mu_layout_set_next` */
            int type = layout.nextType;
            layout.nextType = 0;
            res = layout.next;
            if (type == absolute) return (lastRect = res);
        } else {
            /* handle next row */
            if (layout.itemIndex == layout.items) rowLegacy(layout.items, null, layout.size.y);
            /* position */
            res.x = layout.pos.x;
            res.y = layout.pos.y;
            /* size */
            res.w = layout.items > 0 ? layout.widths[layout.itemIndex] : layout.size.x;
            res.h = layout.size.y;
            if (res.w == 0) res.w = style.size.x + style.padding * 2;
            if (res.h == 0) res.h = style.size.y + style.padding * 2;
            if (res.w <  0) res.w += layout.body.w - res.x + 1;
            if (res.h <  0) res.h += layout.body.h - res.y + 1;
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
        lastRect = res;
        return lastRect;
    }

    /*============================================================================
    ** input handlers
    **============================================================================*/

    void inputMouseMove(int x, int y) {
        mousePos = IVec2(x, y);
    }

    void inputMouseDown(int x, int y, MuMouseFlags btn) {
        inputMouseMove(x, y);
        mouseDown |= btn;
        mousePressed |= btn;
    }

    void inputMouseUp(int x, int y, MuMouseFlags btn) {
        inputMouseMove(x, y);
        mouseDown &= ~btn;
    }

    void inputScroll(int x, int y) {
        scrollDelta.x += x * style.scrollbarSpeed;
        scrollDelta.y += y * style.scrollbarSpeed;
    }

    void inputKeyDown(MuKeyFlags key) {
        keyPressed |= key;
        keyDown |= key;
    }

    void inputKeyUp(MuKeyFlags key) {
        keyDown &= ~key;
    }

    @trusted
    void inputText(IStr str) {
        Sz len = inputTextSlice.length;
        Sz size = str.length;
        if (len + size >= inputTextData.sizeof) assert(0, "String is too big. See `inputTextData` length.");
        jokaMemcpy(inputTextData.ptr + len, str.ptr, size);
        // Added this to make it work with slices.
        inputTextData[len + size] = '\0';
        inputTextSlice = inputTextData[0 .. len + size];
    }

    /*============================================================================
    ** pool
    **============================================================================*/

    @trusted
    int poolInit(MuPoolItem* items, Sz len, MuId id) {
        int n = -1;
        int f = frame;
        foreach (i; 0 .. len) {
            if (items[i].lastUpdate < f) {
                f = items[i].lastUpdate;
                n = cast(int) i;
            }
        }
        if (n <= -1) assert(0, "Could not find pool item.");
        items[n].id = id;
        poolUpdate(items, n);
        return n;
    }

    static @trusted
    int poolGet(MuPoolItem* items, Sz len, MuId id) {
        foreach (i; 0 .. len) {
            if (items[i].id == id) return cast(int) i;
        }
        return -1;
    }

    @trusted
    void poolUpdate(MuPoolItem* items, Sz idx) {
        items[idx].lastUpdate = frame;
    }

    /*============================================================================
    ** commandlist
    **============================================================================*/

    // NOTE(Kapendev): Should maybe zero the memory?
    @trusted
    MuCommandData* pushCommand(MuCommand type, Sz size) {
        MuCommandData* cmd = cast(MuCommandData*) (commandList.items.ptr + commandList.idx);
        if (commandList.idx + size >= muCommandListSize) assert(0, "Can't push command. See `muCommandListSize`.");
        cmd.base.type = type;
        cmd.base.size = cast(int) size;
        commandList.idx += size;
        return cmd;
    }

    @trusted
    bool nextCommand(MuCommandData** cmd) {
        if (*cmd) {
            *cmd = cast(MuCommandData*) ((cast(char*) *cmd) + (*cmd).base.size);
        } else {
            *cmd = cast(MuCommandData*) commandList.items;
        }
        while (cast(char*) *cmd != commandList.items.ptr + commandList.idx) {
            if ((*cmd).type != MuCommand.jump) return true;
            *cmd = cast(MuCommandData*) (*cmd).jump.dst;
        }
        return false;
    }

    void setClip(IRect rect) {
        MuCommandData* cmd;
        cmd = pushCommand(MuCommand.clip, MuClipCommand.sizeof);
        cmd.clip.rect = rect;
    }

    @trusted
    void drawRect(IRect rect, Rgba color, MuAtlas atlasId = MuAtlas.none) {
        MuCommandData* cmd;
        MuClip clipped;
        auto intersect_rect = rect.intersection(getClipRect());
        auto is_atlas_rect = atlasId != MuAtlas.none && style.slices[atlasId].area.hasSize;
        auto target_rect = is_atlas_rect ? rect : intersect_rect;

        if (target_rect.hasSize) {
            if (is_atlas_rect) {
                clipped = checkClip(target_rect);
                if (clipped == MuClip.all ) return;
                if (clipped == MuClip.part) setClip(getClipRect());
            }

            // See `draw_frame` for more info.
            cmd = pushCommand(MuCommand.rect, MuRectCommand.sizeof);
            cmd.rect.rect = target_rect;
            cmd.rect.color = color;
            cmd.rect.id = atlasId;

            if (is_atlas_rect) {
                if (clipped) setClip(unclippedRect);
            }
        }
    }

    void drawBox(IRect rect, Rgba color) {
        drawRect(IRect(rect.x + 1, rect.y, rect.w - 2, 1), color);
        drawRect(IRect(rect.x + 1, rect.y + rect.h - 1, rect.w - 2, 1), color);
        drawRect(IRect(rect.x, rect.y, 1, rect.h), color);
        drawRect(IRect(rect.x + rect.w - 1, rect.y, 1, rect.h), color);
    }

    @trusted
    void drawText(MuFont font, IStr str, IVec2 pos, Rgba color) {
        MuCommandData* cmd;
        IRect rect = IRect(pos.x, pos.y, textWidth(font, str), textHeight(font));
        MuClip clipped = checkClip(rect);
        if (clipped == MuClip.all ) return;
        if (clipped == MuClip.part) setClip(getClipRect());
        /* add command */
        cmd = pushCommand(MuCommand.text, MuTextCommand.sizeof + str.length);
        if (str.length >= muMaxStrSize) assert(0, "String is too big. See `muMaxStrSize`.");
        jokaMemcpy(cmd.text.str.ptr, str.ptr, str.length);
        cmd.text.str.ptr[str.length] = '\0';
        cmd.text.len = cast(int) str.length;
        cmd.text.pos = pos;
        cmd.text.color = color;
        cmd.text.font = font;
        /* reset clipping if it was set */
        if (clipped) setClip(unclippedRect);
    }

    void drawIcon(MuIcon id, IRect rect, Rgba color) {
        MuCommandData* cmd;
        /* do clip command if the rect isn't fully contained within the cliprect */
        MuClip clipped = checkClip(rect);
        if (clipped == MuClip.all ) return;
        if (clipped == MuClip.part) setClip(getClipRect());
        /* do icon command */
        cmd = pushCommand(MuCommand.icon, MuIconCommand.sizeof);
        cmd.icon.id = id;
        cmd.icon.rect = rect;
        cmd.icon.color = color;
        /* reset clipping if it was set */
        if (clipped) setClip(unclippedRect);
    }

    /*============================================================================
    ** other
    **============================================================================*/

    void setFocus(MuId id) {
        focus = id;
        updatedFocus = true;
    }

    @trusted
    MuId getId(const(void)* data, Sz size) {
        // NOTE: It's using `hashFnv32a`.
        MuId result = (idStack.idx > 0) ? idStack.items[idStack.idx - 1] : 2166136261U;
        auto p = cast(const(ubyte)*) data;
        while (size--) result = (result ^ *p++) * 16777619U;
        lastId = result;
        return result;
    }

    @trusted
    MuId getIdFromStr(IStr str) {
        return getId(str.ptr, str.length);
    }

    void pushId(const(void)* data, Sz size) {
        idStack.push(getId(data, size));
    }

    @trusted
    void pushIdFromStr(IStr str) {
        idStack.push(getId(str.ptr, str.length));
    }

    void popId() {
        idStack.pop();
    }

    void pushClipRect(IRect rect) {
        auto last = getClipRect();
        clipStack.push(rect.intersection(last));
    }

    void popClipRect() {
        clipStack.pop();
    }

    IRect getClipRect() {
        return clipStack.items[clipStack.idx - 1];
    }

    MuClip checkClip(IRect r) {
        auto cr = getClipRect();
        if (r.x > cr.x + cr.w || r.x + r.w < cr.x || r.y > cr.y + cr.h || r.y + r.h < cr.y) {
            return MuClip.all;
        } else if (r.x >= cr.x && r.x + r.w <= cr.x + cr.w && r.y >= cr.y && r.y + r.h <= cr.y + cr.h) {
            return MuClip.none;
        } else {
            return MuClip.part;
        }
    }

    MuContainer* getCurrentContainer() {
        return containerStack.items[containerStack.idx - 1];
    }

    MuContainer* getContainer(IStr name) {
        auto id = getIdFromStr(name);
        return _getContainer(&this, id, 0);
    }

    void bringToFront(MuContainer* cnt) {
        cnt.zIndex = ++lastZIndex;
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
        ctx.row(0, 0);
    }

    MuLayout* _getLayout(MuContext* ctx) {
        if (ctx.layoutStack.idx == 0) assert(0, "No layout available, or attempted to add control outside of a window.");
        return &ctx.layoutStack.items[ctx.layoutStack.idx - 1];
    }

    void _popContainer(MuContext* ctx) {
        MuContainer* cnt = ctx.getCurrentContainer();
        MuLayout* layout = _getLayout(ctx);
        cnt.contentSize.x = layout.max.x - layout.body.x;
        cnt.contentSize.y = layout.max.y - layout.body.y;
        /* pop container, layout and id */
        ctx.containerStack.pop();
        ctx.layoutStack.pop();
        ctx.popId();
    }

    @trusted
    MuContainer* _getContainer(MuContext* ctx, MuId id, MuOptFlags opt) {
        MuContainer* cnt;
        /* try to get existing container from pool */
        int idx = ctx.poolGet(ctx.containerPool.ptr, muContainerPoolSize, id);
        if (idx >= 0) {
            if (ctx.containers[idx].open || ~opt & MuOptFlag.closed) {
                ctx.poolUpdate(ctx.containerPool.ptr, idx);
            }
            return &ctx.containers[idx];
        }
        if (opt & MuOptFlag.closed) { return null; }
        /* container not found in pool: init new container */
        idx = ctx.poolInit(ctx.containerPool.ptr, muContainerPoolSize, id);
        cnt = &ctx.containers[idx];
        jokaMemset(cnt, 0, (*cnt).sizeof);
        cnt.open = true;
        ctx.bringToFront(cnt);
        return cnt;
    }

    @trusted
    MuCommandData* _pushJump(MuContext* ctx, MuCommandData* dst) {
        MuCommandData* cmd;
        cmd = ctx.pushCommand(MuCommand.jump, MuJumpCommand.sizeof);
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
            Sz textBoxLength = void;
            auto res = ctx.textBoxRaw(ctx.numberEditBuffer, id, r, textBoxLength, MuOptFlag.none);
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
        MuId id = ctx.getIdFromStr(label);
        int idx = ctx.poolGet(ctx.treeNodePool.ptr, muTreeNodePoolSize, id);
        ctx.row(0, -1);

        active = (idx >= 0);
        expanded = (opt & MuOptFlag.expanded) ? !active : active;
        r = ctx.nextLayout();
        ctx.updateControl(id, r, 0);

        /* handle click */
        active ^= (ctx.mousePressed & MuMouseFlag.left && ctx.focus == id);
        /* update pool ref */
        if (idx >= 0) {
            if (active) {
                ctx.poolUpdate(ctx.treeNodePool.ptr, idx);
            } else {
                jokaMemset(&ctx.treeNodePool[idx], 0, MuPoolItem.sizeof);
            }
        } else if (active) {
            ctx.poolInit(ctx.treeNodePool.ptr, muTreeNodePoolSize, id);
        }

        /* draw */
        if (istreenode) {
            if (ctx.hover == id) { ctx.drawFrame(ctx, r, MuColor.buttonHover); }
        } else {
            ctx.drawControlFrame(id, r, MuColor.button, 0);
        }
        ctx.drawIcon(expanded ? MuIcon.expanded : MuIcon.collapsed, IRect(r.x, r.y, r.h, r.h), ctx.style.colors[MuColor.text]);
        r.x += r.h - ctx.style.padding;
        r.w -= r.h - ctx.style.padding;
        ctx.drawControlText(label, r, MuColor.text, 0);
        return expanded ? MuResFlag.active : 0;
    }

    void _scrollbars(MuContext* ctx, MuContainer* cnt, IRect* body) {
        int sz = ctx.style.scrollbarSize;
        IVec2 cs = cnt.contentSize;
        cs.x += ctx.style.padding * 2;
        cs.y += ctx.style.padding * 2;
        ctx.pushClipRect(*body);
        /* resize body to make room for scrollbars */
        if (cs.y > cnt.body.h) { body.w -= sz; }
        if (cs.x > cnt.body.w) { body.h -= sz; }
        ctx.scrollbarY(cnt, body, cs);
        ctx.scrollbarX(cnt, body, cs);
        ctx.popClipRect();
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
        MuContainer* cnt = ctx.getCurrentContainer();
        cnt.tail = _pushJump(ctx, null);
        cnt.head.jump.dst = ctx.commandList.items.ptr + ctx.commandList.idx;
        /* pop base clip rect and container */
        ctx.popClipRect();
        _popContainer(ctx);
    }
}

@safe nothrow @nogc {
    // Default microui draw frame function.
    void defaultMuDrawFrame(MuContext* ctx, IRect rect, MuColor colorId, MuAtlas atlasId = MuAtlas.none) {
        ctx.drawRect(rect, ctx.style.colors[colorId], atlasId);
        if (colorId == MuColor.scrollBase || colorId == MuColor.scrollThumb || colorId == MuColor.titleBg) return;
        /* draw border */
        if (ctx.style.border && rect.hasSize) {
            auto borderRect = rect;
            foreach (i; 1 .. ctx.style.border + 1) {
                borderRect.addAll(1);
                ctx.drawBox(borderRect, ctx.style.colors[MuColor.border]);
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
