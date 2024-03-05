// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

module popka.core.math;

/// The math module covers essential mathematical operations, vectors, and shapes like rectangles.

import math = core.stdc.math;

enum Flip {
    none, x, y, xy,
}

enum Hook {
    topLeft, top, topRight,
    left, center, right,
    bottomLeft, bottom, bottomRight,
}

struct Vec2 {
    float x = 0.0f;
    float y = 0.0f;
    
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

    Vec2 opUnary(string op)() {
        Vec2 result = void;
        result.x = mixin(op ~ "x");
        result.y = mixin(op ~ "y");
        return result;
    }

    Vec2 opBinary(string op)(Vec2 rhs) {
        Vec2 result = void;
        result.x = mixin("x" ~ op ~ "rhs.x");
        result.y = mixin("y" ~ op ~ "rhs.y");
        return result;
    }

    void opOpAssign(string op)(Vec2 rhs) {
        mixin("x" ~ op ~ "=" ~ "rhs.x;");
        mixin("y" ~ op ~ "=" ~ "rhs.y;");
    }

    Vec2 floor() {
        return Vec2(x.floor, y.floor);
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
        Vec2 result;
        Vec2 offset = this.directionTo(to) * delta;
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

    this(Vec2 xy, float z) {
        this(xy.x, xy.y, z);
    }

    Vec3 opUnary(string op)() {
        Vec3 result = void;
        result.x = mixin(op ~ "x");
        result.y = mixin(op ~ "y");
        result.z = mixin(op ~ "z");
        return result;
    }

    Vec3 opBinary(string op)(Vec3 rhs) {
        Vec3 result = void;
        result.x = mixin("x" ~ op ~ "rhs.x");
        result.y = mixin("y" ~ op ~ "rhs.y");
        result.z = mixin("z" ~ op ~ "rhs.z");
        return result;
    }

    void opOpAssign(string op)(Vec3 rhs) {
        mixin("x" ~ op ~ "=" ~ "rhs.x;");
        mixin("y" ~ op ~ "=" ~ "rhs.y;");
        mixin("z" ~ op ~ "=" ~ "rhs.z;");
    }

    Vec3 floor() {
        return Vec3(x.floor, y.floor, z.floor);
    }
}

struct Vec4 {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    float w = 0.0f;

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

    Vec4 opUnary(string op)() {
        Vec4 result = void;
        result.x = mixin(op ~ "x");
        result.y = mixin(op ~ "y");
        result.z = mixin(op ~ "z");
        result.w = mixin(op ~ "w");
        return result;
    }

    Vec4 opBinary(string op)(Vec4 rhs) {
        Vec4 result = void;
        result.x = mixin("x" ~ op ~ "rhs.x");
        result.y = mixin("y" ~ op ~ "rhs.y");
        result.z = mixin("z" ~ op ~ "rhs.z");
        result.w = mixin("w" ~ op ~ "rhs.w");
        return result;
    }

    void opOpAssign(string op)(Vec4 rhs) {
        mixin("x" ~ op ~ "=" ~ "rhs.x;");
        mixin("y" ~ op ~ "=" ~ "rhs.y;");
        mixin("z" ~ op ~ "=" ~ "rhs.z;");
        mixin("w" ~ op ~ "=" ~ "rhs.w;");
    }

    Vec4 floor() {
        return Vec4(x.floor, y.floor, z.floor, w.floor);
    }
}

struct Rect {
    Vec2 position;
    Vec2 size;

    this(Vec2 position, Vec2 size) {
        this.position = position;
        this.size = size;
    }

    this(Vec2 size) {
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

    Rect floor() {
        Rect result = void;
        result.position = position.floor;
        result.size = size.floor;
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

    Rect rect(Hook hook) {
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

float sqrt(float x) {
    return math.sqrtf(x);
}

float min(float a, float b) {
    return a <= b ? a : b;
}

float max(float a, float b) {
    return a <= b ? b : a;
}

float sign(float x) {
    return x <= 0.0f ? -1.0f : 1.0f;
}

float abs(float x) {
    return x <= 0.0f ? -x : x;
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

float clamp(float x, float a, float b) {
    return x <= a ? a : x >= b ? b : x;
}

float wrap(float x, float a, float b) {
    auto result = x;
    while (result < a) {
        result += b - a;
    }
    while (result > b) {
        result -= b - a;
    }
    return result;
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

unittest {}
