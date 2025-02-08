// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.37
// ---

// TODO: Update all the doc comments here.

/// The `platformer` module provides a simple physics engine.
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

struct Box {
    IVec2 position;
    IVec2 size;
    Vec2 remainder;
    RideSide rideSide;
    bool isPassable;
    bool isRiding;

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

struct BoxWorld {
    List!Box walls;
    List!Box actors;
    List!ActorId squishedIdsBuffer;

    @safe @nogc nothrow:

    WallId appendWall(Box box) {
        walls.append(box);
        return walls.length - 1;
    }

    ActorId appendActor(Box box, RideSide rideSide = RideSide.none) {
        if (rideSide) box.rideSide = rideSide;
        actors.append(box);
        return actors.length - 1;
    }

    bool hasWallCollision(Box box) {
        foreach (wall; walls) {
            if (!wall.isPassable && wall.hasIntersection(box)) return true;
        }
        return false;
    }

    bool hasActorCollision(Box box) {
        foreach (actor; actors) {
            if (!actor.isPassable && actor.hasIntersection(box)) return true;
        }
        return false;
    }

    bool moveActorX(ActorId id, float amount) {
        auto actor = &actors[id];
        actor.remainder.x += amount;

        auto move = cast(int) actor.remainder.x.round();
        if (move == 0) return false;

        int moveSign = move.sign();
        actor.remainder.x -= move;
        while (move != 0) {
            auto tempBox = Box(actor.position + IVec2(moveSign, 0), actor.size);
            if (hasWallCollision(tempBox)) {
                return true;
            } else {
                actor.position.x += moveSign;
                move -= moveSign;
            }
        }
        return false;
    }

    bool moveActorY(ActorId id, float amount) {
        auto actor = &actors[id];
        actor.remainder.y += amount;

        auto move = cast(int) actor.remainder.y.round();
        if (move == 0) return false;

        int moveSign = move.sign();
        actor.remainder.y -= move;
        while (move != 0) {
            auto tempBox = Box(actor.position + IVec2(0, moveSign), actor.size);
            if (hasWallCollision(tempBox)) {
                return true;
            } else {
                actor.position.y += moveSign;
                move -= moveSign;
            }
        }
        return false;
    }

    IVec2 moveActor(ActorId id, Vec2 amount) {
        auto result = IVec2();
        result.x = moveActorX(id, amount.x);
        result.y = moveActorY(id, amount.y);
        return result;
    }

    ActorId[] moveWallX(WallId id, float amount) {
        return moveWall(id, Vec2(amount, 0.0f));
    }

    ActorId[] moveWallY(WallId id, float amount) {
        return moveWall(id, Vec2(0.0f, amount));
    }

    ActorId[] moveWall(WallId id, Vec2 amount) {
        auto wall = &walls[id];
        wall.remainder += amount;

        squishedIdsBuffer.clear();
        auto move = wall.remainder.round().toIVec();
        if (move.x != 0 || move.y != 0) {
            foreach (i, ref actor; actors) {
                actor.isRiding = false;
                if (!actor.rideSide) continue;
                auto rideBox = actor;
                final switch (actor.rideSide) with (RideSide) {
                    case none: break;
                    case top: rideBox.position.y += 1; break;
                    case left: rideBox.position.x += 1; break;
                    case right: rideBox.position.x -= 1; break;
                    case bottom: rideBox.position.y -= 1; break;
                }
                actor.isRiding = wall.hasIntersection(rideBox);
            }
        }
        if (move.x != 0) {
            wall.isPassable = true;
            wall.remainder.x -= move.x;
            wall.position.x += move.x;
            foreach (i, ref actor; actors) {
                if (wall.hasIntersection(actor)) {
                    // Push actor.
                    auto wallLeft = wall.position.x;
                    auto wallRight = wall.position.x + wall.size.x;
                    auto actorLeft = actor.position.x;
                    auto actorRight = actor.position.x + actor.size.x;
                    auto actorPushAmount = (move.x > 0) ? (wallRight - actorLeft) : (wallLeft - actorRight);
                    if (moveActorX(i, actorPushAmount)) {
                        // Squish actor.
                        squishedIdsBuffer.append(i);
                    }
                } else if (actor.isRiding) {
                    // Carry actor.
                    moveActorX(i, move.x);
                }
            }
            wall.isPassable = false;
        }
        if (move.y != 0) {
            wall.isPassable = true;
            wall.remainder.y -= move.y;
            wall.position.y += move.y;
            foreach (i, ref actor; actors) {
                if (wall.hasIntersection(actor)) {
                    // Push actor.
                    auto wallTop = wall.position.y;
                    auto wallBottom = wall.position.y + wall.size.y;
                    auto actorTop = actor.position.y;
                    auto actorBottom = actor.position.y + actor.size.y;
                    auto actorPushAmount = (move.y > 0) ? (wallBottom - actorTop) : (wallTop - actorBottom);
                    if (moveActorY(i, actorPushAmount)) {
                        // Squish actor.
                        squishedIdsBuffer.append(i);
                    }
                } else if (actor.isRiding) {
                    // Carry actor.
                    moveActorY(i, move.y);
                }
            }
            wall.isPassable = false;
        }
        return squishedIdsBuffer[];
    }

    void reserve(Sz capacity) {
        walls.reserve(capacity);
        actors.reserve(capacity);
        squishedIdsBuffer.reserve(capacity);
    }

    void free() {
        walls.free();
        actors.free();
        squishedIdsBuffer.free();
        this = BoxWorld();
    }
}
