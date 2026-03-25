// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

// NOTE: Last time I added on/off states. Works.
//   I now want to think about how that RPGMaker thing will work with the buttons acting like sliders.
//   Also maybe how to do grid layouts. Maybe even navigation there???

/// The `ui` module includes a UI library.
module parin.joka.ui;

import parin.joka.math;
import parin.joka.types;

version (JokaSmallFootprint) {
    enum defaultUiCommandsCapacity = 128;
    enum defaultUiCharDataCapacity = 1 * kilobyte;
} else {
    enum defaultUiCommandsCapacity = 512;
    enum defaultUiCharDataCapacity = 128 * kilobyte;
}

enum defaultUiOptionFlags = UiOptionFlag.alignCenter;

/// The UI font type.
alias UiFont = void*;
/// The UI texture type.
alias UiTexture = void*;
/// The UI icon ID type.
alias UiIconId = uint;

@trusted nothrow @nogc {
    /// A function used for getting the width and height of the text.
    alias UiTextSizeFunc = IVec2 function(UiFont font, IStr text);
    alias UiIconIdSizeFunc = IVec2 function(UiIconId iconId);
}

enum UiColorType : ubyte {
    border,       /// Default border color.
    borderOff,    /// Border color on no interaction.
    icon,         /// Default icon color.
    iconOff,      /// Icon color on no interaction.
    text,         /// Default text color.
    textOff,      /// Text color on no interaction.
    button,       /// Default button color.
    buttonOff,    /// Button color on no interaction.
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
    int padding;
}

alias UiMouseButtonFlags = ubyte;
enum UiMouseButtonFlag : UiMouseButtonFlags {
    none   = 0x0,
    left   = 0x1,
    right  = 0x2,
    middle = 0x4,
}

alias UiKeyFlags = ubyte;
enum UiKeyFlag : UiKeyFlags {
    none  = 0,
    left  = 1U << 1,
    right = 1U << 2,
    up    = 1U << 3,
    down  = 1U << 4,
    tab   = 1U << 5,
    enter = 1U << 6,
}

enum UiKeyNavigation : ubyte {
    none,
    verticalOrHorizontal,
    vertical,
    horizontal,
}

struct UiInput {
    IVec2 mousePosition;
    IVec2 mousePressedPosition;
    UiMouseButtonFlags mouseButtonDown;
    UiMouseButtonFlags mouseButtonPressed;
    UiMouseButtonFlags mouseButtonReleased;
    bool mouseActionOnRelease;

    UiKeyFlags keyDown;
    UiKeyFlags keyPressed;
    UiKeyFlags keyReleased;
    UiKeyNavigation keyNavigation;
    UiKeyNavigation nextKeyNavigation;

    @safe nothrow @nogc:

    bool mouseAction(IRect area) {
        return mouseActionOnRelease
            ? ((mouseButtonReleased & UiMouseButtonFlag.left) && area.hasPoint(mousePressedPosition))
            : (mouseButtonPressed & UiMouseButtonFlag.left);
    }

    bool keyNavigationUpAction() {
        with (UiKeyNavigation) final switch (keyNavigation) {
            case none:
            case verticalOrHorizontal: return (keyPressed & UiKeyFlag.up) || (keyPressed & UiKeyFlag.left);
            case vertical: return (keyPressed & UiKeyFlag.up) != 0;
            case horizontal: return (keyPressed & UiKeyFlag.left) != 0;
        }
    }

    bool keyNavigationDownAction() {
        with (UiKeyNavigation) final switch (keyNavigation) {
            case none:
            case verticalOrHorizontal: return (keyPressed & UiKeyFlag.tab) || (keyPressed & UiKeyFlag.down) || (keyPressed & UiKeyFlag.right);
            case vertical: return (keyPressed & UiKeyFlag.tab) || (keyPressed & UiKeyFlag.down);
            case horizontal: return (keyPressed & UiKeyFlag.tab) || (keyPressed & UiKeyFlag.right);
        }
    }

    bool keyNavigationAction() {
        return keyNavigationUpAction || keyNavigationDownAction;
    }

