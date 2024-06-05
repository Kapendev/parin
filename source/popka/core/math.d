// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The math module covers
/// essential mathematical operations, vectors, and shapes.

module popka.core.math;

private {
    @system @nogc nothrow extern(C):

    float sqrtf(float x);
    float sinf(float x);
    float cosf(float x);
}

@safe @nogc nothrow:

enum pi = 3.14159265358979323846f;

enum Hook : ubyte {
    topLeft, top, topRight,
    left, center, right,
    bottomLeft, bottom, bottomRight,
}

struct Vec2 {
    float x = 0.0f;
    float y = 0.0f;

    enum zero = Vec2(0.0f, 0.0f);
    enum one = Vec2(1.0f, 1.0f);

    @safe @nogc nothrow:

    pragma(inline, true)
    this(float x, float y) {
        this.x = x;
        this.y = y;
    }

    pragma(inline, true)
    this(float x) {
        this(x, x);
    }

    pragma(inline, true)
    this(float[2] xy) {
        this(xy[0], xy[1]);
    }

    pragma(inline, true)
    Vec2 opUnary(const(char)[] op)() {
        return Vec2(
            mixin(op, "x"),
            mixin(op, "y"),
        );
    }

    pragma(inline, true)
    Vec2 opBinary(const(char)[] op)(Vec2 rhs) {
        return Vec2(
            mixin("x", op, "rhs.x"),
            mixin("y", op, "rhs.y"),
        );
    }

    pragma(inline, true)
    Vec2 opBinary(const(char)[] op)(float rhs) {
        return Vec2(
            mixin("x", op, "rhs"),
            mixin("y", op, "rhs"),
        );
    }

    pragma(inline, true)
    Vec2 opBinaryRight(const(char)[] op)(float lhs) {
        return Vec2(
            mixin("lhs", op, "x"),
            mixin("lhs", op, "y"),
        );
    }

    pragma(inline, true)
    void opOpAssign(const(char)[] op)(Vec2 rhs) {
        mixin("x", op, "=rhs.x;");
        mixin("y", op, "=rhs.y;");
    }

    pragma(inline, true)
    void opOpAssign(const(char)[] op)(float rhs) {
        mixin("x", op, "=rhs;");
        mixin("y", op, "=rhs;");
    }

    Vec2 abs() {
        return Vec2(x.abs, y.abs);
    }

    Vec2 floor() {
        return Vec2(x.floor, y.floor);
    }

    Vec2 ceil() {
        return Vec2(x.ceil, y.ceil);
    }

    Vec2 round() {
        return Vec2(x.round, y.round);
    }

    float length() {
        return sqrt(x * x + y * y);
    }

    Vec2 normalize() {
        float l = length;
        if (l == 0.0f) {
            return Vec2();
        } else {
            return this / Vec2(l);
        }
    }

    Vec2 directionTo(Vec2 to) {
        return (to - this).normalize();
    }

    Vec2 moveTo(Vec2 to, Vec2 delta) {
        Vec2 result = void;
        Vec2 offset = this.directionTo(to) * delta;
        if (.abs(to.x - x) > .abs(offset.x)) {
            result.x = x + offset.x;
        } else {
            result.x = to.x;
        }
        if (.abs(to.y - y) > .abs(offset.y)) {
            result.y = y + offset.y;
        } else {
            result.y = to.y;
        }
        return result;
    }

    Vec2 moveTo(Vec2 to, Vec2 delta, float slowdown) {
        return Vec2(
            .moveTo(x, to.x, delta.x, slowdown),
            .moveTo(y, to.y, delta.y, slowdown),
        );
    }
}

struct Vec3 {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;

    enum zero = Vec3(0.0f, 0.0f, 0.0f);
    enum one = Vec3(1.0f, 1.0f, 1.0f);

    @safe @nogc nothrow:

