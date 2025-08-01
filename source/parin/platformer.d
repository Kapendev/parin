// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

// TODO: Needs cleaning!!! I changed how the world data is stored. Turned 2 arrays into 1. The API is the same.
// TODO: Update all the doc comments here.
// TODO: Could have a simpler layer system that is just a number check like `layer1 == later2`.
// TODO: Should maybe create an actor and resolve the collisions at that position. Right now it only resolves when moving.
// TODO: Work on BoxMover acceleration. It's not good right now, but works.
// TODO: Add one-way collision support for moving walls.
// NOTE: The code works, but it's  super experimental and will change in the future!

/// The `platformer` module provides a pixel-perfect physics engine.
module parin.platformer;

import joka.ascii;
import joka.containers;
import joka.math;
import joka.types;
import parin.engine;

@safe nothrow:

deprecated("Every name starts with `Box` now.") {
    alias BaseBoxId        = BoxId;
    alias BaseBoxFlags     = BoxFlags;
    alias WallBoxId        = BoxId;
    alias WallBoxFlags     = BoxFlags;
    alias ActorBoxId       = BoxId;
    alias ActorBoxFlags    = BoxFlags;
    alias RideSide         = OneWaySide;
    alias OneWaySide       = BoxSide;

    enum boxPassableFlag   = 0x1;
    enum boxRidingFlag     = 0x2;
    enum wallBoxTag        = 0;
    enum actorBoxTag       = 1;
    enum boxTagBit         = 1 << 31;

    alias WallBoxProperties = BoxProperties;
    alias ActorBoxProperties = BoxProperties;
}

alias BoxFlags           = uint;
alias BoxWallFlags       = BoxFlags;
alias BoxActorFlags      = BoxFlags;
alias BoxId              = uint;
alias BoxWallId          = BoxId;
alias BoxActorId         = BoxId;
alias BoxUnionId         = BoxId;
alias BoxUnionIdGroup    = FixedList!(BoxUnionId, 254);
alias BoxWallProperties  = BoxProperties;
alias BoxActorProperties = BoxProperties;

enum boxNoneId       = 0;
enum boxUnionTypeBit = 1 << 31;
enum boxErrorMessage = "Box is invalid or was never assigned.";

enum BoxUnionType : ubyte {
    wall  = 0x0,
    actor = 0x1,
}

enum BoxFlag : BoxFlags {
    none       = 0x0,
    isPassable = 0x1,
    isRiding   = 0x2,
}

enum BoxSide : ubyte {
    none,
    top,
    left,
    right,
    bottom,
}

struct BoxProperties {
    Vec2 remainder;
    BoxFlags flags;
    BoxSide side;
}

struct BoxData {
    IRect area;
    BoxProperties properties;
}

struct BoxMover {
    Vec2 direction;
    Vec2 velocity;
    float speed = 1.0f;
    float acceleration = 0.0f;
    float gravity = 0.0f;
    float jump = 0.0f;
    float gravityFallFactor = 0.7f;
    float decelerationFactor = 0.3f;

    @safe nothrow @nogc:

    this(float speed, float acceleration, float gravity = 0.0f, float jump = 0.0f) {
        this.speed = speed;
        this.acceleration = acceleration;
        this.gravity = gravity;
        this.jump = jump;
    }

    bool isSmooth() {
        return acceleration != 0.0f;
    }

    bool isTopDown() {
        return gravity == 0.0f;
    }

