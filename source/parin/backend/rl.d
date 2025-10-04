// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

module parin.backend.rl;

import rl = parin.bindings.rl;
import joka.ascii;
import joka.containers;
import joka.memory;
import parin.types;

__gshared BackendState* _backendState;

// ---------- Config
version (WebAssembly) {
    enum defaultBackendResourcesCapacity = 256;
} else {
    enum defaultBackendResourcesCapacity = 1536;
}
// ----------

@trusted nothrow:

alias RlFilter = int;
alias RlWrap   = int;
alias RlBlend  = int;
alias RlKey    = int;

struct BackendState {
    alias BasicContainer(T)  = FixedList!(T, defaultBackendResourcesCapacity);
    alias SparseContainer(T) = FixedList!(SparseListItem!T, defaultBackendResourcesCapacity);
    alias TexturesData       = SparseList!(rl.Texture, SparseContainer!(rl.Texture2D));
    alias FontsData          = SparseList!(rl.Font, SparseContainer!(rl.Font));
    alias SoundsData         = SparseList!(rl.Sound, SparseContainer!(rl.Sound));
    alias MusicData          = SparseList!(rl.Music, SparseContainer!(rl.Music));
    alias GenData            = BasicContainer!(Gen);

    GenList!(TexturesData.Item.Item, TexturesData, GenData) textures;
    GenList!(FontsData.Item.Item, FontsData, GenData) fonts;
    GenList!(SoundsData.Item.Item, SoundsData, GenData) sounds;
    GenList!(MusicData.Item.Item, MusicData, GenData) music;

    BasicContainer!IStr droppedPaths;
}

Maybe!ResourceId loadTexture(IStr path) {
    auto resource = rl.LoadTexture(path.toCStr().getOr());
    if (resource.id == 0) return Maybe!ResourceId(Fault.cantFind);
    return Maybe!ResourceId(_backendState.textures.append(resource));
}

Maybe!ResourceId loadTexture(const(ubyte)[] memory, IStr ext = ".png") {
    auto image = rl.LoadImageFromMemory(ext.toCStr().getOr(), memory.ptr, cast(int) memory.length);
    if (image.data == null) return Maybe!ResourceId(Fault.cantParse);
    auto resource = rl.LoadTextureFromImage(image);
    rl.UnloadImage(image);
    if (resource.id == 0) return Maybe!ResourceId(Fault.cantFind);
    return Maybe!ResourceId(_backendState.textures.append(resource));
}

Maybe!ResourceId loadFont(IStr path, int size, IStr32 runes) {
    auto resource = rl.LoadFontEx(path.toCStr().getOr(), size, runes.length ? cast(int*) runes.ptr : null, cast(int) runes.length);
    if (resource.texture.id == 0 || resource.texture.id == rl.GetFontDefault().texture.id) return Maybe!ResourceId(Fault.cantFind);
    return Maybe!ResourceId(_backendState.fonts.push(resource));
}

Maybe!ResourceId loadFont(const(ubyte)[] memory, int size, IStr32 runes, IStr ext = ".ttf") {
    auto resource = rl.LoadFontFromMemory(ext.toCStr().getOr(), memory.ptr, cast(int) memory.length, size, runes.length ? cast(int*) runes.ptr : null, cast(int) runes.length);
    if (resource.texture.id == 0 || resource.texture.id == rl.GetFontDefault().texture.id) return Maybe!ResourceId(Fault.cantParse);
    return Maybe!ResourceId(_backendState.fonts.append(resource));
}

Maybe!ResourceId loadFont(ResourceId texture, int tileWidth, int tileHeight) {
    if (!textureIsValid(texture) || tileWidth <= 0|| tileHeight <= 0) return Maybe!ResourceId(Fault.invalid);
    auto oldResource = &_backendState.textures[texture];
    auto newResource = rl.Font();
    auto rowCount = textureHeight(texture) / tileHeight;
    auto colCount = textureWidth(texture) / tileWidth;
    auto maxCount = rowCount * colCount;
    newResource.baseSize = tileHeight;
    newResource.glyphCount = maxCount;
    newResource.glyphPadding = 0;
    newResource.texture = *oldResource;
    newResource.recs = cast(rl.Rectangle*) rl.MemAlloc(cast(uint) (maxCount * rl.Rectangle.sizeof));
    foreach (i; 0 .. maxCount) {
        newResource.recs[i].x = (i % colCount) * tileWidth;
        newResource.recs[i].y = (i / colCount) * tileHeight;
        newResource.recs[i].width = tileWidth;
        newResource.recs[i].height = tileHeight;
    }
    newResource.glyphs = cast(rl.GlyphInfo*) rl.MemAlloc(cast(uint) (maxCount * rl.GlyphInfo.sizeof));
    foreach (i; 0 .. maxCount) {
        newResource.glyphs[i] = rl.GlyphInfo();
        newResource.glyphs[i].value = i + 32;
    }
    // We remove the ID, but not the resource. We need the resource.
    _backendState.textures.remove(texture);
    return Maybe!ResourceId(_backendState.fonts.push(newResource));
}

