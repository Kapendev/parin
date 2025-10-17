// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// ---

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

// TODO: Add more doc comments.
// TODO: work on attributes maybe.

/// A tiny immediate-mode UI library.
module parin.addons.microui.core;

private extern(C) nothrow @nogc {
    // External dependencies required by microui.
    alias STDLIB_QSORT_FUNC = int function(const(void)* a, const(void)* b);
    int sprintf(char* buffer, const(char)* format, ...);
    double strtod(const(char)* str, char** str_end);
    void qsort(void* ptr, size_t count, size_t size, STDLIB_QSORT_FUNC comp);
    void* memset(void* dest, int ch, size_t count);
    void* memcpy(void* dest, const(void)* src, size_t count);
    size_t strlen(const(char)* str);
}

/// Used for getting the width of the text.
alias mu_TextWidthFunc  = int function(mu_Font font, const(char)[] str);
/// Used for getting the height of the text.
alias mu_TextHeightFunc = int function(mu_Font font);
/// Used for drawing a frame.
alias mu_DrawFrameFunc  = void function(mu_Context* ctx, mu_Rect rect, mu_ColorEnum colorid, mu_AtlasEnum atlasid = MU_ATLAS_NONE);

alias mu_Real      = float; /// The floating-point type of microui.
alias mu_Id        = uint;  /// The control ID type of microui.
alias mu_Font      = void*; /// The font type of microui.
alias mu_Texture   = void*; /// The texture type of microui.
alias mu_SliceMode = int;   /// The slice repeat mode type of microui.

alias mu_ClipEnum    = int; /// The type of `MU_CLIP_*` enums.
alias mu_CommandEnum = int; /// The type of `MU_COMMAND_*` enums.
alias mu_ColorEnum   = int; /// The type of `MU_COLOR_*` enums.
alias mu_IconEnum    = int; /// The type of `MU_ICON_*` enums.
alias mu_AtlasEnum   = int; /// The type of `MU_ATLAS*` enums.

alias mu_ResFlags   = int; /// The type of `MU_RES_*` enums.
alias mu_OptFlags   = int; /// The type of `MU_OPT_*` enums.
alias mu_MouseFlags = int; /// The type of `MU_MOUSE_*` enums.
alias mu_KeyFlags   = int; /// The type of `MU_KEY_*` enums.

private enum RELATIVE = 1; // The relative layout type.
private enum ABSOLUTE = 2; // The absolute layout type.
private enum mu_unclipped_rect = mu_Rect(0, 0, 0x1000000, 0x1000000);

enum MU_D_VERSION           = "v0.0.1";              /// Version of the D language rewrite.
enum MU_VERSION             = "2.02";                /// Version of the original microui C library.
enum MU_COMMAND_SIZE        = 1024;                  /// Size of the command, in bytes. Commands include extra space for strings. See `MU_STR_SIZE`.
enum MU_COMMANDLIST_SIZE    = 256 * MU_COMMAND_SIZE; /// Size of the command list, in bytes. Commands include extra space for strings. See `MU_STR_SIZE`.
enum MU_ROOTLIST_SIZE       = 32;                    /// Maximum number of root containers (windows).
enum MU_CONTAINERSTACK_SIZE = 32;                    /// Max depth for container stack.
enum MU_CLIPSTACK_SIZE      = 32;                    /// Max depth for clipping region stack.
enum MU_IDSTACK_SIZE        = 32;                    /// Max depth for ID stack.
enum MU_LAYOUTSTACK_SIZE    = 16;                    /// Max depth for layout stack.
enum MU_CONTAINERPOOL_SIZE  = 48;                    /// Number of reusable containers.
enum MU_TREENODEPOOL_SIZE   = 48;                    /// Number of reusable tree nodes.
enum MU_INPUTTEXT_SIZE      = 1024;                  /// Maximum length of input text buffers.
enum MU_MAX_WIDTHS          = 16;                    /// Maximum number of columns per layout row.
enum MU_REAL_FMT            = "%.3g";                /// Format string used for real numbers.
enum MU_SLIDER_FMT          = "%.2f";                /// Format string used for slider labels.
enum MU_SLIDER_INT_FMT      = "%.0f";                /// Format string used for slider labels.
enum MU_MAX_FMT             = 127;                   /// Max length of any formatted string.
enum MU_COMMON_COLOR_SHIFT  = -12;                   /// The common shift value used for the base color of a control.

enum MU_BLACK = mu_Color(0  ,   0,   0, 255); /// Black.
enum MU_WHITE = mu_Color(255, 255, 255, 255); /// White.

enum MU_STR_SIZE = (cast(int) MU_COMMAND_SIZE) - (cast(int) mu_TextCommand.sizeof) + 1; /// Maximum length of command strings.
static assert(MU_STR_SIZE > 0, "Type `mu_TextCommand` must fit within `MU_COMMAND_SIZE` bytes (used for embedded strings).");

enum : mu_ClipEnum {
    MU_CLIP_NONE = 0, /// No clipping.
    MU_CLIP_PART = 1, /// Partial clipping (for scrollable areas).
    MU_CLIP_ALL,      /// Full clipping to container bounds.
}

enum : mu_CommandEnum {
    MU_COMMAND_NONE = 0, /// No command.
    MU_COMMAND_JUMP = 1, /// Jump to another command in the buffer.
    MU_COMMAND_CLIP,     /// Set a clipping region.
    MU_COMMAND_RECT,     /// Draw a rectangle.
    MU_COMMAND_TEXT,     /// Draw text.
    MU_COMMAND_ICON,     /// Draw an icon.
    MU_COMMAND_MAX,      /// Number of command types.
}

enum : mu_ColorEnum {
    MU_COLOR_TEXT,        /// Default text color.
    MU_COLOR_BORDER,      /// Border color for controls.
    MU_COLOR_WINDOWBG,    /// Background color of windows.
    MU_COLOR_TITLEBG,     /// Background color of window titles.
    MU_COLOR_TITLETEXT,   /// Text color for window titles.
    MU_COLOR_PANELBG,     /// Background color of panels.
    MU_COLOR_BUTTON,      /// Default button color.
    MU_COLOR_BUTTONHOVER, /// Button color on hover.
    MU_COLOR_BUTTONFOCUS, /// Button color when focused.
    MU_COLOR_BASE,        /// Base background for text input or sliders.
    MU_COLOR_BASEHOVER,   /// Hover color for base controls.
    MU_COLOR_BASEFOCUS,   /// Focus color for base controls.
    MU_COLOR_SCROLLBASE,  /// Background of scrollbars.
    MU_COLOR_SCROLLTHUMB, /// Scrollbar thumb color.
    MU_COLOR_MAX,         /// Number of color types.
}

enum : mu_IconEnum {
    MU_ICON_NONE = 0,  /// No icon.
    MU_ICON_CLOSE = 1, /// Close icon.
    MU_ICON_CHECK,     /// Checkmark icon.
    MU_ICON_COLLAPSED, /// Collapsed tree icon.
    MU_ICON_EXPANDED,  /// Expanded tree icon.
    MU_ICON_MAX,       /// Number of icon types.
}

// TODO(Kapendev): I think it needs more things. Add them when people (mostly me) need them because right now I have no idea what to add.
enum : mu_AtlasEnum {
    MU_ATLAS_NONE,        /// No atlas rectangle.
    MU_ATLAS_BUTTON,      /// Default button atlas rectangle.
    MU_ATLAS_BUTTONHOVER, /// Button atlas rectangle on hover.
    MU_ATLAS_BUTTONFOCUS, /// Button atlas rectangle when focused.
    MU_ATLAS_MAX,         /// Number of atlas rectangle types.
}

enum : mu_ResFlags {
    MU_RES_NONE   = 0,        /// No result.
    MU_RES_ACTIVE = (1 << 0), /// Control is active (e.g., active window).
    MU_RES_SUBMIT = (1 << 1), /// Control value submitted (e.g., clicked button).
    MU_RES_CHANGE = (1 << 2), /// Control value changed (e.g., modified text input).
}

enum : mu_OptFlags {
    MU_OPT_NONE         = 0,         /// No option.
    MU_OPT_ALIGNCENTER  = (1 << 0),  /// Center-align control content.
    MU_OPT_ALIGNRIGHT   = (1 << 1),  /// Right-align control content.
    MU_OPT_NOINTERACT   = (1 << 2),  /// Disable interaction.
    MU_OPT_NOFRAME      = (1 << 3),  /// Draw control without a frame.
    MU_OPT_NORESIZE     = (1 << 4),  /// Disable resizing for windows.
    MU_OPT_NOSCROLL     = (1 << 5),  /// Disable scrolling for containers.
    MU_OPT_NOCLOSE      = (1 << 6),  /// Remove close button from window.
    MU_OPT_NOTITLE      = (1 << 7),  /// Remove title bar from window.
    MU_OPT_HOLDFOCUS    = (1 << 8),  /// Keep control focused after click.
    MU_OPT_AUTOSIZE     = (1 << 9),  /// Window automatically sizes to content. Implies `MU_OPT_NORESIZE` and `MU_OPT_NOSCROLL`.
    MU_OPT_POPUP        = (1 << 10), /// Marks window as popup (e.g., closed on mouse click).
    MU_OPT_CLOSED       = (1 << 11), /// Window starts closed.
    MU_OPT_EXPANDED     = (1 << 12), /// Window starts expanded.
    MU_OPT_NONAME       = (1 << 13), /// Hides window name.
    MU_OPT_DEFAULTFOCUS = (1 << 14), /// Keep focus when no other control is focused.
}

enum : mu_MouseFlags {
    MU_MOUSE_NONE   = 0,        /// No mouse button.
    MU_MOUSE_LEFT   = (1 << 0), /// Left mouse button.
    MU_MOUSE_RIGHT  = (1 << 1), /// Right mouse button.
    MU_MOUSE_MIDDLE = (1 << 2), /// Middle mouse button.
}

enum : mu_KeyFlags {
    MU_KEY_NONE      = 0,         /// No key.
    MU_KEY_SHIFT     = (1 << 0),  /// Shift key down.
    MU_KEY_CTRL      = (1 << 1),  /// Control key down.
    MU_KEY_ALT       = (1 << 2),  /// Alt key down.
    MU_KEY_BACKSPACE = (1 << 3),  /// Backspace key down.
    MU_KEY_RETURN    = (1 << 4),  /// Return key down.
    MU_KEY_TAB       = (1 << 5),  /// Tab key down.
    MU_KEY_LEFT      = (1 << 6),  /// Left key down.
    MU_KEY_RIGHT     = (1 << 7),  /// Right key down.
    MU_KEY_UP        = (1 << 8),  /// Up key down.
    MU_KEY_DOWN      = (1 << 9),  /// Down key down.
    MU_KEY_HOME      = (1 << 10), /// Home key down.
    MU_KEY_END       = (1 << 11), /// End key down.
    MU_KEY_PAGEUP    = (1 << 12), /// Page up key down.
    MU_KEY_PAGEDOWN  = (1 << 13), /// Page down key down.
    MU_KEY_F1        = (1 << 14), /// F1 key down.
    MU_KEY_F2        = (1 << 15), /// F2 key down.
    MU_KEY_F3        = (1 << 16), /// F3 key down.
    MU_KEY_F4        = (1 << 17), /// F4 key down.
}

/// A static array allocated on the stack.
// It exists mainly because of weird BetterC stuff.
struct mu_Array(T, size_t N) {
    align(T.alignof) ubyte[T.sizeof * N] data;