    Vec2 move() {
        if (isTopDown) {
            if (isSmooth) {
                if (direction.x > 0.0f) {
                    velocity.x = min(velocity.x + direction.x * acceleration, direction.x * speed);
                } else if (direction.x < 0.0f) {
                    velocity.x = max(velocity.x + direction.x * acceleration, direction.x * speed);
                }
                if (velocity.x != direction.x * speed) {
                   velocity.x = lerp(velocity.x, 0.0f, decelerationFactor);
                }
                if (direction.y > 0.0f) {
                    velocity.y = min(velocity.y + direction.y * acceleration, direction.y * speed);
                } else if (direction.y < 0.0f) {
                    velocity.y = max(velocity.y + direction.y * acceleration, direction.y * speed);
                }
                if (velocity.y != direction.y * speed) {
                   velocity.y = lerp(velocity.y, 0.0f, decelerationFactor);
                }
            } else {
                velocity.x = direction.x * speed;
                velocity.y = direction.y * speed;
            }
            velocity.x = velocity.x;
            velocity.y = velocity.y;
        } else {
            if (isSmooth) {
                if (direction.x > 0.0f) {
                    velocity.x = min(velocity.x + acceleration, speed);
                } else if (direction.x < 0.0f) {
                    velocity.x = max(velocity.x - acceleration, -speed);
                }
                if (velocity.x != direction.x * speed) {
                   velocity.x = lerp(velocity.x, 0.0f, decelerationFactor);
                }
            } else {
                velocity.x = direction.x * speed;
            }
            velocity.x = velocity.x;
            if (velocity.y > 0.0f) velocity.y += gravity;
            else velocity.y += gravity * gravityFallFactor;
            if (direction.y < 0.0f) velocity.y = -jump;
        }
        return velocity;
    }

    Vec2 move(Vec2 newDirection) {
        direction = newDirection;
        return move();
    }
}

struct BoxWorld {
    List!BoxData walls;
    List!BoxData actors;
    List!BoxActorId wallIdsBuffer;
    List!BoxActorId actorIdsBuffer;
    List!BoxActorId squishedIdsBuffer;
    Grid!BoxUnionIdGroup grid;
    int gridTileWidth;
    int gridTileHeight;

    @safe nothrow:

    BoxWallId appendWall(IRect box, BoxSide side = BoxSide.none) {
        auto data = BoxData(box, BoxProperties());
        data.properties.side = side;
        walls.append(data);
        auto id = cast(BoxId) walls.length;
        if (grid.length != 0) {
            auto point = getGridPoint(box);
            if (isGridPointValid(point)) grid[point.y, point.x].append(id & ~boxUnionTypeBit);
        }
        return id;
    }

    BoxActorId appendActor(IRect box, BoxSide side = BoxSide.none) {
        auto data = BoxData(box, BoxProperties());
        data.properties.side = side;
        actors.append(data);
        auto id = cast(BoxId) actors.length;
        if (grid.length != 0) {
            auto point = getGridPoint(box);
            if (isGridPointValid(point)) grid[point.y, point.x].append(id | boxUnionTypeBit);
        }
        return id;
    }

    @nogc
    void clearWalls() {
        if (grid.length != 0) return;
        walls.clear();
    }

    @nogc
    void clearActors() {
        if (grid.length != 0) return;
        actors.clear();
    }

    Fault parseWalls(IStr csv, int tileWidth, int tileHeight) {
        clearWalls();
        if (csv.length == 0) return Fault.invalid;
        auto rowCount = 0;
        auto colCount = 0;
        while (csv.length != 0) {
            rowCount += 1;
            colCount = 0;
            auto line = csv.skipLine();
            while (line.length != 0) {
                colCount += 1;
                auto tile = line.skipValue(',').toSigned();
                if (tile.isNone) {
                    walls.clear();
                    return Fault.invalid;
                }
                if (tile.value <= -1) continue;
                appendWall(IRect((colCount - 1) * tileWidth, (rowCount - 1) * tileHeight, tileWidth, tileHeight));
            }
        }
        return Fault.none;
    }

    void enableGrid(Sz rowCount, Sz colCount, int tileWidth, int tileHeight) {
        gridTileWidth = tileWidth;
        gridTileHeight = tileHeight;
        grid.resizeBlank(rowCount, colCount);
        foreach (ref group; grid) group.clear();
        foreach (i, wall; walls) {
            auto id = cast(BoxId) (i + 1);
            auto point = getGridPoint(wall.area);
            if (isGridPointValid(point)) grid[point.y, point.x].append(id & ~boxUnionTypeBit);
        }
        foreach (i, actor; actors) {
            auto id = cast(BoxId) (i + 1);
            auto point = getGridPoint(actor.area);
            if (isGridPointValid(point)) grid[point.y, point.x].append(id | boxUnionTypeBit);
        }
    }

