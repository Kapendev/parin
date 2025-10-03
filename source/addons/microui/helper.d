// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// ---

// TODO: work on attributes maybe.

/// Equivalent to `import wrapper`, with additional helper functions for Parin.
module addons.microui.helper;
/* TODO: JUST INGORE UNTIL PARIN WORKS AGAIN
import parin.engine;
import addons.microui.core; // TODO: Used because there are some symbols that I haven't removed yet.
import addons.microui.wrapper;

private extern(C) nothrow @nogc {
    enum MOUSE_BUTTON_LEFT   = 0;
    enum MOUSE_BUTTON_RIGHT  = 1;
    enum MOUSE_BUTTON_MIDDLE = 2;
    enum KEY_ENTER           = 257;
    enum KEY_TAB             = 258;
    enum KEY_BACKSPACE       = 259;
    enum KEY_INSERT          = 260;
    enum KEY_DELETE          = 261;
    enum KEY_LEFT_SHIFT      = 340;
    enum KEY_LEFT_CONTROL    = 341;
    enum KEY_LEFT_ALT        = 342;
    enum KEY_LEFT_SUPER      = 343;
    enum KEY_RIGHT_SHIFT     = 344;
    enum KEY_RIGHT_CONTROL   = 345;
    enum KEY_RIGHT_ALT       = 346;
    enum KEY_KP_ENTER        = 335;
    enum KEY_RIGHT           = 262;
    enum KEY_LEFT            = 263;
    enum KEY_DOWN            = 264;
    enum KEY_UP              = 265;
    enum KEY_HOME            = 268;
    enum KEY_END             = 269;
    enum KEY_PAGE_UP         = 266;
    enum KEY_PAGE_DOWN       = 267;
    enum KEY_F1              = 290;
    enum KEY_F2              = 291;
    enum KEY_F3              = 292;
    enum KEY_F4              = 293;

    struct Color { ubyte r, g, b, a; }
    struct Vector2 { float x, y; }
    struct Vector3 { float x, y, z; }
    struct Vector4 { float x, y, z, w; }
    struct Rectangle { float x, y, width, height; }
    struct GlyphInfo {}

    struct Texture {
        uint id;
        int width;
        int height;
        int mipmaps;
        int format;
    }

    struct Font {
        int baseSize;
        int glyphCount;
        int glyphPadding;
        Texture texture;
        Rectangle* recs;
        GlyphInfo* glyphs;
    }

    void* memcpy(void* dest, const(void)* src, size_t count);
    Vector2 MeasureTextEx(Font font, const(char)* text, float fontSize, float spacing);
    Font GetFontDefault();
    float GetMouseWheelMove();
    Vector2 GetMouseWheelMoveV();
    int GetMouseX();
    int GetMouseY();
    bool IsMouseButtonPressed(int button);
    bool IsMouseButtonReleased(int button);
    bool IsKeyPressed(int button);
    bool IsKeyReleased(int button);
    int GetCharPressed();
    int GetScreenWidth();
    int GetScreenHeight();
    void BeginScissorMode(int x, int y, int width, int height);
    void EndScissorMode();
    void DrawTextEx(Font font, const(char)* text, Vector2 position, float fontSize, float spacing, Color tint);
    void DrawRectangleRec(Rectangle rec, Color color);
}

@trusted:

// Temporary text measurement function for prototyping.
nothrow @nogc
private int muprTempTextWidthFunc(UiFont font, const(char)[] str) {
    auto da = cast(PFontId*) font;
    auto options = DrawOptions();
    options.scale = Vec2(uiStyle.fontScale, uiStyle.fontScale);
    return cast(int) prMeasureTextSizeId(*da, str, options, TextOptions()).x;
}
// Temporary text measurement function for prototyping.
nothrow @nogc
private int muprTempTextHeightFunc(UiFont font) {
    auto da = cast(PFontId*) font;
    auto data = cast(Font*) prFontIdGet(da);
    return data.baseSize * uiStyle.fontScale;
}

/// Initializes the microui context and sets temporary text size functions. Value `font` should be a `FontId*`.
nothrow @nogc
void readyUi(UiFont font = null, int fontScale = 1) {
    readyUiCore(&muprTempTextWidthFunc, &muprTempTextHeightFunc, font, fontScale);
    auto da = cast(PFontId*) uiStyle.font;
    if (da) {
        auto data = cast(Font*) prFontIdGet(da);
        auto baseSize = data.baseSize * uiStyle.fontScale;
        uiStyle.size = UiVec(baseSize * 6, baseSize);
        uiStyle.titleHeight = cast(int) (baseSize * 1.5f);

        // No idea, just looks good sometimes.
        if (baseSize <= 16) {
        } else if (baseSize <= 38) {
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

/// Initializes the microui context and sets custom text size functions. Value `font` should be a `FontId*`.
nothrow @nogc
void readyUi(UiTextWidthFunc width, UiTextHeightFunc height, UiFont font = null, int fontScale = 1) {
    readyUi(font, fontScale);
    uiContext.textWidth = width;
    uiContext.textHeight = height;
}

/// Handles input events and updates the microui context accordingly.
nothrow @nogc
void handleUiInput() {
    with (UiMouseFlag) {
        uiInputScroll(cast(int) prDeltaWheel, cast(int) prDeltaWheel);
        uiInputMouseDown(cast(int) prMouse.x, cast(int) prMouse.y, prIsPressedMouse(Mouse.left) ? left : none);
        uiInputMouseUp(cast(int) prMouse.x, cast(int) prMouse.y, prIsReleasedMouse(Mouse.left) ? left : none);
        uiInputMouseDown(cast(int) prMouse.x, cast(int) prMouse.y, prIsPressedMouse(Mouse.right) ? right : none);
        uiInputMouseUp(cast(int) prMouse.x, cast(int) prMouse.y, prIsReleasedMouse(Mouse.right) ? right : none);
        uiInputMouseDown(cast(int) prMouse.x, cast(int) prMouse.y, prIsPressedMouse(Mouse.middle) ? middle : none);
        uiInputMouseUp(cast(int) prMouse.x, cast(int) prMouse.y, prIsReleasedMouse(Mouse.middle) ? middle : none);
    }

    with (UiKeyFlag) {
        uiInputKeyDown(IsKeyPressed(KEY_LEFT_SHIFT) ? shift : none);
        uiInputKeyDown(IsKeyPressed(KEY_RIGHT_SHIFT) ? shift : none);
        uiInputKeyDown(IsKeyPressed(KEY_LEFT_CONTROL) ? ctrl : none);
        uiInputKeyDown(IsKeyPressed(KEY_RIGHT_CONTROL) ? ctrl : none);
        uiInputKeyDown(IsKeyPressed(KEY_LEFT_ALT) ? alt : none);
        uiInputKeyDown(IsKeyPressed(KEY_RIGHT_ALT) ? alt : none);
        uiInputKeyDown(IsKeyPressed(KEY_BACKSPACE) ? backspace : none);
        uiInputKeyDown(IsKeyPressed(KEY_ENTER) ? enter : none);
        uiInputKeyDown(IsKeyPressed(KEY_KP_ENTER) ? enter : none);
        uiInputKeyDown(IsKeyPressed(KEY_TAB) ? tab : none);
        uiInputKeyDown(IsKeyPressed(KEY_LEFT) ? left : none);
        uiInputKeyDown(IsKeyPressed(KEY_RIGHT) ? right : none);
        uiInputKeyDown(IsKeyPressed(KEY_UP) ? up : none);
        uiInputKeyDown(IsKeyPressed(KEY_DOWN) ? down : none);
        uiInputKeyDown(IsKeyPressed(KEY_HOME) ? home : none);
        uiInputKeyDown(IsKeyPressed(KEY_END) ? end : none);
        uiInputKeyDown(IsKeyPressed(KEY_PAGE_UP) ? pageUp : none);
        uiInputKeyDown(IsKeyPressed(KEY_PAGE_DOWN) ? pageDown : none);
        uiInputKeyDown(IsKeyPressed(KEY_F1) ? f1 : none);
        uiInputKeyDown(IsKeyPressed(KEY_F2) ? f2 : none);
        uiInputKeyDown(IsKeyPressed(KEY_F3) ? f3 : none);
        uiInputKeyDown(IsKeyPressed(KEY_F4) ? f4 : none);

        uiInputKeyUp(IsKeyReleased(KEY_LEFT_SHIFT) ? shift : none);
        uiInputKeyUp(IsKeyReleased(KEY_RIGHT_SHIFT) ? shift : none);
        uiInputKeyUp(IsKeyReleased(KEY_LEFT_CONTROL) ? ctrl : none);
        uiInputKeyUp(IsKeyReleased(KEY_RIGHT_CONTROL) ? ctrl : none);
        uiInputKeyUp(IsKeyReleased(KEY_LEFT_ALT) ? alt : none);
        uiInputKeyUp(IsKeyReleased(KEY_RIGHT_ALT) ? alt : none);
        uiInputKeyUp(IsKeyReleased(KEY_BACKSPACE) ? backspace : none);
        uiInputKeyUp(IsKeyReleased(KEY_ENTER) ? enter : none);
        uiInputKeyUp(IsKeyReleased(KEY_KP_ENTER) ? enter : none);
        uiInputKeyUp(IsKeyReleased(KEY_TAB) ? tab : none);
        uiInputKeyUp(IsKeyReleased(KEY_LEFT) ? left : none);
        uiInputKeyUp(IsKeyReleased(KEY_RIGHT) ? right : none);
        uiInputKeyUp(IsKeyReleased(KEY_UP) ? up : none);
        uiInputKeyUp(IsKeyReleased(KEY_DOWN) ? down : none);
        uiInputKeyUp(IsKeyReleased(KEY_HOME) ? home : none);
        uiInputKeyUp(IsKeyReleased(KEY_END) ? end : none);
        uiInputKeyUp(IsKeyReleased(KEY_PAGE_UP) ? pageUp : none);
        uiInputKeyUp(IsKeyReleased(KEY_PAGE_DOWN) ? pageDown : none);
        uiInputKeyUp(IsKeyReleased(KEY_F1) ? f1 : none);
        uiInputKeyUp(IsKeyReleased(KEY_F2) ? f2 : none);
        uiInputKeyUp(IsKeyReleased(KEY_F3) ? f3 : none);
        uiInputKeyUp(IsKeyReleased(KEY_F4) ? f4 : none);
    }

    char[128] charBuffer = void;
    size_t charBufferLength = 0;
    foreach (i; 0 .. charBuffer.length) {
        charBuffer[i] = cast(char) GetCharPressed();
        if (charBuffer[i] == '\0') { charBufferLength = i; break; }
    }
    if (charBufferLength) uiInputText(charBuffer[0 .. charBufferLength]);
}

/// Draws the microui context to the screen.
void drawUi() {
    auto style_font = cast(PFontId*) uiStyle.font;
    auto style_texture = cast(PTextureId*) uiStyle.texture;
    auto parin_options = DrawOptions(); // We just change the color, so it should be fine.
    BeginScissorMode(0, 0, prWindowWidth, prWindowHeight);
    UiCommand *cmd;
    while (nextUiCommand(&cmd)) {
        switch (cmd.type) {
            case MU_COMMAND_TEXT:
                auto text_font = cast(PFontId*) cmd.text.font;
                parin_options.color = *(cast(Rgba*) (&cmd.text.color));
                parin_options.scale = Vec2(uiStyle.fontScale, uiStyle.fontScale);
                prDrawTextId(
                    *text_font,
                    cmd.text.str.ptr[0 .. cmd.text.len],
                    Vec2(cmd.text.pos.x, cmd.text.pos.y),
                    parin_options,
                    TextOptions(),
                );
                parin_options.scale = Vec2(1, 1);
                break;
            case MU_COMMAND_RECT:
                parin_options.color = *(cast(Rgba*) (&cmd.rect.color));
                auto atlas_rect = uiStyle.atlasRects[cmd.rect.id];
                if (style_texture && atlas_rect.hasSize) {
                    auto slice_margin = uiStyle.sliceMargins[cmd.rect.id];
                    auto slice_mode = uiStyle.sliceModes[cmd.rect.id];
                    foreach (i, ref part; computeUiSliceParts(atlas_rect, cmd.rect.rect, slice_margin)) {
                        if (slice_mode && part.canTile) {
                            parin_options.scale = Vec2(1, 1);
                            foreach (y; 0 .. part.tileCount.y) {
                                foreach (x; 0 .. part.tileCount.x) {
                                    auto source_w = (x != part.tileCount.x - 1) ? part.source.w : mu_max(0, part.target.w - x * part.source.w);
                                    auto source_h = (y != part.tileCount.y - 1) ? part.source.h : mu_max(0, part.target.h - y * part.source.h);
                                    prDrawTextureAreaId(
                                        *style_texture,
                                        Rect(part.source.x, part.source.y, source_w, source_h),
                                        Vec2(part.target.x + x * part.source.w, part.target.y + y * part.source.h),
                                        parin_options,
                                    );
                                }
                            }
                        } else {
                            parin_options.scale = Vec2(
                                part.target.w / cast(float) part.source.w,
                                part.target.h / cast(float) part.source.h,
                            );
                            prDrawTextureAreaId(
                                *style_texture,
                                Rect(part.source.x, part.source.y, part.source.w, part.source.h),
                                Vec2(part.target.x, part.target.y),
                                parin_options,
                            );
                        }
                    }
                    parin_options.scale = Vec2(1, 1);
                } else {
                    prDrawRect(
                        Rect(cmd.rect.rect.x, cmd.rect.rect.y, cmd.rect.rect.w, cmd.rect.rect.h),
                        parin_options.color,
                    );
                }
                break;
            case MU_COMMAND_ICON:
                parin_options.color = *(cast(Rgba*) (&cmd.icon.color));
                auto icon_atlas_rect = uiStyle.iconAtlasRects[cmd.icon.id];
                auto icon_diff = UiVec(cmd.icon.rect.w - icon_atlas_rect.w, cmd.icon.rect.h - icon_atlas_rect.h);
                if (style_texture && icon_atlas_rect.hasSize) {
                    prDrawTextureAreaId(
                        *style_texture,
                        Rect(icon_atlas_rect.x, icon_atlas_rect.y, icon_atlas_rect.w, icon_atlas_rect.h),
                        Vec2(cmd.icon.rect.x + icon_diff.x / 2, cmd.icon.rect.y + icon_diff.y / 2),
                        parin_options,
                    );
                } else {
                    parin_options.scale = Vec2(uiStyle.fontScale, uiStyle.fontScale);
                    const(char)[] icon = "?";
                    switch (cmd.icon.id) {
                        case MU_ICON_CLOSE: icon = "x"; break;
                        case MU_ICON_CHECK: icon = "*"; break;
                        case MU_ICON_COLLAPSED: icon = "+"; break;
                        case MU_ICON_EXPANDED: icon = "-"; break;
                        default: break;
                    }
                    auto icon_width = uiContext.textWidth(style_font, icon);
                    auto icon_height = uiContext.textHeight(style_font);
                    icon_diff = UiVec(cmd.icon.rect.w - icon_width, cmd.icon.rect.h - icon_height);
                    prDrawTextId(
                        *style_font,
                        icon,
                        Vec2(cmd.icon.rect.x + icon_diff.x / 2, cmd.icon.rect.y + icon_diff.y / 2),
                        parin_options,
                        TextOptions(),
                    );
                    parin_options.scale = Vec2(1, 1);
                }
                break;
            case MU_COMMAND_CLIP:
                EndScissorMode();
                BeginScissorMode(cmd.clip.rect.x, cmd.clip.rect.y, cmd.clip.rect.w, cmd.clip.rect.h);
                break;
            default:
                break;
        }
    }
    EndScissorMode();
}

/// Begins input handling and UI processing.
void beginUi() {
    handleUiInput();
    beginUiCore();
}

/// Ends UI processing and performs drawing.
void endUi() {
    endUiCore();
    drawUi();
}
*/