    void clear() {
        auto tempMousePressedPosition = mousePressedPosition;
        this = UiInput();
        mousePressedPosition = tempMousePressedPosition;
    }
}

alias UiCommandFlags = ubyte;
enum UiCommandFlag : UiCommandFlags {
    none   = 0x00,
    hover  = 0x01,
    active = 0x02,
    focus  = 0x04,
    border = 0x08,
    off    = 0x10,
}

enum UiCommandType : ubyte {
    none,
    rect,
    text,
    icon,
}

struct UiCommandBase {
    UiCommandType type;
    UiColorType colorType;
}

struct UiCommandRect {
    UiCommandBase base;
    UiCommandFlags flags;
    IRect data;
    alias data this;
}

struct UiCommandText {
    UiCommandBase base;
    IRect area;
    IStr data;
    alias data this;
}

struct UiCommandIcon {
    UiCommandBase base;
    IRect area;
    UiIconId data;
    alias data this;
}

union UiCommand {
    UiCommandType type;
    UiCommandBase base;
    UiCommandRect rect;
    UiCommandText text;
    UiCommandIcon icon;
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

    bool nextIsRectWith(Sz currentIndex, UiCommandFlags flags) {
        if (currentIndex + 1 >= length) return false;
        auto next = &items[currentIndex + 1];
        return next.type == UiCommandType.rect && next.rect.flags & flags;
    }
}

alias UiControlFlags = ubyte;
enum UiControlFlag : UiControlFlags {
    none      = 0x00, /// None.
    active    = 0x01, /// Control is active (e.g. active window).
    submitted = 0x02, /// Control value submitted (e.g. clicked button).
    changed   = 0x04, /// Control value changed (e.g. modified text).
}

alias UiOptionFlags = ubyte;
enum UiOptionFlag : UiOptionFlags {
    none        = 0x0000,
    alignCenter = 0x0001,
    alignRight  = 0x0002,
    turnOff     = 0x0004,
}

struct UiFocusState {
    int currentFocusId;
    int nextFocusId;       // Can be used to force a new current ID for the next frame.
    IVec2 nextFocusIdWrap; // Can be used to force a specific start and end value when wrapping at the end.
    int focusIdCounter;
    bool focusIsActive;

    @safe nothrow @nogc:

    bool isFocused(int id) {
        return focusIsActive && currentFocusId == id;
    }

    void setCurrentFocusId(int id) {
        currentFocusId = id;
        focusIsActive = true;
    }

    void wrapCurrentFocusIdIfNeeded(int startInclusive, int endInclusive) {
        if (focusIdCounter == 0) return;
        if (currentFocusId < startInclusive) currentFocusId = endInclusive;
        if (currentFocusId > endInclusive) currentFocusId = startInclusive;
    }
}

struct ScopedUiFocus {
    UiContext* _uiContext;
    int _previousFocusIdCounter;
    bool _canIgnore;

    pragma(inline, true) @safe nothrow @nogc:
    @disable this();

    @trusted
    this(ref UiContext context, UiKeyNavigation keyNavigation = UiKeyNavigation.none, bool canIgnore = false) {
        _uiContext = &context;
        _previousFocusIdCounter = context.focusState.focusIdCounter;
        _canIgnore = canIgnore;
        if (_canIgnore) return;
        _uiContext.input.nextKeyNavigation = keyNavigation;
    }

    ~this() {
        if (_canIgnore) return;
        auto count = _uiContext.focusState.focusIdCounter - _previousFocusIdCounter;
        if (count && _uiContext.input.keyNavigationAction) {
            _uiContext.focusState.nextFocusIdWrap = IVec2(_previousFocusIdCounter + 1, _uiContext.focusState.focusIdCounter);
        }
    }
}

struct UiLayout {
    IRect area;
    int slice;
    int spacing;
    bool isVertical;
    bool isStartingfromBottomOrRight;

    @safe nothrow @nogc:

