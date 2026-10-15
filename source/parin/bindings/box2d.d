// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

/// The `box2d` module provides access to the Box2D v3 C API.
/// By default these bindings match the Box2D v3.1.1 release.
/// To use latest Box2D instead, compile with `-version=Box2D_Main`.
/// The versions have different ABIs, so the flag must match the library you link.
module parin.bindings.box2d;

import joka = parin.joka.math;

version (Box2D_Main) {} else {
    version = Box2D_3_1;
}

extern(C) @system nothrow @nogc:

alias b2Vec2 = joka.Vec2;
alias b2Pos = b2Vec2;
alias b2WorldTransform = b2Transform;

version (Box2D_3_1) {
    alias b2UserMaterialId = int;
} else {
    alias b2UserMaterialId = ulong;
}

alias b2OverlapResultFcn = bool function(b2ShapeId shapeId, void* context);
alias b2CastResultFcn = float function(b2ShapeId shapeId, b2Vec2 point, b2Vec2 normal, float fraction, void* context);

version (Box2D_3_1) {
    alias b2TaskCallback = void function(int startIndex, int endIndex, uint workerIndex, void* taskContext);
    alias b2EnqueueTaskCallback = void* function(b2TaskCallback task, int itemCount, int minRange, void* taskContext, void* userContext);
} else {
    alias b2TaskCallback = void function(void* taskContext);
    alias b2EnqueueTaskCallback = void* function(b2TaskCallback task, void* taskContext, void* userContext);
}
alias b2FinishTaskCallback = void function(void* userTask, void* userContext);
alias b2FrictionCallback = float function(float frictionA, b2UserMaterialId userMaterialIdA, float frictionB, b2UserMaterialId userMaterialIdB);
alias b2RestitutionCallback = float function(float restitutionA, b2UserMaterialId userMaterialIdA, float restitutionB, b2UserMaterialId userMaterialIdB);

alias b2BodyType = int;
alias b2ShapeType = int;
alias b2JointType = int;

enum : b2BodyType {
    b2_staticBody    = 0,
    b2_kinematicBody = 1,
    b2_dynamicBody   = 2,
    b2_bodyTypeCount
}

enum : b2ShapeType {
    b2_circleShape,
    b2_capsuleShape,
    b2_segmentShape,
    b2_polygonShape,
    b2_chainSegmentShape,
    b2_shapeTypeCount
}

version (Box2D_3_1) {
    enum : b2JointType {
        b2_distanceJoint,
        b2_filterJoint,
        b2_motorJoint,
        b2_mouseJoint,
        b2_prismaticJoint,
        b2_revoluteJoint,
        b2_weldJoint,
        b2_wheelJoint,
    }
} else {
    enum : b2JointType {
        b2_distanceJoint,
        b2_filterJoint,
        b2_motorJoint,
        b2_moverJoint,
        b2_pogoJoint,
        b2_prismaticJoint,
        b2_revoluteJoint,
        b2_weldJoint,
        b2_wheelJoint,
    }
}

struct b2WorldId {
    ushort index1;
    ushort generation;
}

struct b2BodyId {
    int index1;
    ushort world0;
    ushort generation;
}

struct b2ShapeId {
    int index1;
    ushort world0;
    ushort generation;
}

struct b2ChainId {
    int index1;
    ushort world0;
    ushort generation;
}

struct b2JointId {
    int index1;
    ushort world0;
    ushort generation;
}

// Contact ids do not exist in 3.1.1.
version (Box2D_3_1) {} else {
    struct b2ContactId {
        int index1;
        ushort world0;
        short padding;
        uint generation;
    }
}

struct b2Rot {
    float c;
    float s;
}

struct b2Transform {
    b2Vec2 p;
    b2Rot q;
}

struct b2AABB {
    b2Vec2 lowerBound;
    b2Vec2 upperBound;
}

struct b2Mat22 {
    b2Vec2 cx;
    b2Vec2 cy;
}