    pragma(inline, true)
    this(float x, float y, float z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    pragma(inline, true)
    this(float x) {
        this(x, x, x);
    }

    pragma(inline, true)
    this(float[3] xyz) {
        this(xyz[0], xyz[1], xyz[2]);
    }

    pragma(inline, true)
    this(Vec2 xy, float z) {
        this(xy.x, xy.y, z);
    }

    pragma(inline, true)
    Vec3 opUnary(const(char)[] op)() {
        return Vec3(
            mixin(op, "x"),
            mixin(op, "y"),
            mixin(op, "z"),
        );
    }

    pragma(inline, true)
    Vec3 opBinary(const(char)[] op)(Vec3 rhs) {
        return Vec3(
            mixin("x", op, "rhs.x"),
            mixin("y", op, "rhs.y"),
            mixin("z", op, "rhs.z"),
        );
    }

    pragma(inline, true)
    Vec3 opBinary(const(char)[] op)(float rhs) {
        return Vec3(
            mixin("x", op, "rhs"),
            mixin("y", op, "rhs"),
            mixin("z", op, "rhs"),
        );
    }

    pragma(inline, true)
    Vec3 opBinaryRight(const(char)[] op)(float lhs) {
        return Vec3(
            mixin("lhs", op, "x"),
            mixin("lhs", op, "y"),
            mixin("lhs", op, "z"),
        );
    }

    pragma(inline, true)
    void opOpAssign(const(char)[] op)(Vec3 rhs) {
        mixin("x", op, "=rhs.x;");
        mixin("y", op, "=rhs.y;");
        mixin("z", op, "=rhs.z;");
    }

    pragma(inline, true)
    void opOpAssign(const(char)[] op)(float rhs) {
        mixin("x", op, "=rhs;");
        mixin("y", op, "=rhs;");
        mixin("z", op, "=rhs;");
    }

    Vec3 abs() {
        return Vec3(x.abs, y.abs, z.abs);
    }

    Vec3 floor() {
        return Vec3(x.floor, y.floor, z.floor);
    }

    Vec3 ceil() {
        return Vec3(x.ceil, y.ceil, z.ceil);
    }

    Vec3 round() {
        return Vec3(x.round, y.round, z.round);
    }
}

struct Vec4 {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    float w = 0.0f;

    enum zero = Vec4(0.0f, 0.0f, 0.0f, 0.0f);
    enum one = Vec4(1.0f, 1.0f, 1.0f, 1.0f);

    @safe @nogc nothrow:

    pragma(inline, true)
    this(float x, float y, float z, float w) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    pragma(inline, true)
    this(float x) {
        this(x, x, x, x);
    }

    pragma(inline, true)
    this(float[4] xyzw) {
        this(xyzw[0], xyzw[1], xyzw[2], xyzw[3]);
    }

    pragma(inline, true)
    Vec4 opUnary(const(char)[] op)() {
        return Vec4(
            mixin(op, "x"),
            mixin(op, "y"),
            mixin(op, "z"),
            mixin(op, "w"),
        );
    }

    pragma(inline, true)
    Vec4 opBinary(const(char)[] op)(Vec4 rhs) {
        return Vec4(
            mixin("x", op, "rhs.x"),
            mixin("y", op, "rhs.y"),
            mixin("z", op, "rhs.z"),
            mixin("w", op, "rhs.w"),
        );
    }

    pragma(inline, true)
    Vec4 opBinary(const(char)[] op)(float rhs) {
        return Vec4(
            mixin("x", op, "rhs"),
            mixin("y", op, "rhs"),
            mixin("z", op, "rhs"),
            mixin("w", op, "rhs"),
        );
    }

    pragma(inline, true)
    Vec4 opBinaryRight(const(char)[] op)(float lhs) {
        return Vec4(
            mixin("lhs", op, "x"),
            mixin("lhs", op, "y"),
            mixin("lhs", op, "z"),
            mixin("lhs", op, "w"),
        );
    }

    pragma(inline, true)
    void opOpAssign(const(char)[] op)(Vec4 rhs) {
        mixin("x", op, "=rhs.x;");
        mixin("y", op, "=rhs.y;");
        mixin("z", op, "=rhs.z;");
        mixin("w", op, "=rhs.w;");
    }

    pragma(inline, true)
    void opOpAssign(const(char)[] op)(float rhs) {
        mixin("x", op, "=rhs;");
        mixin("y", op, "=rhs;");
        mixin("z", op, "=rhs;");
        mixin("w", op, "=rhs;");
    }

    Vec4 abs() {
        return Vec4(x.abs, y.abs, z.abs, w.abs);
    }

    Vec4 floor() {
        return Vec4(x.floor, y.floor, z.floor, w.floor);
    }

    Vec4 ceil() {
        return Vec4(x.ceil, y.ceil, z.ceil, w.ceil);
    }

    Vec4 round() {
        return Vec4(x.round, y.round, z.round, w.round);
    }
}

struct Rect {
    Vec2 position;
    Vec2 size;

    enum zero = Rect(0.0f, 0.0f, 0.0f, 0.0f);
    enum one = Rect(1.0f, 1.0f, 1.0f, 1.0f);

    @safe @nogc nothrow:

    pragma(inline, true)
    this(Vec2 position, Vec2 size) {
        this.position = position;
        this.size = size;
    }

    pragma(inline, true)
    this(Vec2 size) {
        this(Vec2(), size);
    }

    pragma(inline, true)
    this(float x, float y, float w, float h) {
        this(Vec2(x, y), Vec2(w, h));
    }

    pragma(inline, true)
    this(float w, float h) {
        this(Vec2(), Vec2(w, h));
    }

