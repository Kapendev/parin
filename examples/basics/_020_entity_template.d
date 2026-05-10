/// This example is a template that can be used as a starting point for a project.
/// It includes the entity system from `_018_entity.d`.

import parin;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    return false;
}

void finish() {}

mixin runGame!(ready, update, finish, 960, 540, "Game Title");

// --- Entities

alias Entities = GenList!Entity;

alias Entity = Union!(
    EntityBase,
    Player,
);

struct EntityBase {
    Rect body;

    void update(float dt) {}
    void draw() {}
}

struct Player {
    mixin distinct!EntityBase;

    void update(float dt) {
        body.position += wasd;
    }

    void draw() {
        drawText("Player", body.position);
    }
}

// --- Helpers

static foreach (T; Entity.Types) {
    Entity xx(T value) => Entity(value);
}

static assert(Entity.isBaseAliasingSafe);