struct b2Filter {
    ulong categoryBits;
    ulong maskBits;
    int groupIndex;
}

struct b2QueryFilter {
    ulong categoryBits;
    ulong maskBits;
}

struct b2SurfaceMaterial {
    float friction;
    float restitution;
    float rollingResistance;
    float tangentSpeed;
    b2UserMaterialId userMaterialId;
    uint customColor;
}

version (Box2D_3_1) {} else {
    struct b2MotionLocks {
        bool linearX;
        bool linearY;
        bool angularZ;
    }

    struct b2Capacity {
        int staticShapeCount;
        int dynamicShapeCount;
        int staticBodyCount;
        int dynamicBodyCount;
        int contactCount;
    }
}

struct b2WorldDef {
    b2Vec2 gravity;
    float restitutionThreshold;
    version (Box2D_3_1) {} else {
        int restitutionIterations;
        bool enableRestitutionPropagation;
    }
    float hitEventThreshold;
    float contactHertz;
    float contactDampingRatio;
    version (Box2D_3_1) {
        float maxContactPushSpeed;
    } else {
        float contactSpeed;
    }
    float maximumLinearSpeed;
    b2FrictionCallback frictionCallback;
    b2RestitutionCallback restitutionCallback;
    bool enableSleep;
    bool enableContinuous;
    int workerCount;
    b2EnqueueTaskCallback enqueueTask;
    b2FinishTaskCallback finishTask;
    void* userTaskContext;
    void* userData;
    version (Box2D_3_1) {} else {
        b2Capacity capacity;
    }
    int internalValue;
}

struct b2BodyDef {
    b2BodyType type;
    b2Pos position;
    b2Rot rotation;
    b2Vec2 linearVelocity;
    float angularVelocity;
    float linearDamping;
    float angularDamping;
    float gravityScale;
    float sleepThreshold;
    version (Box2D_3_1) {} else {
        float safetyFactor;
    }
    const(char)* name;
    void* userData;
    version (Box2D_3_1) {} else {
        b2MotionLocks motionLocks;
    }
    bool enableSleep;
    bool isAwake;
    version (Box2D_3_1) {
        bool fixedRotation;
    }
    bool isBullet;
    bool isEnabled;
    bool allowFastRotation;
    version (Box2D_3_1) {} else {
        bool enableContactRecycling;
    }
    int internalValue;
}

struct b2ShapeDef {
    void* userData;
    b2SurfaceMaterial material;
    float density;
    b2Filter filter;
    version (Box2D_3_1) {} else {
        bool enableCustomFiltering;
    }
    bool isSensor;
    bool enableSensorEvents;
    bool enableContactEvents;
    bool enableHitEvents;
    bool enablePreSolveEvents;
    bool invokeContactCreation;
    bool updateBodyMass;
    int internalValue;
}

struct b2Circle {
    b2Vec2 center;
    float radius;
}

struct b2Capsule {
    b2Vec2 center1;
    b2Vec2 center2;
    float radius;
}

struct b2Segment {
    b2Vec2 point1;
    b2Vec2 point2;
}

struct b2Polygon {
    joka.StaticArray!(b2Vec2, 8) vertices;
    joka.StaticArray!(b2Vec2, 8) normals;
    b2Vec2 centroid;
    float radius;
    int count;
}

