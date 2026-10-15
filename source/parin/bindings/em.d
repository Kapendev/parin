// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `em` module provides access to Emscripten functions.
module parin.bindings.em;

import joka = parin.joka.types;

extern(C) @system nothrow @nogc:

alias em_pthread_t = uint;

enum EM_TIMING_SETTIMEOUT   = 0;
enum EM_TIMING_RAF          = 1;
enum EM_TIMING_SETIMMEDIATE = 2;

enum EM_CALLBACK_THREAD_CONTEXT_MAIN_RUNTIME_THREAD = 1;
enum EM_CALLBACK_THREAD_CONTEXT_CALLING_THREAD      = 2;

alias EMSCRIPTEN_EVENT_TYPE = int;

enum : EMSCRIPTEN_EVENT_TYPE {
    EMSCRIPTEN_EVENT_KEYPRESS              = 1,
    EMSCRIPTEN_EVENT_KEYDOWN               = 2,
    EMSCRIPTEN_EVENT_KEYUP                 = 3,
    EMSCRIPTEN_EVENT_CLICK                 = 4,
    EMSCRIPTEN_EVENT_MOUSEDOWN             = 5,
    EMSCRIPTEN_EVENT_MOUSEUP               = 6,
    EMSCRIPTEN_EVENT_DBLCLICK              = 7,
    EMSCRIPTEN_EVENT_MOUSEMOVE             = 8,
    EMSCRIPTEN_EVENT_WHEEL                 = 9,
    EMSCRIPTEN_EVENT_RESIZE                = 10,
    EMSCRIPTEN_EVENT_SCROLL                = 11,
    EMSCRIPTEN_EVENT_BLUR                  = 12,
    EMSCRIPTEN_EVENT_FOCUS                 = 13,
    EMSCRIPTEN_EVENT_FOCUSIN               = 14,
    EMSCRIPTEN_EVENT_FOCUSOUT              = 15,
    EMSCRIPTEN_EVENT_DEVICEORIENTATION     = 16,
    EMSCRIPTEN_EVENT_DEVICEMOTION          = 17,
    EMSCRIPTEN_EVENT_ORIENTATIONCHANGE     = 18,
    EMSCRIPTEN_EVENT_FULLSCREENCHANGE      = 19,
    EMSCRIPTEN_EVENT_POINTERLOCKCHANGE     = 20,
    EMSCRIPTEN_EVENT_VISIBILITYCHANGE      = 21,
    EMSCRIPTEN_EVENT_TOUCHSTART            = 22,
    EMSCRIPTEN_EVENT_TOUCHEND              = 23,
    EMSCRIPTEN_EVENT_TOUCHMOVE             = 24,
    EMSCRIPTEN_EVENT_TOUCHCANCEL           = 25,
    EMSCRIPTEN_EVENT_GAMEPADCONNECTED      = 26,
    EMSCRIPTEN_EVENT_GAMEPADDISCONNECTED   = 27,
    EMSCRIPTEN_EVENT_BEFOREUNLOAD          = 28,
    EMSCRIPTEN_EVENT_BATTERYCHARGINGCHANGE = 29,
    EMSCRIPTEN_EVENT_BATTERYLEVELCHANGE    = 30,
    EMSCRIPTEN_EVENT_WEBGLCONTEXTLOST      = 31,
    EMSCRIPTEN_EVENT_WEBGLCONTEXTRESTORED  = 32,
    EMSCRIPTEN_EVENT_MOUSEENTER            = 33,
    EMSCRIPTEN_EVENT_MOUSELEAVE            = 34,
    EMSCRIPTEN_EVENT_MOUSEOVER             = 35,
    EMSCRIPTEN_EVENT_MOUSEOUT              = 36,
    EMSCRIPTEN_EVENT_CANVASRESIZED         = 37,
    EMSCRIPTEN_EVENT_POINTERLOCKERROR      = 38
}

enum EM_HTML5_SHORT_STRING_LEN_BYTES  = 32;
enum EM_HTML5_MEDIUM_STRING_LEN_BYTES = 64;
enum EM_HTML5_LONG_STRING_LEN_BYTES   = 128;

enum DOM_DELTA_PIXEL = 0;
enum DOM_DELTA_LINE  = 1;
enum DOM_DELTA_PAGE  = 2;

