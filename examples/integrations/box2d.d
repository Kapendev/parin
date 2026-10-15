/// This example shows how to use Parin with Box2D.
/// Repository: https://github.com/erincatto/box2d

import parin;
import parin.bindings.box2d;

b2WorldId world;
b2BodyId ground;
b2BodyId leftWall;
b2BodyId rightWall;
List!b2BodyId boxes;
b2BodyId dragged;

enum scale = 30.0;
enum center = Vec2(320, 180);

Vec2 worldPoint(b2Vec2 p) {
    return Vec2(p.x * scale + center.x, -p.y * scale + center.y);
}

b2Vec2 screenPoint(Vec2 p) {
    return b2Vec2((p.x - center.x) / scale, -(p.y - center.y) / scale);
}

void ready() {
    lockResolution(640, 360);
    setWindowBackgroundColor(gray3);

    auto worldDef = b2DefaultWorldDef();
    worldDef.gravity = b2Vec2(0, -10);
    world = b2CreateWorld(&worldDef);

    // Static ground (bottom edge flush with window)
    auto groundDef = b2DefaultBodyDef();
    groundDef.position = b2Vec2(0, -5.5);
    ground = b2CreateBody(world, &groundDef);
    auto groundShape = b2DefaultShapeDef();
    auto groundBox = b2MakeBox(11, 0.5);
    b2CreatePolygonShape(ground, &groundShape, &groundBox);

    // Left wall (flush with left edge)
    auto leftDef = b2DefaultBodyDef();
    leftDef.position = b2Vec2(-10.5, 2);
    leftWall = b2CreateBody(world, &leftDef);
    auto wallShape = b2DefaultShapeDef();
    auto wallBox = b2MakeBox(0.5, 8);
    b2CreatePolygonShape(leftWall, &wallShape, &wallBox);

    // Right wall (flush with right edge)
    auto rightDef = b2DefaultBodyDef();
    rightDef.position = b2Vec2(10.5, 2);
    rightWall = b2CreateBody(world, &rightDef);
    b2CreatePolygonShape(rightWall, &wallShape, &wallBox);

    // Dynamic boxes
    foreach (i; 0 .. 16) {
        auto bodyDef = b2DefaultBodyDef();
        bodyDef.type = b2_dynamicBody;
        bodyDef.position = b2Vec2((i % 4 - 1.5) * 1.4, 2 + (i / 4) * 1.4);
        auto id = b2CreateBody(world, &bodyDef);
        auto shapeDef = b2DefaultShapeDef();
        shapeDef.density = 1.0f;
        auto box = b2MakeBox(0.6, 0.6);
        b2CreatePolygonShape(id, &shapeDef, &box);
        boxes.append(id);
    }
}

bool update(float dt) {
    if (Key.f11.isPressed) toggleIsFullscreen();

    b2World_Step(world, 1.0 / 60.0, 4);

    auto worldMouse = screenPoint(mouse());

    if (isPressed(Mouse.left)) {
        dragged = b2BodyId.init;
        foreach (id; boxes) {
            auto pos = b2Body_GetPosition(id);
            if (abs(worldMouse.x - pos.x) < 0.6 && abs(worldMouse.y - pos.y) < 0.6) {
                dragged = id;
                break;
            }
        }
    }
    if (isReleased(Mouse.left)) dragged = b2BodyId.init;

    if (dragged != b2BodyId.init) {
        auto current = b2Body_GetPosition(dragged);
        auto vel = b2Body_GetLinearVelocity(dragged);
        auto force = (worldMouse - current) * 200 - vel * 20;
        b2Body_ApplyForceToCenter(dragged, force, true);
    }

    // Draw ground
    auto gpos = worldPoint(b2Body_GetPosition(ground));
    drawRect(Rect(gpos.x - 330, gpos.y - 15, 660, 30), gray);

    // Draw walls
    auto lpos = worldPoint(b2Body_GetPosition(leftWall));
    drawRect(Rect(lpos.x - 15, lpos.y - 240, 30, 480), gray);
    auto rpos = worldPoint(b2Body_GetPosition(rightWall));
    drawRect(Rect(rpos.x - 15, rpos.y - 240, 30, 480), gray);

    // Draw boxes
    foreach (i, id; boxes) {
        auto pos = worldPoint(b2Body_GetPosition(id));
        auto rot = b2Body_GetRotation(id);
        auto angle = -atan2(rot.s, rot.c) * 180 / pi;
        auto size = 36;
        drawRect(
            Rect(pos.x, pos.y, size, size),
            id == dragged ? yellow : (i % 2 ? cyan : pink),
            -1,
            Vec2(size / 2, size / 2),
            angle,
        );
    }

    drawText("Click and drag boxes~", Vec2(32, 16));
    return false;
}

void finish() {
    b2DestroyWorld(world);
}

mixin runGame!(ready, update, finish);