// Joint definitions.
// In main every joint definition starts with a `b2JointDef base` that holds the bodies, the local frames and more.
// In 3.1.1 every joint definition has its own bodies, local anchors, `collideConnected` and `userData`.
version (Box2D_3_1) {
    struct b2DistanceJointDef {
        b2BodyId bodyIdA;
        b2BodyId bodyIdB;
        b2Vec2 localAnchorA;
        b2Vec2 localAnchorB;
        float length;
        bool enableSpring;
        float hertz;
        float dampingRatio;
        bool enableLimit;
        float minLength;
        float maxLength;
        bool enableMotor;
        float maxMotorForce;
        float motorSpeed;
        bool collideConnected;
        void* userData;
        int internalValue;
    }

    struct b2MotorJointDef {
        b2BodyId bodyIdA;
        b2BodyId bodyIdB;
        b2Vec2 linearOffset;
        float angularOffset;
        float maxForce;
        float maxTorque;
        float correctionFactor;
        bool collideConnected;
        void* userData;
        int internalValue;
    }

    struct b2MouseJointDef {
        b2BodyId bodyIdA;
        b2BodyId bodyIdB;
        b2Vec2 target;
        float hertz;
        float dampingRatio;
        float maxForce;
        bool collideConnected;
        void* userData;
        int internalValue;
    }

    struct b2FilterJointDef {
        b2BodyId bodyIdA;
        b2BodyId bodyIdB;
        void* userData;
        int internalValue;
    }

    struct b2PrismaticJointDef {
        b2BodyId bodyIdA;
        b2BodyId bodyIdB;
        b2Vec2 localAnchorA;
        b2Vec2 localAnchorB;
        b2Vec2 localAxisA;
        float referenceAngle;
        float targetTranslation;
        bool enableSpring;
        float hertz;
        float dampingRatio;
        bool enableLimit;
        float lowerTranslation;
        float upperTranslation;
        bool enableMotor;
        float maxMotorForce;
        float motorSpeed;
        bool collideConnected;
        void* userData;
        int internalValue;
    }

    struct b2RevoluteJointDef {
        b2BodyId bodyIdA;
        b2BodyId bodyIdB;
        b2Vec2 localAnchorA;
        b2Vec2 localAnchorB;
        float referenceAngle;
        float targetAngle;
        bool enableSpring;
        float hertz;
        float dampingRatio;
        bool enableLimit;
        float lowerAngle;
        float upperAngle;
        bool enableMotor;
        float maxMotorTorque;
        float motorSpeed;
        float drawSize;
        bool collideConnected;
        void* userData;
        int internalValue;
    }

    struct b2WeldJointDef {
        b2BodyId bodyIdA;
        b2BodyId bodyIdB;
        b2Vec2 localAnchorA;
        b2Vec2 localAnchorB;
        float referenceAngle;
        float linearHertz;
        float angularHertz;
        float linearDampingRatio;
        float angularDampingRatio;
        bool collideConnected;
        void* userData;
        int internalValue;
    }

    struct b2WheelJointDef {
        b2BodyId bodyIdA;
        b2BodyId bodyIdB;
        b2Vec2 localAnchorA;
        b2Vec2 localAnchorB;
        b2Vec2 localAxisA;
        bool enableSpring;
        float hertz;
        float dampingRatio;
        bool enableLimit;
        float lowerTranslation;
        float upperTranslation;
        bool enableMotor;
        float maxMotorTorque;
        float motorSpeed;
        bool collideConnected;
        void* userData;
        int internalValue;
    }
} else {
    struct b2JointDef {
        void* userData;
        b2BodyId bodyIdA;
        b2BodyId bodyIdB;
        b2Transform localFrameA;
        b2Transform localFrameB;
        float forceThreshold;
        float torqueThreshold;
        float constraintHertz;
        float constraintDampingRatio;
        float drawScale;
        bool collideConnected;
    }

    struct b2DistanceJointDef {
        b2JointDef base;
        float length;
        bool enableSpring;
        float lowerSpringForce;
        float upperSpringForce;
        float hertz;
        float dampingRatio;
        bool enableLimit;
        float minLength;
        float maxLength;
        bool enableMotor;
        float maxMotorForce;
        float motorSpeed;
        int internalValue;
    }

    struct b2MotorJointDef {
        b2JointDef base;
        b2Vec2 linearVelocity;
        float maxVelocityForce;
        float angularVelocity;
        float maxVelocityTorque;
        float linearHertz;
        float linearDampingRatio;
        float maxSpringForce;
        float angularHertz;
        float angularDampingRatio;
        float maxSpringTorque;
        int internalValue;
    }

    struct b2MoverJointDef {
        b2JointDef base;
        b2Vec2 linearVelocity;
        b2Vec2 maxVelocityForce;
        int internalValue;
    }

    struct b2PogoJointDef {
        b2JointDef base;
        b2Vec2 normal;
        float hertz;
        float dampingRatio;
        float restLength;
        float maxTensionForce;
        float maxCompressionForce;
        float impulse;
        float velocity;
        int internalValue;
    }

    struct b2FilterJointDef {
        b2JointDef base;
        int internalValue;
    }

    struct b2PrismaticJointDef {
        b2JointDef base;
        bool enableSpring;
        float hertz;
        float dampingRatio;
        float targetTranslation;
        bool enableLimit;
        float lowerTranslation;
        float upperTranslation;
        bool enableMotor;
        float maxMotorForce;
        float motorSpeed;
        int internalValue;
    }

    struct b2RevoluteJointDef {
        b2JointDef base;
        float targetAngle;
        bool enableSpring;
        float hertz;
        float dampingRatio;
        bool enableLimit;
        float lowerAngle;
        float upperAngle;
        bool enableMotor;
        float maxMotorTorque;
        float motorSpeed;
        int internalValue;
    }

    struct b2WeldJointDef {
        b2JointDef base;
        float linearHertz;
        float angularHertz;
        float linearDampingRatio;
        float angularDampingRatio;
        int internalValue;
    }

    struct b2WheelJointDef {
        b2JointDef base;
        bool enableSpring;
        float hertz;
        float dampingRatio;
        bool enableLimit;
        float lowerTranslation;
        float upperTranslation;
        bool enableMotor;
        float maxMotorTorque;
        float motorSpeed;
        int internalValue;
    }
}