enum EMSCRIPTEN_ORIENTATION_UNSUPPORTED         = 0;
enum EMSCRIPTEN_ORIENTATION_PORTRAIT_PRIMARY    = 1;
enum EMSCRIPTEN_ORIENTATION_PORTRAIT_SECONDARY  = 2;
enum EMSCRIPTEN_ORIENTATION_LANDSCAPE_PRIMARY   = 4;
enum EMSCRIPTEN_ORIENTATION_LANDSCAPE_SECONDARY = 8;

enum EMSCRIPTEN_FULLSCREEN_SCALE_DEFAULT = 0;
enum EMSCRIPTEN_FULLSCREEN_SCALE_STRETCH = 1;
enum EMSCRIPTEN_FULLSCREEN_SCALE_ASPECT  = 2;
enum EMSCRIPTEN_FULLSCREEN_SCALE_CENTER  = 3;

enum EMSCRIPTEN_FULLSCREEN_CANVAS_SCALE_NONE   = 0;
enum EMSCRIPTEN_FULLSCREEN_CANVAS_SCALE_STDDEF = 1;
enum EMSCRIPTEN_FULLSCREEN_CANVAS_SCALE_HIDEF  = 2;

enum EMSCRIPTEN_FULLSCREEN_FILTERING_DEFAULT  = 0;
enum EMSCRIPTEN_FULLSCREEN_FILTERING_NEAREST  = 1;
enum EMSCRIPTEN_FULLSCREEN_FILTERING_BILINEAR = 2;

/// This type is used to return the result of most functions in this API.
/// Zero and positive values denote success, while negative values signal failure.
alias EMSCRIPTEN_RESULT = int;

alias em_mouse_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenMouseEvent* mouseEvent, void* userData);
alias em_key_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenKeyboardEvent* keyEvent, void* userData);
alias em_wheel_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenWheelEvent* wheelEvent, void* userData);
alias em_ui_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenUiEvent* uiEvent, void* userData);
alias em_focus_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenFocusEvent* focusEvent, void* userData);
alias em_deviceorientation_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenDeviceOrientationEvent* deviceOrientationEvent, void* userData);
alias em_devicemotion_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenDeviceMotionEvent* deviceMotionEvent, void* userData);
alias em_orientationchange_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenOrientationChangeEvent* orientationChangeEvent, void* userData);
alias em_fullscreenchange_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenFullscreenChangeEvent* fullscreenChangeEvent, void* userData);
alias em_pointerlockchange_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenPointerlockChangeEvent* pointerlockChangeEvent, void* userData);
alias em_pointerlockerror_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, void* reserved, void* userData);
alias em_visibilitychange_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenVisibilityChangeEvent* visibilityChangeEvent, void* userData);
alias em_touch_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenTouchEvent* touchEvent, void* userData);
alias em_gamepad_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenGamepadEvent* gamepadEvent, void* userData);
alias em_battery_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, EmscriptenBatteryEvent* batteryEvent, void* userData);
alias em_beforeunload_callback = const(char)* function(EMSCRIPTEN_EVENT_TYPE eventType, void* reserved, void* userData);
alias em_canvasresized_callback_func = bool function(EMSCRIPTEN_EVENT_TYPE eventType, void* reserved, void* userData);

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
    // canvasX and canvasY are deprecated
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
    // canvasX and canvasY are deprecated
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
    joka.StaticArray!(EmscriptenTouchPoint, 32) touches;
}

struct EmscriptenKeyboardEvent {
    double timestamp;
    uint location;
    bool ctrlKey;
    bool shiftKey;
    bool altKey;
    bool metaKey;
    bool repeat;
    uint charCode;
    uint keyCode;
    uint which;
    char[EM_HTML5_SHORT_STRING_LEN_BYTES] key;
    char[EM_HTML5_SHORT_STRING_LEN_BYTES] code;
    char[EM_HTML5_SHORT_STRING_LEN_BYTES] charValue;
    char[EM_HTML5_SHORT_STRING_LEN_BYTES] locale;
}

struct EmscriptenWheelEvent {
    EmscriptenMouseEvent mouse;
    double deltaX;
    double deltaY;
    double deltaZ;
    uint deltaMode;
}

