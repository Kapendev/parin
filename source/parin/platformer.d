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

struct Box {
    IVec2 position;
    IVec2 size;
    Vec2 remainder;

    @safe @nogc nothrow:

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

    @safe @nogc nothrow:

    bool hasWallCollision(Box box) {
        foreach (wall; walls) {
            if (wall.hasIntersection(box)) return true;
        }
        return false;
    }

    bool moveActorX(Sz id, float amount) {
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

    bool moveActorY(Sz id, float amount) {
        assert(0, "TODO");
        return false;
    }

    void moveWall(Sz id, Vec2 amount) {
        assert(0, "TODO");
    }
}