struct b2ManifoldPoint {
    version (Box2D_3_1) {
        b2Vec2 point;
    }
    b2Vec2 anchorA;
    b2Vec2 anchorB;
    float separation;
    float normalImpulse;
    float tangentImpulse;
    float totalNormalImpulse;
    float normalVelocity;
    version (Box2D_3_1) {} else {
        float baseSeparation;
    }
    ushort id;
    bool persisted;
}

struct b2Manifold {
    b2Vec2 normal;
    float rollingImpulse;
    joka.StaticArray!(b2ManifoldPoint, 2) points;
    int pointCount;
}

struct b2SensorBeginTouchEvent {
    b2ShapeId sensorShapeId;
    b2ShapeId visitorShapeId;
}

struct b2SensorEndTouchEvent {
    b2ShapeId sensorShapeId;
    b2ShapeId visitorShapeId;
}

struct b2SensorEvents {
    b2SensorBeginTouchEvent* beginEvents;
    b2SensorEndTouchEvent* endEvents;
    int beginCount;
    int endCount;
}

// In 3.1.1 the begin touch event carries a manifold and the other contact events have no contact id.
struct b2ContactBeginTouchEvent {
    b2ShapeId shapeIdA;
    b2ShapeId shapeIdB;
    version (Box2D_3_1) {
        b2Manifold manifold;
    } else {
        b2ContactId contactId;
    }
}

struct b2ContactEndTouchEvent {
    b2ShapeId shapeIdA;
    b2ShapeId shapeIdB;
    version (Box2D_3_1) {} else {
        b2ContactId contactId;
    }
}

struct b2ContactHitEvent {
    b2ShapeId shapeIdA;
    b2ShapeId shapeIdB;
    version (Box2D_3_1) {} else {
        b2ContactId contactId;
    }
    b2Pos point;
    b2Vec2 normal;
    float approachSpeed;
}

struct b2ContactEvents {
    b2ContactBeginTouchEvent* beginEvents;
    b2ContactEndTouchEvent* endEvents;
    b2ContactHitEvent* hitEvents;
    int beginCount;
    int endCount;
    int hitCount;
}

struct b2BodyMoveEvent {
    version (Box2D_3_1) {
        b2WorldTransform transform;
        b2BodyId bodyId;
        void* userData;
    } else {
        void* userData;
        b2WorldTransform transform;
        b2BodyId bodyId;
    }
    bool fellAsleep;
}