struct EmscriptenUiEvent {
    int detail;
    int documentBodyClientWidth;
    int documentBodyClientHeight;
    int windowInnerWidth;
    int windowInnerHeight;
    int windowOuterWidth;
    int windowOuterHeight;
    int scrollTop;
    int scrollLeft;
}

struct EmscriptenFocusEvent {
    char[EM_HTML5_LONG_STRING_LEN_BYTES] nodeName;
    char[EM_HTML5_LONG_STRING_LEN_BYTES] id;
}

struct EmscriptenDeviceOrientationEvent {
    double alpha;
    double beta;
    double gamma;
    bool absolute;
}

struct EmscriptenDeviceMotionEvent {
    double accelerationX;
    double accelerationY;
    double accelerationZ;
    double accelerationIncludingGravityX;
    double accelerationIncludingGravityY;
    double accelerationIncludingGravityZ;
    double rotationRateAlpha;
    double rotationRateBeta;
    double rotationRateGamma;
    int supportedFields;
}

struct EmscriptenOrientationChangeEvent {
    int orientationIndex;
    int orientationAngle;
}

struct EmscriptenFullscreenChangeEvent {
    bool isFullscreen;
    bool fullscreenEnabled;
    char[EM_HTML5_LONG_STRING_LEN_BYTES] nodeName;
    char[EM_HTML5_LONG_STRING_LEN_BYTES] id;
    int elementWidth;
    int elementHeight;
    int screenWidth;
    int screenHeight;
}

struct EmscriptenPointerlockChangeEvent {
    bool isActive;
    char[EM_HTML5_LONG_STRING_LEN_BYTES] nodeName;
    char[EM_HTML5_LONG_STRING_LEN_BYTES] id;
}

struct EmscriptenVisibilityChangeEvent {
    bool hidden;
    int visibilityState;
}

struct EmscriptenGamepadEvent {
    double timestamp;
    int numAxes;
    int numButtons;
    double[64] axis;
    double[64] analogButton;
    bool[64] digitalButton;
    bool connected;
    int index;
    char[EM_HTML5_MEDIUM_STRING_LEN_BYTES] id;
    char[EM_HTML5_MEDIUM_STRING_LEN_BYTES] mapping;
}

struct EmscriptenBatteryEvent {
    double chargingTime;
    double dischargingTime;
    double level;
    bool charging;
}

struct EmscriptenFullscreenStrategy {
    int scaleMode;
    int canvasResolutionScaleMode;
    int filteringMode;
    em_canvasresized_callback_func canvasResizedCallback;
    void* canvasResizedCallbackUserData;
    em_pthread_t canvasResizedCallbackTargetThread;
}

// Keyboard
EMSCRIPTEN_RESULT emscripten_set_keypress_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_key_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_keydown_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_key_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_keyup_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_key_callback_func callback, em_pthread_t targetThread);

// Mouse
EMSCRIPTEN_RESULT emscripten_set_click_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_mousedown_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_mouseup_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_dblclick_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_mousemove_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_mouseenter_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_mouseleave_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_mouseover_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_mouseout_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_contextmenu_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_mouse_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_get_mouse_status(EmscriptenMouseEvent* mouseState);

// Wheel
EMSCRIPTEN_RESULT emscripten_set_wheel_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_wheel_callback_func callback, em_pthread_t targetThread);

// UI (resize/scroll)
EMSCRIPTEN_RESULT emscripten_set_resize_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_ui_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_scroll_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_ui_callback_func callback, em_pthread_t targetThread);

// Focus
EMSCRIPTEN_RESULT emscripten_set_blur_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_focus_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_focus_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_focus_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_focusin_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_focus_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_focusout_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_focus_callback_func callback, em_pthread_t targetThread);