void readyBackend(int width, int height, IStr title, bool vsync, int fpsMax, int windowMinWidth, int windowMinHeight) {
    // Make sure the state is OK first.
    _backendState = jokaMakeBlank!BackendState();
    _backendState.textures.clear();
    _backendState.fonts.clear();
    _backendState.sounds.clear();
    _backendState.music.clear();
    _backendState.droppedPaths.clear();
    // These make the zero value invalid.
    _backendState.textures.push(rl.Texture());
    _backendState.fonts.push(rl.Font());
    _backendState.sounds.push(rl.Sound());
    _backendState.music.push(rl.Music());

    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | (vsync ? rl.FLAG_VSYNC_HINT : 0));
    rl.SetTraceLogLevel(rl.LOG_ERROR);
    rl.InitWindow(width, height, title.toCStr().getOr());
    rl.InitAudioDevice();
    rl.SetExitKey(rl.KEY_NULL);
    rl.SetTargetFPS(fpsMax);
    rl.SetWindowMinSize(windowMinWidth, windowMinHeight);
    rl.rlSetBlendFactorsSeparate(0x0302, 0x0303, 1, 0x0303, 0x8006, 0x8006);
}

@trusted nothrow @nogc:

void freeAllTextures() {
    foreach (id; _backendState.textures.ids) textureFree(id);
}

void freeAllFonts() {
    foreach (id; _backendState.fonts.ids) fontFree(id);
}

void freeBackend() {
    freeAllTextures();
    freeAllFonts();
    jokaFree(_backendState);
    rl.CloseAudioDevice();
    rl.CloseWindow();
}

Sz backendTextureCount() => _backendState.textures.length - 1;
Sz backendFontCount()    => _backendState.fonts.length - 1;
Sz backendSoundCount()   => _backendState.sounds.length - 1;
Sz backendMusicCount()   => _backendState.music.length - 1;

/// Checks if the texture is null (default value).
bool resourceIsNull(ResourceId id) {
    return id.value == 0;
}

// --- Texture

/// Checks if the texture is valid (loaded). Null is invalid.
bool textureIsValid(ResourceId id) {
    return !resourceIsNull(id) && _backendState.textures.has(id);
}

/// Returns the width of the texture.
/// Will return `0` for null and asserts for other invalid IDs.
int textureWidth(ResourceId id) {
    auto resource = &_backendState.textures[id];
    return resource.width;
}

/// Returns the height of the texture.
/// Will return `0` for null and asserts for other invalid IDs.
int textureHeight(ResourceId id) {
    auto resource = &_backendState.textures[id];
    return resource.height;
}

/// Returns the size of the texture.
/// Will return `Vec2(0)` for null and asserts for other invalid IDs.
Vec2 textureSize(ResourceId id) {
    auto resource = &_backendState.textures[id];
    return Vec2(resource.width, resource.height);
}

/// Sets the filter mode of the texture.
void textureSetFilter(ResourceId id, Filter value) {
    auto resource = &_backendState.textures[id];
    rl.SetTextureFilter(*resource, toRl(value));
}

/// Sets the wrap mode of the texture.
void textureSetWrap(ResourceId id, Wrap value) {
    auto resource = &_backendState.textures[id];
    rl.SetTextureWrap(*resource, toRl(value));
}

/// Frees the loaded texture.
void textureFree(ResourceId id) {
    if (!textureIsValid(id)) return;
    auto resource = &_backendState.textures[id];
    rl.UnloadTexture(*resource);
    _backendState.textures.remove(id);
}

// --- Font

/// Checks if the font is not loaded.
bool fontIsValid(ResourceId id) {
    return !resourceIsNull(id) && _backendState.fonts.has(id);
}

/// Returns the size of the font.
int fontSize(ResourceId id) {
    auto resource = &_backendState.fonts[id];
    return resource.baseSize;
}

/// Sets the filter mode of the font.
void fontSetFilter(ResourceId id, Filter value) {
    auto resource = &_backendState.fonts[id];
    rl.SetTextureFilter(resource.texture, toRl(value));
}

