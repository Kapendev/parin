// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.39
// ---

// TODO: Update all the doc comments here.
// TODO: Add one-way collision support for moving walls.
// TODO: Add spatial partitioning.
// NOTE: Was working on spatial partitioning. The grid is done, just need to add values in it.

/// The `platformer` module provides a pixel-perfect physics engine.
module parin.platformer;

import joka.ascii;
import joka.containers;
import joka.math;
import joka.types;

@safe @nogc nothrow:

alias BaseBoxId            = uint;
alias BaseBoxFlags         = ubyte;
alias WallBoxId            = BaseBoxId;
alias WallBoxFlags         = BaseBoxFlags;
alias ActorBoxId           = BaseBoxId;
alias ActorBoxFlags        = BaseBoxFlags;
alias TaggedBaseBoxId      = BaseBoxId;
alias TaggedBaseBoxIdGroup = FixedList!(TaggedBaseBoxId, 510);
alias OneWaySide           = RideSide;

enum wallBoxTag      = 0;
enum actorBoxTag     = 1;
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
    Grid!TaggedBaseBoxIdGroup grid;
    int gridTileWidth;
    int gridTileHeight;

    @safe @nogc nothrow:

    @trusted
    void appendWallIdToSpatialGrid(WallBoxId id) {
        FixedList!(IVec2, 4) vecSet = void;
//        vecSet.clear();
//        auto taggedId = id & ~(1 << 31);
//        foreach (position; getWallSpatialGridPositions) {
//            auto canAppend = true;
//            foreach (vec; vecSet) {
//                if (vec == position) {
//                    canAppend = false;
//                    break;
//                }
//            }
//            if (canAppend) {
//                grid[vec.y, vec.x].append(taggedId);
//                vecSet.append(vec);
//            }
//        }
    }

    void removeWallIdFromSpatialGrid(WallBoxId id) {

    }

    void enableSpatialGrid(Sz rowCount, Sz colCount, int tileWidth, int tileHeight) {
        gridTileWidth = tileWidth;
        gridTileHeight = tileHeight;
        grid.resizeBlank(rowCount, colCount);
        foreach (ref group; grid) {
            group.length = 0;
        }
        foreach (i, ref properties; wallsProperties) {
            auto id = cast(BaseBoxId) (i + 1);
            auto tagged = id & ~(1 << 31);
            auto positions = getWallSpatialGridPositions(id);
//            grid[positions[0].y, positions[0].x].append(tagged);
//            if (positions[0] != positions[1]) {
//                grid[positions[1].y, positions[1].x].append(tagged);
//            }
        }
        foreach (i, ref properties; actorsProperties) {
            auto id = cast(BaseBoxId) (i + 1);
            auto tagged = id | (1 << 31);
            auto positions = getActorSpatialGridPositions(id);
//            grid[positions[0].y, positions[0].x].append(tagged);
//            if (positions[0] != positions[1]) {
//                grid[positions[1].y, positions[1].x].append(tagged);
//            }
        }
    }

    void disableSpatialGrid() {
        gridTileWidth = 0;
        gridTileHeight = 0;
        grid.clear();
    }

    ref IRect getWall(WallBoxId id) {
        if (id == 0) {
            assert(0, "ID `0` is always invalid and represents a box that was never created.");
        } else if (id > walls.length) {
            assert(0, "ID `{}` does not exist.".format(id));
        }
        return walls[id - 1];
    }

    ref WallBoxProperties getWallProperties(WallBoxId id) {
        if (id == 0) {
            assert(0, "ID `0` is always invalid and represents a box that was never created.");
        } else if (id > wallsProperties.length) {
            assert(0, "ID `{}` does not exist.".format(id));
        }
        return wallsProperties[id - 1];
    }

    @trusted
    IVec2[4] getWallSpatialGridPositions(WallBoxId id) {
        IVec2[4] result = void;
        auto i = id - 1;
        result[0].x = walls[i].position.x / gridTileWidth - (walls[i].position.x < 0);
        result[0].y = walls[i].position.y / gridTileHeight - (walls[i].position.y < 0);
        result[3].x = (walls[i].position.x + walls[i].size.x) - ((walls[i].position.x + walls[i].size.x) < 0);
        result[3].y = (walls[i].position.y + walls[i].size.y) - ((walls[i].position.y + walls[i].size.y) < 0);
        result[1].x = result[3].x;
        result[1].y = result[0].y;
        result[2].x = result[0].x;
        result[2].y = result[3].y;
        return result;
    }

    ref IRect getActor(ActorBoxId id) {
        if (id == 0) {
            assert(0, "ID `0` is always invalid and represents a box that was never created.");
        } else if (id > actors.length) {
            assert(0, "ID `{}` does not exist.".format(id));
        }
        return actors[id - 1];
    }

    ref ActorBoxProperties getActorProperties(ActorBoxId id) {
        if (id == 0) {
            assert(0, "ID `0` is always invalid and represents a box that was never created.");
        } else if (id > actorsProperties.length) {
            assert(0, "ID `{}` does not exist.".format(id));
        }
        return actorsProperties[id - 1];
    }

    @trusted
    IVec2[4] getActorSpatialGridPositions(WallBoxId id) {
        IVec2[4] result = void;
        auto i = id - 1;
        result[0].x = actors[i].position.x / gridTileWidth - (actors[i].position.x < 0);
        result[0].y = actors[i].position.y / gridTileHeight - (actors[i].position.y < 0);
        result[1].x = (actors[i].position.x + actors[i].size.x) - ((actors[i].position.x + actors[i].size.x) < 0);
        result[1].y = (actors[i].position.y + actors[i].size.y) - ((actors[i].position.y + actors[i].size.y) < 0);
        result[1].x = result[3].x;
        result[1].y = result[0].y;
        result[2].x = result[0].x;
        result[2].y = result[3].y;
        return result;
    }

    WallBoxId appendWall(IRect box, OneWaySide oneWaySide = OneWaySide.none) {
        walls.append(box);
        wallsProperties.append(WallBoxProperties());
        wallsProperties[$ - 1].oneWaySide = oneWaySide;
        return cast(BaseBoxId) walls.length;
    }

    ActorBoxId appendActor(IRect box, RideSide rideSide = RideSide.none) {
        actors.append(box);
        actorsProperties.append(ActorBoxProperties());
        actorsProperties[$ - 1].rideSide = rideSide;
        return cast(BaseBoxId) actors.length;
    }

    WallBoxId hasWallCollision(IRect box) {
        foreach (i, wall; walls) {
            if (wall.hasIntersection(box) && ~wallsProperties[i].flags & boxPassableFlag) return cast(BaseBoxId) (i + 1);
        }
        return 0;
    }

    ActorBoxId hasActorCollision(IRect box) {
        foreach (i, actor; actors) {
            if (actor.hasIntersection(box) && ~actorsProperties[i].flags & boxPassableFlag) return cast(BaseBoxId) (i + 1);
        }
        return 0;
    }

    WallBoxId[] getWallCollisions(IRect box) {
        collisionIdsBuffer.clear();
        foreach (i, wall; walls) {
            if (wall.hasIntersection(box) && ~wallsProperties[i].flags & boxPassableFlag) collisionIdsBuffer.append(cast(BaseBoxId) (i + 1));
        }
        return collisionIdsBuffer[];
    }

    ActorBoxId[] getActorCollisions(IRect box) {
        collisionIdsBuffer.clear();
        foreach (i, actor; actors) {
            if (actor.hasIntersection(box) && ~actorsProperties[i].flags & boxPassableFlag) collisionIdsBuffer.append(cast(BaseBoxId) (i + 1));
        }
        return collisionIdsBuffer[];
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
                actor.position.x += moveSign;
                move -= moveSign;
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
                actor.position.y += moveSign;
                move -= moveSign;
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
        properties.remainder += amount;

        // NOTE: Will be removed when I want to work on that...
        if (properties.oneWaySide) {
            assert(0, "One-way collisions are not yet supported for moving walls.");
        }

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
            wall.position.x += move.x;
            properties.remainder.x -= move.x;
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
            wall.position.y += move.y;
            properties.remainder.y -= move.y;
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
        collisionIdsBuffer.clear();
    }

    void reserve(Sz capacity) {
        walls.reserve(capacity);
        actors.reserve(capacity);
        wallsProperties.reserve(capacity);
        actorsProperties.reserve(capacity);
        squishedIdsBuffer.reserve(capacity);
        collisionIdsBuffer.reserve(capacity);
    }

    void free() {
        walls.free();
        actors.free();
        wallsProperties.free();
        actorsProperties.free();
        squishedIdsBuffer.free();
        collisionIdsBuffer.free();
        this = BoxWorld();
    }
}