// Device Sensors
EMSCRIPTEN_RESULT emscripten_set_deviceorientation_callback_on_thread(void* userData, bool useCapture, em_deviceorientation_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_devicemotion_callback_on_thread(void* userData, bool useCapture, em_devicemotion_callback_func callback, em_pthread_t targetThread);

// Orientation
EMSCRIPTEN_RESULT emscripten_set_orientationchange_callback_on_thread(void* userData, bool useCapture, em_orientationchange_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_lock_orientation(int allowedOrientations);
EMSCRIPTEN_RESULT emscripten_unlock_orientation();

// Fullscreen
EMSCRIPTEN_RESULT emscripten_request_fullscreen(const(char)* target, bool deferUntilInEventHandler);
EMSCRIPTEN_RESULT emscripten_request_fullscreen_strategy(const(char)* target, bool deferUntilInEventHandler, const EmscriptenFullscreenStrategy* fullscreenStrategy);
EMSCRIPTEN_RESULT emscripten_exit_fullscreen();
EMSCRIPTEN_RESULT emscripten_enter_soft_fullscreen(const(char)* target, const EmscriptenFullscreenStrategy* fullscreenStrategy);
EMSCRIPTEN_RESULT emscripten_exit_soft_fullscreen();
EMSCRIPTEN_RESULT emscripten_set_fullscreenchange_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_fullscreenchange_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_get_fullscreen_status(EmscriptenFullscreenChangeEvent* fullscreenStatus);

// Pointer Lock
EMSCRIPTEN_RESULT emscripten_request_pointerlock(const(char)* target, bool deferUntilInEventHandler);
EMSCRIPTEN_RESULT emscripten_exit_pointerlock();
EMSCRIPTEN_RESULT emscripten_set_pointerlockchange_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_pointerlockchange_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_pointerlockerror_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_pointerlockerror_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_get_pointerlock_status(EmscriptenPointerlockChangeEvent* pointerlockStatus);

// Visibility
EMSCRIPTEN_RESULT emscripten_set_visibilitychange_callback_on_thread(void* userData, bool useCapture, em_visibilitychange_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_get_visibility_status(EmscriptenVisibilityChangeEvent* visibilityStatus);

// Touch
EMSCRIPTEN_RESULT emscripten_set_touchstart_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_touch_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_touchend_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_touch_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_touchmove_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_touch_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_touchcancel_callback_on_thread(const(char)* target, void* userData, bool useCapture, em_touch_callback_func callback, em_pthread_t targetThread);

// Gamepad
EMSCRIPTEN_RESULT emscripten_set_gamepadconnected_callback_on_thread(void* userData, bool useCapture, em_gamepad_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_gamepaddisconnected_callback_on_thread(void* userData, bool useCapture, em_gamepad_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_sample_gamepad_data();
int emscripten_get_num_gamepads();
EMSCRIPTEN_RESULT emscripten_get_gamepad_status(int index, EmscriptenGamepadEvent* gamepadState);

// Battery
EMSCRIPTEN_RESULT emscripten_set_batterychargingchange_callback_on_thread(void* userData, em_battery_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_set_batterylevelchange_callback_on_thread(void* userData, em_battery_callback_func callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_get_battery_status(EmscriptenBatteryEvent* batteryState);

// Other
EMSCRIPTEN_RESULT emscripten_vibrate(int msecs);
EMSCRIPTEN_RESULT emscripten_vibrate_pattern(int* msecsArray, int numEntries);
EMSCRIPTEN_RESULT emscripten_set_beforeunload_callback_on_thread(void* userData, em_beforeunload_callback callback, em_pthread_t targetThread);
EMSCRIPTEN_RESULT emscripten_html5_remove_event_listener(const(char)* target, void* userData, EMSCRIPTEN_EVENT_TYPE eventTypeId, void* callback);
EMSCRIPTEN_RESULT emscripten_get_canvas_element_size(const(char)* target, int* width, int* height);
EMSCRIPTEN_RESULT emscripten_set_canvas_element_size(const(char)* target, int width, int height);
EMSCRIPTEN_RESULT emscripten_get_element_css_size(const(char)* target, double* width, double* height);
EMSCRIPTEN_RESULT emscripten_set_element_css_size(const(char)* target, double width, double height);
void emscripten_html5_remove_all_event_listeners();
void emscripten_set_main_loop(void* ptr, int fps, bool loop);
void emscripten_cancel_main_loop();
double emscripten_get_device_pixel_ratio();
void emscripten_set_window_title(const(char)* title);
void emscripten_hide_mouse();
int emscripten_set_main_loop_timing(int mode, int value);
int emscripten_request_animation_frame(bool function(double time, void* userData) cb, void* userData);
void emscripten_cancel_animation_frame(int requestAnimationFrameId);
void emscripten_request_animation_frame_loop(bool function(double time, void* userData) cb, void* userData);
double emscripten_date_now();
double emscripten_performance_now();
