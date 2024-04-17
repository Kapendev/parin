// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The math module covers
/// essential mathematical operations, vectors, and shapes.

module popka.core.math;

import math = core.stdc.math;

@safe @nogc nothrow:

enum pi = 3.141592f;

enum Hook : ubyte {
    topLeft, top, topRight,
    left, center, right,
    bottomLeft, bottom, bottomRight,
}

struct Vector2 {
    float x = 0.0f;
    float y = 0.0f;
    
    @safe @nogc nothrow:

    this(float x, float y) {
        this.x = x;
        this.y = y;
    }

    this(float x) {
        this(x, x);
    }

    this(float[2] xy) {
        this(xy[0], xy[1]);
    }

    Vector2 opUnary(string op)() {
        Vector2 result = void;
        result.x = mixin(op ~ "x");
        result.y = mixin(op ~ "y");
        return result;
    }

    Vector2 opBinary(string op)(Vector2 rhs) {
        Vector2 result = void;
        result.x = mixin("x" ~ op ~ "rhs.x");
        result.y = mixin("y" ~ op ~ "rhs.y");
        return result;
    }

    void opOpAssign(string op)(Vector2 rhs) {
        mixin("x" ~ op ~ "=" ~ "rhs.x;");
        mixin("y" ~ op ~ "=" ~ "rhs.y;");
    }

    Vector2 floor() {
        return Vector2(x.floor, y.floor);
    }

    float length() {
        return sqrt(x * x + y * y);
    }

    Vector2 normalize() {
        float l = length;
        if (l == 0.0f) {
            return Vector2();
        } else {
            return this / Vector2(l);
        }
    }

    Vector2 directionTo(Vector2 to) {
        return (to - this).normalize();
    }

    Vector2 moveTo(Vector2 to, Vector2 delta) {
        Vector2 result;
        Vector2 offset = this.directionTo(to) * delta;
        if (abs(to.x - x) > abs(offset.x)) {
            result.x = x + offset.x;
        } else {
            result.x = to.x;
        }
        if (abs(to.y - y) > abs(offset.y)) {
            result.y = y + offset.y;
        } else {
            result.y = to.y;
        }
        return result;
    }

    Vector2 moveTo(Vector2 to, Vector2 delta, float slowdown) {
        return Vector2(
            .moveTo(x, to.x, delta.x, slowdown),
            .moveTo(y, to.y, delta.y, slowdown),
        );
    }
}

struct Vector3 {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;

    @safe @nogc nothrow:

    this(float x, float y, float z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    this(float x) {
        this(x, x, x);
    }

    this(float[3] xyz) {
        this(xyz[0], xyz[1], xyz[2]);
    }

    this(Vector2 xy, float z) {
        this(xy.x, xy.y, z);
    }

    Vector3 opUnary(string op)() {
        Vector3 result = void;
        result.x = mixin(op ~ "x");
        result.y = mixin(op ~ "y");
        result.z = mixin(op ~ "z");
        return result;
    }

    Vector3 opBinary(string op)(Vector3 rhs) {
        Vector3 result = void;
        result.x = mixin("x" ~ op ~ "rhs.x");
        result.y = mixin("y" ~ op ~ "rhs.y");
        result.z = mixin("z" ~ op ~ "rhs.z");
        return result;
    }

    void opOpAssign(string op)(Vector3 rhs) {
        mixin("x" ~ op ~ "=" ~ "rhs.x;");
        mixin("y" ~ op ~ "=" ~ "rhs.y;");
        mixin("z" ~ op ~ "=" ~ "rhs.z;");
    }

    Vector3 floor() {
        return Vector3(x.floor, y.floor, z.floor);
    }
}

struct Vector4 {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    float w = 0.0f;

    @safe @nogc nothrow:

    this(float x, float y, float z, float w) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    this(float x) {
        this(x, x, x, x);
    }

    this(float[4] xyzw) {
        this(xyzw[0], xyzw[1], xyzw[2], xyzw[3]);
    }

    Vector4 opUnary(string op)() {
        Vector4 result = void;
        result.x = mixin(op ~ "x");
        result.y = mixin(op ~ "y");
        result.z = mixin(op ~ "z");
        result.w = mixin(op ~ "w");
        return result;
    }

    Vector4 opBinary(string op)(Vector4 rhs) {
        Vector4 result = void;
        result.x = mixin("x" ~ op ~ "rhs.x");
        result.y = mixin("y" ~ op ~ "rhs.y");
        result.z = mixin("z" ~ op ~ "rhs.z");
        result.w = mixin("w" ~ op ~ "rhs.w");
        return result;
    }

    void opOpAssign(string op)(Vector4 rhs) {
        mixin("x" ~ op ~ "=" ~ "rhs.x;");
        mixin("y" ~ op ~ "=" ~ "rhs.y;");
        mixin("z" ~ op ~ "=" ~ "rhs.z;");
        mixin("w" ~ op ~ "=" ~ "rhs.w;");
    }

    Vector4 floor() {
        return Vector4(x.floor, y.floor, z.floor, w.floor);
    }
}

struct Rectangle {
    Vector2 position;
    Vector2 size;

    @safe @nogc nothrow:

    this(Vector2 position, Vector2 size) {
        this.position = position;
        this.size = size;
    }