struct b2BodyEvents {
    b2BodyMoveEvent* moveEvents;
    int moveCount;
}

version (Box2D_3_1) {} else {
    struct b2JointEvent {
        b2JointId jointId;
        void* userData;
    }

    struct b2JointEvents {
        b2JointEvent* jointEvents;
        int count;
    }
}

struct b2TreeStats {
    int nodeVisits;
    int leafVisits;
}

struct b2Hull {
    joka.StaticArray!(b2Vec2, 8) points;
    int count;
}

struct b2ShapeProxy {
    joka.StaticArray!(b2Vec2, 8) points;
    int count;
    float radius;
}

struct b2RayResult {
    b2ShapeId shapeId;
    b2Pos point;
    b2Vec2 normal;
    float fraction;
    int nodeVisits;
    int leafVisits;
    bool hit;
}

struct b2ChainSegment {
    b2Vec2 ghost1;
    b2Segment segment;
    b2Vec2 ghost2;
    int chainId;
}

struct b2ChainDef {
    void* userData;
    const(b2Vec2)* points;
    version (Box2D_3_1) {
        int count;
    } else {
        int pointCount;
        b2Vec2 ghost1;
        b2Vec2 ghost2;
    }
    const(b2SurfaceMaterial)* materials;
    int materialCount;
    b2Filter filter;
    bool isLoop;
    bool enableSensorEvents;
    int internalValue;
}

// In 3.1.1 there is no contact id.
struct b2ContactData {
    version (Box2D_3_1) {} else {
        b2ContactId contactId;
    }
    b2ShapeId shapeIdA;
    b2ShapeId shapeIdB;
    b2Manifold manifold;
}

// World
b2WorldDef b2DefaultWorldDef();
b2WorldId b2CreateWorld(const(b2WorldDef)* def);
void b2DestroyWorld(b2WorldId worldId);
bool b2World_IsValid(b2WorldId id);
void b2World_Step(b2WorldId worldId, float timeStep, int subStepCount);
b2BodyEvents b2World_GetBodyEvents(b2WorldId worldId);
b2SensorEvents b2World_GetSensorEvents(b2WorldId worldId);
b2ContactEvents b2World_GetContactEvents(b2WorldId worldId);
void b2World_SetGravity(b2WorldId worldId, b2Vec2 gravity);
b2Vec2 b2World_GetGravity(b2WorldId worldId);
void b2World_EnableSleeping(b2WorldId worldId, bool flag);
bool b2World_IsSleepingEnabled(b2WorldId worldId);
void b2World_EnableContinuous(b2WorldId worldId, bool flag);
bool b2World_IsContinuousEnabled(b2WorldId worldId);
void b2World_SetUserData(b2WorldId worldId, void* userData);
void* b2World_GetUserData(b2WorldId worldId);
version (Box2D_3_1) {} else {
    b2AABB b2World_GetBounds(b2WorldId worldId);
    b2JointEvents b2World_GetJointEvents(b2WorldId worldId);
}

