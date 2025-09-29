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
    enum defaultBackendResourcesCapacity = 1024;
}
// ----------

@trusted nothrow:

alias RlFilter = int;
alias RlWrap   = int;
alias RlBlend  = int;
alias RlKey    = int;

struct BackendState {
    alias TexturesData = FixedList!(SparseListItem!(rl.Texture2D), defaultBackendResourcesCapacity);
    alias SoundsData   = FixedList!(SparseListItem!(rl.Sound), defaultBackendResourcesCapacity);
    alias MusicData    = FixedList!(SparseListItem!(rl.Music), defaultBackendResourcesCapacity);
    alias FontsData    = FixedList!(SparseListItem!(rl.Font), defaultBackendResourcesCapacity);

    SparseList!(TexturesData.Item.Item, TexturesData) textures;
    SparseList!(SoundsData.Item.Item, SoundsData) sounds;
    SparseList!(MusicData.Item.Item, MusicData) music;
    SparseList!(FontsData.Item.Item, FontsData) fonts;
}

void readyBackend(int width, int height, IStr title, bool vsync, int fpsMax, int windowMinWidth, int windowMinHeight) {
    _backendState = jokaMake!BackendState();
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | (vsync ? rl.FLAG_VSYNC_HINT : 0));
    rl.SetTraceLogLevel(rl.LOG_ERROR);
    rl.InitWindow(width, height, title.toCStr().getOr());
    rl.InitAudioDevice();
    rl.SetExitKey(rl.KEY_NULL);
    rl.SetTargetFPS(fpsMax);
    rl.SetWindowMinSize(windowMinWidth, windowMinHeight);
    rl.rlSetBlendFactorsSeparate(0x0302, 0x0303, 1, 0x0303, 0x8006, 0x8006);
}

void finishBackend() {
    jokaFree(_backendState);
    rl.CloseAudioDevice();
    rl.CloseWindow();
}

Resource loadTexture(const(ubyte)[] from, IStr ext = ".png") {
    auto image = rl.LoadImageFromMemory(ext.toCStr().getOr(), from.ptr, cast(int) from.length);
    auto texture = rl.LoadTextureFromImage(image);
    rl.UnloadImage(image);
    _backendState.textures.append(texture);
    return cast(Resource) _backendState.textures.hotIndex;
}

@trusted nothrow @nogc:

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

// raylib does stuff internally.
// NOTE: No idea if this is a good name.
void pumpEvents() {}

void setTextureFilter(Resource resource, Filter filter) {
    // TODO
}

void setTextureWrap(Resource resource, Wrap wrap) {
    // TODO
}

void beginBlend(Blend blend) {
    rl.BeginBlendMode(toRl(blend));
}

void endBlend() {
    rl.EndBlendMode();
}

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