/// Sets the wrap mode of the font.
void fontSetWrap(ResourceId id, Wrap value) {
    auto resource = &_backendState.fonts[id];
    rl.SetTextureWrap(resource.texture, toRl(value));
}

GlyphInfo fontGlyphInfo(ResourceId id, int rune) {
    auto resource = &_backendState.fonts[id];
    auto glyphIndex = rl.GetGlyphIndex(*resource, rune);
    auto info = resource.glyphs[glyphIndex];
    auto rect = resource.recs[glyphIndex];
    // "Why are you not using named thingy magingykdopwjopjw!??"
    auto result = GlyphInfo();
    result.value = info.value;
    result.offset = IVec2(info.offsetX, info.offsetY);
    result.advanceX = info.advanceX;
    result.rect = IRect(cast(int) rect.x, cast(int) rect.y, cast(int) rect.width, cast(int) rect.height);
    return result;
}

/// Frees the loaded font.
void fontFree(ResourceId id) {
    if (!fontIsValid(id)) return;
    auto resource = &_backendState.fonts[id];
    rl.UnloadFont(*resource);
    _backendState.fonts.remove(id);
}

// --- Camera

void cameraAttach(ref Camera camera, Vec2 canvasSize, Rounding type) {
    camera.isAttached = true;
    rl.BeginMode2D(toRl(camera, canvasSize, type));
}

void cameraDetach(ref Camera camera) {
    camera.isAttached = false;
    rl.EndMode2D();
}

// --- Dropped Paths

void beginDroppedPaths() {
    if (rl.IsFileDropped()) {
        _backendState.droppedPaths.clear();
        auto list = rl.LoadDroppedFiles();
        foreach (i; 0 .. min(list.count, defaultBackendResourcesCapacity)) {
            _backendState.droppedPaths.append(list.paths[i].toStr());
        }
    }
}

void endDroppedPaths() {
    if (rl.IsFileDropped()) {
        // NOTE: LoadDroppedFiles just returns a global variable.
        rl.UnloadDroppedFiles(rl.LoadDroppedFiles());
    }
}

IStr[] droppedPaths() {
    return _backendState.droppedPaths.items;
}

// --- Stuff

// raylib does not let you do that.
void setVsync(bool value) {}

// raylib does stuff internally.
// NOTE: No idea if this is a good name.
void pumpEvents() {}

// --- Input

/// Begin blending mode.
void beginBlend(Blend blend) => rl.BeginBlendMode(toRl(blend));
/// End blending mode.
void endBlend() => rl.EndBlendMode();

/// Returns true if the specified key is currently pressed.
bool isDown(char key) => rl.IsKeyDown(toRl(key));
/// Returns true if the specified key is currently pressed.
bool isDown(Keyboard key) => rl.IsKeyDown(toRl(key));
/// Returns true if the specified key is currently pressed.
bool isDown(Mouse key) => rl.IsMouseButtonDown(toRl(key));
/// Returns true if the specified key is currently pressed.
bool isDown(Gamepad key, int id = 0) => rl.IsGamepadButtonDown(id, toRl(key));

/// Returns true if the specified key was pressed.
bool isPressed(char key) => rl.IsKeyPressed(toRl(key));
/// Returns true if the specified key was pressed.
bool isPressed(Keyboard key) => rl.IsKeyPressed(toRl(key));
/// Returns true if the specified key was pressed.
bool isPressed(Mouse key) => rl.IsMouseButtonPressed(toRl(key));
/// Returns true if the specified key was pressed.
bool isPressed(Gamepad key, int id = 0) => rl.IsGamepadButtonPressed(id, toRl(key));

/// Returns true if the specified key was released.
bool isReleased(char key) => rl.IsKeyReleased(toRl(key));
/// Returns true if the specified key was released.
bool isReleased(Keyboard key) => rl.IsKeyReleased(toRl(key));
/// Returns true if the specified key was released.
bool isReleased(Mouse key) => rl.IsMouseButtonReleased(toRl(key));
/// Returns true if the specified key was released.
bool isReleased(Gamepad key, int id = 0) => rl.IsGamepadButtonReleased(id, toRl(key));

void drawTexture(ResourceId id, Rect area, Rect target, Vec2 origin, float rotation, Rgba color) {
    auto resource = &_backendState.textures[id];
    rl.DrawTexturePro(
        *resource,
        toRl(area),
        toRl(target),
        toRl(origin),
        rotation,
        toRl(color),
    );
}