// Body
b2BodyDef b2DefaultBodyDef();
b2BodyId b2CreateBody(b2WorldId worldId, const(b2BodyDef)* def);
void b2DestroyBody(b2BodyId bodyId);
bool b2Body_IsValid(b2BodyId id);
b2BodyType b2Body_GetType(b2BodyId bodyId);
void b2Body_SetType(b2BodyId bodyId, b2BodyType type);
void b2Body_SetUserData(b2BodyId bodyId, void* userData);
void* b2Body_GetUserData(b2BodyId bodyId);
b2Pos b2Body_GetPosition(b2BodyId bodyId);
b2Rot b2Body_GetRotation(b2BodyId bodyId);
b2WorldTransform b2Body_GetTransform(b2BodyId bodyId);
void b2Body_SetTransform(b2BodyId bodyId, b2Pos position, b2Rot rotation);
b2Vec2 b2Body_GetLinearVelocity(b2BodyId bodyId);
float b2Body_GetAngularVelocity(b2BodyId bodyId);
void b2Body_SetLinearVelocity(b2BodyId bodyId, b2Vec2 linearVelocity);
void b2Body_SetAngularVelocity(b2BodyId bodyId, float angularVelocity);
void b2Body_ApplyForce(b2BodyId bodyId, b2Vec2 force, b2Pos point, bool wake);
void b2Body_ApplyForceToCenter(b2BodyId bodyId, b2Vec2 force, bool wake);
void b2Body_ApplyTorque(b2BodyId bodyId, float torque, bool wake);
void b2Body_ApplyLinearImpulse(b2BodyId bodyId, b2Vec2 impulse, b2Pos point, bool wake);
void b2Body_ApplyLinearImpulseToCenter(b2BodyId bodyId, b2Vec2 impulse, bool wake);
void b2Body_ApplyAngularImpulse(b2BodyId bodyId, float impulse, bool wake);
float b2Body_GetMass(b2BodyId bodyId);
bool b2Body_IsAwake(b2BodyId bodyId);
void b2Body_SetAwake(b2BodyId bodyId, bool awake);
bool b2Body_IsEnabled(b2BodyId bodyId);
void b2Body_Enable(b2BodyId bodyId);
void b2Body_Disable(b2BodyId bodyId);
void b2Body_SetBullet(b2BodyId bodyId, bool flag);
bool b2Body_IsBullet(b2BodyId bodyId);
int b2Body_GetShapeCount(b2BodyId bodyId);
int b2Body_GetShapes(b2BodyId bodyId, b2ShapeId* shapeArray, int capacity);

// Shape
b2ShapeDef b2DefaultShapeDef();
b2ShapeId b2CreateCircleShape(b2BodyId bodyId, const(b2ShapeDef)* def, const(b2Circle)* circle);
b2ShapeId b2CreateCapsuleShape(b2BodyId bodyId, const(b2ShapeDef)* def, const(b2Capsule)* capsule);
b2ShapeId b2CreateSegmentShape(b2BodyId bodyId, const(b2ShapeDef)* def, const(b2Segment)* segment);
b2ShapeId b2CreatePolygonShape(b2BodyId bodyId, const(b2ShapeDef)* def, const(b2Polygon)* polygon);
void b2DestroyShape(b2ShapeId shapeId, bool updateBodyMass);
bool b2Shape_IsValid(b2ShapeId id);
b2ShapeType b2Shape_GetType(b2ShapeId shapeId);
b2BodyId b2Shape_GetBody(b2ShapeId shapeId);
void b2Shape_SetUserData(b2ShapeId shapeId, void* userData);
void* b2Shape_GetUserData(b2ShapeId shapeId);
void b2Shape_SetDensity(b2ShapeId shapeId, float density, bool updateBodyMass);
float b2Shape_GetDensity(b2ShapeId shapeId);
void b2Shape_SetFriction(b2ShapeId shapeId, float friction);
float b2Shape_GetFriction(b2ShapeId shapeId);
void b2Shape_SetRestitution(b2ShapeId shapeId, float restitution);
float b2Shape_GetRestitution(b2ShapeId shapeId);
b2Filter b2Shape_GetFilter(b2ShapeId shapeId);
void b2Shape_SetFilter(b2ShapeId shapeId, b2Filter filter);
bool b2Shape_TestPoint(b2ShapeId shapeId, b2Pos point);
b2AABB b2Shape_GetAABB(b2ShapeId shapeId);

