/// This example is a template that can be used as a starting point for a project.
/// It includes the entity and state systems from `_018_entity.d` and `_019_state.d`.

import parin;

StateManager manager;

void ready() {
    lockResolution(320, 180);
    manager.changeTo!TitleState();
}

bool update(float dt) {
    return manager.update(dt);
}

void finish() {
    manager.finish();
}

mixin runGame!(ready, update, finish, 960, 540, "Game Title");

// --- Entities

alias Entity = Union!(
    EntityBase,
);

struct EntityBase {
    Rect body;

    void update(float dt) {}
    void draw() {}
}

alias Entities = GenList!Entity;

static foreach (T; Entity.Types) {
    Entity xx(T value) => Entity(value);
}

static assert(Entity.isBaseAliasingSafe);

// --- States

alias State = Union!(
    StateBase,
    TitleState,
    PlayState,
);

struct StateBase {
    void ready() {}
    bool update(float dt) { return false; }
    void finish() {}
}

struct TitleState {
    mixin distinct!StateBase;

    bool update(float dt) {
        drawText("~ Game Title ~", resolution * 0.5, DrawOptions(Hook.center));
        return false;
    }
}

struct PlayState {
    mixin distinct!StateBase;

    bool update(float dt) {
        foreach (ref e; manager.entities.items) e.call!"update"(dt);
        foreach (ref e; manager.entities.items) e.call!"draw"();
        return false;
    }
}

struct StateManager {
    alias Base = State.Base;

    // Shared data kept here to avoid redundant copying during state switches.
    Entities entities;
    // Private data used by the manager.
    State _current;
    State _next;

    void ready() {
        _current.call!"ready"();
    }

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

    void finish() {
        _current.call!"finish"();
        entities.free();
    }

    void changeTo(S)() {
        if (_current.isType!Base) {
            _current = S();
            ready();
        } else {
            _next = S();
        }
    }
}

static foreach (T; State.Types) {
    State xx(T value) => State(value);
}

static assert(State.isBaseAliasingSafe);
