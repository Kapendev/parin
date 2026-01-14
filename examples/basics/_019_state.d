/// This example shows how to make a basic state (scene) system with the `Union` type.
/// Check `_018_entity.d` for more info about how `Union` works.

import parin;

StateManager manager;

alias State = Union!(StateBase, TitleState, PlayState);
static assert(State.isBaseAliasingSafe);

// A manager to handle state transitions.
struct StateManager {
    alias Base = State.Base;

    // Shared data kept here to avoid redundant copying during state switches.
    Rgba color;
    // Private data used by the manager.
    State _current;
    State _next;

    // Initializes the active state.
    void ready() {
        _current.call!"ready"();
    }

    // Updates the active state and checks if a transition is pending.
    bool update(float dt) {
        auto result = _current.call!"update"(dt);
        if (!_next.isType!Base) {
            finish();
            _current = _next;
            ready();
            _next = Base();
        }
        return result;
    }

    // Cleans up the active state.
    void finish() {
        _current.call!"finish"();
    }

    // Schedules a switch to a new state.
    void changeTo(S)() {
        if (_current.isType!Base) {
            _current = S();
            ready();
        } else {
            _next = S();
        }
    }
}

// The base structure for all states, containing shared data.
struct StateBase {
    void ready() {}
    bool update(float dt) { return false; }
    void finish() {}
}

// The state for the title menu.
struct TitleState {
    // Like `alias base this` from `_018_entity.d`, but using a helper mixin provided by Parin.
    mixin distinct!StateBase;

    void ready() {
        setWindowBackgroundColor(black);
        manager.color = cyan;
    }

    bool update(float dt) {
        auto hasClicked = Keyboard.enter.isPressed;
        auto button = Rect(resolution * 0.5, 0, 0);
        button.size = drawText("Click Or Press ENTER", resolution * 0.5, DrawOptions(manager.color, Hook.center));
        button = button.area(Hook.center).addAll(8).addLeftRight(4);
        if (button.hasPoint(mouse)) {
            drawRect(button, manager.color.alpha(255), 2);
            hasClicked = Mouse.left.isPressed;
        } else {
            drawRect(button, manager.color.alpha(150), 2);
        }

        drawRect(Rect(resolution).subAll(5), manager.color.alpha(70), 1);
        drawText("~ The Game ~", resolution * Vec2(0.5, 0.1), DrawOptions(manager.color, Hook.center));
        drawText(engineFontSmall, "ESC: To exit", resolution - 10, DrawOptions(manager.color, Hook.bottomRight));

        // Request a transition to `PlayState`.
        if (hasClicked) manager.changeTo!PlayState();
        return Keyboard.esc.isPressed;
    }
}

// The state for the gameplay logic.
struct PlayState {
    mixin distinct!StateBase;

    List!Vec2 textPoints;

    void updateTextPoints() {
        foreach (ref point; textPoints) {
            auto sign1 = (randi % 2) ? 1 : -1;
            auto sign2 = (randi % 2) ? 1 : -1;
            point = resolution * 0.5 + Vec2(randi % 100 * sign1, randi % 40 * sign2);
        }
    }

    void ready() {
        manager.color = orange;
        foreach (i; 0 .. 3) textPoints.push(Vec2());
        updateTextPoints();
    }

    bool update(float dt) {
        auto hasClicked = Keyboard.esc.isPressed;
        if (Keyboard.space.isPressed) updateTextPoints();

        foreach (point; textPoints) {
            auto o = DrawOptions(manager.color, Hook.center);
            o.scale = Vec2(sin(elapsedTime * 3) * 0.5 + 1.5);
            drawText("Play", point, o);
        }

        drawRect(Rect(resolution).subAll(5), manager.color.alpha(70), 1);
        drawText("[ Press SPACE to do stuff ]", resolution * Vec2(0.5, 0.1), DrawOptions(manager.color, Hook.center));
        drawText(engineFontSmall, "ESC: To title menu", resolution - 10, DrawOptions(manager.color, Hook.bottomRight));

        // Request a transition to `TitleState`.
        if (hasClicked) manager.changeTo!TitleState();
        return false;
    }

    void finish() {
        textPoints.free();
    }
}

void ready() {
    lockResolution(320, 180);
    manager.changeTo!TitleState();
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    return manager.update(dt);
}

void finish() {
    manager.finish();
}

mixin runGame!(ready, update, finish);