    @nogc
    void disableGrid() {
        gridTileWidth = 0;
        gridTileHeight = 0;
        grid.clear();
    }

    @nogc
    bool isGridPointValid(IVec2 point) {
        return point.x >= 0 && point.y >= 0 && grid.has(point.y, point.x);
    }

    @nogc
    IVec2 getGridPoint(IRect box) {
        if (!grid.length) assert(0, "Can't get a grid point from a disabled grid.");
        return IVec2(
            box.position.x / gridTileWidth - (box.position.x < 0),
            box.position.y / gridTileHeight - (box.position.y < 0),
        );
    }

    @nogc
    ref IRect getWall(BoxWallId id) {
        if (id == boxNoneId) assert(0, boxErrorMessage);
        return walls[id - 1].area;
    }

    @nogc
    ref BoxWallProperties getWallProperties(BoxWallId id) {
        if (id == boxNoneId) assert(0, boxErrorMessage);
        return walls[id - 1].properties;
    }

    @nogc
    ref IRect getActor(BoxActorId id) {
        if (id == boxNoneId) assert(0, boxErrorMessage);
        return actors[id - 1].area;
    }

    @nogc
    ref BoxActorProperties getActorProperties(BoxActorId id) {
        if (id == boxNoneId) assert(0, boxErrorMessage);
        return actors[id - 1].properties;
    }

    BoxWallId[] getWallCollisions(IRect box, bool canStopAtFirst = false) {
        wallIdsBuffer.clear();
        if (grid.length) {
            auto point = getGridPoint(box);
            foreach (y; -1 .. 2) { foreach (x; -1 .. 2) {
                auto otherPoint = IVec2(point.x + x, point.y + y);
                if (!isGridPointValid(otherPoint)) continue;
                foreach (taggedId; grid[otherPoint.y, otherPoint.x]) {
                    auto i = (taggedId & ~boxUnionTypeBit) - 1;
                    auto isActor = taggedId & boxUnionTypeBit;
                    if (isActor) continue;
                    if (walls[i].area.hasIntersection(box) && ~walls[i].properties.flags & BoxFlag.isPassable) {
                        wallIdsBuffer.append(cast(BoxId) (i + 1));
                        if (canStopAtFirst) return wallIdsBuffer[];
                    }
                }
            }}
        } else {
            foreach (i, wall; walls) {
                if (wall.area.hasIntersection(box) && ~wall.properties.flags & BoxFlag.isPassable) {
                    wallIdsBuffer.append(cast(BoxId) (i + 1));
                    if (canStopAtFirst) return wallIdsBuffer[];
                }
            }
        }
        return wallIdsBuffer[];
    }

    BoxWallId hasWallCollision(IRect box) {
        auto boxes = getWallCollisions(box, true);
        return boxes.length ? boxes[0] : 0;
    }

    BoxWallId hasWallCollision(BoxWallId id) {
        return hasWallCollision(getWall(id));
    }

    @nogc
    BoxWallId hasWallCollision(BoxWallId id1, BoxWallId id2) {
        return getWall(id1).hasIntersection(getWall(id2)) ? id2 : 0;
    }