    enum length = N;

    @trusted nothrow @nogc:

    this(const(T)[] items...) {
        if (items.length > N) assert(0, "Too many items.");
        auto datadata = this.items;
        foreach (i; 0 .. N) datadata[i] = cast(T) items[i];
    }

    pragma(inline, true)
    T[] opSlice(size_t dim)(size_t i, size_t j) {
        return items[i .. j];
    }

    pragma(inline, true)
    T[] opIndex() {
        return items[];
    }

    pragma(inline, true)
    T[] opIndex(T[] slice) {
        return slice;
    }

    pragma(inline, true)
    ref T opIndex(size_t i) {
        return items[i];
    }

    pragma(inline, true)
    void opIndexAssign(const(T) rhs, size_t i) {
        items[i] = cast(T) rhs;
    }

    pragma(inline, true)
    void opIndexOpAssign(const(char)[] op)(const(T) rhs, size_t i) {
        mixin("items[i]", op, "= cast(T) rhs;");
    }

    pragma(inline, true)
    size_t opDollar(size_t dim)() {
        return N;
    }

    /// Returns the items of the array.
    pragma(inline, true)
    T[] items() {
        return (cast(T*) data.ptr)[0 .. N];
    }

    /// Returns the pointer of the array.
    pragma(inline, true)
    T* ptr() {
        return cast(T*) data.ptr;
    }
}

/// A static stack allocated on the stack.
struct mu_Stack(T, size_t N) {
    int idx;
    mu_Array!(T, N) data = void;

    alias data this;

    @safe nothrow @nogc:

    /// Pushes a value onto the stack.
    pragma(inline, true)
    void push(T val) {
        items[idx] = val;
        idx += 1; /* incremented after incase `val` uses this value */
    }

    /// Pops a value off the stack.
    pragma(inline, true)
    void pop() {
        mu_expect(idx > 0);
        idx -= 1;
    }
}

/// A RGBA color using ubytes.
struct mu_Color {
    ubyte r, g, b, a;

    @safe nothrow @nogc pure:

    pragma(inline, true)
    mu_Color shift(int value) => mu_shift_color(this, value);
}

/// A 2D rectangle using ints.
struct mu_Rect {
    int x, y, w, h;

    @safe nothrow @nogc pure:

    pragma(inline, true):
    mu_Rect expand(int n) => mu_expand_rect(this, n);
    mu_Rect intersect(mu_Rect r2) => mu_intersect_rects(this, r2);
    bool overlaps(mu_Vec2 p) => mu_rect_overlaps_vec2(this, p);
    bool hasSize() => mu_rect_has_size(this);
}

/// A 2D vector using ints.
struct mu_Vec2 { int x, y; }
/// A 2D vector using floats.
struct mu_FVec2 { mu_Real x = 0, y = 0; }
/// A set of 4 integer margins for left, top, right, and bottom.
struct mu_Margin { int left, top, right, bottom; }

/// A part of a 9-slice with source and target rectangles for drawing.
struct mu_SlicePart {
    mu_Rect source;
    mu_Rect target;
    bool isCorner;
    bool canTile;
    mu_Vec2 tileCount;
}
/// The parts of a 9-slice.
alias mu_SliceParts = mu_Array!(mu_SlicePart, 9);

/// A pool item.
struct mu_PoolItem { mu_Id id; int lastUpdate; }
/// Base structure for all render commands, containing type and size metadata.
struct mu_BaseCommand { mu_CommandEnum type; int size; }
/// Command to jump to another location in the command buffer.
struct mu_JumpCommand { mu_BaseCommand base; void* dst; }
/// Command to set a clipping rectangle.
struct mu_ClipCommand { mu_BaseCommand base; mu_Rect rect; }
/// Command to draw a rectangle with a given color.
struct mu_RectCommand { mu_BaseCommand base; mu_Rect rect; mu_AtlasEnum id; mu_Color color; }
/// Command to render text at a given position with a font and color. The text is a null-terminated string. Use `str.ptr` to access it.
struct mu_TextCommand { mu_BaseCommand base; mu_Font font; mu_Vec2 pos; mu_Color color; int len; char[1] str; }
/// Command to draw an icon inside a rectangle with a given color.
struct mu_IconCommand { mu_BaseCommand base; mu_Rect rect; mu_IconEnum id; mu_Color color; }

/// A union of all possible render commands.
/// The `type` and `base` fields are always valid, as all commands begin with a `mu_CommandEnum` and `mu_BaseCommand`.
/// Use `type` to determine the active command variant.
union mu_Command {
    mu_CommandEnum type;
    mu_BaseCommand base;
    mu_JumpCommand jump;
    mu_ClipCommand clip;
    mu_RectCommand rect;
    mu_TextCommand text;
    mu_IconCommand icon;
}

/// Layout state used to position UI controls within a container.
struct mu_Layout {
    mu_Rect body;
    mu_Rect next;
    mu_Vec2 pos;
    mu_Vec2 size;
    mu_Vec2 max;
    int[MU_MAX_WIDTHS] widths;
    int items;
    int itemIndex;
    int nextRow;
    int nextType;
    int indent;
}

/// A UI container holding commands.
struct mu_Container {
    mu_Command* head;
    mu_Command* tail;
    mu_Rect rect;
    mu_Rect body;
    mu_Vec2 contentSize;
    mu_Vec2 scroll;
    int zIndex;
    bool open;
}

/// UI style settings including font, sizes, spacing, and colors.
struct mu_Style {
    mu_Font font;                                    /// The font used for UI controls.
    mu_Texture texture;                              /// the atlas texture used for UI controls.
    mu_Vec2 size;                                    /// The size of UI controls.
    int padding;                                     /// The padding around UI controls.
    int spacing;                                     /// The spacing between UI controls.
    int indent;                                      /// The indent of UI controls.
    int border;                                      /// The border of UI controls.
    int titleHeight;                                 /// The height of the window title bar.
    int scrollbarSize;                               /// The size of the scrollbar.
    int scrollbarSpeed;                              /// The speed of the scrollbar.
    int scrollbarKeySpeed;                           /// The speed of the scrollbar key.
    int thumbSize;                                   /// The size of the thumb.
    int fontScale;                                   /// The scale of the font.
    mu_Array!(mu_Color, MU_COLOR_MAX) colors;        /// The array of colors used in the UI.
    mu_Array!(mu_Rect, MU_ATLAS_MAX) atlasRects;     /// Optional array of control atlas rectangles used in the UI.
    mu_Array!(mu_Rect, MU_ICON_MAX) iconAtlasRects;  /// Optional array of icon atlas rectangles used in the UI.
    mu_Array!(mu_Margin, MU_ATLAS_MAX) sliceMargins; /// Optional margins for drawing 9-slices.
    mu_SliceMode[MU_ATLAS_MAX] sliceModes;           /// Optional repeat modes for drawing 9-slices.
}

/// The main UI context.
struct mu_Context {
    // -- Callbacks
    mu_TextWidthFunc textWidth;   /// The function used for getting the width of the text.
    mu_TextHeightFunc textHeight; /// The function used for getting the height of the text.
    mu_DrawFrameFunc drawFrame;   /// The function used for drawing a frame.

    // -- Core State
    mu_Style _style; /// The backup UI style.
    mu_Style* style; /// The UI style.
    mu_Id hover;
    mu_Id focus;
    mu_Id lastId;
    mu_Rect lastRect;
    int lastZIndex;
    bool updatedFocus;
    int frame;
    mu_Container* hoverRoot;
    mu_Container* nextHoverRoot;
    mu_Container* scrollTarget;
    char[MU_MAX_FMT] numberEditBuffer;
    mu_Id numberEdit;
    bool isExpectingEnd;         // Used for missing `mu_end` call.
    uint buttonCounter;          // Used to avoid id problems.
    mu_KeyFlags dragWindowKey;   // Used for window stuff.
    mu_KeyFlags resizeWindowKey; // Used for window stuff.

    // -- Stacks
    mu_Stack!(char, MU_COMMANDLIST_SIZE) commandList;
    mu_Stack!(mu_Container*, MU_ROOTLIST_SIZE) rootList;
    mu_Stack!(mu_Container*, MU_CONTAINERSTACK_SIZE) containerStack;
    mu_Stack!(mu_Rect, MU_CLIPSTACK_SIZE) clipStack;
    mu_Stack!(mu_Id, MU_IDSTACK_SIZE) idStack;
    mu_Stack!(mu_Layout, MU_LAYOUTSTACK_SIZE) layoutStack;

    // -- Retained State Pools
    mu_Array!(mu_PoolItem, MU_CONTAINERPOOL_SIZE) containerPool;
    mu_Array!(mu_Container, MU_CONTAINERPOOL_SIZE) containers;
    mu_Array!(mu_PoolItem, MU_TREENODEPOOL_SIZE) treeNodePool;

    // -- Input State
    mu_Vec2 mousePos;
    mu_Vec2 lastMousePos;
    mu_Vec2 mouseDelta;
    mu_Vec2 scrollDelta;
    mu_MouseFlags mouseDown;
    mu_MouseFlags mousePressed;
    mu_KeyFlags keyDown;
    mu_KeyFlags keyPressed;
    char[MU_INPUTTEXT_SIZE] inputText;
    char[] inputTextSlice;
}