    IRect pop(bool span = false) {
        if (!area.hasSize) return IRect();
        if (span) {
            return isVertical ? area.subTop(area.h) : area.subLeft(area.w);
        }
        if (isVertical) {
            return isStartingfromBottomOrRight ? area.subBottom(slice, spacing) : area.subTop(slice, spacing);
        } else {
            return isStartingfromBottomOrRight ? area.subRight(slice, spacing) : area.subLeft(slice, spacing);
        }
    }
}

struct UiContext {
    UiCommands commands;
    UiFocusState focusState;
    UiTextSizeFunc textSize; /// The function used for getting the size of the text.
    UiIconIdSizeFunc iconSize;
    UiStyle* style;
    UiStyle _style;
    UiInput input;

    char[defaultUiCharDataCapacity] charData;
    Sz charDataLength;
    int charHeight;
    int charOffset;

    @safe nothrow @nogc:

    this(UiTextSizeFunc textSizeFunc, UiFont font, int fontScale = 1, UiIconIdSizeFunc iconSizeFunc = null) {
        ready(textSizeFunc, font, fontScale, iconSizeFunc);
    }

    void ready(UiTextSizeFunc textSizeFunc, UiFont font, int fontScale = 1, UiIconIdSizeFunc iconSizeFunc = null) {
        textSize = textSizeFunc ? textSizeFunc : &tempUiTextSizeFunc;
        restoreDefaultStyle();
        applyDefaultStyle();
        setFont(font, fontScale);
        iconSize = iconSizeFunc;
    }

    void setFont(UiFont font, int fontScale = 1) {
        style.font = font;
        style.fontScale = fontScale;
        charHeight = textSize(style.font, "A").y * style.fontScale;
        charOffset = (textSize(style.font, "A\nA").y * style.fontScale) - charHeight * 2;
    }

    void applyDefaultStyle() {
        with (UiColorType) {
            // Borders
            style.colors[border]       = Rgba(40,  44,  52,  255);
            style.colors[borderOff]    = Rgba(33,  37,  43,  255);
            // Foreground Elements
            style.colors[icon]         = Rgba(255, 255, 255, 200); // Soft white
            style.colors[iconOff]      = Rgba(100, 110, 125, 255);
            style.colors[text]         = Rgba(210, 215, 225, 255);
            style.colors[textOff]      = Rgba(100, 110, 125, 255);
            // Interaction Elements
            style.colors[button]       = Rgba(55,  61,  72,  255);
            style.colors[buttonOff]    = Rgba(45,  50,  60,  255);
            style.colors[buttonHover]  = Rgba(70,  78,  92,  255);
            style.colors[buttonActive] = Rgba(79,  140, 255, 255); // Vibrant Blue
            style.colors[buttonFocus]  = Rgba(97,  175, 239, 255); // Soft Blue highlight
        }
        style.border = 1;
        style.padding = 5;
    }

    void restoreDefaultStyle() {
        style = &_style;
    }

    ScopedUiFocus captureFocus(UiKeyNavigation keyNavigation = UiKeyNavigation.none, bool canIgnore = false) {
        return ScopedUiFocus(this, keyNavigation, canIgnore);
    }

    static @trusted
    UiLayout row(IRect area, int areaCount, int spacing, bool isStartingfromBottomOrRight = false, int infiniteSlice = 0) {
        if (infiniteSlice && !isStartingfromBottomOrRight) {
            auto infiniteArea = area;
            infiniteArea.w = int.max;
            return UiLayout(infiniteArea, infiniteSlice, spacing, false, isStartingfromBottomOrRight);
        } else {
            return UiLayout(area, area.sliceX(areaCount, spacing), spacing, false, isStartingfromBottomOrRight);
        }
    }

    static @trusted
    UiLayout col(IRect area, int areaCount, int spacing, bool isStartingfromBottomOrRight = false, int infiniteSlice = 0) {
        if (infiniteSlice && !isStartingfromBottomOrRight) {
            auto infiniteArea = area;
            infiniteArea.h = int.max;
            return UiLayout(infiniteArea, infiniteSlice, spacing, true, isStartingfromBottomOrRight);
        } else {
            return UiLayout(area, area.sliceY(areaCount, spacing), spacing, true, isStartingfromBottomOrRight);
        }
    }