    BoxActorId[] getActorCollisions(IRect box, bool canStopAtFirst = false) {
        actorIdsBuffer.clear();
        if (grid.length) {
            auto point = getGridPoint(box);
            foreach (y; -1 .. 2) { foreach (x; -1 .. 2) {
                auto otherPoint = IVec2(point.x + x, point.y + y);
                if (!isGridPointValid(otherPoint)) continue;
                foreach (taggedId; grid[otherPoint.y, otherPoint.x]) {
                    auto i = (taggedId & ~boxUnionTypeBit) - 1;
                    auto isWall = !(taggedId & boxUnionTypeBit);
                    if (isWall) continue;
                    if (actors[i].area.hasIntersection(box) && ~actors[i].properties.flags & BoxFlag.isPassable) {
                        actorIdsBuffer.append(cast(BoxId) (i + 1));
                        if (canStopAtFirst) return actorIdsBuffer[];
                    }
                }
            }}
        } else {
            foreach (i, actor; actors) {
                if (actor.area.hasIntersection(box) && ~actor.properties.flags & BoxFlag.isPassable) {
                    actorIdsBuffer.append(cast(BoxId) (i + 1));
                    if (canStopAtFirst) return actorIdsBuffer[];
                }
            }
        }
        return actorIdsBuffer[];
    }

    BoxActorId hasActorCollision(IRect box) {
        auto boxes = getActorCollisions(box, true);
        return boxes.length ? boxes[0] : 0;
    }

    BoxActorId hasActorCollision(BoxActorId id) {
        return hasActorCollision(getActor(id));
    }

    @nogc
    BoxActorId hasActorCollision(BoxActorId id1, BoxActorId id2) {
        return getActor(id1).hasIntersection(getActor(id2)) ? id2 : 0;
    }

    BoxWallId moveActorX(BoxActorId id, float amount) {
        auto actor = &getActor(id);
        auto properties = &getActorProperties(id);
        properties.remainder.x += amount;
        auto move = cast(int) properties.remainder.x.round();
        if (move == 0) return false;

        int moveSign = move.sign();
        properties.remainder.x -= move;
        while (move != 0) {
            auto tempBox = IRect(actor.position + IVec2(moveSign, 0), actor.size);
            auto wallId = hasWallCollision(tempBox);
            if (wallId) {
                // One way stuff.
                auto wall = &getWall(wallId);
                auto wallProperties = &getWallProperties(wallId);
                final switch (wallProperties.side) with (BoxSide) {
                    case none:
                        break;
                    case top:
                    case bottom:
                        wallId = boxNoneId;
                        break;
                    case left:
                        if (wall.position.x < actor.position.x || wall.hasIntersection(*actor)) wallId = boxNoneId;
                        break;
                    case right:
                        if (wall.position.x > actor.position.x || wall.hasIntersection(*actor)) wallId = boxNoneId;
                        break;
                }
            }
            if (~properties.flags & BoxFlag.isPassable && wallId) {
                return wallId;
            } else {
                // Move.
                if (grid.length) {
                    auto oldPoint = getGridPoint(*actor);
                    actor.position.x += moveSign;
                    move -= moveSign;
                    auto newPoint = getGridPoint(*actor);
                    if (oldPoint != newPoint) {
                        if (isGridPointValid(oldPoint)) {
                            foreach (j, taggedId; grid[oldPoint.y, oldPoint.x]) {
                                auto i = (taggedId & ~boxUnionTypeBit) - 1;
                                auto isActor = taggedId & boxUnionTypeBit;
                                if (isActor && (i + 1 == id)) {
                                    grid[oldPoint.y, oldPoint.x].remove(j);
                                    break;
                                }
                            }
                        }
                        if (isGridPointValid(newPoint)) {
                            grid[newPoint.y, newPoint.x].append(id | boxUnionTypeBit);
                        }
                    }
                } else {
                    actor.position.x += moveSign;
                    move -= moveSign;
                }
            }
        }
        return 0;
    }

    BoxWallId moveActorXTo(BoxActorId id, float to, float amount) {
        auto actor = &getActor(id);
        auto target = moveTo(cast(float) actor.position.x, to.floor(), amount);
        return moveActorX(id, target - actor.position.x);
    }

    BoxWallId moveActorXToWithSlowdown(BoxActorId id, float to, float amount, float slowdown) {
        auto actor = &getActor(id);
        auto target = moveToWithSlowdown(cast(float) actor.position.x, to.floor(), amount, slowdown);
        return moveActorX(id, target - actor.position.x);
    }

