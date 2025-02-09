// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.37
// ---

// TODO: Update all the doc comments here.
// TODO: Add spatial partitioning after testing this in a game.
// NOTE: Maybe a world pixel size value could be useful.

/// The `platformer` module provides a pixel-perfect physics engine.
module parin.platformer;

import joka.containers;
import joka.math;
import joka.types;

@safe @nogc nothrow:

alias ActorId = Sz;
alias WallId = Sz;

enum RideSide : ubyte {
    none,
    top,
    left,
    right,
    bottom,
}

struct BoxMover {
    Vec2 direction;
    Vec2 velocity;
    float speed = 1.0f;
    float jump = 0.0f;
    float gravity = 0.0f;
    float gravityFallFactor = 0.7f;
    float acceleration = 0.0f;
    float decelerationFactor = 0.3f;

    @safe @nogc nothrow:

    this(float speed, float jump, float gravity) {
        this.speed = speed;
        this.jump = jump;
        this.gravity = gravity;
    }

    bool isSmooth() {
        return acceleration != 0.0f;
    }

    bool isTopDown() {
        return gravity == 0.0f;
    }

    Vec2 move(float dt, bool isUnnormalized = false) {
        if (isTopDown) {
            auto tempDirection = isUnnormalized ? direction : direction.normalize();
            if (isSmooth) {
                if (direction.x > 0.0f) {
                    velocity.x = min(velocity.x + tempDirection.x * acceleration * dt, tempDirection.x * speed);
                } else if (direction.x < 0.0f) {
                    velocity.x = max(velocity.x + tempDirection.x * acceleration * dt, tempDirection.x * speed);
                }
                if (velocity.x != tempDirection.x * speed) {
                   velocity.x = lerp(velocity.x, 0.0f, decelerationFactor);
                }
                if (direction.y > 0.0f) {
                    velocity.y = min(velocity.y + tempDirection.y * acceleration * dt, tempDirection.y * speed);
                } else if (direction.y < 0.0f) {
                    velocity.y = max(velocity.y + tempDirection.y * acceleration * dt, tempDirection.y * speed);
                }
                if (velocity.y != tempDirection.y * speed) {
                   velocity.y = lerp(velocity.y, 0.0f, decelerationFactor);
                }
            } else {
                velocity.x = tempDirection.x * speed;
                velocity.y = tempDirection.y * speed;
            }
            velocity.x = velocity.x * dt;
            velocity.y = velocity.y * dt;
        } else {
            if (isSmooth) {
                if (direction.x > 0.0f) {
                    velocity.x = min(velocity.x + acceleration * dt, speed);
                } else if (direction.x < 0.0f) {
                    velocity.x = max(velocity.x - acceleration * dt, -speed);
                }
                if (velocity.x != direction.x * speed) {
                   velocity.x = lerp(velocity.x, 0.0f, decelerationFactor);
                }
            } else {
                velocity.x = direction.x * speed;
            }
            velocity.x = velocity.x * dt;

            if (velocity.y > 0.0f) velocity.y += gravity * dt;
            else velocity.y += gravity * gravityFallFactor * dt;
            if (direction.y < 0.0f) velocity.y = -jump;
        }
        return velocity;
    }
}

struct Box {
    IVec2 position;
    IVec2 size;

    @safe @nogc nothrow:

    pragma(inline, true)
    this(IVec2 position, IVec2 size) {
        this.position = position;
        this.size = size;
    }

    pragma(inline, true)
    this(int x, int y, int w, int h) {
        this(IVec2(x, y), IVec2(w, h));
    }

    pragma(inline, true)
    this(IVec2 position, int w, int h) {
        this(position, IVec2(w, h));
    }

    pragma(inline, true)
    this(int x, int y, IVec2 size) {
        this(IVec2(x, y), size);
    }

    bool hasPoint(IVec2 point) {
        return (
            point.x > position.x &&
            point.x < position.x + size.x &&
            point.y > position.y &&
            point.y < position.y + size.y
        );
    }

    bool hasIntersection(Box area) {
        return (
            position.x + size.x > area.position.x &&
            position.x < area.position.x + area.size.x &&
            position.y + size.y > area.position.y &&
            position.y < area.position.y + area.size.y
        );
    }
}

struct WallBoxProperties {
    Vec2 remainder;
    bool isPassable;
}

struct ActorBoxProperties {
    Vec2 remainder;
    RideSide rideSide;
    bool isRiding;
    bool isPassable;
}

struct BoxWorld {
    List!Box walls;
    List!Box actors;
    List!WallBoxProperties wallsProperties;
    List!ActorBoxProperties actorsProperties;
    List!ActorId squishedIdsBuffer;

    @safe @nogc nothrow:

    ref Box getWall(WallId id) {
        return walls[id - 1];
    }

    ref Box getActor(ActorId id) {
        return actors[id - 1];
    }

    ref WallBoxProperties getWallProperties(WallId id) {
        return wallsProperties[id - 1];
    }

    ref ActorBoxProperties getActorProperties(ActorId id) {
        return actorsProperties[id - 1];
    }

    WallId appendWall(Box box) {
        walls.append(box);
        wallsProperties.append(WallBoxProperties());
        return walls.length;
    }

    ActorId appendActor(Box box, RideSide rideSide = RideSide.none) {
        actors.append(box);
        actorsProperties.append(ActorBoxProperties());
        actorsProperties[$ - 1].rideSide = rideSide;
        return actors.length;
    }

    WallId hasWallCollision(Box box) {
        foreach (i, wall; walls) {
            if (wall.hasIntersection(box) && !wallsProperties[i].isPassable) return i + 1;
        }
        return 0;
    }