    @trusted
    IStrz makeStrzCopy(IStr text) {
        auto charsNeeded = text.length + 1;
        auto newCharDataLength = charDataLength + charsNeeded;
        if (newCharDataLength > defaultUiCharDataCapacity) return null;

        auto result = charData.ptr + charDataLength;
        jokaMemcpy(result, text.ptr, text.length);
        result[text.length] = '\0';
        charDataLength = newCharDataLength;
        return result;
    }

    @trusted
    void drawRect(IRect area, UiColorType colorType, bool hover, bool active, bool focus, bool border, bool off) {
        if (!area.hasSize) return;

        auto command = UiCommand();
        command.base.type = UiCommandType.rect;
        command.base.colorType = colorType;
        command.rect.data = area;
        if (hover)  command.rect.flags |= UiCommandFlag.hover;
        if (active) command.rect.flags |= UiCommandFlag.active;
        if (focus)  command.rect.flags |= UiCommandFlag.focus;
        if (border) command.rect.flags |= UiCommandFlag.border;
        if (off)    command.rect.flags |= UiCommandFlag.off;
        commands.appendRef(command);
    }

    void drawBorder(IRect area, UiColorType colorType, bool off) {
        if (style.border == 0) return;
        auto borderArea = area;
        borderArea.addAll(style.border);
        drawRect(borderArea, off ? UiColorType.borderOff : UiColorType.border, false, false, false, true, off);
    }

    void drawBox(IRect area, UiColorType colorType, bool hover, bool active, bool focus, bool off) {
        drawBorder(area, colorType, off);
        drawRect(area, colorType, hover, active, focus, false, off);
    }

    void drawIcon(UiIconId iconId, UiColorType colorType, IRect area, UiOptionFlags optionFlags) {
        if (iconId == 0) return;

        auto command = UiCommand();
        command.base.type = UiCommandType.icon;
        command.base.colorType = colorType;
        command.icon.data = iconId;
        auto iconArea = IRect(iconSize(iconId) * style.fontScale);
        iconArea.y = area.centerPoint.y - iconArea.h / 2;
        if (optionFlags & UiOptionFlag.alignCenter) {
            iconArea.x = area.centerPoint.x - iconArea.w / 2;
        } else if (optionFlags & UiOptionFlag.alignRight) {
            iconArea.x = area.rightPoint.x - iconArea.w - style.padding;
        } else {
            iconArea.x = area.x + style.padding;
        }
        command.icon.area = iconArea;
        commands.appendRef(command);
    }

    @trusted
    void drawText(IStr text, UiColorType colorType, IRect area, UiOptionFlags optionFlags) {
        if (text.length == 0) return;

        auto baseTextArea = IRect(textSize(style.font, text) * style.fontScale);
        baseTextArea.y = area.centerPoint.y - baseTextArea.h / 2;
        if (optionFlags & UiOptionFlag.alignCenter) {
            baseTextArea.x = area.centerPoint.x - baseTextArea.w / 2;
        } else if (optionFlags & UiOptionFlag.alignRight) {
            baseTextArea.x = area.rightPoint.x - baseTextArea.w - style.padding;
        } else {
            baseTextArea.x = area.x + style.padding;
        }

        Sz lineStartIndex;
        foreach (i, c; text) {
            if (c == '\n' || i == text.length - 1) {
                auto line = text[lineStartIndex .. i + (i == text.length - 1)];
                auto lineArea = baseTextArea;
                lineArea.w = textSize(style.font, line).x * style.fontScale;
                lineArea.h = charHeight;
                lineArea.y += lineStartIndex ? (lineArea.h + charOffset) : 0;
                // NOTE: Could maybe refactor that alignment part into a function.
                if (optionFlags & UiOptionFlag.alignCenter) {
                    lineArea.x = baseTextArea.centerPoint.x - lineArea.w / 2;
                } else if (optionFlags & UiOptionFlag.alignRight) {
                    lineArea.x = baseTextArea.rightPoint.x - lineArea.w;
                } else {
                    lineArea.x = baseTextArea.x;
                }
                auto lineCommand = UiCommand();
                lineCommand.base.type = UiCommandType.text;
                lineCommand.base.colorType = colorType;
                lineCommand.text.data = makeStrzCopy(line)[0 .. line.length];
                lineCommand.text.area = lineArea;
                commands.appendRef(lineCommand);
                lineStartIndex = i + 1;
            }
        }
    }