    BoxWallId moveActorY(BoxActorId id, float amount) {
        auto actor = &getActor(id);
        auto properties = &getActorProperties(id);
        properties.remainder.y += amount;
        auto move = cast(int) properties.remainder.y.round();
        if (move == 0) return false;

        int moveSign = move.sign();
        properties.remainder.y -= move;
        while (move != 0) {
            auto tempBox = IRect(actor.position + IVec2(0, moveSign), actor.size);
            auto wallId = hasWallCollision(tempBox);
            if (wallId) {
                // One way stuff.
                auto wall = &getWall(wallId);
                auto wallProperties = &getWallProperties(wallId);
                final switch (wallProperties.side) with (BoxSide) {
                    case none:
                        break;
                    case left:
                    case right:
                        wallId = boxNoneId;
                        break;
                    case top:
                        if (wall.position.y < actor.position.y || wall.hasIntersection(*actor)) wallId = boxNoneId;
                        break;
                    case bottom:
                        if (wall.position.y > actor.position.y || wall.hasIntersection(*actor)) wallId = boxNoneId;
                        break;
                }
            }
            if (~properties.flags & BoxFlag.isPassable && wallId) {
                return wallId;
            } else {
                // Move.
                if (grid.length) {
                    auto oldPoint = getGridPoint(*actor);
                    actor.position.y += moveSign;
                    move -= moveSign;
                    auto newPoint = getGridPoint(*actor);
                    if (oldPoint != newPoint) {
                        if (isGridPointValid(oldPoint)) {
                            foreach (j, taggedId; grid[oldPoint.y, oldPoint.x]) {
                                auto i = (taggedId & ~boxUnionTypeBit) - 1;
                                auto isActor = taggedId & boxUnionTypeBit;
                                if (isActor && (i + 1 == id)) {
                                    grid[oldPoint.y, oldPoint.x].remove(j);
                                    break;
                                }
                            }
                        }
                        if (isGridPointValid(newPoint)) {
                            grid[newPoint.y, newPoint.x].append(id | boxUnionTypeBit);
                        }
                    }
                } else {
                    actor.position.y += moveSign;
                    move -= moveSign;
                }
            }
        }
        return 0;
    }

    BoxWallId moveActorYTo(BoxActorId id, float to, float amount) {
        auto actor = &getActor(id);
        auto target = moveTo(cast(float) actor.position.y, to.floor(), amount);
        return moveActorY(id, target - actor.position.y);
    }

    BoxWallId moveActorYToWithSlowdown(BoxActorId id, float to, float amount, float slowdown) {
        auto actor = &getActor(id);
        auto target = moveToWithSlowdown(cast(float) actor.position.y, to.floor(), amount, slowdown);
        return moveActorY(id, target - actor.position.y);
    }

    IVec2 moveActor(BoxActorId id, Vec2 amount) {
        auto result = IVec2();
        result.x = cast(int) moveActorX(id, amount.x);
        result.y = cast(int) moveActorY(id, amount.y);
        return result;
    }

    IVec2 moveActorTo(BoxActorId id, Vec2 to, Vec2 amount) {
        auto actor = &getActor(id);
        auto target = moveTo(actor.position.toVec(), to.floor(), amount);
        return moveActor(id, target - actor.position.toVec());
    }

    IVec2 moveActorToWithSlowdown(BoxActorId id, Vec2 to, Vec2 amount, float slowdown) {
        auto actor = &getActor(id);
        auto target = moveToWithSlowdown(actor.position.toVec(), to.floor(), amount, slowdown);
        return moveActor(id, target - actor.position.toVec());
    }

    BoxActorId[] moveWallX(BoxWallId id, float amount) {
        return moveWall(id, Vec2(amount, 0.0f));
    }