    pragma(inline, true)
    this(Vec2 position, float w, float h) {
        this(position, Vec2(w, h));
    }

    pragma(inline, true)
    this(float x, float y, Vec2 size) {
        this(Vec2(x, y), size);
    }

    void fix() {
        if (size.x < 0.0f) {
            position.x = position.x + size.x;
            size.x = -size.x;
        }
        if (size.y < 0.0f) {
            position.y = position.y + size.y;
            size.y = -size.y;
        }
    }

    Rect floor() {
        Rect result = void;
        result.position = position.floor;
        result.size = size.floor;
        return result;
    }

    Rect ceil() {
        Rect result = void;
        result.position = position.ceil;
        result.size = size.ceil;
        return result;
    }

    Rect round() {
        Rect result = void;
        result.position = position.round;
        result.size = size.round;
        return result;
    }

    Vec2 origin(Hook hook) {
        final switch (hook) {
            case Hook.topLeft: return size * Vec2(0.0f, 0.0f);
            case Hook.top: return size * Vec2(0.5f, 0.0f);
            case Hook.topRight: return size * Vec2(1.0f, 0.0f);
            case Hook.left: return size * Vec2(0.0f, 0.5f);
            case Hook.center: return size * Vec2(0.5f, 0.5f);
            case Hook.right: return size * Vec2(1.0f, 0.5f);
            case Hook.bottomLeft: return size * Vec2(0.0f, 1.0f);
            case Hook.bottom: return size * Vec2(0.5f, 1.0f);
            case Hook.bottomRight: return size * Vec2(1.0f, 1.0f);
        }
    }

    Rect area(Hook hook) {
        Rect result = void;
        result.position = position - origin(hook);
        result.size = size;
        return result;
    }

    Vec2 point(Hook hook) {
        Vec2 result = void;
        result = position + origin(hook);
        return result;
    }

    Vec2 topLeftPoint() {
        return point(Hook.topLeft);
    }

    Vec2 topPoint() {
        return point(Hook.top);
    }

    Vec2 topRightPoint() {
        return point(Hook.topRight);
    }

    Vec2 leftPoint() {
        return point(Hook.left);
    }

    Vec2 centerPoint() {
        return point(Hook.center);
    }

    Vec2 rightPoint() {
        return point(Hook.right);
    }

    Vec2 bottomLeftPoint() {
        return point(Hook.bottomLeft);
    }

    Vec2 bottomPoint() {
        return point(Hook.bottom);
    }

    Vec2 bottomRightPoint() {
        return point(Hook.bottomRight);
    }

    Rect topLeftArea() {
        return area(Hook.topLeft);
    }

    Rect topArea() {
        return area(Hook.top);
    }

    Rect topRightArea() {
        return area(Hook.topRight);
    }

    Rect leftArea() {
        return area(Hook.left);
    }

    Rect centerArea() {
        return area(Hook.center);
    }

    Rect rightArea() {
        return area(Hook.right);
    }

    Rect bottomLeftArea() {
        return area(Hook.bottomLeft);
    }

    Rect bottomArea() {
        return area(Hook.bottom);
    }

    Rect bottomRightArea() {
        return area(Hook.bottomRight);
    }

    bool hasPoint(Vec2 point) {
        return (
            point.x >= position.x &&
            point.x <= position.x + size.x &&
            point.y >= position.y &&
            point.y <= position.y + size.y
        );
    }

    bool hasIntersection(Rect area) {
        return (
            position.x + size.x >= area.position.x &&
            position.x <= area.position.x + area.size.x &&
            position.y + size.y >= area.position.y &&
            position.y <= area.position.y + area.size.y
        );
    }

    Rect intersection(Rect area) {
        Rect result = void;
        if (!this.hasIntersection(area)) {
            result = Rect();
        } else {
            float maxY = max(position.x, area.position.x);
            float maxX = max(position.y, area.position.y);
            result.position.x = maxX;
            result.position.y = maxY;
            result.size.x = min(position.x + size.x, area.position.x + area.size.x) - maxX;
            result.size.y = min(position.y + size.y, area.position.y + area.size.y) - maxY;
        }
        return result;
    }

    Rect merger(Rect area) {
        Rect result = void;
        float minX = min(position.x, area.position.x);
        float minY = min(position.y, area.position.y);
        result.position.x = minX;
        result.position.y = minY;
        result.size.x = max(position.x + size.x, area.position.x + area.size.x) - minX;
        result.size.y = max(position.y + size.y, area.position.y + area.size.y) - minY;
        return result;
    }

    Rect addLeft(float amount) {
        position.x -= amount;
        size.x += amount;
        return Rect(position.x, position.y, amount, size.y);
    }

    Rect addRight(float amount) {
        float w = size.x;
        size.x += amount;
        return Rect(w, position.y, amount, size.y);
    }