    void drawLabelContent(IRect area, IStr text, UiIconId iconId = 0, UiOptionFlags optionFlags = defaultUiOptionFlags) {
        auto iconColorType = (optionFlags & UiOptionFlag.turnOff) ? UiColorType.iconOff : UiColorType.icon;
        auto textColorType = (optionFlags & UiOptionFlag.turnOff) ? UiColorType.textOff : UiColorType.text;
        if (iconId && iconSize && !iconSize(iconId).isZero) {
            if (optionFlags & UiOptionFlag.alignCenter) {
                drawIcon(iconId, iconColorType, area, optionFlags);
            } else if (optionFlags & UiOptionFlag.alignRight) {
                auto newArea = area;
                drawIcon(iconId, iconColorType, newArea.subRight(iconSize(iconId).x), optionFlags);
                newArea.subRight(style.padding);
                drawText(text, textColorType, newArea, optionFlags);
            } else {
                auto newArea = area;
                drawIcon(iconId, iconColorType, newArea.subLeft(iconSize(iconId).x), optionFlags);
                newArea.subLeft(style.padding);
                drawText(text, textColorType, newArea, optionFlags);
            }
        } else {
            drawText(text, textColorType, area, optionFlags);
        }
    }

    void handleKeyNavigationWithoutWrappingCurrentFocusId() {
        if (input.keyNavigationUpAction) {
            focusState.currentFocusId -= 1;
            focusState.focusIsActive = true;
        } else if (input.keyNavigationDownAction) {
            focusState.currentFocusId += 1;
            focusState.focusIsActive = true;
        }
    }

    void begin() {
        commands.clear();
        charDataLength = 0;

        focusState.focusIdCounter = 0;
        if (focusState.nextFocusId) {
            focusState.setCurrentFocusId(focusState.nextFocusId);
            focusState.nextFocusId = 0;
        }

        if (input.mouseButtonPressed & UiMouseButtonFlag.left) {
            input.mousePressedPosition = input.mousePosition;
            focusState.focusIsActive = false;
        }
    }

    void end() {
        if (input.nextKeyNavigation) {
            // NOTE: This part depending on a temp variable is a bit ugly. Maybe change that later.
            auto previousKeyNavigation = input.keyNavigation;
            input.keyNavigation = input.nextKeyNavigation;
            handleKeyNavigationWithoutWrappingCurrentFocusId();
            input.keyNavigation = previousKeyNavigation;
            input.nextKeyNavigation = UiKeyNavigation.none;
        } else {
            handleKeyNavigationWithoutWrappingCurrentFocusId();
        }

        if (focusState.nextFocusIdWrap.isZero) {
            focusState.wrapCurrentFocusIdIfNeeded(1, focusState.focusIdCounter);
        } else {
            focusState.wrapCurrentFocusIdIfNeeded(focusState.nextFocusIdWrap.x, focusState.nextFocusIdWrap.y);
            focusState.nextFocusIdWrap = IVec2();
        }
        input.clear();
    }

    UiControlFlags label(IRect area, IStr text, UiIconId iconId = 0, UiOptionFlags optionFlags = defaultUiOptionFlags) {
        drawLabelContent(area, text, iconId, optionFlags);
        return UiControlFlag.none;
    }

    UiControlFlags label(IVec2 position, IVec2 size, IStr text, UiIconId iconId = 0, UiOptionFlags optionFlags = defaultUiOptionFlags) {
        return label(IRect(position, size), text, iconId, optionFlags);
    }

    UiControlFlags label(int x, int y, int w, int h, IStr text, UiIconId iconId = 0, UiOptionFlags optionFlags = defaultUiOptionFlags) {
        return label(IRect(x, y, w, h), text, iconId, optionFlags);
    }