// Joints
b2DistanceJointDef b2DefaultDistanceJointDef();
b2JointId b2CreateDistanceJoint(b2WorldId worldId, const(b2DistanceJointDef)* def);
b2RevoluteJointDef b2DefaultRevoluteJointDef();
b2JointId b2CreateRevoluteJoint(b2WorldId worldId, const(b2RevoluteJointDef)* def);
b2PrismaticJointDef b2DefaultPrismaticJointDef();
b2JointId b2CreatePrismaticJoint(b2WorldId worldId, const(b2PrismaticJointDef)* def);
b2WeldJointDef b2DefaultWeldJointDef();
b2JointId b2CreateWeldJoint(b2WorldId worldId, const(b2WeldJointDef)* def);
b2WheelJointDef b2DefaultWheelJointDef();
b2JointId b2CreateWheelJoint(b2WorldId worldId, const(b2WheelJointDef)* def);
void b2DestroyJoint(b2JointId jointId);
bool b2Joint_IsValid(b2JointId id);
b2JointType b2Joint_GetType(b2JointId jointId);
b2BodyId b2Joint_GetBodyA(b2JointId jointId);
b2BodyId b2Joint_GetBodyB(b2JointId jointId);
void b2Joint_SetUserData(b2JointId jointId, void* userData);
void* b2Joint_GetUserData(b2JointId jointId);

// Queries
// In main the world queries take an `origin` (the world position that the shape or ray is relative to).
b2TreeStats b2World_CastRay(b2WorldId worldId, b2Pos origin, b2Vec2 translation, b2QueryFilter filter, b2CastResultFcn fcn, void* context);

// Helpers
b2Vec2 b2Body_GetWorldPoint(b2BodyId bodyId, b2Vec2 localPoint);
b2Vec2 b2Body_GetLocalPoint(b2BodyId bodyId, b2Pos worldPoint);
b2Vec2 b2Body_GetWorldVector(b2BodyId bodyId, b2Vec2 localVector);
b2Vec2 b2Body_GetLocalVector(b2BodyId bodyId, b2Vec2 worldVector);

b2Polygon b2MakePolygon(const(b2Hull)* hull, float radius);
b2Polygon b2MakeOffsetPolygon(const(b2Hull)* hull, b2Vec2 position, b2Rot rotation);
b2Polygon b2MakeOffsetRoundedPolygon(const(b2Hull)* hull, b2Vec2 position, b2Rot rotation, float radius);
b2Polygon b2MakeSquare(float halfWidth);
b2Polygon b2MakeBox(float halfWidth, float halfHeight);
b2Polygon b2MakeRoundedBox(float halfWidth, float halfHeight, float radius);
b2Polygon b2MakeOffsetBox(float halfWidth, float halfHeight, b2Vec2 center, b2Rot rotation);
b2Polygon b2MakeOffsetRoundedBox(float halfWidth, float halfHeight, b2Vec2 center, b2Rot rotation, float radius);
b2Polygon b2TransformPolygon(b2Transform transform, const(b2Polygon)* polygon);
b2Hull b2ComputeHull(const(b2Vec2)* points, int count);
b2ShapeProxy b2MakeProxy(const(b2Vec2)* points, int count, float radius);
b2ShapeProxy b2MakeOffsetProxy(const(b2Vec2)* points, int count, float radius, b2Vec2 position, b2Rot rotation);

// Chain
b2ChainDef b2DefaultChainDef();
b2ChainId b2CreateChain(b2BodyId bodyId, const(b2ChainDef)* def);
void b2DestroyChain(b2ChainId chainId);
bool b2Chain_IsValid(b2ChainId id);
int b2Chain_GetSegmentCount(b2ChainId chainId);
int b2Chain_GetSegments(b2ChainId chainId, b2ShapeId* segmentArray, int capacity);
version (Box2D_3_1) {
    void b2Chain_SetFriction(b2ChainId chainId, float friction);
    void b2Chain_SetRestitution(b2ChainId chainId, float restitution);
} else {
    void b2Chain_SetAllSurfaceMaterials(b2ChainId chainId, const(b2SurfaceMaterial)* material);
    void b2Chain_SetSurfaceMaterial(b2ChainId chainId, const(b2SurfaceMaterial)* material, int segmentIndex);
    b2SurfaceMaterial b2Chain_GetSurfaceMaterial(b2ChainId chainId, int segmentIndex);
}