    this(Vector2 size) {
        this.size = size;
    }

    this(float x, float y, float w, float h) {
        this.position.x = x;
        this.position.y = y;
        this.size.x = w;
        this.size.y = h;
    }

    this(float w, float h) {
        this.size.x = w;
        this.size.y = h;
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

    Rectangle floor() {
        Rectangle result = void;
        result.position = position.floor;
        result.size = size.floor;
        return result;
    }

    Vector2 origin(Hook hook) {
        final switch (hook) {
            case Hook.topLeft: return size * Vector2(0.0f, 0.0f);
            case Hook.top: return size * Vector2(0.5f, 0.0f);
            case Hook.topRight: return size * Vector2(1.0f, 0.0f);
            case Hook.left: return size * Vector2(0.0f, 0.5f);
            case Hook.center: return size * Vector2(0.5f, 0.5f);
            case Hook.right: return size * Vector2(1.0f, 0.5f);
            case Hook.bottomLeft: return size * Vector2(0.0f, 1.0f);
            case Hook.bottom: return size * Vector2(0.5f, 1.0f);
            case Hook.bottomRight: return size * Vector2(1.0f, 1.0f);
        }
    }

    Rectangle rectangle(Hook hook) {
        Rectangle result = void;
        result.position = position - origin(hook);
        result.size = size;
        return result;
    }

    Vector2 point(Hook hook) {
        Vector2 result = void;
        result = position + origin(hook);
        return result;
    }

    bool hasPoint(Vector2 point) {
        return (
            point.x >= position.x &&
            point.x <= position.x + size.x &&
            point.y >= position.y &&
            point.y <= position.y + size.y
        );
    }

    bool hasIntersection(Rectangle area) {
        return (
            position.x + size.x >= area.position.x &&
            position.x <= area.position.x + area.size.x &&
            position.y + size.y >= area.position.y &&
            position.y <= area.position.y + area.size.y
        );
    }

    Rectangle intersection(Rectangle area) {
        Rectangle result = void;
        if (!this.hasIntersection(area)) {
            result = Rectangle();
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

    Rectangle merger(Rectangle area) {
        Rectangle result = void;
        float minX = min(position.x, area.position.x);
        float minY = min(position.y, area.position.y);
        result.position.x = minX;
        result.position.y = minY;
        result.size.x = max(position.x + size.x, area.position.x + area.size.x) - minX;
        result.size.y = max(position.y + size.y, area.position.y + area.size.y) - minY;
        return result;
    }

    Rectangle addLeft(float amount) {
        position.x -= amount;
        size.x += amount;
        return Rectangle(position.x, position.y, amount, size.y);
    }

    Rectangle addRight(float amount) {
        float w = size.x;
        size.x += amount;
        return Rectangle(w, position.y, amount, size.y);
    }

    Rectangle addTop(float amount) {
        position.y -= amount;
        size.y += amount;
        return Rectangle(position.x, position.y, size.x, amount);
    }

    Rectangle addBottom(float amount) {
        float h = size.y;
        size.y += amount;
        return Rectangle(position.x, h, size.x, amount);
    }

    Rectangle subLeft(float amount) {
        float x = position.x;
        position.x = min(position.x + amount, position.x + size.x);
        size.x = max(size.x - amount, 0.0f);
        return Rectangle(x, position.y, amount, size.y);
    }

    Rectangle subRight(float amount) {
        size.x = max(size.x - amount, 0.0f);
        return Rectangle(position.x + size.x, position.y, amount, size.y);
    }

    Rectangle subTop(float amount) {
        float y = position.y;
        position.y = min(position.y + amount, position.y + size.y);
        size.y = max(size.y - amount, 0.0f);
        return Rectangle(position.x, y, size.x, amount);
    }

    Rectangle subBottom(float amount) {
        size.y = max(size.y - amount, 0.0f);
        return Rectangle(position.x, position.y + size.y, size.x, amount);
    }

    void addLeftRight(float amount) {
        this.addLeft(amount);
        this.addRight(amount);
    }

    void addTopBottom(float amount) {
        this.addTop(amount);
        this.addBottom(amount);
    }

    void addAll(float amount) {
        this.addLeftRight(amount);
        this.addTopBottom(amount);
    }

    void subLeftRight(float amount) {
        this.subLeft(amount);
        this.subRight(amount);
    }

    void subTopBottom(float amount) {
        this.subTop(amount);
        this.subBottom(amount);
    }

    void subAll(float amount) {
        this.subLeftRight(amount);
        this.subTopBottom(amount);
    }

    Rectangle left(float amount) {
        Rectangle temp = this;
        return temp.subLeft(amount);
    }

    Rectangle right(float amount) {
        Rectangle temp = this;
        return temp.subRight(amount);
    }

    Rectangle top(float amount) {
        Rectangle temp = this;
        return temp.subTop(amount);
    }

    Rectangle bottom(float amount) {
        Rectangle temp = this;
        return temp.subBottom(amount);
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

float sqrt(float x) {
    return math.sqrtf(x);
}

float sin(float x) {
    return math.sinf(x);
}

float cos(float x) {
    return math.cosf(x);
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
    return from + (target - from) * delta;
}