private @trusted {
    void draw_frame(mu_Context* ctx, mu_Rect rect, mu_ColorEnum colorid, mu_AtlasEnum atlasid = MU_ATLAS_NONE) {
        mu_draw_rect(ctx, rect, ctx.style.colors[colorid], atlasid);
        if (colorid == MU_COLOR_SCROLLBASE || colorid == MU_COLOR_SCROLLTHUMB || colorid == MU_COLOR_TITLEBG) return;
        /* draw border */
        if (ctx.style.border && rect.hasSize) {
            foreach (i; 1 .. ctx.style.border + 1) {
                mu_draw_box(ctx, mu_expand_rect(rect, i), ctx.style.colors[MU_COLOR_BORDER]);
            }
        }
    }

    int compare_zindex(const(void)* a, const(void)* b) {
        return (*cast(mu_Container**) b).zIndex - (*cast(mu_Container**) a).zIndex;
    }

    void hash(mu_Id* hash, const(void)* data, size_t size) {
        const(ubyte)* p = cast(const(ubyte)*) data;
        while (size--) {
            *hash = (*hash ^ *p++) * 16777619;
        }
    }

    void push_layout(mu_Context* ctx, mu_Rect body, mu_Vec2 scroll) {
        mu_Layout layout;
        memset(&layout, 0, layout.sizeof);
        layout.body = mu_rect(body.x - scroll.x, body.y - scroll.y, body.w, body.h);
        layout.max = mu_vec2(-0x1000000, -0x1000000);
        ctx.layoutStack.push(layout);
        mu_layout_row(ctx, 0, 0);
    }

    mu_Layout* get_layout(mu_Context* ctx) {
        mu_expect(ctx.layoutStack.idx != 0, "No layout available, or attempted to add control outside of a window.");
        return &ctx.layoutStack.items[ctx.layoutStack.idx - 1];
    }

    void pop_container(mu_Context* ctx) {
        mu_Container* cnt = mu_get_current_container(ctx);
        mu_Layout* layout = get_layout(ctx);
        cnt.contentSize.x = layout.max.x - layout.body.x;
        cnt.contentSize.y = layout.max.y - layout.body.y;
        /* pop container, layout and id */
        ctx.containerStack.pop();
        ctx.layoutStack.pop();
        mu_pop_id(ctx);
    }

    mu_Container* get_container(mu_Context* ctx, mu_Id id, mu_OptFlags opt) {
        mu_Container* cnt;
        /* try to get existing container from pool */
        int idx = mu_pool_get(ctx, ctx.containerPool.ptr, MU_CONTAINERPOOL_SIZE, id);
        if (idx >= 0) {
            if (ctx.containers[idx].open || ~opt & MU_OPT_CLOSED) {
                mu_pool_update(ctx, ctx.containerPool.ptr, idx);
            }
            return &ctx.containers[idx];
        }
        if (opt & MU_OPT_CLOSED) { return null; }
        /* container not found in pool: init new container */
        idx = mu_pool_init(ctx, ctx.containerPool.ptr, MU_CONTAINERPOOL_SIZE, id);
        cnt = &ctx.containers[idx];
        memset(cnt, 0, (*cnt).sizeof);
        cnt.open = true;
        mu_bring_to_front(ctx, cnt);
        return cnt;
    }

    mu_Command* push_jump(mu_Context* ctx, mu_Command* dst) {
        mu_Command* cmd;
        cmd = mu_push_command(ctx, MU_COMMAND_JUMP, mu_JumpCommand.sizeof);
        cmd.jump.dst = dst;
        return cmd;
    }

    bool in_hover_root(mu_Context* ctx) {
        int i = ctx.containerStack.idx;
        while (i--) {
            if (ctx.containerStack.items[i] == ctx.hoverRoot) { return true; }
            /* only root containers have their `head` field set; stop searching if we've
            ** reached the current root container */
            if (ctx.containerStack.items[i].head) { break; }
        }
        return false;
    }

    mu_ResFlags number_textbox(mu_Context* ctx, mu_Real* value, mu_Rect r, mu_Id id) {
        if (ctx.mousePressed & MU_MOUSE_LEFT && ctx.keyDown & MU_KEY_SHIFT && ctx.hover == id) {
            ctx.numberEdit = id;
            sprintf(ctx.numberEditBuffer.ptr, MU_REAL_FMT, *value);
        }
        if (ctx.numberEdit == id) {
            mu_ResFlags res = mu_textbox_raw(ctx, ctx.numberEditBuffer, id, r, 0);
            if (res & MU_RES_SUBMIT || ctx.focus != id) {
                *value = strtod(ctx.numberEditBuffer.ptr, null);
                ctx.numberEdit = 0;
            } else {
                return MU_RES_ACTIVE;
            }
        }
        return MU_RES_NONE;
    }

    mu_ResFlags header(mu_Context* ctx, const(char)[] label, int istreenode, mu_OptFlags opt) {
        mu_Rect r;
        int active, expanded;
        mu_Id id = mu_get_id_str(ctx, label);
        int idx = mu_pool_get(ctx, ctx.treeNodePool.ptr, MU_TREENODEPOOL_SIZE, id);
        mu_layout_row(ctx, 0, -1);

        active = (idx >= 0);
        expanded = (opt & MU_OPT_EXPANDED) ? !active : active;
        r = mu_layout_next(ctx);
        mu_update_control(ctx, id, r, 0);

        /* handle click */
        active ^= (ctx.mousePressed & MU_MOUSE_LEFT && ctx.focus == id);
        /* update pool ref */
        if (idx >= 0) {
            if (active) { mu_pool_update(ctx, ctx.treeNodePool.ptr, idx); }
            else { memset(&ctx.treeNodePool[idx], 0, mu_PoolItem.sizeof); }
        } else if (active) {
            mu_pool_init(ctx, ctx.treeNodePool.ptr, MU_TREENODEPOOL_SIZE, id);
        }

        /* draw */
        if (istreenode) {
            if (ctx.hover == id) { ctx.drawFrame(ctx, r, MU_COLOR_BUTTONHOVER); }
        } else {
            mu_draw_control_frame(ctx, id, r, MU_COLOR_BUTTON, 0);
        }
        mu_draw_icon(ctx, expanded ? MU_ICON_EXPANDED : MU_ICON_COLLAPSED, mu_rect(r.x, r.y, r.h, r.h), ctx.style.colors[MU_COLOR_TEXT]);
        r.x += r.h - ctx.style.padding;
        r.w -= r.h - ctx.style.padding;
        mu_draw_control_text(ctx, label, r, MU_COLOR_TEXT, 0);
        return expanded ? MU_RES_ACTIVE : 0;
    }

    void scrollbars(mu_Context* ctx, mu_Container* cnt, mu_Rect* body) {
        int sz = ctx.style.scrollbarSize;
        mu_Vec2 cs = cnt.contentSize;
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

    void push_container_body(mu_Context* ctx, mu_Container* cnt, mu_Rect body, mu_OptFlags opt) {
        if (~opt & MU_OPT_NOSCROLL) { scrollbars(ctx, cnt, &body); }
        push_layout(ctx, mu_expand_rect(body, -ctx.style.padding), cnt.scroll);
        cnt.body = body;
    }

    void begin_root_container(mu_Context* ctx, mu_Container* cnt) {
        /* push container to roots list and push head command */
        ctx.containerStack.push(cnt);
        ctx.rootList.push(cnt);
        cnt.head = push_jump(ctx, null);
        /* set as hover root if the mouse is overlapping this container and it has a
        ** higher z index than the current hover root */
        if (mu_rect_overlaps_vec2(cnt.rect, ctx.mousePos) && (!ctx.nextHoverRoot || cnt.zIndex > ctx.nextHoverRoot.zIndex)) {
            ctx.nextHoverRoot = cnt;
        }
        /* clipping is reset here in case a root-container is made within
        ** another root-containers's begin/end block; this prevents the inner
        ** root-container being clipped to the outer */
        ctx.clipStack.push(mu_unclipped_rect);
    }

    void end_root_container(mu_Context* ctx) {
        /* push tail 'goto' jump command and set head 'skip' command. the final steps
        ** on initing these are done in mu_end() */
        mu_Container* cnt = mu_get_current_container(ctx);
        cnt.tail = push_jump(ctx, null);
        cnt.head.jump.dst = ctx.commandList.items.ptr + ctx.commandList.idx;
        /* pop base clip rect and container */
        mu_pop_clip_rect(ctx);
        pop_container(ctx);
    }

    // The microui assert function.
    nothrow @nogc pure
    void mu_expect(bool x, const(char)[] message = "Fatal microui error.") => assert(x, message);
    // Temporary text measurement function for prototyping.
    nothrow @nogc pure
    int mu_temp_text_width_func(mu_Font font, const(char)[] str) => 200;
    // Temporary text measurement function for prototyping.
    nothrow @nogc pure
    int mu_temp_text_height_func(mu_Font font) => 20;
}

pragma(inline, true) @safe nothrow @nogc pure {
    T mu_min(T)(T a, T b)        => ((a) < (b) ? (a) : (b));
    T mu_max(T)(T a, T b)        => ((a) > (b) ? (a) : (b));
    T mu_clamp(T)(T x, T a, T b) => mu_min(b, mu_max(a, x));

    /// Returns true if the character is a symbol (!, ", ...).
    bool mu_is_symbol_char(char c) {
        return (c >= '!' && c <= '/') || (c >= ':' && c <= '@') || (c >= '[' && c <= '`') || (c >= '{' && c <= '~');
    }

    /// Returns true if the character is a whitespace character (space, tab, ...).
    bool mu_is_space_char(char c) {
        return (c >= '\t' && c <= '\r') || (c == ' ');
    }

    /// Returns true if the character is a autocomplete separator.
    bool mu_is_autocomplete_sep(char c) {
        return mu_is_space_char(c) || mu_is_symbol_char(c);
    }

    mu_Vec2 mu_vec2(int x, int y) {
        return mu_Vec2(x, y);
    }

    mu_FVec2 mu_fvec2(mu_Real x, mu_Real y) {
        return mu_FVec2(x, y);
    }

    mu_Rect mu_rect(int x, int y, int w, int h) {
        return mu_Rect(x, y, w, h);
    }

    mu_Color mu_color(ubyte r, ubyte g, ubyte b, ubyte a) {
        return mu_Color(r, g, b, a);
    }

    mu_Color mu_shift_color(mu_Color c, int value) {
        return mu_color(cast(ubyte) (c.r + value), cast(ubyte) (c.g + value), cast(ubyte) (c.b + value), c.a);
    }

    mu_Rect mu_expand_rect(mu_Rect rect, int n) {
        return mu_rect(rect.x - n, rect.y - n, rect.w + n * 2, rect.h + n * 2);
    }

    mu_Rect mu_intersect_rects(mu_Rect r1, mu_Rect r2) {
        int x1 = mu_max(r1.x, r2.x);
        int y1 = mu_max(r1.y, r2.y);
        int x2 = mu_min(r1.x + r1.w, r2.x + r2.w);
        int y2 = mu_min(r1.y + r1.h, r2.y + r2.h);
        if (x2 < x1) { x2 = x1; }
        if (y2 < y1) { y2 = y1; }
        return mu_rect(x1, y1, x2 - x1, y2 - y1);
    }

    bool mu_rect_overlaps_vec2(mu_Rect r, mu_Vec2 p) {
        return p.x >= r.x && p.x < r.x + r.w && p.y >= r.y && p.y < r.y + r.h;
    }

    bool mu_rect_has_size(mu_Rect r) {
        return r.w > 0 && r.h > 0;
    }

    @trusted
    mu_SliceParts mu_compute_slice_parts(mu_Rect source, mu_Rect target, mu_Margin margin) {
        mu_SliceParts result;
        if (!source.hasSize || !target.hasSize) return result;
        auto can_clip_w = target.w - source.w < -margin.left - margin.right;
        auto can_clip_h = target.h - source.h < -margin.top - margin.bottom;

        // -- 1
        result[0].source.x  = source.x;                                              result[0].source.y = source.y;
        result[0].source.w  = margin.left;                                           result[0].source.h = margin.top;
        result[0].target.x  = target.x;                                              result[0].target.y = target.y;
        result[0].target.w  = margin.left;                                           result[0].target.h = margin.top;
        result[0].isCorner = true;

        result[1].source.x  = source.x + result[0].source.w;                         result[1].source.y = result[0].source.y;
        result[1].source.w  = source.w - margin.left - margin.right;                 result[1].source.h = result[0].source.h;
        result[1].target.x  = target.x + margin.left;                                result[1].target.y = result[0].target.y;
        result[1].target.w  = target.w - margin.left - margin.right;                 result[1].target.h = result[0].target.h;
        result[1].canTile = true;

        result[2].source.x  = source.x + result[0].source.w + result[1].source.w;    result[2].source.y = result[0].source.y;
        result[2].source.w  = margin.right;                                          result[2].source.h = result[0].source.h;
        result[2].target.x  = target.x + target.w - margin.right;                    result[2].target.y = result[0].target.y;
        result[2].target.w  = margin.right;                                          result[2].target.h = result[0].target.h;
        result[2].isCorner = true;

        // -- 2
        result[3].source.x  = result[0].source.x;                                    result[3].source.y = source.y + margin.top;
        result[3].source.w  = result[0].source.w;                                    result[3].source.h = source.h - margin.top - margin.bottom;
        result[3].target.x  = result[0].target.x;                                    result[3].target.y = target.y + margin.top;
        result[3].target.w  = result[0].target.w;                                    result[3].target.h = target.h - margin.top - margin.bottom;
        result[3].canTile = true;

        result[4].source.x  = result[1].source.x;                                    result[4].source.y = result[3].source.y;
        result[4].source.w  = result[1].source.w;                                    result[4].source.h = result[3].source.h;
        result[4].target.x  = result[1].target.x;                                    result[4].target.y = result[3].target.y;
        result[4].target.w  = result[1].target.w;                                    result[4].target.h = result[3].target.h;
        result[4].canTile = true;

        result[5].source.x  = result[2].source.x;                                    result[5].source.y = result[3].source.y;
        result[5].source.w  = result[2].source.w;                                    result[5].source.h = result[3].source.h;
        result[5].target.x  = result[2].target.x;                                    result[5].target.y = result[3].target.y;
        result[5].target.w  = result[2].target.w;                                    result[5].target.h = result[3].target.h;
        result[5].canTile = true;

        // -- 3
        result[6].source.x  = result[0].source.x;                                    result[6].source.y = source.y + margin.top + result[3].source.h;
        result[6].source.w  = result[0].source.w;                                    result[6].source.h = margin.bottom;
        result[6].target.x  = result[0].target.x;                                    result[6].target.y = target.y + margin.top + result[3].target.h;
        result[6].target.w  = result[0].target.w;                                    result[6].target.h = margin.bottom;
        result[6].isCorner = true;

        result[7].source.x  = result[1].source.x;                                    result[7].source.y = result[6].source.y;
        result[7].source.w  = result[1].source.w;                                    result[7].source.h = result[6].source.h;
        result[7].target.x  = result[1].target.x;                                    result[7].target.y = result[6].target.y;
        result[7].target.w  = result[1].target.w;                                    result[7].target.h = result[6].target.h;
        result[7].canTile = true;

        result[8].source.x  = result[2].source.x;                                    result[8].source.y = result[6].source.y;
        result[8].source.w  = result[2].source.w;                                    result[8].source.h = result[6].source.h;
        result[8].target.x  = result[2].target.x;                                    result[8].target.y = result[6].target.y;
        result[8].target.w  = result[2].target.w;                                    result[8].target.h = result[6].target.h;
        result[8].isCorner = true;

        if (can_clip_w) {
            foreach (ref item; result) {
                item.target.x = target.x;
                item.target.w = target.w;
            }
        }
        if (can_clip_h) {
            foreach (ref item; result) {
                item.target.y = target.y;
                item.target.h = target.h;
            }
        }
        result[1].tileCount.x = result[1].source.w ? result[1].target.w / result[1].source.w + 1 : 0;
        result[1].tileCount.y = result[1].source.h ? result[1].target.h / result[1].source.h + 1 : 0;
        result[3].tileCount.x = result[3].source.w ? result[3].target.w / result[3].source.w + 1 : 0;
        result[3].tileCount.y = result[3].source.h ? result[3].target.h / result[3].source.h + 1 : 0;
        result[4].tileCount.x = result[4].source.w ? result[4].target.w / result[4].source.w + 1 : 0;
        result[4].tileCount.y = result[4].source.h ? result[4].target.h / result[4].source.h + 1 : 0;
        result[5].tileCount.x = result[5].source.w ? result[5].target.w / result[5].source.w + 1 : 0;
        result[5].tileCount.y = result[5].source.h ? result[5].target.h / result[5].source.h + 1 : 0;
        result[7].tileCount.x = result[7].source.w ? result[7].target.w / result[7].source.w + 1 : 0;
        result[7].tileCount.y = result[7].source.h ? result[7].target.h / result[7].source.h + 1 : 0;
        return result;
    }
}

@trusted:

nothrow @nogc
void mu_init(mu_Context* ctx, mu_Font font = null, int font_scale = 1) {
    memset(ctx, 0, (*ctx).sizeof);
    ctx.drawFrame = &draw_frame;
    ctx.textWidth = &mu_temp_text_width_func;
    ctx.textHeight = &mu_temp_text_height_func;
    ctx.dragWindowKey = MU_KEY_F1;
    ctx.resizeWindowKey = MU_KEY_F2;
    ctx._style = mu_Style(
        /* font | atlas | size | padding | spacing | indent | border */
        null, null, mu_Vec2(68, 10), 5, 4, 24, 1,
        /* titleHeight | scrollbarSize | scrollbarSpeed | scrollbarKeySpeed | thumbSize | fontScale */
        24, 12, 30, cast(int) (30 * 0.4f), 8, font_scale,
        mu_Array!(mu_Color, 14)(
            mu_Color(230, 230, 230, 255), /* MU_COLOR_TEXT */
            mu_Color(25,  25,  25,  255), /* MU_COLOR_BORDER */
            mu_Color(50,  50,  50,  255), /* MU_COLOR_WINDOWBG */
            mu_Color(25,  25,  25,  255), /* MU_COLOR_TITLEBG */
            mu_Color(240, 240, 240, 255), /* MU_COLOR_TITLETEXT */
            mu_Color(0,   0,   0,   0  ), /* MU_COLOR_PANELBG */
            mu_Color(75,  75,  75,  255), /* MU_COLOR_BUTTON */
            mu_Color(95,  95,  95,  255), /* MU_COLOR_BUTTONHOVER */
            mu_Color(115, 115, 115, 255), /* MU_COLOR_BUTTONFOCUS */
            mu_Color(30,  30,  30,  255), /* MU_COLOR_BASE */
            mu_Color(35,  35,  35,  255), /* MU_COLOR_BASEHOVER */
            mu_Color(40,  40,  40,  255), /* MU_COLOR_BASEFOCUS */
            mu_Color(43,  43,  43,  255), /* MU_COLOR_SCROLLBASE */
            mu_Color(30,  30,  30,  255), /* MU_COLOR_SCROLLTHUMB */
        ),
    );
    ctx.style = &ctx._style;
    ctx.style.font = font;
    ctx.inputTextSlice = ctx.inputText[0 .. 0];
}

nothrow @nogc
void mu_init_with_funcs(mu_Context* ctx, mu_TextWidthFunc width, mu_TextHeightFunc height, mu_Font font = null, int font_scale = 1) {
    mu_init(ctx, font, font_scale);
    ctx.textWidth = width;
    ctx.textHeight = height;
}

void mu_begin(mu_Context* ctx) {
    mu_expect(ctx.textWidth && ctx.textHeight, "Missing text measurement functions (ctx.textWidth, ctx.textHeight).");
    mu_expect(!ctx.isExpectingEnd, "Missing call to `mu_end` after `mu_begin` function.");

    ctx.commandList.idx = 0;
    ctx.rootList.idx = 0;
    ctx.scrollTarget = null;
    ctx.hoverRoot = ctx.nextHoverRoot;
    ctx.nextHoverRoot = null;
    ctx.mouseDelta.x = ctx.mousePos.x - ctx.lastMousePos.x;
    ctx.mouseDelta.y = ctx.mousePos.y - ctx.lastMousePos.y;
    ctx.frame += 1;
    ctx.isExpectingEnd = true;
    ctx.buttonCounter = 0;
}

void mu_end(mu_Context *ctx) {
    /* check stacks */
    mu_expect(ctx.containerStack.idx == 0, "Container stack is not empty.");
    mu_expect(ctx.clipStack.idx      == 0, "Clip stack is not empty.");
    mu_expect(ctx.idStack.idx        == 0, "ID stack is not empty.");
    mu_expect(ctx.layoutStack.idx    == 0, "Layout stack is not empty.");
    ctx.isExpectingEnd = false;
    ctx.buttonCounter = 0;

    /* handle scroll input */
    if (ctx.scrollTarget) {
        if (ctx.keyDown & MU_KEY_SHIFT) ctx.scrollTarget.scroll.x += ctx.scrollDelta.x;
        else ctx.scrollTarget.scroll.y += ctx.scrollDelta.y;
    }

    /* unset focus if focus id was not touched this frame */
    if (!ctx.updatedFocus) { ctx.focus = 0; }
    ctx.updatedFocus = false;

    /* bring hover root to front if mouse was pressed */
    if (ctx.mousePressed && ctx.nextHoverRoot && ctx.nextHoverRoot.zIndex < ctx.lastZIndex && ctx.nextHoverRoot.zIndex >= 0) {
        if (ctx.nextHoverRoot.open) { mu_bring_to_front(ctx, ctx.nextHoverRoot); }
    }

    /* reset input state */
    ctx.keyPressed = 0;
    ctx.inputText[0] = '\0';
    ctx.inputTextSlice = ctx.inputText[0 .. 0];
    ctx.mousePressed = 0;
    ctx.scrollDelta = mu_vec2(0, 0);
    ctx.lastMousePos = ctx.mousePos;

    /* sort root containers by z index */
    int n = ctx.rootList.idx;
    qsort(ctx.rootList.items.ptr, n, (mu_Container*).sizeof, cast(STDLIB_QSORT_FUNC) &compare_zindex);

    /* set root container jump commands */
    foreach (i; 0 .. n) {
        mu_Container* cnt = ctx.rootList.items[i];
        /* if this is the first container then make the first command jump to it.
        ** otherwise set the previous container's tail to jump to this one */
        if (i == 0) {
            mu_Command* cmd = cast(mu_Command*) ctx.commandList.items;
            cmd.jump.dst = cast(char*) cnt.head + mu_JumpCommand.sizeof;
        } else {
            mu_Container* prev = ctx.rootList.items[i - 1];
            prev.tail.jump.dst = cast(char*) cnt.head + mu_JumpCommand.sizeof;
        }
        /* make the last container's tail jump to the end of command list */
        if (i == n - 1) {
            cnt.tail.jump.dst = ctx.commandList.items.ptr + ctx.commandList.idx;
        }
    }
}

void mu_set_focus(mu_Context* ctx, mu_Id id) {
    ctx.focus = id;
    ctx.updatedFocus = true;
}

mu_Id mu_get_id(mu_Context *ctx, const(void)* data, size_t size) {
    enum HASH_INITIAL = 2166136261; // A 32bit fnv-1a hash.

    int idx = ctx.idStack.idx;
    mu_Id res = (idx > 0) ? ctx.idStack.items[idx - 1] : HASH_INITIAL;
    hash(&res, data, size);
    ctx.lastId = res;
    return res;
}

mu_Id mu_get_id_str(mu_Context *ctx, const(char)[] str) {
    return mu_get_id(ctx, str.ptr, str.length);
}

void mu_push_id(mu_Context* ctx, const(void)* data, size_t size) {
    ctx.idStack.push(mu_get_id(ctx, data, size));
}

void mu_push_id_str(mu_Context* ctx, const(char)[] str) {
    ctx.idStack.push(mu_get_id(ctx, str.ptr, str.length));
}

void mu_pop_id(mu_Context* ctx) {
    ctx.idStack.pop();
}

void mu_push_clip_rect(mu_Context* ctx, mu_Rect rect) {
    mu_Rect last = mu_get_clip_rect(ctx);
    ctx.clipStack.push(mu_intersect_rects(rect, last));
}

void mu_pop_clip_rect(mu_Context* ctx) {
    ctx.clipStack.pop();
}

mu_Rect mu_get_clip_rect(mu_Context* ctx) {
    mu_expect(ctx.clipStack.idx > 0);
    return ctx.clipStack.items[ctx.clipStack.idx - 1];
}

mu_ClipEnum mu_check_clip(mu_Context* ctx, mu_Rect r) {
    mu_Rect cr = mu_get_clip_rect(ctx);
    if (r.x > cr.x + cr.w || r.x + r.w < cr.x || r.y > cr.y + cr.h || r.y + r.h < cr.y) { return MU_CLIP_ALL; }
    if (r.x >= cr.x && r.x + r.w <= cr.x + cr.w && r.y >= cr.y && r.y + r.h <= cr.y + cr.h) { return MU_CLIP_NONE; }
    return MU_CLIP_PART;
}

mu_Container* mu_get_current_container(mu_Context* ctx) {
    mu_expect(ctx.containerStack.idx > 0);
    return ctx.containerStack.items[ctx.containerStack.idx - 1];
}

mu_Container* mu_get_container(mu_Context* ctx, const(char)[] name) {
    mu_Id id = mu_get_id_str(ctx, name);
    return get_container(ctx, id, 0);
}

void mu_bring_to_front(mu_Context* ctx, mu_Container* cnt) {
    cnt.zIndex = ++ctx.lastZIndex;
}

/*============================================================================
** pool
**============================================================================*/

int mu_pool_init(mu_Context* ctx, mu_PoolItem* items, size_t len, mu_Id id) {
    int n = -1;
    int f = ctx.frame;
    foreach (i; 0 .. len) {
        if (items[i].lastUpdate < f) {
            f = items[i].lastUpdate;
            n = cast(int) i;
        }
    }
    mu_expect(n > -1);
    items[n].id = id;
    mu_pool_update(ctx, items, n);
    return n;
}

int mu_pool_get(mu_Context* ctx, mu_PoolItem* items, size_t len, mu_Id id) {
    foreach (i; 0 .. len) {
        if (items[i].id == id) { return cast(int) i; }
    }
    return -1;
}

void mu_pool_update(mu_Context* ctx, mu_PoolItem* items, size_t idx) {
    items[idx].lastUpdate = ctx.frame;
}

/*============================================================================
** input handlers
**============================================================================*/

nothrow @nogc {
    void mu_input_mousemove(mu_Context* ctx, int x, int y) {
        ctx.mousePos = mu_vec2(x, y);
    }

    void mu_input_mousedown(mu_Context* ctx, int x, int y, mu_MouseFlags btn) {
        mu_input_mousemove(ctx, x, y);
        ctx.mouseDown |= btn;
        ctx.mousePressed |= btn;
    }

    void mu_input_mouseup(mu_Context* ctx, int x, int y, mu_MouseFlags btn) {
        mu_input_mousemove(ctx, x, y);
        ctx.mouseDown &= ~btn;
    }

    void mu_input_scroll(mu_Context* ctx, int x, int y) {
        ctx.scrollDelta.x += x * ctx.style.scrollbarSpeed;
        ctx.scrollDelta.y += y * ctx.style.scrollbarSpeed;
    }

    void mu_input_keydown(mu_Context* ctx, mu_KeyFlags key) {
        ctx.keyPressed |= key;
        ctx.keyDown |= key;
    }

    void mu_input_keyup(mu_Context* ctx, mu_KeyFlags key) {
        ctx.keyDown &= ~key;
    }

    void mu_input_text(mu_Context* ctx, const(char)[] text) {
        size_t len = ctx.inputTextSlice.length;
        size_t size = text.length;
        mu_expect(len + size < ctx.inputText.sizeof);
        memcpy(ctx.inputText.ptr + len, text.ptr, size);
        // Added this to make it work with slices.
        ctx.inputText[len + size] = '\0';
        ctx.inputTextSlice = ctx.inputText[0 .. len + size];
    }
}

/*============================================================================
** commandlist
**============================================================================*/

// NOTE(Kapendev): Should maybe zero the memory?
mu_Command* mu_push_command(mu_Context* ctx, mu_CommandEnum type, size_t size) {
    mu_Command* cmd = cast(mu_Command*) (ctx.commandList.items.ptr + ctx.commandList.idx);
    mu_expect(ctx.commandList.idx + size < MU_COMMANDLIST_SIZE);
    cmd.base.type = type;
    cmd.base.size = cast(int) size;
    ctx.commandList.idx += size;
    return cmd;
}

bool mu_next_command(mu_Context* ctx, mu_Command** cmd) {
    if (*cmd) {
        *cmd = cast(mu_Command*) ((cast(char*) *cmd) + (*cmd).base.size);
    } else {
        *cmd = cast(mu_Command*) ctx.commandList.items;
    }
    while (cast(char*) *cmd != ctx.commandList.items.ptr + ctx.commandList.idx) {
        if ((*cmd).type != MU_COMMAND_JUMP) { return true; }
        *cmd = cast(mu_Command*) (*cmd).jump.dst;
    }
    return false;
}

void mu_set_clip(mu_Context* ctx, mu_Rect rect) {
    mu_Command* cmd;
    cmd = mu_push_command(ctx, MU_COMMAND_CLIP, mu_ClipCommand.sizeof);
    cmd.clip.rect = rect;
}

void mu_draw_rect(mu_Context* ctx, mu_Rect rect, mu_Color color, mu_AtlasEnum id = MU_ATLAS_NONE) {
    mu_Command* cmd;
    mu_ClipEnum clipped;
    auto intersect_rect = mu_intersect_rects(rect, mu_get_clip_rect(ctx));
    auto is_atlas_rect = id != MU_ATLAS_NONE && ctx.style.atlasRects[id].hasSize;
    auto target_rect = is_atlas_rect ? rect : intersect_rect;

    if (target_rect.hasSize) {
        if (is_atlas_rect) {
            clipped = mu_check_clip(ctx, target_rect);
            if (clipped == MU_CLIP_ALL ) { return; }
            if (clipped == MU_CLIP_PART) { mu_set_clip(ctx, mu_get_clip_rect(ctx)); }
        }

        // See `draw_frame` for more info.
        cmd = mu_push_command(ctx, MU_COMMAND_RECT, mu_RectCommand.sizeof);
        cmd.rect.rect = target_rect;
        cmd.rect.color = color;
        cmd.rect.id = id;

        if (is_atlas_rect) {
            if (clipped) { mu_set_clip(ctx, mu_unclipped_rect); }
        }
    }
}

void mu_draw_box(mu_Context* ctx, mu_Rect rect, mu_Color color) {
    mu_draw_rect(ctx, mu_rect(rect.x + 1, rect.y, rect.w - 2, 1), color);
    mu_draw_rect(ctx, mu_rect(rect.x + 1, rect.y + rect.h - 1, rect.w - 2, 1), color);
    mu_draw_rect(ctx, mu_rect(rect.x, rect.y, 1, rect.h), color);
    mu_draw_rect(ctx, mu_rect(rect.x + rect.w - 1, rect.y, 1, rect.h), color);
}

void mu_draw_text(mu_Context* ctx, mu_Font font, const(char)[] str, mu_Vec2 pos, mu_Color color) {
    mu_Command* cmd;
    mu_Rect rect = mu_rect(pos.x, pos.y, ctx.textWidth(font, str), ctx.textHeight(font));
    mu_ClipEnum clipped = mu_check_clip(ctx, rect);
    if (clipped == MU_CLIP_ALL ) { return; }
    if (clipped == MU_CLIP_PART) { mu_set_clip(ctx, mu_get_clip_rect(ctx)); }
    /* add command */
    cmd = mu_push_command(ctx, MU_COMMAND_TEXT, mu_TextCommand.sizeof + str.length);
    mu_expect(str.length < MU_STR_SIZE, "String is too big. See `MU_STR_SIZE`.");
    memcpy(cmd.text.str.ptr, str.ptr, str.length);
    cmd.text.str.ptr[str.length] = '\0';
    cmd.text.len = cast(int) str.length;
    cmd.text.pos = pos;
    cmd.text.color = color;
    cmd.text.font = font;
    /* reset clipping if it was set */
    if (clipped) { mu_set_clip(ctx, mu_unclipped_rect); }
}

void mu_draw_icon(mu_Context* ctx, mu_IconEnum id, mu_Rect rect, mu_Color color) {
    mu_Command* cmd;
    /* do clip command if the rect isn't fully contained within the cliprect */
    mu_ClipEnum clipped = mu_check_clip(ctx, rect);
    if (clipped == MU_CLIP_ALL ) { return; }
    if (clipped == MU_CLIP_PART) { mu_set_clip(ctx, mu_get_clip_rect(ctx)); }
    /* do icon command */
    cmd = mu_push_command(ctx, MU_COMMAND_ICON, mu_IconCommand.sizeof);
    cmd.icon.id = id;
    cmd.icon.rect = rect;
    cmd.icon.color = color;
    /* reset clipping if it was set */
    if (clipped) { mu_set_clip(ctx, mu_unclipped_rect); }
}

/*============================================================================
** layout
**============================================================================*/

void mu_layout_begin_column(mu_Context* ctx) {
    push_layout(ctx, mu_layout_next(ctx), mu_vec2(0, 0));
}

void mu_layout_end_column(mu_Context* ctx) {
    mu_Layout* a, b;
    b = get_layout(ctx);
    ctx.layoutStack.pop();
    /* inherit position/nextRow/max from child layout if they are greater */
    a = get_layout(ctx);
    a.pos.x = mu_max(a.pos.x, b.pos.x + b.body.x - a.body.x);
    a.nextRow = mu_max(a.nextRow, b.nextRow + b.body.y - a.body.y);
    a.max.x = mu_max(a.max.x, b.max.x);
    a.max.y = mu_max(a.max.y, b.max.y);
}

void mu_layout_row_legacy(mu_Context* ctx, int items, const(int)* widths, int height) {
    mu_Layout* layout = get_layout(ctx);
    if (widths) {
        mu_expect(items <= MU_MAX_WIDTHS);
        memcpy(layout.widths.ptr, widths, items * widths[0].sizeof);
    }
    layout.items = items;
    layout.pos = mu_vec2(layout.indent, layout.nextRow);
    layout.size.y = height;
    layout.itemIndex = 0;
}

void mu_layout_row(mu_Context* ctx, int height, const(int)[] widths...) {
    mu_layout_row_legacy(ctx, cast(int) widths.length, widths.ptr, height);
}

void mu_layout_width(mu_Context* ctx, int width) {
    get_layout(ctx).size.x = width;
}

void mu_layout_height(mu_Context* ctx, int height) {
    get_layout(ctx).size.y = height;
}

void mu_layout_set_next(mu_Context* ctx, mu_Rect r, bool relative) {
    mu_Layout* layout = get_layout(ctx);
    layout.next = r;
    layout.nextType = relative ? RELATIVE : ABSOLUTE;
}

mu_Rect mu_layout_next(mu_Context* ctx) {
    mu_Layout* layout = get_layout(ctx);
    mu_Style* style = ctx.style;
    mu_Rect res;

    if (layout.nextType) {
        /* handle rect set by `mu_layout_set_next` */
        int type = layout.nextType;
        layout.nextType = 0;
        res = layout.next;
        if (type == ABSOLUTE) { return (ctx.lastRect = res); }
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
    layout.nextRow = mu_max(layout.nextRow, res.y + res.h + style.spacing);
    /* apply body offset */
    res.x += layout.body.x;
    res.y += layout.body.y;
    /* update max position */
    layout.max.x = mu_max(layout.max.x, res.x + res.w);
    layout.max.y = mu_max(layout.max.y, res.y + res.h);
    ctx.lastRect = res;
    return ctx.lastRect;
}

/*============================================================================
** controls
**============================================================================*/

void mu_draw_control_frame(mu_Context* ctx, mu_Id id, mu_Rect rect, mu_ColorEnum colorid, mu_OptFlags opt, mu_AtlasEnum atlasid = MU_ATLAS_NONE) {
    if (opt & MU_OPT_NOFRAME) { return; }
    colorid += (ctx.focus == id) ? 2 : (ctx.hover == id) ? 1 : 0;
    atlasid += (ctx.focus == id) ? 2 : (ctx.hover == id) ? 1 : 0;
    ctx.drawFrame(ctx, rect, colorid, atlasid);
}

void mu_draw_control_text_legacy(mu_Context* ctx, const(char)* str, mu_Rect rect, mu_ColorEnum colorid, mu_OptFlags opt) {
    mu_draw_control_text(ctx, str[0 .. (str ? strlen(str) : 0)], rect, colorid, opt);
}

void mu_draw_control_text(mu_Context* ctx, const(char)[] str, mu_Rect rect, mu_ColorEnum colorid, mu_OptFlags opt) {
    mu_Vec2 pos;
    mu_Font font = ctx.style.font;
    int tw = ctx.textWidth(font, str);
    mu_push_clip_rect(ctx, rect);
    pos.y = rect.y + (rect.h - ctx.textHeight(font)) / 2;
    if (opt & MU_OPT_ALIGNCENTER) {
        pos.x = rect.x + (rect.w - tw) / 2;
    } else if (opt & MU_OPT_ALIGNRIGHT) {
        pos.x = rect.x + rect.w - tw - ctx.style.padding;
    } else {
        pos.x = rect.x + ctx.style.padding;
    }
    mu_draw_text(ctx, font, str, pos, ctx.style.colors[colorid]);
    mu_pop_clip_rect(ctx);
}

bool mu_mouse_over(mu_Context* ctx, mu_Rect rect) {
    return mu_rect_overlaps_vec2(rect, ctx.mousePos) && mu_rect_overlaps_vec2(mu_get_clip_rect(ctx), ctx.mousePos) && in_hover_root(ctx);
}

void mu_update_control(mu_Context* ctx, mu_Id id, mu_Rect rect, mu_OptFlags opt, bool isDragOrResizeControl = false, mu_MouseFlags action = MU_MOUSE_LEFT) {
    if (!isDragOrResizeControl) {
        if (ctx.keyDown & ctx.dragWindowKey || ctx.keyDown & ctx.resizeWindowKey) { return; }
    }

    bool mouseover = mu_mouse_over(ctx, rect);
    if (ctx.focus == 0 && opt & MU_OPT_DEFAULTFOCUS) { mu_set_focus(ctx, id); }

    if (ctx.focus == id) { ctx.updatedFocus = true; }
    if (opt & MU_OPT_NOINTERACT) { return; }
    if (mouseover && !(ctx.mouseDown & action)) { ctx.hover = id; }
    if (ctx.focus == id && ~opt & MU_OPT_DEFAULTFOCUS) {
        if (ctx.mousePressed & action && !mouseover) { mu_set_focus(ctx, 0); }
        if (!(ctx.mouseDown & action) && ~opt & MU_OPT_HOLDFOCUS) { mu_set_focus(ctx, 0); }
    }
    if (ctx.hover == id) {
        if (ctx.mousePressed & action) {
            mu_set_focus(ctx, id);
        } else if (!mouseover) {
            ctx.hover = 0;
        }
    }
}

void mu_text_legacy(mu_Context* ctx, const(char)* text) {
    mu_text(ctx, text[0 .. (text ? strlen(text) : 0)]);
}

/// It handles both D strings and C strings, so you can also pass null-terminated buffers directly.
// NOTE(Kapendev): Might need checking. I replaced lines without thinking too much. Original code had bugs too btw.
void mu_text(mu_Context* ctx, const(char)[] text) {
    mu_Font font = ctx.style.font;
    mu_Color color = ctx.style.colors[MU_COLOR_TEXT];
    mu_layout_begin_column(ctx);
    mu_layout_row(ctx, ctx.textHeight(font), -1);

    if (text.length != 0) {
        const(char)* p = text.ptr;
        const(char)* start = p;
        const(char)* end = p;
        do {
            mu_Rect r = mu_layout_next(ctx);
            int w = 0;
            start = p;
            end = p;
            do {
                const(char)* word = p;
                while (p < text.ptr + text.length && *p && *p != ' ' && *p != '\n') { p += 1; }
                w += ctx.textWidth(font, word[0 .. p - word]);
                if (w > r.w && end != start) { break; }
                end = p++;
            } while(end < text.ptr + text.length && *end && *end != '\n');
            mu_draw_text(ctx, font, start[0 .. end - start], mu_vec2(r.x, r.y), color);
            p = end + 1;
        } while(end < text.ptr + text.length && *end);
    }
    mu_layout_end_column(ctx);
}

void mu_label_legacy(mu_Context* ctx, const(char)* text) {
    mu_label(ctx, text[0 .. (text ? strlen(text) : 0)]);
}

void mu_label(mu_Context* ctx, const(char)[] text) {
    mu_draw_control_text(ctx, text, mu_layout_next(ctx), MU_COLOR_TEXT, 0);
}

mu_ResFlags mu_button_ex_legacy(mu_Context* ctx, const(char)[] label, mu_IconEnum icon, mu_OptFlags opt) {
    mu_ResFlags res = MU_RES_NONE;
    mu_Id id = (label.ptr && label.length)
        ? mu_get_id_str(ctx, label)
        : mu_get_id(ctx, &icon, icon.sizeof);
    mu_Rect r = mu_layout_next(ctx);
    mu_update_control(ctx, id, r, opt);
    /* handle click */
    if (ctx.focus == id) {
        if (opt & MU_OPT_DEFAULTFOCUS) {
            if (ctx.keyPressed & MU_KEY_RETURN || (ctx.hover == id && ctx.mousePressed & MU_MOUSE_LEFT)) { res |= MU_RES_SUBMIT; }
        } else {
            if (ctx.mousePressed & MU_MOUSE_LEFT) { res |= MU_RES_SUBMIT; }
        }
    }
    /* draw */
    mu_draw_control_frame(ctx, id, r, MU_COLOR_BUTTON, opt, MU_ATLAS_BUTTON);
    if (label.ptr) { mu_draw_control_text(ctx, label, r, MU_COLOR_TEXT, opt); }
    if (icon) { mu_draw_icon(ctx, icon, r, ctx.style.colors[MU_COLOR_TEXT]); }
    return res;
}

mu_ResFlags mu_button_ex(mu_Context* ctx, const(char)[] label, mu_IconEnum icon, mu_OptFlags opt) {
    mu_push_id(ctx, &ctx.buttonCounter, ctx.buttonCounter.sizeof);
    auto res = mu_button_ex_legacy(ctx, label, icon, opt);
    mu_pop_id(ctx);
    ctx.buttonCounter += 1;
    return res;
}

mu_ResFlags mu_button(mu_Context* ctx, const(char)[] label) {
    return mu_button_ex(ctx, label, 0, MU_OPT_ALIGNCENTER);
}

// NOTE(Kapendev): The only function that puts the return pointer at the end. It's fine.
mu_ResFlags mu_checkbox(mu_Context* ctx, const(char)[] label, bool* state) {
    mu_ResFlags res = MU_RES_NONE;
    mu_Id id = mu_get_id(ctx, &state, state.sizeof);
    mu_Rect r = mu_layout_next(ctx);
    mu_Rect box = mu_rect(r.x, r.y, r.h, r.h);
    mu_update_control(ctx, id, box, 0); // NOTE(Kapendev): Why was this r and not box???
    /* handle click */
    if (ctx.mousePressed & MU_MOUSE_LEFT && ctx.focus == id) {
        res |= MU_RES_CHANGE;
        *state = !*state;
    }
    /* draw */
    mu_draw_control_frame(ctx, id, box, MU_COLOR_BASE, 0);
    if (*state) {
        mu_draw_icon(ctx, MU_ICON_CHECK, box, ctx.style.colors[MU_COLOR_TEXT]);
    }
    r = mu_rect(r.x + box.w, r.y, r.w - box.w, r.h);
    mu_draw_control_text(ctx, label, r, MU_COLOR_TEXT, 0);
    return res;
}

mu_ResFlags mu_textbox_raw_legacy(mu_Context* ctx, char* buf, size_t bufsz, mu_Id id, mu_Rect r, mu_OptFlags opt, size_t* newlen = null) {
    mu_ResFlags res;
    mu_update_control(ctx, id, r, opt | MU_OPT_HOLDFOCUS);

    size_t buflen = strlen(buf);
    if (ctx.focus == id) {
        /* handle text input */
        int n = mu_min((cast(int) bufsz) - (cast(int) buflen) - 1, cast(int) ctx.inputTextSlice.length);
        if (n > 0) {
            memcpy(buf + buflen, ctx.inputText.ptr, n);
            buflen += n;
            buf[buflen] = '\0';
            res |= MU_RES_CHANGE;
        }
        /* handle backspace */
        if (ctx.keyPressed & MU_KEY_BACKSPACE && buflen > 0) {
            if (ctx.keyDown & MU_KEY_CTRL) {
                buflen = 0;
                buf[buflen] = '\0';
            } else if (ctx.keyDown & MU_KEY_ALT && buflen > 0) {
                /* skip empty space */
                while (buf[buflen - 1] == ' ') { buflen -= 1; }
                while (buflen > 0) {
                    /* skip utf-8 continuation bytes */
                    while ((buf[--buflen] & 0xc0) == 0x80 && buflen > 0) {}
                    if (buflen == 0 || mu_is_autocomplete_sep(buf[buflen - 1])) break;
                }
                buf[buflen] = '\0';
            } else if (buflen > 0) {
                /* skip utf-8 continuation bytes */
                while ((buf[--buflen] & 0xc0) == 0x80 && buflen > 0) {}
                buf[buflen] = '\0';
            }
            res |= MU_RES_CHANGE;
        }
        /* handle return */
        if (ctx.keyPressed & MU_KEY_RETURN) {
            mu_set_focus(ctx, 0);
            res |= MU_RES_SUBMIT;
        }
    }

    /* draw */
    mu_draw_control_frame(ctx, id, r, MU_COLOR_BASE, opt);
    if (ctx.focus == id) {
        mu_Color color = ctx.style.colors[MU_COLOR_TEXT];
        mu_Font font = ctx.style.font;
        int textw = ctx.textWidth(font, buf[0 .. buflen]);
        int texth = ctx.textHeight(font);
        int ofx = r.w - ctx.style.padding - textw - 1;
        int textx = r.x + mu_min(ofx, ctx.style.padding);
        int texty = r.y + (r.h - texth) / 2;
        mu_push_clip_rect(ctx, r);

        if (opt & MU_OPT_ALIGNCENTER) {
            textx = r.x + (r.w - textw) / 2;
        } else if (opt & MU_OPT_ALIGNRIGHT) {
            textx = r.x + r.w - textw - ctx.style.padding;
        }

        mu_draw_text(ctx, font, buf[0 .. buflen], mu_vec2(textx, texty), color);
        mu_draw_rect(ctx, mu_rect(textx + textw, texty, 1, texth), color);
        mu_pop_clip_rect(ctx);
    } else {
        mu_draw_control_text(ctx, buf[0 .. buflen], r, MU_COLOR_TEXT, opt);
    }
    if (newlen) *newlen = buflen;
    return res;
}

mu_ResFlags mu_textbox_raw(mu_Context* ctx, char[] buf, mu_Id id, mu_Rect r, mu_OptFlags opt, size_t* newlen = null) {
    return mu_textbox_raw_legacy(ctx, buf.ptr, buf.length, id, r, opt, newlen);
}

mu_ResFlags mu_textbox_ex_legacy(mu_Context* ctx, char* buf, size_t bufsz, mu_OptFlags opt, size_t* newlen = null) {
    mu_Id id = mu_get_id(ctx, &buf, buf.sizeof);
    mu_Rect r = mu_layout_next(ctx);
    return mu_textbox_raw_legacy(ctx, buf, bufsz, id, r, opt, newlen);
}

mu_ResFlags mu_textbox_ex(mu_Context* ctx, char[] buf, mu_OptFlags opt, size_t* newlen = null) {
    return mu_textbox_ex_legacy(ctx, buf.ptr, buf.length, opt, newlen);
}

mu_ResFlags mu_textbox_legacy(mu_Context* ctx, char* buf, size_t bufsz, size_t* newlen = null) {
    return mu_textbox_ex_legacy(ctx, buf, bufsz, 0, newlen);
}

mu_ResFlags mu_textbox(mu_Context* ctx, char[] buf, size_t* newlen = null) {
    return  mu_textbox_legacy(ctx, buf.ptr, buf.length, newlen);
}

mu_ResFlags mu_slider_ex(mu_Context* ctx, mu_Real* value, mu_Real low, mu_Real high, mu_Real step, const(char)[] fmt, mu_OptFlags opt) {
    // Used for the `sprintf` function.
    char[MU_MAX_FMT + 1] fmt_buf = void;
    mu_expect(fmt_buf.length > fmt.length);
    memcpy(fmt_buf.ptr, fmt.ptr, fmt.length);
    fmt_buf[fmt.length] = '\0';

    char[MU_MAX_FMT + 1] buf = void;
    int x, w;
    mu_Rect thumb;
    mu_ResFlags res = 0;
    mu_Real last = *value, v = last;
    mu_Id id = mu_get_id(ctx, &value, value.sizeof);
    mu_Rect base = mu_layout_next(ctx);

    /* handle text input mode */
    if (number_textbox(ctx, &v, base, id)) { return res; }
    /* handle normal mode */
    mu_update_control(ctx, id, base, opt);
    /* handle input */
    if (ctx.focus == id && (ctx.mouseDown | ctx.mousePressed) & MU_MOUSE_LEFT) {
        v = low + (ctx.mousePos.x - base.x) * (high - low) / base.w;
        if (step) { v = (cast(long) ((v + step / 2) / step)) * step; }
    }
    /* clamp and store value, update res */
    *value = v = mu_clamp(v, low, high);
    if (last != v) { res |= MU_RES_CHANGE; }

    /* draw base */
    mu_draw_control_frame(ctx, id, base, MU_COLOR_BASE, opt);
    /* draw thumb */
    w = ctx.style.thumbSize;
    x = cast(int) ((v - low) * (base.w - w) / (high - low));
    thumb = mu_rect(base.x + x, base.y, w, base.h);
    mu_draw_control_frame(ctx, id, thumb, MU_COLOR_BUTTON, opt);
    /* draw text  */
    // This original was not checking the result of `sprintf`...
    int buflen = sprintf(buf.ptr, fmt_buf.ptr, v);
    if (buflen < 0) buflen = 0;
    mu_draw_control_text(ctx, buf[0 .. buflen], base, MU_COLOR_TEXT, opt);
    return res;
}

mu_ResFlags mu_slider_ex_int(mu_Context* ctx, int* value, int low, int high, int step, const(char)[] fmt, mu_OptFlags opt) {
    mu_push_id(ctx, &value, value.sizeof);
    mu_Real temp = *value;
    mu_ResFlags res = mu_slider_ex(ctx, &temp, low, high, step, fmt, opt);
    *value = cast(int) temp;
    mu_pop_id(ctx);
    return res;
}

mu_ResFlags mu_slider(mu_Context* ctx, mu_Real* value, mu_Real low, mu_Real high) {
    return mu_slider_ex(ctx, value, low, high, 0.01f, MU_SLIDER_FMT, MU_OPT_ALIGNCENTER);
}

mu_ResFlags mu_slider_int(mu_Context* ctx, int* value, int low, int high) {
    return mu_slider_ex_int(ctx, value, low, high, 1, MU_SLIDER_INT_FMT, MU_OPT_ALIGNCENTER);
}

mu_ResFlags mu_number_ex(mu_Context* ctx, mu_Real* value, mu_Real step, const(char)[] fmt, mu_OptFlags opt) {
    // Used for the `sprintf` function.
    char[MU_MAX_FMT + 1] fmt_buf = void;
    mu_expect(fmt_buf.length > fmt.length);
    memcpy(fmt_buf.ptr, fmt.ptr, fmt.length);
    fmt_buf[fmt.length] = '\0';

    char[MU_MAX_FMT + 1] buf = void;
    mu_ResFlags res = 0;
    mu_Id id = mu_get_id(ctx, &value, value.sizeof);
    mu_Rect base = mu_layout_next(ctx);
    mu_Real last = *value;

    /* handle text input mode */
    if (number_textbox(ctx, value, base, id)) { return res; }
    /* handle normal mode */
    mu_update_control(ctx, id, base, opt);
    /* handle input */
    if (ctx.focus == id && ctx.mouseDown & MU_MOUSE_LEFT) { *value += ctx.mouseDelta.x * step; }
    /* set flag if value changed */
    if (*value != last) { res |= MU_RES_CHANGE; }

    /* draw base */
    mu_draw_control_frame(ctx, id, base, MU_COLOR_BASE, opt);
    /* draw text  */
    // This original was not checking the result of `sprintf`...
    int buflen = sprintf(buf.ptr, fmt_buf.ptr, *value);
    if (buflen < 0) buflen = 0;
    mu_draw_control_text(ctx, buf[0 .. buflen], base, MU_COLOR_TEXT, opt);
    return res;
}

mu_ResFlags mu_number_ex_int(mu_Context* ctx, int* value, int step, const(char)[] fmt, mu_OptFlags opt) {
    mu_push_id(ctx, &value, value.sizeof);
    mu_Real temp = *value;
    mu_ResFlags res = mu_number_ex(ctx, &temp, step, fmt, opt);
    *value = cast(int) temp;
    mu_pop_id(ctx);
    return res;
}

mu_ResFlags mu_number(mu_Context* ctx, mu_Real* value, mu_Real step) {
    return mu_number_ex(ctx, value, step, MU_SLIDER_FMT, MU_OPT_ALIGNCENTER);
}

mu_ResFlags mu_number_int(mu_Context* ctx, int* value, int step) {
    return mu_number_ex_int(ctx, value, step, MU_SLIDER_INT_FMT, MU_OPT_ALIGNCENTER);
}

mu_ResFlags mu_header_ex(mu_Context* ctx, const(char)[] label, mu_OptFlags opt) {
    return header(ctx, label, 0, opt);
}

mu_ResFlags mu_header(mu_Context* ctx, const(char)[] label) {
    return mu_header_ex(ctx, label, 0);
}

mu_ResFlags mu_begin_treenode_ex(mu_Context* ctx, const(char)[] label, mu_OptFlags opt) {
    mu_ResFlags res = header(ctx, label, 1, opt);
    if (res & MU_RES_ACTIVE) {
        get_layout(ctx).indent += ctx.style.indent;
        ctx.idStack.push(ctx.lastId);
    }
    return res;
}

mu_ResFlags mu_begin_treenode(mu_Context* ctx, const(char)[] label) {
    return mu_begin_treenode_ex(ctx, label, 0);
}

void mu_end_treenode(mu_Context* ctx) {
    get_layout(ctx).indent -= ctx.style.indent;
    mu_pop_id(ctx);
}

void mu_scrollbar_y(mu_Context* ctx, mu_Container* cnt, mu_Rect* b, mu_Vec2 cs) {
    /* only add scrollbar if content size is larger than body */
    int maxscroll = cs.y - b.h;
    if (maxscroll > 0 && b.h > 0) {
        mu_Rect base, thumb, mouse_area;
        mu_Id id = mu_get_id_str(ctx, "!scrollbary");
        /* get sizing/positioning */
        base = *b;
        base.x = b.x + b.w;
        base.w = ctx.style.scrollbarSize;
        thumb = base;
        thumb.h = mu_max(ctx.style.thumbSize, base.h * b.h / cs.y);
        thumb.y += cnt.scroll.y * (base.h - thumb.h) / maxscroll;
        mouse_area = *b;
        mouse_area.w += ctx.style.scrollbarSize;
        mouse_area.h += ctx.style.scrollbarSize;
        /* handle input */
        mu_update_control(ctx, id, base, 0);
        if (ctx.focus == id && ctx.mouseDown & MU_MOUSE_LEFT) {
            if (ctx.mousePressed & MU_MOUSE_LEFT) {
                cnt.scroll.y = ((ctx.mousePos.y - base.y - thumb.h / 2) * maxscroll) / (base.h - thumb.h);
            } else {
                cnt.scroll.y += ctx.mouseDelta.y * cs.y / base.h;
            }
        }
        // TODO: Containers inside containers don't work that well. Fix later.
        if ((ctx.focus == id || cnt.zIndex >= ctx.lastZIndex) && ~ctx.keyDown & MU_KEY_SHIFT) {
            if (ctx.keyPressed & MU_KEY_HOME) {
                cnt.scroll.y = 0;
            } else if (ctx.keyPressed & MU_KEY_END) {
                cnt.scroll.y = maxscroll;
            }
            if (ctx.keyDown & MU_KEY_PAGEUP) {
                cnt.scroll.y -= ctx.style.scrollbarKeySpeed;
            } else if (ctx.keyDown & MU_KEY_PAGEDOWN) {
                cnt.scroll.y += ctx.style.scrollbarKeySpeed;
            }
        }
        /* clamp scroll to limits */
        cnt.scroll.y = mu_clamp(cnt.scroll.y, 0, maxscroll);
        thumb.y = mu_clamp(thumb.y, base.y, base.y + base.h - thumb.h);
        /* draw base and thumb */
        ctx.drawFrame(ctx, base, MU_COLOR_SCROLLBASE);
        ctx.drawFrame(ctx, thumb, MU_COLOR_SCROLLTHUMB);
        /* set this as the scroll target (will get scrolled on mousewheel) */
        /* if the mouse is over it */
        if (mu_mouse_over(ctx, mouse_area)) { ctx.scrollTarget = cnt; }
    } else {
        cnt.scroll.y = 0;
    }
}

void mu_scrollbar_x(mu_Context* ctx, mu_Container* cnt, mu_Rect* b, mu_Vec2 cs) {
    /* only add scrollbar if content size is larger than body */
    int maxscroll = cs.x - b.w;
    if (maxscroll > 0 && b.w > 0) {
        mu_Rect base, thumb, mouse_area;
        mu_Id id = mu_get_id_str(ctx, "!scrollbarx");
        /* get sizing/positioning */
        base = *b;
        base.y = b.y + b.h;
        base.h = ctx.style.scrollbarSize;
        thumb = base;
        thumb.w = mu_max(ctx.style.thumbSize, base.w * b.w / cs.x);
        thumb.x += cnt.scroll.x * (base.w - thumb.w) / maxscroll;
        mouse_area = *b;
        mouse_area.w += ctx.style.scrollbarSize;
        mouse_area.h += ctx.style.scrollbarSize;
        /* handle input */
        mu_update_control(ctx, id, base, 0);
        if (ctx.focus == id && ctx.mouseDown & MU_MOUSE_LEFT) {
            if (ctx.mousePressed & MU_MOUSE_LEFT) {
                cnt.scroll.x = ((ctx.mousePos.x - base.x - thumb.w / 2) * maxscroll) / (base.w - thumb.w);
            } else {
                cnt.scroll.x += ctx.mouseDelta.x * cs.x / base.w;
            }
        }
        // TODO: Containers inside containers don't work that well. Fix later.
        if ((ctx.focus == id || cnt.zIndex >= ctx.lastZIndex) && ctx.keyDown & MU_KEY_SHIFT) {
            if (ctx.keyPressed & MU_KEY_HOME) {
                cnt.scroll.x = 0;
            } else if (ctx.keyPressed & MU_KEY_END) {
                cnt.scroll.x = maxscroll;
            }
            if (ctx.keyDown & MU_KEY_PAGEUP) {
                cnt.scroll.x -= ctx.style.scrollbarKeySpeed;
            } else if (ctx.keyDown & MU_KEY_PAGEDOWN) {
                cnt.scroll.x += ctx.style.scrollbarKeySpeed;
            }
        }
        /* clamp scroll to limits */
        cnt.scroll.x = mu_clamp(cnt.scroll.x, 0, maxscroll);
        thumb.x = mu_clamp(thumb.x, base.x, base.x + base.w - thumb.w);
        /* draw base and thumb */
        ctx.drawFrame(ctx, base, MU_COLOR_SCROLLBASE);
        ctx.drawFrame(ctx, thumb, MU_COLOR_SCROLLTHUMB);
        /* set this as the scroll_target (will get scrolled on mousewheel) */
        /* if the mouse is over it */
        if (mu_mouse_over(ctx, mouse_area)) { ctx.scrollTarget = cnt; }
    } else {
        cnt.scroll.x = 0;
    }
}

mu_ResFlags mu_begin_window_ex(mu_Context* ctx, const(char)[] title, mu_Rect rect, mu_OptFlags opt) {
    if (opt & MU_OPT_AUTOSIZE) { opt |= MU_OPT_NORESIZE | MU_OPT_NOSCROLL; }

    mu_Rect body;
    mu_Id id = mu_get_id_str(ctx, title);
    mu_Container* cnt = get_container(ctx, id, opt);
    if (!cnt || !cnt.open) { return MU_RES_NONE; }
    ctx.idStack.push(id);

    if (cnt.rect.w == 0) { cnt.rect = rect; }
    begin_root_container(ctx, cnt);
    rect = body = cnt.rect;

    /* draw frame */
    if (~opt & MU_OPT_NOFRAME) {
        ctx.drawFrame(ctx, rect, MU_COLOR_WINDOWBG);
    }

    /* do title bar */
    if (~opt & MU_OPT_NOTITLE) {
        mu_Rect tr = rect;
        tr.h = ctx.style.titleHeight;
        ctx.drawFrame(ctx, tr, MU_COLOR_TITLEBG);
        /* do title text */
        if (~opt & MU_OPT_NOTITLE) {
            if (~opt & MU_OPT_NONAME) { mu_draw_control_text(ctx, title, tr, MU_COLOR_TITLETEXT, opt); }
            mu_Id id2 = mu_get_id_str(ctx, "!title"); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
            if (ctx.keyDown & ctx.dragWindowKey) {
                mu_update_control(ctx, id2, body, opt, true);
                if (id2 == ctx.focus && ctx.mouseDown & MU_MOUSE_LEFT) {
                    cnt.rect.x += ctx.mouseDelta.x;
                    cnt.rect.y += ctx.mouseDelta.y;
                }
            } else {
                mu_update_control(ctx, id2, tr, opt);
                if (id2 == ctx.focus && ctx.mouseDown & MU_MOUSE_LEFT) {
                    cnt.rect.x += ctx.mouseDelta.x;
                    cnt.rect.y += ctx.mouseDelta.y;
                }
            }
            body.y += tr.h;
            body.h -= tr.h;
        }
        /* do `close` button */
        if (~opt & MU_OPT_NOCLOSE) {
            mu_Id id2 = mu_get_id_str(ctx, "!close"); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
            mu_Rect r = mu_rect(tr.x + tr.w - tr.h, tr.y, tr.h, tr.h);
            tr.w -= r.w;
            mu_draw_icon(ctx, MU_ICON_CLOSE, r, ctx.style.colors[MU_COLOR_TITLETEXT]);
            mu_update_control(ctx, id2, r, opt);
            if (ctx.mousePressed & MU_MOUSE_LEFT && id2 == ctx.focus) { cnt.open = false; }
        }
    }

    push_container_body(ctx, cnt, body, opt);

    /* do `resize` handle */
    if (~opt & MU_OPT_NORESIZE) {
        int sz = ctx.style.scrollbarSize; // RXI, WHY WAS THIS USING THE TITLE HEIGHT?
        mu_Id id2 = mu_get_id_str(ctx, "!resize"); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
        mu_Rect r = mu_rect(rect.x + rect.w - sz, rect.y + rect.h - sz, sz, sz);
        if (ctx.keyDown & ctx.resizeWindowKey) {
            mu_update_control(ctx, id2, body, opt, true);
            if (id2 == ctx.focus && ctx.mouseDown & MU_MOUSE_LEFT) {
                cnt.rect.w = mu_max(96, cnt.rect.w + ctx.mouseDelta.x);
                cnt.rect.h = mu_max(64, cnt.rect.h + ctx.mouseDelta.y);
            }
        } else {
            mu_update_control(ctx, id2, r, opt);
            if (id2 == ctx.focus && ctx.mouseDown & MU_MOUSE_LEFT) {
                cnt.rect.w = mu_max(96, cnt.rect.w + ctx.mouseDelta.x);
                cnt.rect.h = mu_max(64, cnt.rect.h + ctx.mouseDelta.y);
            }
        }
    }
    /* resize to content size */
    if (opt & MU_OPT_AUTOSIZE) {
        mu_Rect r = get_layout(ctx).body;
        cnt.rect.w = cnt.contentSize.x + (cnt.rect.w - r.w);
        cnt.rect.h = cnt.contentSize.y + (cnt.rect.h - r.h);
    }
    /* close if this is a popup window and elsewhere was clicked */
    if (opt & MU_OPT_POPUP && ctx.mousePressed && ctx.hoverRoot != cnt) { cnt.open = false; }
    mu_push_clip_rect(ctx, cnt.body);
    return MU_RES_ACTIVE;
}

mu_ResFlags mu_begin_window(mu_Context* ctx, const(char)[] title, mu_Rect rect) {
    return mu_begin_window_ex(ctx, title, rect, 0);
}

void mu_end_window(mu_Context* ctx) {
    mu_pop_clip_rect(ctx);
    end_root_container(ctx);
}

void mu_open_popup(mu_Context* ctx, const(char)[] name) {
    mu_Container* cnt = mu_get_container(ctx, name);
    /* set as hover root so popup isn't closed in begin_window_ex() */
    ctx.hoverRoot = ctx.nextHoverRoot = cnt;
    /* position at mouse cursor, open and bring-to-front */
    cnt.rect = mu_rect(ctx.mousePos.x, ctx.mousePos.y, 1, 1);
    cnt.open = true;
    mu_bring_to_front(ctx, cnt);
}

mu_ResFlags mu_begin_popup(mu_Context* ctx, const(char)[] name) {
    mu_OptFlags opt = MU_OPT_POPUP | MU_OPT_AUTOSIZE | MU_OPT_NOTITLE | MU_OPT_CLOSED;
    return mu_begin_window_ex(ctx, name, mu_rect(0, 0, 0, 0), opt);
}

void mu_end_popup(mu_Context* ctx) {
    mu_end_window(ctx);
}

void mu_begin_panel_ex(mu_Context* ctx, const(char)[] name, mu_OptFlags opt) {
    mu_Container* cnt;
    mu_push_id_str(ctx, name);
    cnt = get_container(ctx, ctx.lastId, opt);
    cnt.rect = mu_layout_next(ctx);
    if (~opt & MU_OPT_NOFRAME) { ctx.drawFrame(ctx, cnt.rect, MU_COLOR_PANELBG); }
    ctx.containerStack.push(cnt);
    push_container_body(ctx, cnt, cnt.rect, opt);
    mu_push_clip_rect(ctx, cnt.body);
}

void mu_begin_panel(mu_Context* ctx, const(char)[] name) {
    mu_begin_panel_ex(ctx, name, 0);
}

void mu_end_panel(mu_Context* ctx) {
    mu_pop_clip_rect(ctx);
    pop_container(ctx);
}

void mu_open_dmenu(mu_Context* ctx) {
    auto cnt = mu_get_container(ctx, "!dmenu");
    cnt.open = true;
}

mu_ResFlags mu_begin_dmenu(mu_Context* ctx, const(char)[]* selection, const(const(char)[])[] items, mu_Vec2 canvas, const(char)[] label = "", mu_FVec2 scale = mu_FVec2(0.5f, 0.7f)) {
    static char[MU_INPUTTEXT_SIZE] input_buffer = '\0';

    auto result = MU_RES_NONE;
    auto size = mu_vec2(cast(int) (canvas.x * scale.x), cast(int) (canvas.y * scale.y));
    auto rect = mu_rect(canvas.x / 2 - size.x / 2, canvas.y / 2 - size.y / 2,  size.x, size.y);
    if (mu_begin_window_ex(ctx, "!dmenu", rect, MU_OPT_NOCLOSE | MU_OPT_NORESIZE | MU_OPT_NOTITLE)) {
        result |= MU_RES_ACTIVE;
        auto window_cnt = mu_get_current_container(ctx);
        if (label.length) {
            mu_layout_row(ctx, 0, ctx.textWidth(ctx.style.font, label) + ctx.textWidth(ctx.style.font, "  "), -1);
            mu_label(ctx, label);
        } else {
            mu_layout_row(ctx, 0, -1);
        }

        size_t input_length;
        auto input_result = mu_textbox_ex(ctx, input_buffer, MU_OPT_DEFAULTFOCUS, &input_length);
        auto input = input_buffer[0 .. input_length];
        auto pick = -1;
        auto first = -1;
        auto buttonCount = 0;
        mu_layout_row(ctx, -1, -1);

        mu_begin_panel_ex(ctx, "!dmenupanel", MU_OPT_NOSCROLL);
        mu_layout_row(ctx, 0, -1);
        foreach (i, item; items) {
            auto starts_with_input = input.length == 0 || (item.length < input.length ? false : item[0 .. input.length] == input);
            // Draw the item.
            if (!starts_with_input) continue;
            buttonCount += 1;
            if (mu_button_ex(ctx, item, 0, 0)) pick = cast(int) i;
            // Do autocomplete.
            if (buttonCount > 1) continue;
            first = cast(int) i;
            auto autocomplete_length = item.length;
            if (ctx.keyPressed & MU_KEY_TAB) {
                foreach (j, c; item) {
                    input_buffer[j] = c;
                    if (j > input.length && mu_is_autocomplete_sep(c)) {
                        autocomplete_length = j;
                        break;
                    }
                }
                input_buffer[autocomplete_length] = '\0';
            }
        }
        mu_end_panel(ctx);

        if (items.length && input_result & MU_RES_SUBMIT) pick = first;
        if (pick >= 0) {
            result |= MU_RES_SUBMIT;
            input_buffer[0] = '\0';
            window_cnt.open = false;
            *selection = items[pick];
        }
    }
    return result;
}

void mu_end_dmenu(mu_Context* ctx) {
    mu_end_window(ctx);
}
