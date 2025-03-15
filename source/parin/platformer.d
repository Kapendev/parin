// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.40
// ---

// TODO: Update all the doc comments here.
// TODO: Add one-way collision support for moving walls.
// NOTE: The code works, but it's  super experimental and will change in the future!

/// The `platformer` module provides a pixel-perfect physics engine.
module parin.platformer;

import joka.ascii;
import joka.containers;
import joka.math;
import joka.types;

@safe @nogc nothrow:

alias BaseBoxId        = uint;
alias BaseBoxFlags     = ubyte;
alias WallBoxId        = BaseBoxId;
alias WallBoxFlags     = BaseBoxFlags;
alias ActorBoxId       = BaseBoxId;
alias ActorBoxFlags    = BaseBoxFlags;
alias TaggedBoxId      = BaseBoxId;
alias TaggedBoxIdGroup = FixedList!(TaggedBoxId, 254);
alias OneWaySide       = RideSide;

enum wallBoxTag      = 0;
enum actorBoxTag     = 1;
enum taggedBoxTagBit = 1 << 31;
enum boxPassableFlag = 0x1;
enum boxRidingFlag   = 0x2;

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
    bool isUnnormalized;

    @safe @nogc nothrow:

    this(float speed, float jump, float gravity, float acceleration) {
        this.speed = speed;
        this.jump = jump;
        this.gravity = gravity;
        this.acceleration = acceleration;
    }

    bool isSmooth() {
        return acceleration != 0.0f;
    }

    bool isTopDown() {
        return gravity == 0.0f;
    }

    Vec2 move() {
        if (isTopDown) {
            auto tempDirection = isUnnormalized ? direction : direction.normalize();
            if (isSmooth) {
                if (direction.x > 0.0f) {
                    velocity.x = min(velocity.x + tempDirection.x * acceleration, tempDirection.x * speed);
                } else if (direction.x < 0.0f) {
                    velocity.x = max(velocity.x + tempDirection.x * acceleration, tempDirection.x * speed);
                }
                if (velocity.x != tempDirection.x * speed) {
                   velocity.x = lerp(velocity.x, 0.0f, decelerationFactor);
                }
                if (direction.y > 0.0f) {
                    velocity.y = min(velocity.y + tempDirection.y * acceleration, tempDirection.y * speed);
                } else if (direction.y < 0.0f) {
                    velocity.y = max(velocity.y + tempDirection.y * acceleration, tempDirection.y * speed);
                }
                if (velocity.y != tempDirection.y * speed) {
                   velocity.y = lerp(velocity.y, 0.0f, decelerationFactor);
                }
            } else {
                velocity.x = tempDirection.x * speed;
                velocity.y = tempDirection.y * speed;
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
}

struct WallBoxProperties {
    Vec2 remainder;
    OneWaySide oneWaySide;
    WallBoxFlags flags;
}

struct ActorBoxProperties {
    Vec2 remainder;
    RideSide rideSide;
    ActorBoxFlags flags;
}

struct BoxWorld {
    List!IRect walls;
    List!IRect actors;
    List!WallBoxProperties wallsProperties;
    List!ActorBoxProperties actorsProperties;
    List!ActorBoxId squishedIdsBuffer;
    List!BaseBoxId collisionIdsBuffer;
    Grid!TaggedBoxIdGroup grid;
    int gridTileWidth;
    int gridTileHeight;

    @safe @nogc nothrow:

    WallBoxId appendWall(IRect box, OneWaySide oneWaySide = OneWaySide.none) {
        walls.append(box);
        wallsProperties.append(WallBoxProperties());
        wallsProperties[$ - 1].oneWaySide = oneWaySide;
        auto id = cast(BaseBoxId) walls.length;
        if (grid.length) {
            auto point = getGridPoint(box);
            if (isGridPointValid(point)) grid[point.y, point.x].append(id & ~taggedBoxTagBit);
        }
        return id;
    }

    ActorBoxId appendActor(IRect box, RideSide rideSide = RideSide.none) {
        actors.append(box);
        actorsProperties.append(ActorBoxProperties());
        actorsProperties[$ - 1].rideSide = rideSide;
        auto id = cast(BaseBoxId) actors.length;
        if (grid.length) {
            auto point = getGridPoint(box);
            if (isGridPointValid(point)) grid[point.y, point.x].append(id | taggedBoxTagBit);
        }
        return id;
    }

    void enableGrid(Sz rowCount, Sz colCount, int tileWidth, int tileHeight) {
        gridTileWidth = tileWidth;
        gridTileHeight = tileHeight;
        grid.resizeBlank(rowCount, colCount);
        foreach (ref group; grid) group.clear();
        foreach (i, wall; walls) {
            auto id = cast(BaseBoxId) (i + 1);
            auto point = getGridPoint(wall);
            if (isGridPointValid(point)) grid[point.y, point.x].append(id & ~taggedBoxTagBit);
        }
        foreach (i, actor; actors) {
            auto id = cast(BaseBoxId) (i + 1);
            auto point = getGridPoint(actor);
            if (isGridPointValid(point)) grid[point.y, point.x].append(id | taggedBoxTagBit);
        }
    }

    void disableGrid() {
        gridTileWidth = 0;
        gridTileHeight = 0;
        grid.clear();
    }

    bool isGridPointValid(IVec2 point) {
        return point.x >= 0 && point.y >= 0 && grid.has(point.y, point.x);
    }

    IVec2 getGridPoint(IRect box) {
        if (!grid.length) assert(0, "Can't get a grid point from a disabled grid.");
        return IVec2(
            box.position.x / gridTileWidth - (box.position.x < 0),
            box.position.y / gridTileHeight - (box.position.y < 0),
        );
    }

    ref IRect getWall(WallBoxId id) {
        if (id == 0) assert(0, "ID `0` is always invalid and represents a box that was never created.");
        return walls[id - 1];
    }

    ref WallBoxProperties getWallProperties(WallBoxId id) {
        if (id == 0) assert(0, "ID `0` is always invalid and represents a box that was never created.");
        return wallsProperties[id - 1];
    }

    ref IRect getActor(ActorBoxId id) {
        if (id == 0) assert(0, "ID `0` is always invalid and represents a box that was never created.");
        return actors[id - 1];
    }

    ref ActorBoxProperties getActorProperties(ActorBoxId id) {
        if (id == 0) assert(0, "ID `0` is always invalid and represents a box that was never created.");
        return actorsProperties[id - 1];
    }

    WallBoxId[] getWallCollisions(IRect box, bool canStopAtFirst = false) {
        collisionIdsBuffer.clear();
        if (grid.length) {
            auto point = getGridPoint(box);
            foreach (y; -1 .. 2) { foreach (x; -1 .. 2) {
                auto otherPoint = IVec2(point.x + x, point.y + y);
                if (!isGridPointValid(otherPoint)) continue;
                foreach (taggedId; grid[otherPoint.y, otherPoint.x]) {
                    auto i = (taggedId & ~taggedBoxTagBit) - 1;
                    auto isActor = taggedId & taggedBoxTagBit;
                    if (isActor) continue;
                    if (walls[i].hasIntersection(box) && ~wallsProperties[i].flags & boxPassableFlag) {
                        collisionIdsBuffer.append(cast(BaseBoxId) (i + 1));
                        if (canStopAtFirst) return collisionIdsBuffer[];
                    }
                }
            }}
        } else {
            foreach (i, wall; walls) {
                if (wall.hasIntersection(box) && ~wallsProperties[i].flags & boxPassableFlag) {
                    collisionIdsBuffer.append(cast(BaseBoxId) (i + 1));
                    if (canStopAtFirst) return collisionIdsBuffer[];
                }
            }
        }
        return collisionIdsBuffer[];
    }

    ActorBoxId[] getActorCollisions(IRect box, bool canStopAtFirst = false) {
        collisionIdsBuffer.clear();
        if (grid.length) {
            auto point = getGridPoint(box);
            foreach (y; -1 .. 2) { foreach (x; -1 .. 2) {
                auto otherPoint = IVec2(point.x + x, point.y + y);
                if (!isGridPointValid(otherPoint)) continue;
                foreach (taggedId; grid[otherPoint.y, otherPoint.x]) {
                    auto i = (taggedId & ~taggedBoxTagBit) - 1;
                    auto isWall = !(taggedId & taggedBoxTagBit);
                    if (isWall) continue;
                    if (actors[i].hasIntersection(box) && ~actorsProperties[i].flags & boxPassableFlag) {
                        collisionIdsBuffer.append(cast(BaseBoxId) (i + 1));
                        if (canStopAtFirst) return collisionIdsBuffer[];
                    }
                }
            }}
        } else {
            foreach (i, actor; actors) {
                if (actor.hasIntersection(box) && ~actorsProperties[i].flags & boxPassableFlag) {
                    collisionIdsBuffer.append(cast(BaseBoxId) (i + 1));
                    if (canStopAtFirst) return collisionIdsBuffer[];
                }
            }
        }
        return collisionIdsBuffer[];
    }

    WallBoxId hasWallCollision(IRect box) {
        auto boxes = getWallCollisions(box, true);
        return boxes.length ? boxes[0] : 0;
    }

    ActorBoxId hasActorCollision(IRect box) {
        auto boxes = getActorCollisions(box, true);
        return boxes.length ? boxes[0] : 0;
    }

    WallBoxId moveActorX(ActorBoxId id, float amount) {
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
                final switch (wallProperties.oneWaySide) with (OneWaySide) {
                    case none:
                        break;
                    case top:
                    case bottom:
                        wallId = 0;
                        break;
                    case left:
                        if (wall.position.x < actor.position.x || wall.hasIntersection(*actor)) wallId = 0;
                        break;
                    case right:
                        if (wall.position.x > actor.position.x || wall.hasIntersection(*actor)) wallId = 0;
                        break;
                }
            }
            if (~properties.flags & boxPassableFlag && wallId) {
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
                                auto i = (taggedId & ~taggedBoxTagBit) - 1;
                                auto isActor = taggedId & taggedBoxTagBit;
                                if (isActor && (i + 1 == id)) {
                                    grid[oldPoint.y, oldPoint.x].remove(j);
                                    break;
                                }
                            }
                        }
                        if (isGridPointValid(newPoint)) {
                            grid[newPoint.y, newPoint.x].append(id | taggedBoxTagBit);
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

    WallBoxId moveActorXTo(ActorBoxId id, float to, float amount) {
        auto actor = &getActor(id);
        auto target = moveTo(cast(float) actor.position.x, to.floor(), amount);
        return moveActorX(id, target - actor.position.x);
    }

    WallBoxId moveActorXToWithSlowdown(ActorBoxId id, float to, float amount, float slowdown) {
        auto actor = &getActor(id);
        auto target = moveToWithSlowdown(cast(float) actor.position.x, to.floor(), amount, slowdown);
        return moveActorX(id, target - actor.position.x);
    }

    WallBoxId moveActorY(ActorBoxId id, float amount) {
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
                final switch (wallProperties.oneWaySide) with (OneWaySide) {
                    case none:
                        break;
                    case left:
                    case right:
                        wallId = 0;
                        break;
                    case top:
                        if (wall.position.y < actor.position.y || wall.hasIntersection(*actor)) wallId = 0;
                        break;
                    case bottom:
                        if (wall.position.y > actor.position.y || wall.hasIntersection(*actor)) wallId = 0;
                        break;
                }
            }
            if (~properties.flags & boxPassableFlag && wallId) {
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
                                auto i = (taggedId & ~taggedBoxTagBit) - 1;
                                auto isActor = taggedId & taggedBoxTagBit;
                                if (isActor && (i + 1 == id)) {
                                    grid[oldPoint.y, oldPoint.x].remove(j);
                                    break;
                                }
                            }
                        }
                        if (isGridPointValid(newPoint)) {
                            grid[newPoint.y, newPoint.x].append(id | taggedBoxTagBit);
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

    WallBoxId moveActorYTo(ActorBoxId id, float to, float amount) {
        auto actor = &getActor(id);
        auto target = moveTo(cast(float) actor.position.y, to.floor(), amount);
        return moveActorY(id, target - actor.position.y);
    }

    WallBoxId moveActorYToWithSlowdown(ActorBoxId id, float to, float amount, float slowdown) {
        auto actor = &getActor(id);
        auto target = moveToWithSlowdown(cast(float) actor.position.y, to.floor(), amount, slowdown);
        return moveActorY(id, target - actor.position.y);
    }

    IVec2 moveActor(ActorBoxId id, Vec2 amount) {
        auto result = IVec2();
        result.x = cast(int) moveActorX(id, amount.x);
        result.y = cast(int) moveActorY(id, amount.y);
        return result;
    }

    IVec2 moveActorTo(ActorBoxId id, Vec2 to, Vec2 amount) {
        auto actor = &getActor(id);
        auto target = moveTo(actor.position.toVec(), to.floor(), amount);
        return moveActor(id, target - actor.position.toVec());
    }

    IVec2 moveActorToWithSlowdown(ActorBoxId id, Vec2 to, Vec2 amount, float slowdown) {
        auto actor = &getActor(id);
        auto target = moveToWithSlowdown(actor.position.toVec(), to.floor(), amount, slowdown);
        return moveActor(id, target - actor.position.toVec());
    }

    ActorBoxId[] moveWallX(WallBoxId id, float amount) {
        return moveWall(id, Vec2(amount, 0.0f));
    }

    ActorBoxId[] moveWallXTo(WallBoxId id, float to, float amount) {
        auto wall = &getWall(id);
        auto target = moveTo(cast(float) wall.position.x, to.floor(), amount);
        return moveWallX(id, target - wall.position.x);
    }

    ActorBoxId[] moveWallXToWithSlowdown(WallBoxId id, float to, float amount, float slowdown) {
        auto wall = &getWall(id);
        auto target = moveToWithSlowdown(cast(float) wall.position.x, to.floor(), amount, slowdown);
        return moveWallX(id, target - wall.position.x);
    }

    ActorBoxId[] moveWallY(WallBoxId id, float amount) {
        return moveWall(id, Vec2(0.0f, amount));
    }

    ActorBoxId[] moveWallYTo(WallBoxId id, float to, float amount) {
        auto wall = &getWall(id);
        auto target = moveTo(cast(float) wall.position.y, to.floor(), amount);
        return moveWallY(id, target - wall.position.y);
    }

    ActorBoxId[] moveWallYToWithSlowdown(WallBoxId id, float to, float amount, float slowdown) {
        auto wall = &getWall(id);
        auto target = moveToWithSlowdown(cast(float) wall.position.y, to.floor(), amount, slowdown);
        return moveWallY(id, target - wall.position.y);
    }

    ActorBoxId[] moveWall(WallBoxId id, Vec2 amount) {
        auto wall = &getWall(id);
        auto properties = &getWallProperties(id);
        if (properties.oneWaySide) assert(0, "One-way collisions are not yet supported for moving walls.");
        properties.remainder += amount;

        squishedIdsBuffer.clear();
        auto move = properties.remainder.round().toIVec();
        if (move.x != 0 || move.y != 0) {
            foreach (i, ref actorProperties; actorsProperties) {
                actorProperties.flags &= ~boxRidingFlag;
                if (!actorProperties.rideSide || actorProperties.flags & boxPassableFlag) continue;
                auto rideBox = actors[i];
                final switch (actorProperties.rideSide) with (RideSide) {
                    case none: break;
                    case top: rideBox.position.y += 1; break;
                    case left: rideBox.position.x += 1; break;
                    case right: rideBox.position.x -= 1; break;
                    case bottom: rideBox.position.y -= 1; break;
                }
                actorProperties.flags |= wall.hasIntersection(rideBox) ? boxRidingFlag : 0x0;
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
                            auto i = (taggedId & ~taggedBoxTagBit) - 1;
                            auto isWall = !(taggedId & taggedBoxTagBit);
                            if (isWall && (i + 1 == id)) {
                                grid[oldPoint.y, oldPoint.x].remove(j);
                                break;
                            }
                        }
                    }
                    if (isGridPointValid(newPoint)) {
                        grid[newPoint.y, newPoint.x].append(id & ~taggedBoxTagBit);
                    }
                }
            } else {
                wall.position.x += move.x;
            }
            if (~properties.flags & boxPassableFlag) {
                properties.flags |= boxPassableFlag;
                foreach (i, ref actor; actors) {
                    if (actorsProperties[i].flags & boxPassableFlag) continue;
                    if (wall.hasIntersection(actor)) {
                        // Push actor.
                        auto wallLeft = wall.position.x;
                        auto wallRight = wall.position.x + wall.size.x;
                        auto actorLeft = actor.position.x;
                        auto actorRight = actor.position.x + actor.size.x;
                        auto actorPushAmount = (move.x > 0) ? (wallRight - actorLeft) : (wallLeft - actorRight);
                        if (moveActorX(cast(BaseBoxId) (i + 1), actorPushAmount)) {
                            // Squish actor.
                            squishedIdsBuffer.append(cast(BaseBoxId) (i + 1));
                        }
                    } else if (actorsProperties[i].flags & boxRidingFlag) {
                        // Carry actor.
                        moveActorX(cast(BaseBoxId) (i + 1), move.x);
                    }
                }
                properties.flags &= ~boxPassableFlag;
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
                            auto i = (taggedId & ~taggedBoxTagBit) - 1;
                            auto isWall = !(taggedId & taggedBoxTagBit);
                            if (isWall && (i + 1 == id)) {
                                grid[oldPoint.y, oldPoint.x].remove(j);
                                break;
                            }
                        }
                    }
                    if (isGridPointValid(newPoint)) {
                        grid[newPoint.y, newPoint.x].append(id & ~taggedBoxTagBit);
                    }
                }
            } else {
                wall.position.y += move.y;
            }
            if (~properties.flags & boxPassableFlag) {
                properties.flags |= boxPassableFlag;
                foreach (i, ref actor; actors) {
                    if (actorsProperties[i].flags & boxPassableFlag) continue;
                    if (wall.hasIntersection(actor)) {
                        // Push actor.
                        auto wallTop = wall.position.y;
                        auto wallBottom = wall.position.y + wall.size.y;
                        auto actorTop = actor.position.y;
                        auto actorBottom = actor.position.y + actor.size.y;
                        auto actorPushAmount = (move.y > 0) ? (wallBottom - actorTop) : (wallTop - actorBottom);
                        if (moveActorY(cast(BaseBoxId) (i + 1), actorPushAmount)) {
                            // Squish actor.
                            squishedIdsBuffer.append(cast(BaseBoxId) (i + 1));
                        }
                    } else if (actorsProperties[i].flags & boxRidingFlag) {
                        // Carry actor.
                        moveActorY(cast(BaseBoxId) (i + 1), move.y);
                    }
                }
                properties.flags &= ~boxPassableFlag;
            }
        }
        return squishedIdsBuffer[];
    }

    ActorBoxId[] moveWallTo(WallBoxId id, Vec2 to, Vec2 amount) {
        auto wall = &getWall(id);
        auto target = moveTo(wall.position.toVec(), to.floor(), amount);
        return moveWall(id, target - wall.position.toVec());
    }

    ActorBoxId[] moveWallToWithSlowdown(WallBoxId id, Vec2 to, Vec2 amount, float slowdown) {
        auto wall = &getWall(id);
        auto target = moveToWithSlowdown(wall.position.toVec(), to.floor(), amount, slowdown);
        return moveWall(id, target - wall.position.toVec());
    }

    void clear() {
        walls.clear();
        wallsProperties.clear();
        actors.clear();
        actorsProperties.clear();
        foreach (ref group; grid) group.clear();
    }

    void reserve(Sz capacity) {
        walls.reserve(capacity);
        actors.reserve(capacity);
        wallsProperties.reserve(capacity);
        actorsProperties.reserve(capacity);
    }

    void free() {
        walls.free();
        actors.free();
        wallsProperties.free();
        actorsProperties.free();
        squishedIdsBuffer.free();
        collisionIdsBuffer.free();
        grid.free();
        this = BoxWorld();
    }
}
