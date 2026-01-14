/// This example shows how to make a basic entity system with the `Union` type.
/// It demonstrates composition-based inheritance.

import parin;

Entities entities;

// The `Union` type allows a single variable to hold one of several different types.
alias Entity = Union!(EntityBase, Actor, Player);
// A generational list to store and manage the entities.
alias Entities = GenList!Entity;

// Ensure at compile time that all types in the union have `EntityBase` as their first field.
// This guarantees that using `.base` is always safe, regardless of the active type.
static assert(Entity.isBaseAliasingSafe);

// The base structure for all entities, containing shared data.
struct EntityBase {
    Rect body = Rect(24, 32);

    void update(float dt) {}
    void draw() {}
}

// An `Actor` is one type of entity. It does nothing special.
// It uses `alias base this` to inherit the fields and methods of `EntityBase`.
struct Actor {
    EntityBase base;
    alias base this;

    this(float x, float y) {
        body.position = Vec2(x, y);
    }

    // Custom draw logic for `Actor`.
    void draw() {
        drawRect(body, orange);
        drawText("Actor", body.position - Vec2(16));
    }
}

// A `Player` is another type of entity. It can walk and run around.
struct Player {
    EntityBase base;
    bool isRunning;
    alias base this;

    this(float x, float y) {
        body.position = Vec2(x, y);
    }

    // Custom update logic for `Player` to handle movement.
    void update(float dt) {
        isRunning = Keyboard.shift.isDown;
        body.position += wasd * (isRunning ? 2 : 1);
    }

    void draw() {
        drawRect(body, cyan);
        drawText("Player\nisRunning: {}".fmt(isRunning), body.position - Vec2(16, 32));
    }
}

// A helper. It generates a conversion function for each type in the union
// so they can be easily added into the entities list.
static foreach (T; Entity.Types) {
    Entity xx(T value) => Entity(value);
}

void ready() {
    lockResolution(320, 180);

    // Instantiate entities and add them to the list.
    entities.push(Actor(40, 60).xx);
    entities.push(Actor(80, 120).xx);
    entities.push(Player(320 / 2, 180 / 2 - 16).xx);

    // Access the base shared by all types in the union.
    // This allows bulk modification of shared data, like position, without checking the specific type.
    foreach (ref e; entities.items) e.base.body.x += 35;
}

bool update(float dt) {
    // e.call!"methodName"() calls the correct method for the underlying type.

    // Update all entities in the list.
    foreach (ref e; entities.items) e.call!"update"(dt);
    // Draw all entities in the list.
    foreach (ref e; entities.items) e.call!"draw"();

    return false;
}

mixin runGame!(ready, update, null);