    Rect addTop(float amount) {
        position.y -= amount;
        size.y += amount;
        return Rect(position.x, position.y, size.x, amount);
    }

    Rect addBottom(float amount) {
        float h = size.y;
        size.y += amount;
        return Rect(position.x, h, size.x, amount);
    }

    Rect subLeft(float amount) {
        float x = position.x;
        position.x = min(position.x + amount, position.x + size.x);
        size.x = max(size.x - amount, 0.0f);
        return Rect(x, position.y, amount, size.y);
    }

    Rect subRight(float amount) {
        size.x = max(size.x - amount, 0.0f);
        return Rect(position.x + size.x, position.y, amount, size.y);
    }

    Rect subTop(float amount) {
        float y = position.y;
        position.y = min(position.y + amount, position.y + size.y);
        size.y = max(size.y - amount, 0.0f);
        return Rect(position.x, y, size.x, amount);
    }

    Rect subBottom(float amount) {
        size.y = max(size.y - amount, 0.0f);
        return Rect(position.x, position.y + size.y, size.x, amount);
    }

    Rect addLeftRight(float amount) {
        this.addLeft(amount);
        this.addRight(amount);
        return this;
    }

    Rect addTopBottom(float amount) {
        this.addTop(amount);
        this.addBottom(amount);
        return this;
    }

    Rect addAll(float amount) {
        this.addLeftRight(amount);
        this.addTopBottom(amount);
        return this;
    }

    Rect subLeftRight(float amount) {
        this.subLeft(amount);
        this.subRight(amount);
        return this;
    }

    Rect subTopBottom(float amount) {
        this.subTop(amount);
        this.subBottom(amount);
        return this;
    }

    Rect subAll(float amount) {
        this.subLeftRight(amount);
        this.subTopBottom(amount);
        return this;
    }

    Rect left(float amount) {
        Rect temp = this;
        return temp.subLeft(amount);
    }

    Rect right(float amount) {
        Rect temp = this;
        return temp.subRight(amount);
    }

    Rect top(float amount) {
        Rect temp = this;
        return temp.subTop(amount);
    }

    Rect bottom(float amount) {
        Rect temp = this;
        return temp.subBottom(amount);
    }
}

struct Circ {
    Vec2 position;
    float radius = 0.0f;

    enum zero = Circ(0.0f, 0.0f, 0.0f);
    enum one = Circ(1.0f, 1.0f, 1.0f);

    @safe @nogc nothrow:

    this(Vec2 position, float radius) {
        this.position = position;
        this.radius = radius;
    }

    this(float x, float y, float radius) {
        this(Vec2(x, y), radius);
    }
}

T min(T)(T a, T b) {
    return a < b ? a : b;
}

T max(T)(T a, T b) {
    return a < b ? b : a;
}

T sign(T)(T x) {
    return x < 0 ? -1 : 1;
}

T abs(T)(T x) {
    return x < 0 ? -x : x;
}

T clamp(T)(T x, T a, T b) {
    return x <= a ? a : x >= b ? b : x;
}

T wrap(T)(T x, T a, T b) {
    auto result = x;
    while (result < a) {
        result += b - a;
    }
    while (result > b) {
        result -= b - a;
    }
    return result;
}

float floor(float x) {
    float xx = cast(float) cast(int) x;
    return (x <= 0.0f && xx != x) ? xx - 1.0f : xx;
}

float ceil(float x) {
    float xx = cast(float) cast(int) x;
    return (x <= 0.0f || xx == x) ? xx : xx + 1.0f;
}

float round(float x) {
    return x <= 0.0f ? cast(float) cast(int) (x - 0.5f) : cast(float) cast(int) (x + 0.5f);
}

@trusted
float sqrt(float x) {
    return sqrtf(x);
}

@trusted
float sin(float x) {
    return sinf(x);
}

@trusted
float cos(float x) {
    return cosf(x);
}

float lerp(float from, float to, float weight) {
    return from + (to - from) * weight;
}

float smoothstep(float from, float to, float weight) {
    float v = weight * weight * (3.0f - 2.0f * weight);
    return (to * v) + (from * (1.0f - v));
}

float smootherstep(float from, float to, float weight) {
    float v = weight * weight * weight * (weight * (weight * 6.0f - 15.0f) + 10.0f);
    return (to * v) + (from * (1.0f - v));
}

float moveTo(float from, float to, float delta) {
    if (abs(to - from) > abs(delta)) return from + sign(to - from) * delta;
    else return to;
}

float moveTo(float from, float to, float delta, float slowdown) {
    float target = ((from * (slowdown - 1.0f)) + to) / slowdown;
    float offset = target - from;
    if (abs(offset) > abs(delta)) return from + offset * delta;
    else return to;
}