    UiControlFlags icon(IRect area, UiIconId iconId, UiOptionFlags optionFlags = defaultUiOptionFlags) {
        return label(area, "", iconId, optionFlags);
    }

    UiControlFlags icon(IVec2 position, IVec2 size, UiIconId iconId, UiOptionFlags optionFlags = defaultUiOptionFlags) {
        return label(position, size, "", iconId, optionFlags);
    }

    UiControlFlags icon(int x, int y, int w, int h, UiIconId iconId, UiOptionFlags optionFlags = defaultUiOptionFlags) {
        return label(x, y, w, h, "", iconId, optionFlags);
    }

    UiControlFlags button(IRect area, IStr text, UiIconId iconId = 0, UiOptionFlags optionFlags = defaultUiOptionFlags) {
        auto result = UiControlFlags();
        auto focusId = ++focusState.focusIdCounter; // NOTE: Will never have a value of zero.
        auto hover = area.hasPoint(input.mousePosition) && !(optionFlags & UiOptionFlag.turnOff) ;
        auto active = hover && (input.mouseButtonDown & UiMouseButtonFlag.left) && !(optionFlags & UiOptionFlag.turnOff) ;

        if (hover && (input.mouseButtonPressed & UiMouseButtonFlag.left)) {
            focusState.currentFocusId = focusId;
            focusState.focusIsActive = false;
        }

        auto focus = focusState.isFocused(focusId) && !(optionFlags & UiOptionFlag.turnOff);
        auto submittedByKeyboard = focus && (input.keyPressed & UiKeyFlag.enter);
        if (hover && input.mouseAction(area) || submittedByKeyboard) result |= UiControlFlag.submitted;

        auto colorType = active
            ? UiColorType.buttonActive
            : (  focus ? UiColorType.buttonFocus : (hover ? UiColorType.buttonHover : UiColorType.button)  );
        if (optionFlags & UiOptionFlag.turnOff) {
            colorType = UiColorType.buttonOff;
        }

        drawBox(area, colorType, hover, active, focus, (optionFlags & UiOptionFlag.turnOff) != 0);
        drawLabelContent(area, text, iconId, optionFlags);
        return result;
    }

    UiControlFlags button(IVec2 position, IVec2 size, IStr text, UiIconId iconId = 0, UiOptionFlags optionFlags = defaultUiOptionFlags) {
        return button(IRect(position, size), text, iconId, optionFlags);
    }

    UiControlFlags button(int x, int y, int w, int h, IStr text, UiIconId iconId = 0, UiOptionFlags optionFlags = defaultUiOptionFlags) {
        return button(IRect(x, y, w, h), text, iconId, optionFlags);
    }
}

@safe nothrow @nogc
IVec2 tempUiTextSizeFunc(UiFont font, IStr text) {
    enum charWidth = 8;
    enum charHeight = 8;

    auto maxHorizontalLength = 0;
    auto maxVerticalLength = 1;
    auto horizontalLengthCounter = 0;
    foreach (c; text) {
        if (c == '\n') {
            if (maxHorizontalLength < horizontalLengthCounter) maxHorizontalLength = horizontalLengthCounter;
            maxVerticalLength += 1;
            horizontalLengthCounter = 0;
        } else {
            horizontalLengthCounter += 1;
        }
    }
    if (maxHorizontalLength < horizontalLengthCounter) maxHorizontalLength = horizontalLengthCounter;
    if (horizontalLengthCounter == 0) maxVerticalLength = 0;

    return IVec2(
        maxHorizontalLength ? (maxHorizontalLength * charWidth - 1) : 0,
        maxVerticalLength ? (maxVerticalLength * charHeight - 1) : 0,
    );
}

// UI test.
unittest {
    auto ui = UiContext(null, null);

    ui.begin();
    ui.button(IRect(0, 0, 60, 20), "My Button");
    ui.end();

    assert(ui.commands.length == 3);
    foreach (ref command; ui.commands) {
        with (UiCommandType) final switch (command.type) {
            case none: break;
            case rect: break;
            case text: break;
            case icon: break;
        }
    }
}