    BoxActorId[] moveWallXTo(BoxWallId id, float to, float amount) {
        auto wall = &getWall(id);
        auto target = moveTo(cast(float) wall.position.x, to.floor(), amount);
        return moveWallX(id, target - wall.position.x);
    }

    BoxActorId[] moveWallXToWithSlowdown(BoxWallId id, float to, float amount, float slowdown) {
        auto wall = &getWall(id);
        auto target = moveToWithSlowdown(cast(float) wall.position.x, to.floor(), amount, slowdown);
        return moveWallX(id, target - wall.position.x);
    }

    BoxActorId[] moveWallY(BoxWallId id, float amount) {
        return moveWall(id, Vec2(0.0f, amount));
    }

    BoxActorId[] moveWallYTo(BoxWallId id, float to, float amount) {
        auto wall = &getWall(id);
        auto target = moveTo(cast(float) wall.position.y, to.floor(), amount);
        return moveWallY(id, target - wall.position.y);
    }

    BoxActorId[] moveWallYToWithSlowdown(BoxWallId id, float to, float amount, float slowdown) {
        auto wall = &getWall(id);
        auto target = moveToWithSlowdown(cast(float) wall.position.y, to.floor(), amount, slowdown);
        return moveWallY(id, target - wall.position.y);
    }

    BoxActorId[] moveWall(BoxWallId id, Vec2 amount) {
        auto wall = &getWall(id);
        auto properties = &getWallProperties(id);
        if (properties.side) assert(0, "One-way collisions are not yet supported for moving walls.");
        properties.remainder += amount;

        squishedIdsBuffer.clear();
        auto move = properties.remainder.round().toIVec();
        if (move.x != 0 || move.y != 0) {
            foreach (i, ref actorData; actors) {
                auto actorProperties = &actorData.properties;
                actorProperties.flags &= ~BoxFlag.isRiding;
                if (!actorProperties.side || actorProperties.flags & BoxFlag.isPassable) continue;
                auto rideBox = actorData.area;
                final switch (actorProperties.side) with (BoxSide) {
                    case none: break;
                    case top: rideBox.position.y += 1; break;
                    case left: rideBox.position.x += 1; break;
                    case right: rideBox.position.x -= 1; break;
                    case bottom: rideBox.position.y -= 1; break;
                }
                actorProperties.flags |= wall.hasIntersection(rideBox) ? BoxFlag.isRiding : 0x0;
            }
        }

        if (move.x != 0) {
            properties.remainder.x -= move.x;
            // Move.
            if (grid.length) {
                auto oldPoint = getGridPoint(*wall);
                wall.position.x += move.x;
                auto newPoint = getGridPoint(*wall);
                if (oldPoint != newPoint) {
                    if (isGridPointValid(oldPoint)) {
                        foreach (j, taggedId; grid[oldPoint.y, oldPoint.x]) {
                            auto i = (taggedId & ~boxUnionTypeBit) - 1;
                            auto isWall = !(taggedId & boxUnionTypeBit);
                            if (isWall && (i + 1 == id)) {
                                grid[oldPoint.y, oldPoint.x].remove(j);
                                break;
                            }
                        }
                    }
                    if (isGridPointValid(newPoint)) {
                        grid[newPoint.y, newPoint.x].append(id & ~boxUnionTypeBit);
                    }
                }
            } else {
                wall.position.x += move.x;
            }
            if (~properties.flags & BoxFlag.isPassable) {
                properties.flags |= BoxFlag.isPassable;
                foreach (i, ref actor; actors) {
                    if (actor.properties.flags & BoxFlag.isPassable) continue;
                    if (wall.hasIntersection(actor.area)) {
                        // Push actor.
                        auto wallLeft = wall.position.x;
                        auto wallRight = wall.position.x + wall.size.x;
                        auto actorLeft = actor.area.position.x;
                        auto actorRight = actor.area.position.x + actor.area.size.x;
                        auto actorPushAmount = (move.x > 0) ? (wallRight - actorLeft) : (wallLeft - actorRight);
                        if (moveActorX(cast(BoxId) (i + 1), actorPushAmount)) {
                            // Squish actor.
                            squishedIdsBuffer.append(cast(BoxId) (i + 1));
                        }
                    } else if (actor.properties.flags & BoxFlag.isRiding) {
                        // Carry actor.
                        moveActorX(cast(BoxId) (i + 1), move.x);
                    }
                }
                properties.flags &= ~BoxFlag.isPassable;
            }
        }
        if (move.y != 0) {
            properties.remainder.y -= move.y;
            // Move.
            if (grid.length) {
                auto oldPoint = getGridPoint(*wall);
                wall.position.y += move.y;
                auto newPoint = getGridPoint(*wall);
                if (oldPoint != newPoint) {
                    if (isGridPointValid(oldPoint)) {
                        foreach (j, taggedId; grid[oldPoint.y, oldPoint.x]) {
                            auto i = (taggedId & ~boxUnionTypeBit) - 1;
                            auto isWall = !(taggedId & boxUnionTypeBit);
                            if (isWall && (i + 1 == id)) {
                                grid[oldPoint.y, oldPoint.x].remove(j);
                                break;
                            }
                        }
                    }
                    if (isGridPointValid(newPoint)) {
                        grid[newPoint.y, newPoint.x].append(id & ~boxUnionTypeBit);
                    }
                }
            } else {
                wall.position.y += move.y;
            }
            if (~properties.flags & BoxFlag.isPassable) {
                properties.flags |= BoxFlag.isPassable;
                foreach (i, ref actor; actors) {
                    if (actor.properties.flags & BoxFlag.isPassable) continue;
                    if (wall.hasIntersection(actor.area)) {
                        // Push actor.
                        auto wallTop = wall.position.y;
                        auto wallBottom = wall.position.y + wall.size.y;
                        auto actorTop = actor.area.position.y;
                        auto actorBottom = actor.area.position.y + actor.area.size.y;
                        auto actorPushAmount = (move.y > 0) ? (wallBottom - actorTop) : (wallTop - actorBottom);
                        if (moveActorY(cast(BoxId) (i + 1), actorPushAmount)) {
                            // Squish actor.
                            squishedIdsBuffer.append(cast(BoxId) (i + 1));
                        }
                    } else if (actor.properties.flags & BoxFlag.isRiding) {
                        // Carry actor.
                        moveActorY(cast(BoxId) (i + 1), move.y);
                    }
                }
                properties.flags &= ~BoxFlag.isPassable;
            }
        }
        return squishedIdsBuffer[];
    }