    ActorId hasActorCollision(Box box) {
        foreach (i, actor; actors) {
            if (actor.hasIntersection(box) && !actorsProperties[i].isPassable) return i + 1;
        }
        return 0;
    }

    WallId moveActorX(ActorId id, float amount) {
        auto actor = &actors[id - 1];
        auto properties = &actorsProperties[id - 1];
        properties.remainder.x += amount;

        auto move = cast(int) properties.remainder.x.round();
        if (move == 0) return false;

        int moveSign = move.sign();
        properties.remainder.x -= move;
        while (move != 0) {
            auto tempBox = Box(actor.position + IVec2(moveSign, 0), actor.size);
            auto wallId = hasWallCollision(tempBox);
            if (!properties.isPassable && wallId) {
                return wallId;
            } else {
                actor.position.x += moveSign;
                move -= moveSign;
            }
        }
        return 0;
    }

    WallId moveActorY(ActorId id, float amount) {
        auto actor = &actors[id - 1];
        auto properties = &actorsProperties[id - 1];
        properties.remainder.y += amount;

        auto move = cast(int) properties.remainder.y.round();
        if (move == 0) return false;

        int moveSign = move.sign();
        properties.remainder.y -= move;
        while (move != 0) {
            auto tempBox = Box(actor.position + IVec2(0, moveSign), actor.size);
            auto wallId = hasWallCollision(tempBox);
            if (!properties.isPassable && wallId) {
                return wallId;
            } else {
                actor.position.y += moveSign;
                move -= moveSign;
            }
        }
        return 0;
    }

    IVec2 moveActor(ActorId id, Vec2 amount) {
        auto result = IVec2();
        result.x = cast(int) moveActorX(id, amount.x);
        result.y = cast(int) moveActorY(id, amount.y);
        return result;
    }

    ActorId[] moveWallX(WallId id, float amount) {
        return moveWall(id, Vec2(amount, 0.0f));
    }

    ActorId[] moveWallY(WallId id, float amount) {
        return moveWall(id, Vec2(0.0f, amount));
    }

    ActorId[] moveWall(WallId id, Vec2 amount) {
        auto wall = &walls[id - 1];
        auto properties = &wallsProperties[id - 1];
        properties.remainder += amount;

        squishedIdsBuffer.clear();
        auto move = properties.remainder.round().toIVec();
        if (move.x != 0 || move.y != 0) {
            foreach (i, ref actorProperties; actorsProperties) {
                actorProperties.isRiding = false;
                if (!actorProperties.rideSide || actorProperties.isPassable) continue;
                auto rideBox = actors[i];
                final switch (actorProperties.rideSide) with (RideSide) {
                    case none: break;
                    case top: rideBox.position.y += 1; break;
                    case left: rideBox.position.x += 1; break;
                    case right: rideBox.position.x -= 1; break;
                    case bottom: rideBox.position.y -= 1; break;
                }
                actorProperties.isRiding = wall.hasIntersection(rideBox);
            }
        }
        if (move.x != 0) {
            wall.position.x += move.x;
            properties.remainder.x -= move.x;
            if (!properties.isPassable) {
                properties.isPassable = true;
                foreach (i, ref actor; actors) {
                    if (actorsProperties[i].isPassable) continue;
                    if (wall.hasIntersection(actor)) {
                        // Push actor.
                        auto wallLeft = wall.position.x;
                        auto wallRight = wall.position.x + wall.size.x;
                        auto actorLeft = actor.position.x;
                        auto actorRight = actor.position.x + actor.size.x;
                        auto actorPushAmount = (move.x > 0) ? (wallRight - actorLeft) : (wallLeft - actorRight);
                        if (moveActorX(i + 1, actorPushAmount)) {
                            // Squish actor.
                            squishedIdsBuffer.append(i + 1);
                        }
                    } else if (actorsProperties[i].isRiding) {
                        // Carry actor.
                        moveActorX(i + 1, move.x);
                    }
                }
                properties.isPassable = false;
            }
        }
        if (move.y != 0) {
            wall.position.y += move.y;
            properties.remainder.y -= move.y;
            if (!properties.isPassable) {
                properties.isPassable = true;
                foreach (i, ref actor; actors) {
                    if (actorsProperties[i].isPassable) continue;
                    if (wall.hasIntersection(actor)) {
                        // Push actor.
                        auto wallTop = wall.position.y;
                        auto wallBottom = wall.position.y + wall.size.y;
                        auto actorTop = actor.position.y;
                        auto actorBottom = actor.position.y + actor.size.y;
                        auto actorPushAmount = (move.y > 0) ? (wallBottom - actorTop) : (wallTop - actorBottom);
                        if (moveActorY(i + 1, actorPushAmount)) {
                            // Squish actor.
                            squishedIdsBuffer.append(i + 1);
                        }
                    } else if (actorsProperties[i].isRiding) {
                        // Carry actor.
                        moveActorY(i + 1, move.y);
                    }
                }
                properties.isPassable = false;
            }
        }
        return squishedIdsBuffer[];
    }

    void clearWalls() {
        walls.clear();
        wallsProperties.clear();
    }

    void clearActors() {
        actors.clear();
        actorsProperties.clear();
    }

    void clear() {
        clearWalls();
        clearActors();
        squishedIdsBuffer.clear();
    }

    void reserve(Sz capacity) {
        walls.reserve(capacity);
        actors.reserve(capacity);
        wallsProperties.reserve(capacity);
        actorsProperties.reserve(capacity);
        squishedIdsBuffer.reserve(capacity);
    }

    void free() {
        walls.free();
        actors.free();
        wallsProperties.free();
        actorsProperties.free();
        squishedIdsBuffer.free();
        this = BoxWorld();
    }
}