// Extra shapes / queries
b2RayResult b2World_CastRayClosest(b2WorldId worldId, b2Pos origin, b2Vec2 translation, b2QueryFilter filter);
version (Box2D_3_1) {
    b2TreeStats b2World_OverlapAABB(b2WorldId worldId, b2AABB aabb, b2QueryFilter filter, b2OverlapResultFcn fcn, void* context);
    b2TreeStats b2World_OverlapShape(b2WorldId worldId, const(b2ShapeProxy)* proxy, b2QueryFilter filter, b2OverlapResultFcn fcn, void* context);
    b2TreeStats b2World_CastShape(b2WorldId worldId, const(b2ShapeProxy)* proxy, b2Vec2 translation, b2QueryFilter filter, b2CastResultFcn fcn, void* context);
} else {
    b2ShapeId b2CreateChainSegmentShape(b2BodyId bodyId, const(b2ShapeDef)* def, const(b2ChainSegment)* chainSegment);
    b2TreeStats b2World_OverlapAABB(b2WorldId worldId, b2Pos origin, b2AABB aabb, b2QueryFilter filter, b2OverlapResultFcn fcn, void* context);
    b2TreeStats b2World_OverlapShape(b2WorldId worldId, b2Pos origin, const(b2ShapeProxy)* proxy, b2QueryFilter filter, b2OverlapResultFcn fcn, void* context);
    b2TreeStats b2World_CastShape(b2WorldId worldId, b2Pos origin, const(b2ShapeProxy)* proxy, b2Vec2 translation, b2QueryFilter filter, b2CastResultFcn fcn, void* context);
}

// Filter / motor joints
b2FilterJointDef b2DefaultFilterJointDef();
b2JointId b2CreateFilterJoint(b2WorldId worldId, const(b2FilterJointDef)* def);
b2MotorJointDef b2DefaultMotorJointDef();
b2JointId b2CreateMotorJoint(b2WorldId worldId, const(b2MotorJointDef)* def);

// Mouse joint (3.1.1 only) and mover / pogo joints (main only)
version (Box2D_3_1) {
    b2MouseJointDef b2DefaultMouseJointDef();
    b2JointId b2CreateMouseJoint(b2WorldId worldId, const(b2MouseJointDef)* def);
} else {
    b2MoverJointDef b2DefaultMoverJointDef();
    b2JointId b2CreateMoverJoint(b2WorldId worldId, const(b2MoverJointDef)* def);
    b2PogoJointDef b2DefaultPogoJointDef();
    b2JointId b2CreatePogoJoint(b2WorldId worldId, const(b2PogoJointDef)* def);
}

// Extra body helpers
void b2Body_SetName(b2BodyId bodyId, const(char)* name);
const(char)* b2Body_GetName(b2BodyId bodyId);
float b2Body_GetRotationalInertia(b2BodyId bodyId);
void b2Body_SetLinearDamping(b2BodyId bodyId, float linearDamping);
float b2Body_GetLinearDamping(b2BodyId bodyId);
void b2Body_SetAngularDamping(b2BodyId bodyId, float angularDamping);
float b2Body_GetAngularDamping(b2BodyId bodyId);
void b2Body_SetGravityScale(b2BodyId bodyId, float gravityScale);
float b2Body_GetGravityScale(b2BodyId bodyId);
version (Box2D_3_1) {
    b2Vec2 b2Body_GetLocalCenterOfMass(b2BodyId bodyId);
    b2Pos b2Body_GetWorldCenterOfMass(b2BodyId bodyId);
    void b2Body_ApplyMassFromShapes(b2BodyId bodyId);
} else {
    b2Vec2 b2Body_GetLocalCenter(b2BodyId bodyId);
    b2Pos b2Body_GetWorldCenter(b2BodyId bodyId);
    void b2Body_UpdateMassFromShapes(b2BodyId bodyId);
}

// Contact (main only)
version (Box2D_3_1) {} else {
    bool b2Contact_IsValid(b2ContactId id);
    b2ContactData b2Contact_GetData(b2ContactId contactId);
}