    BoxActorId[] moveWallTo(BoxWallId id, Vec2 to, Vec2 amount) {
        auto wall = &getWall(id);
        auto target = moveTo(wall.position.toVec(), to.floor(), amount);
        return moveWall(id, target - wall.position.toVec());
    }

    BoxActorId[] moveWallToWithSlowdown(BoxWallId id, Vec2 to, Vec2 amount, float slowdown) {
        auto wall = &getWall(id);
        auto target = moveToWithSlowdown(wall.position.toVec(), to.floor(), amount, slowdown);
        return moveWall(id, target - wall.position.toVec());
    }

    @nogc
    void clear() {
        walls.clear();
        actors.clear();
        foreach (ref group; grid) group.clear();
    }

    void reserve(Sz capacity) {
        walls.reserve(capacity);
        actors.reserve(capacity);
    }

    @nogc
    void free() {
        walls.free();
        actors.free();
        wallIdsBuffer.free();
        actorIdsBuffer.free();
        squishedIdsBuffer.free();
        grid.free();
        this = BoxWorld();
    }
}

@nogc
void drawDebugBoxWorld(ref BoxWorld world) {
    foreach (wall; world.walls) drawRect(wall.area.toRect(), brown.alpha(170));
    foreach (actor; world.actors) drawRect(actor.area.toRect(), cyan.alpha(170));
}