void drawRune(ResourceId id, int rune, Vec2 position, float scale, Rgba color) {
    auto resource = &_backendState.fonts[id];
    rl.DrawTextCodepoint(*resource, rune, toRl(position), resource.baseSize * scale, toRl(color));
}

pragma(inline, true) {
    rl.Color toRl(Rgba from) {
        return rl.Color(from.r, from.g, from.b, from.a);
    }

    rl.Vector2 toRl(Vec2 from) {
        return rl.Vector2(from.x, from.y);
    }

    rl.Vector3 toRl(Vec3 from) {
        return rl.Vector3(from.x, from.y, from.z);
    }

    rl.Vector4 toRl(Vec4 from) {
        return rl.Vector4(from.x, from.y, from.z, from.w);
    }

    rl.Rectangle toRl(Rect from) {
        return rl.Rectangle(from.position.x, from.position.y, from.size.x, from.size.y);
    }

    rl.Camera2D toRl(Camera from, Vec2 canvasSize, Rounding type) {
        return rl.Camera2D(
            Rect(canvasSize).origin(from.isCentered ? Hook.center : Hook.topLeft).applyRounding(type).toRl(),
            from.sum.applyRounding(type).toRl(),
            from.rotation,
            from.scale,
        );
    }

    RlFilter toRl(Filter from) {
        with (Filter) final switch (from) {
            case nearest: return rl.TEXTURE_FILTER_POINT;
            case linear: return rl.TEXTURE_FILTER_BILINEAR;
        }
    }

    RlWrap toRl(Wrap from) {
        with (Wrap) final switch (from) {
            case clamp: return rl.TEXTURE_WRAP_CLAMP;
            case repeat: return rl.TEXTURE_WRAP_REPEAT;
        }
    }

    RlBlend toRl(Blend from) {
        with (Blend) final switch (from) {
            case alpha: return rl.BLEND_CUSTOM_SEPARATE;
            case additive: return rl.BLEND_ADDITIVE;
            case multiplied: return rl.BLEND_MULTIPLIED;
            case add: return rl.BLEND_ADD_COLORS;
            case sub: return rl.BLEND_SUBTRACT_COLORS;
        }
    }

    RlKey toRl(char from) {
        return toUpper(from);
    }

    RlKey toRl(Keyboard from) {
        with (Keyboard) final switch (from) {
            case none: return rl.KEY_NULL;
            case apostrophe: return rl.KEY_APOSTROPHE;
            case comma: return rl.KEY_COMMA;
            case minus: return rl.KEY_MINUS;
            case period: return rl.KEY_PERIOD;
            case slash: return rl.KEY_SLASH;
            case n0: return rl.KEY_ZERO;
            case n1: return rl.KEY_ONE;
            case n2: return rl.KEY_TWO;
            case n3: return rl.KEY_THREE;
            case n4: return rl.KEY_FOUR;
            case n5: return rl.KEY_FIVE;
            case n6: return rl.KEY_SIX;
            case n7: return rl.KEY_SEVEN;
            case n8: return rl.KEY_EIGHT;
            case n9: return rl.KEY_NINE;
            case nn0: return rl.KEY_KP_0;
            case nn1: return rl.KEY_KP_1;
            case nn2: return rl.KEY_KP_2;
            case nn3: return rl.KEY_KP_3;
            case nn4: return rl.KEY_KP_4;
            case nn5: return rl.KEY_KP_5;
            case nn6: return rl.KEY_KP_6;
            case nn7: return rl.KEY_KP_7;
            case nn8: return rl.KEY_KP_8;
            case nn9: return rl.KEY_KP_9;
            case semicolon: return rl.KEY_SEMICOLON;
            case equal: return rl.KEY_EQUAL;
            case a: return rl.KEY_A;
            case b: return rl.KEY_B;
            case c: return rl.KEY_C;
            case d: return rl.KEY_D;
            case e: return rl.KEY_E;
            case f: return rl.KEY_F;
            case g: return rl.KEY_G;
            case h: return rl.KEY_H;
            case i: return rl.KEY_I;
            case j: return rl.KEY_J;
            case k: return rl.KEY_K;
            case l: return rl.KEY_L;
            case m: return rl.KEY_M;
            case n: return rl.KEY_N;
            case o: return rl.KEY_O;
            case p: return rl.KEY_P;
            case q: return rl.KEY_Q;
            case r: return rl.KEY_R;
            case s: return rl.KEY_S;
            case t: return rl.KEY_T;
            case u: return rl.KEY_U;
            case v: return rl.KEY_V;
            case w: return rl.KEY_W;
            case x: return rl.KEY_X;
            case y: return rl.KEY_Y;
            case z: return rl.KEY_Z;
            case bracketLeft: return rl.KEY_LEFT_BRACKET;
            case bracketRight: return rl.KEY_RIGHT_BRACKET;
            case backslash: return rl.KEY_BACKSLASH;
            case grave: return rl.KEY_GRAVE;
            case space: return rl.KEY_SPACE;
            case esc: return rl.KEY_ESCAPE;
            case enter: return rl.KEY_ENTER;
            case tab: return rl.KEY_TAB;
            case backspace: return rl.KEY_BACKSPACE;
            case insert: return rl.KEY_INSERT;
            case del: return rl.KEY_DELETE;
            case right: return rl.KEY_RIGHT;
            case left: return rl.KEY_LEFT;
            case down: return rl.KEY_DOWN;
            case up: return rl.KEY_UP;
            case pageUp: return rl.KEY_PAGE_UP;
            case pageDown: return rl.KEY_PAGE_DOWN;
            case home: return rl.KEY_HOME;
            case end: return rl.KEY_END;
            case capsLock: return rl.KEY_CAPS_LOCK;
            case scrollLock: return rl.KEY_SCROLL_LOCK;
            case numLock: return rl.KEY_NUM_LOCK;
            case printScreen: return rl.KEY_PRINT_SCREEN;
            case pause: return rl.KEY_PAUSE;
            case shift: return rl.KEY_LEFT_SHIFT;
            case shiftRight: return rl.KEY_RIGHT_SHIFT;
            case ctrl: return rl.KEY_LEFT_CONTROL;
            case ctrlRight: return rl.KEY_RIGHT_CONTROL;
            case alt: return rl.KEY_LEFT_ALT;
            case altRight: return rl.KEY_RIGHT_ALT;
            case win: return rl.KEY_LEFT_SUPER;
            case winRight: return rl.KEY_RIGHT_SUPER;
            case menu: return rl.KEY_KB_MENU;
            case f1: return rl.KEY_F1;
            case f2: return rl.KEY_F2;
            case f3: return rl.KEY_F3;
            case f4: return rl.KEY_F4;
            case f5: return rl.KEY_F5;
            case f6: return rl.KEY_F6;
            case f7: return rl.KEY_F7;
            case f8: return rl.KEY_F8;
            case f9: return rl.KEY_F9;
            case f10: return rl.KEY_F10;
            case f11: return rl.KEY_F11;
            case f12: return rl.KEY_F12;
        }
    }

    RlKey toRl(Mouse from) {
        with (Mouse) final switch (from) {
            case none: return rl.MOUSE_BUTTON_LEFT; // NOTE: This is funny, but works.
            case left: return rl.MOUSE_BUTTON_LEFT;
            case right: return rl.MOUSE_BUTTON_RIGHT;
            case middle: return rl.MOUSE_BUTTON_MIDDLE;
        }
    }

    RlKey toRl(Gamepad from) {
        with (Gamepad) final switch (from) {
            case none: return rl.GAMEPAD_BUTTON_UNKNOWN;
            case left: return rl.GAMEPAD_BUTTON_LEFT_FACE_LEFT;
            case right: return rl.GAMEPAD_BUTTON_LEFT_FACE_RIGHT;
            case up: return rl.GAMEPAD_BUTTON_LEFT_FACE_UP;
            case down: return rl.GAMEPAD_BUTTON_LEFT_FACE_DOWN;
            case y: return rl.GAMEPAD_BUTTON_RIGHT_FACE_UP;
            case x: return rl.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT;
            case a: return rl.GAMEPAD_BUTTON_RIGHT_FACE_DOWN;
            case b: return rl.GAMEPAD_BUTTON_RIGHT_FACE_LEFT;
            case lt: return rl.GAMEPAD_BUTTON_LEFT_TRIGGER_2;
            case lb: return rl.GAMEPAD_BUTTON_LEFT_TRIGGER_1;
            case lsb: return rl.GAMEPAD_BUTTON_LEFT_THUMB;
            case rt: return rl.GAMEPAD_BUTTON_RIGHT_TRIGGER_2;
            case rb: return rl.GAMEPAD_BUTTON_RIGHT_TRIGGER_1;
            case rsb: return rl.GAMEPAD_BUTTON_RIGHT_THUMB;
            case back: return rl.GAMEPAD_BUTTON_MIDDLE_LEFT;
            case start: return rl.GAMEPAD_BUTTON_MIDDLE_RIGHT;
            case middle: return rl.GAMEPAD_BUTTON_MIDDLE;
        }
    }
}
