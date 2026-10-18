/// This example shows how to use Parin with Box2D.
/// Box2D uses meters with Y pointing up, so positions are converted before drawing.
/// Repository: https://github.com/erincatto/box2d

import parin;
import parin.bindings.box2d;

auto world = b2WorldId();
auto dragged = b2BodyId();
auto boxes = List!Box();

enum scale = 30.0; // Pixels per meter.

struct Box {
    b2BodyId id;
    b2ShapeId shape;
    Vec2 halfSize;
}

Vec2 toScreen(b2Vec2 point) {
    return Vec2(point.x * scale, -point.y * scale) + resolution * Vec2(0.5);
}

b2Vec2 toWorld(Vec2 point) {
    auto result = point - resolution * Vec2(0.5);
    return b2Vec2(result.x / scale, -result.y / scale);
}

void addBox(b2BodyType type, b2Vec2 position, Vec2 halfSize) {
    auto bodyDef = b2DefaultBodyDef();
    bodyDef.type = type;
    bodyDef.position = position;
    auto id = b2CreateBody(world, &bodyDef);
    auto shapeDef = b2DefaultShapeDef();
    auto polygon = b2MakeBox(halfSize.x, halfSize.y);
    boxes.append(Box(id, b2CreatePolygonShape(id, &shapeDef, &polygon), halfSize));
}

void ready() {
    lockResolution(640, 360);
    // Create the world.
    auto worldDef = b2DefaultWorldDef();
    worldDef.gravity = b2Vec2(0, -10);
    world = b2CreateWorld(&worldDef);
    // Add the ground and the walls. They line up with the window edges.
    addBox(b2_staticBody, b2Vec2(0, -5.5), Vec2(11, 0.5));
    addBox(b2_staticBody, b2Vec2(-10.5, 2), Vec2(0.5, 8));
    addBox(b2_staticBody, b2Vec2(10.5, 2), Vec2(0.5, 8));
    // Add a stack of dynamic boxes.
    foreach (i; 0 .. 16) {
        addBox(b2_dynamicBody, b2Vec2((i % 4 - 1.5) * 1.4, 2 + (i / 4) * 1.4), Vec2(0.6));
    }
}

bool update(float dt) {
    if (Keyboard.f11.isPressed) toggleIsFullscreen();
    // Pick up or drop a box.
    auto worldMouse = toWorld(mouse);
    if (Mouse.left.isPressed) {
        foreach (box; boxes) {
            if (b2Body_GetType(box.id) == b2_dynamicBody && b2Shape_TestPoint(box.shape, worldMouse)) {
                dragged = box.id;
                break;
            }
        }
    }
    if (Mouse.left.isReleased) dragged = b2BodyId.init;
    // Pull the dragged box toward the mouse with a damped spring.
    if (dragged != b2BodyId.init) {
        auto offset = worldMouse - b2Body_GetPosition(dragged);
        auto velocity = b2Body_GetLinearVelocity(dragged);
        b2Body_ApplyForceToCenter(dragged, offset * 200 - velocity * 20, true);
    }
    // Update the world.
    b2World_Step(world, dt, 4);
    // Draw the boxes.
    foreach (i, box; boxes) {
        auto size = box.halfSize * Vec2(scale * 2);
        auto rotation = b2Body_GetRotation(box.id);
        auto color = Rgba(60);
        if (b2Body_GetType(box.id) == b2_dynamicBody) color = box.id == dragged ? yellow : (i % 2 ? cyan : pink);
        drawRect(
            Rect(toScreen(b2Body_GetPosition(box.id)), size),
            color,
            -1,
            size * Vec2(0.5),
            -atan2(rotation.s, rotation.c).toDegrees,
        );
    }
    drawText("Click and drag boxes!", Vec2(30, 8));
    return false;
}

void finish() {
    b2DestroyWorld(world);
}

mixin runGame!(ready, update, finish);
