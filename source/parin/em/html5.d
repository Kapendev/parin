// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `html5` module provides access to the html5.h functions.
module parin.em.html5;

import joka.types;

nothrow @nogc extern(C):

enum EMSCRIPTEN_EVENT_KEYPRESS               = 1;
enum EMSCRIPTEN_EVENT_KEYDOWN                = 2;
enum EMSCRIPTEN_EVENT_KEYUP                  = 3;
enum EMSCRIPTEN_EVENT_CLICK                  = 4;
enum EMSCRIPTEN_EVENT_MOUSEDOWN              = 5;
enum EMSCRIPTEN_EVENT_MOUSEUP                = 6;
enum EMSCRIPTEN_EVENT_DBLCLICK               = 7;
enum EMSCRIPTEN_EVENT_MOUSEMOVE              = 8;
enum EMSCRIPTEN_EVENT_WHEEL                  = 9;
enum EMSCRIPTEN_EVENT_RESIZE                = 10;
enum EMSCRIPTEN_EVENT_SCROLL                = 11;
enum EMSCRIPTEN_EVENT_BLUR                  = 12;
enum EMSCRIPTEN_EVENT_FOCUS                 = 13;
enum EMSCRIPTEN_EVENT_FOCUSIN               = 14;
enum EMSCRIPTEN_EVENT_FOCUSOUT              = 15;
enum EMSCRIPTEN_EVENT_DEVICEORIENTATION     = 16;
enum EMSCRIPTEN_EVENT_DEVICEMOTION          = 17;
enum EMSCRIPTEN_EVENT_ORIENTATIONCHANGE     = 18;
enum EMSCRIPTEN_EVENT_FULLSCREENCHANGE      = 19;
enum EMSCRIPTEN_EVENT_POINTERLOCKCHANGE     = 20;
enum EMSCRIPTEN_EVENT_VISIBILITYCHANGE      = 21;
enum EMSCRIPTEN_EVENT_TOUCHSTART            = 22;
enum EMSCRIPTEN_EVENT_TOUCHEND              = 23;
enum EMSCRIPTEN_EVENT_TOUCHMOVE             = 24;
enum EMSCRIPTEN_EVENT_TOUCHCANCEL           = 25;
enum EMSCRIPTEN_EVENT_GAMEPADCONNECTED      = 26;
enum EMSCRIPTEN_EVENT_GAMEPADDISCONNECTED   = 27;
enum EMSCRIPTEN_EVENT_BEFOREUNLOAD          = 28;
enum EMSCRIPTEN_EVENT_BATTERYCHARGINGCHANGE = 29;
enum EMSCRIPTEN_EVENT_BATTERYLEVELCHANGE    = 30;
enum EMSCRIPTEN_EVENT_WEBGLCONTEXTLOST      = 31;
enum EMSCRIPTEN_EVENT_WEBGLCONTEXTRESTORED  = 32;
enum EMSCRIPTEN_EVENT_MOUSEENTER            = 33;
enum EMSCRIPTEN_EVENT_MOUSELEAVE            = 34;
enum EMSCRIPTEN_EVENT_MOUSEOVER             = 35;
enum EMSCRIPTEN_EVENT_MOUSEOUT              = 36;
enum EMSCRIPTEN_EVENT_CANVASRESIZED         = 37;
enum EMSCRIPTEN_EVENT_POINTERLOCKERROR      = 38;

// This type is used to return the result of most functions in this API.
// Zero and positive values denote success, while negative values signal failure.
alias EMSCRIPTEN_RESULT = int;
alias em_mouse_callback_func = bool function(int eventType, const(EmscriptenMouseEvent)* mouseEvent, void* userData);
alias em_touch_callback_func = bool function(int eventType, const(EmscriptenTouchEvent)* touchEvent, void* userData);

struct EmscriptenMouseEvent {
    double timestamp = 0;
    int screenX;
    int screenY;
    int clientX;
    int clientY;
    bool ctrlKey;
    bool shiftKey;
    bool altKey;
    bool metaKey;
    ushort button;
    ushort buttons;
    int movementX;
    int movementY;
    int targetX;
    int targetY;
    // canvasX and canvasY are deprecated - there no longer exists a Module['canvas'] object, so canvasX/Y are no longer reported (register a listener on canvas directly to get canvas coordinates, or translate manually)
    int canvasX;
    int canvasY;
    int padding;
}

struct EmscriptenTouchPoint {
    int identifier;
    int screenX;
    int screenY;
    int clientX;
    int clientY;
    int pageX;
    int pageY;
    bool isChanged;
    bool onTarget;
    int targetX;
    int targetY;
    // canvasX and canvasY are deprecated - there no longer exists a Module['canvas'] object, so canvasX/Y are no longer reported (register a listener on canvas directly to get canvas coordinates, or translate manually)
    int canvasX;
    int canvasY;
}

struct EmscriptenTouchEvent {
    double timestamp = 0;
    int numTouches;
    bool ctrlKey;
    bool shiftKey;
    bool altKey;
    bool metaKey;
    Array!(EmscriptenTouchPoint, 32) touches;
}

void emscripten_set_main_loop(void* ptr, int fps, bool loop);
void emscripten_cancel_main_loop();
double emscripten_get_device_pixel_ratio();

EMSCRIPTEN_RESULT emscripten_get_canvas_element_size(const(char)* target, int* width, int* height);
EMSCRIPTEN_RESULT emscripten_get_element_css_size(const(char)* target, double* width, double* height);

EMSCRIPTEN_RESULT emscripten_set_click_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback);
EMSCRIPTEN_RESULT emscripten_set_mousedown_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback);
EMSCRIPTEN_RESULT emscripten_set_mouseup_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback);
EMSCRIPTEN_RESULT emscripten_set_dblclick_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback);
EMSCRIPTEN_RESULT emscripten_set_mousemove_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback);
EMSCRIPTEN_RESULT emscripten_set_mouseenter_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback);
EMSCRIPTEN_RESULT emscripten_set_mouseleave_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback);
EMSCRIPTEN_RESULT emscripten_get_mouse_status(EmscriptenMouseEvent* mouseState);

EMSCRIPTEN_RESULT emscripten_set_touchstart_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_touch_callback_func callback);
EMSCRIPTEN_RESULT emscripten_set_touchend_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_touch_callback_func callback);
EMSCRIPTEN_RESULT emscripten_set_touchmove_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_touch_callback_func callback);
EMSCRIPTEN_RESULT emscripten_set_touchcancel_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_touch_callback_func callback);
