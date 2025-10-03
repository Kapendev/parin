// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `math` module provides mathematical data structures and functions.
module joka.math;

import joka.ascii;
import joka.types;
import stdc = joka.stdc.math;

// I don't care about `pure`, but I'm a nice person.
@safe nothrow @nogc pure:

enum epsilon = 0.0001;                                /// The value of epsilon.
enum euler   = 2.71828182845904523536028747135266249; /// The value of Euler's number.
enum log2e   = 1.44269504088896340735992468100189214; /// The value of log2(e).
enum log10e  = 0.43429448190325182765112891891660508; /// The value of log10(e).
enum ln2     = 0.69314718055994530941723212145817656; /// The value of ln(2).
enum ln10    = 2.30258509299404568401799145468436421; /// The value of ln(10).
enum pi      = 3.14159265358979323846264338327950288; /// The value of PI.
enum pi2     = pi / 2.0;                              /// The value of PI / 2.
enum pi4     = pi / 4.0;                              /// The value of PI / 4.
enum pi180   = pi / 180.0;                            /// The value of PI / 180.
enum dpi     = 1.0 / pi;                              /// The value of 1 / PI.
enum dpi2    = 2.0 / pi;                              /// The value of 2 / PI.
enum dpi180  = 180.0 / pi;                            /// The value of 180 / PI.
enum sqrt2   = 1.41421356237309504880168872420969808; /// The value of sqrt(2).
enum dsqrt2  = 0.70710678118654752440084436210484903; /// The value of 1 / sqrt(2).

enum blank   = Rgba();              /// Not a color.
enum black   = Rgba(0);             /// Black black.
enum white   = Rgba(255);           /// White white.
enum red     = Rgba(255, 0, 0);     /// Red red.
enum green   = Rgba(0, 255, 0);     /// Green green.
enum blue    = Rgba(0, 0, 255);     /// Blue blue.
enum yellow  = Rgba(255, 255, 0);   /// Yellow yellow.
enum magenta = Rgba(255, 0, 255);   /// Magenta magenta.
enum pink    = Rgba(255, 192, 204); /// Pink pink.
enum cyan    = Rgba(0, 255, 255);   /// Cyan cyan.
enum orange  = Rgba(255, 165, 0);   /// Orange orange.
enum beige   = Rgba(240, 235, 210); /// Beige beige.
enum brown   = Rgba(165, 72, 42);   /// Brown brown.
enum maroon  = Rgba(128, 0, 0);     /// Maroon maroon.
enum gray1   = Rgba(32, 32, 32);    /// Gray 1.
enum gray2   = Rgba(96, 96, 96);    /// Gray 22.
enum gray3   = Rgba(159, 159, 159); /// Gray 333.
enum gray4   = Rgba(223, 223, 223); /// Gray 4444.
enum gray    = gray2;               /// Gray gray.

alias Color = Rgba;         /// The common color type.

alias BVec2 = GVec2!byte;   /// A 2D vector using bytes.
alias IVec2 = GVec2!int;    /// A 2D vector using ints.
alias UVec2 = GVec2!uint;   /// A 2D vector using uints.
alias Vec2 = GVec2!float;   /// A 2D vector using floats.
alias DVec2 = GVec2!double; /// A 2D vector using doubles.

alias BVec3 = GVec3!byte;   /// A 3D vector using bytes.
alias IVec3 = GVec3!int;    /// A 3D vector using ints.
alias UVec3 = GVec3!uint;   /// A 3D vector using uints.
alias Vec3 = GVec3!float;   /// A 3D vector using floats.
alias DVec3 = GVec3!double; /// A 3D vector using doubles.

alias BVec4 = GVec4!byte;   /// A 4D vector using bytes.
alias IVec4 = GVec4!int;    /// A 4D vector using ints.
alias UVec4 = GVec4!uint;   /// A 4D vector using uints.
alias Vec4 = GVec4!float;   /// A 4D vector using floats.
alias DVec4 = GVec4!double; /// A 4D vector using doubles.

alias BRect = GRect!byte;   /// A 2D rectangle using bytes.
alias IRect = GRect!int;    /// A 2D rectangle using ints.
alias URect = GRect!uint;   /// A 2D rectangle using uints.
alias Rect = GRect!float;   /// A 2D rectangle using floats.
alias DRect = GRect!double; /// A 2D rectangle using doubles.

alias BCirc = GCirc!byte;   /// A 2D circle using bytes.
alias ICirc = GCirc!int;    /// A 2D circle using ints.
alias UCirc = GCirc!uint;   /// A 2D circle using uints.
alias Circ = GCirc!float;   /// A 2D circle using floats.
alias DCirc = GCirc!double; /// A 2D circle using doubles.

alias BLine = GLine!byte;   /// A 2D line using bytes.
alias ILine = GLine!int;    /// A 2D line using ints.
alias ULine = GLine!uint;   /// A 2D line using uints.
alias Line = GLine!float;   /// A 2D line using floats.
alias DLine = GLine!double; /// A 2D line using doubles.

alias Tween = GTween!float;   /// A tween using floats.
alias Tween2 = GTween!Vec2;   /// A tween using 2D vectors.
alias Tween3 = GTween!Vec3;   /// A tween using 3D vectors.
alias Tween4 = GTween!Vec4;   /// A tween using 4D vectors.
alias DTween = GTween!double; /// A tween using doubles.
alias DTween2 = GTween!DVec2; /// A tween using 2D vectors with doubles.
alias DTween3 = GTween!DVec3; /// A tween using 3D vectors with doubles.
alias DTween4 = GTween!DVec4; /// A tween using 4D vectors with doubles.

alias EaseFunc = float function(float x); /// A function used for easing.

/// A type representing easing functions.
enum Ease : ubyte {
    linear,
    inSine,
    outSine,
    inOutSine,
    inCubic,
    outCubic,
    inOutCubic,
    inQuint,
    outQuint,
    inOutQuint,
    inCirc,
    outCirc,
    inOutCirc,
    inElastic,
    outElastic,
    inOutElastic,
    inQuad,
    outQuad,
    inOutQuad,
    inQuart,
    outQuart,
    inOutQuart,
    inExpo,
    outExpo,
    inOutExpo,
    inBack,
    outBack,
    inOutBack,
    inBounce,
    outBounce,
    inOutBounce,
}

/// A type that describes how a tween should update.
enum TweenMode : ubyte {
    bomb, /// It stops updating when it reaches the beginning or end of the animation.
    loop, /// It returns to the beginning or end of the animation when it reaches the beginning or end of the animation.
    yoyo, /// It reverses the given delta time when it reaches the beginning or end of the animation.
}

/// A type representing relative points.
enum Hook : ubyte {
    topLeft,     /// The top left point.
    top,         /// The top point.
    topRight,    /// The top right point.
    left,        /// The left point.
    center,      /// The center point.
    right,       /// The right point.
    bottomLeft,  /// The bottom left point.
    bottom,      /// The bottom point.
    bottomRight, /// The bottom right point.
}

/// A RGBA color using ubytes.
struct Rgba {
    ubyte r; /// The R component of the color.
    ubyte g; /// The G component of the color.
    ubyte b; /// The B component of the color.
    ubyte a; /// The A component of the color.

    enum length = 4;              /// The component count of the color.
    enum form = "rgba";           /// The form of the color.
    enum zero = Rgba(0, 0, 0, 0); /// The zero value of the color.
    enum one = Rgba(1, 1, 1, 1);  /// The one value of the color.

    @safe nothrow @nogc:

    IStr toStr() {
        return "({} {} {} {})".fmt(r, g, b, a);
    }

    IStr toString() {
        return toStr();
    }

    @safe nothrow @nogc pure:

    mixin addXyzwOps!(Rgba, ubyte, length, form);

    pragma(inline, true)
    this(ubyte r, ubyte g, ubyte b, ubyte a = 255) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    pragma(inline, true)
    this(ubyte r) {
        this(r, r, r, 255);
    }

    pragma(inline, true) @trusted
    ubyte[] items() {
        return (cast(ubyte*) &this)[0 .. length];
    }

    pragma(inline, true)
    bool isZero() {
        return r == 0 && g == 0 && b == 0 && a == 0;
    }

    pragma(inline, true)
    bool isOne() {
        return r == 1 && g == 1 && b == 1 && a == 1;
    }

    /// Returns a color with just the alpha modified.
    Rgba alpha(ubyte value) {
        return Rgba(r, g, b, value);
    }
}

/// A generic 2D vector.
struct GVec2(T) {
    T x = 0; /// The X component of the vector.
    T y = 0; /// The Y component of the vector.

    enum length = 2;        /// The component count of the vector.
    enum form = "xy";       /// The form of the vector.
    enum zero = GVec2!T(0); /// The zero value of the vector.
    enum one = GVec2!T(1);  /// The one value of the vector.

    static if (T.sizeof > float.sizeof) {
        enum is64 = true;
        alias Float = double;
    } else {
        enum is64 = false;
        alias Float = float;
    }

    @safe nothrow @nogc:

    IStr toStr() {
        return "({} {})".fmt(x, y);
    }

    IStr toString() {
        return toStr();
    }

    @safe nothrow @nogc pure:

    mixin addXyzwOps!(GVec2!T, T, length, form);

    pragma(inline, true) {
        this(T x, T y) {
            this.x = x;
            this.y = y;
        }

        this(T x) {
            this(x, x);
        }

        @trusted T[] items() => (cast(T*) &this)[0 .. length];
        bool isZero() => x == 0 && y == 0;
        bool isOne() => x == 1 && y == 1;
        T chop() => x;
        GVec2!T abs() => GVec2!T(x.abs, y.abs);

        GVec2!T floor() {
            static if (isIntegerType!T) {
                return this;
            } else {
                static if (is64) {
                    return GVec2!T(x.floor64, y.floor64);
                } else {
                    return GVec2!T(x.floor, y.floor);
                }
            }
        }

        GVec2!T ceil() {
            static if (isIntegerType!T) {
                return this;
            } else {
                static if (is64) {
                    return GVec2!T(x.ceil64, y.ceil64);
                } else {
                    return GVec2!T(x.ceil, y.ceil);
                }
            }
        }

        GVec2!T round() {
            static if (isIntegerType!T) {
                return this;
            } else {
                static if (is64) {
                    return GVec2!T(x.round64, y.round64);
                } else {
                    return GVec2!T(x.round, y.round);
                }
            }
        }

        GVec2!Float sqrt() {
            static if (is64) {
                return GVec2!Float(x.sqrt64, y.sqrt64);
            } else {
                return GVec2!Float(x.sqrt, y.sqrt);
            }
        }

        GVec2!Float sin() {
            static if (is64) {
                return GVec2!Float(x.sin64, y.sin64);
            } else {
                return GVec2!Float(x.sin, y.sin);
            }
        }

        GVec2!Float cos() {
            static if (is64) {
                return GVec2!Float(x.cos64, y.cos64);
            } else {
                return GVec2!Float(x.cos, y.cos);
            }
        }

        GVec2!Float tan() {
            static if (is64) {
                return GVec2!Float(x.tan64, y.tan64);
            } else {
                return GVec2!Float(x.tan, y.tan);
            }
        }

        GVec2!Float asin() {
            static if (is64) {
                return GVec2!Float(x.asin64, y.asin64);
            } else {
                return GVec2!Float(x.asin, y.asin);
            }
        }

        GVec2!Float acos() {
            static if (is64) {
                return GVec2!Float(x.acos64, y.acos64);
            } else {
                return GVec2!Float(x.acos, y.acos);
            }
        }

        GVec2!Float atan() {
            static if (is64) {
                return GVec2!Float(x.atan64, y.atan64);
            } else {
                return GVec2!Float(x.atan, y.atan);
            }
        }

        Float angle() {
            return atan2(y, x);
        }

        Float magnitude() {
            static if (is64) {
                return (x * x + y * y).sqrt64;
            } else {
                return (x * x + y * y).sqrt;
            }
        }

        Float magnitudeSquared() {
            return x * x + y * y;
        }
    }

    GVec2!Float normalize() {
        static if (isIntegerType!T) {
            return GVec2!Float(cast(Float) x, cast(Float) y).normalize();
        } else {
            auto m = magnitude;
            if (m == 0) return GVec2!Float();
            return this / GVec2!Float(m);
        }
    }

    Float distanceTo(GVec2!T to) {
        return (to - this).magnitude;
    }

    GVec2!Float directionTo(GVec2!T to) {
        static if (isIntegerType!T) {
            return (to - this).normalize();
        } else {
            return (to - this).normalize();
        }
    }
}

/// A generic 3D vector.
struct GVec3(T) {
    T x = 0; /// The X component of the vector.
    T y = 0; /// The Y component of the vector.
    T z = 0; /// The Z component of the vector.

    enum length = 3;        /// The component count of the vector.
    enum form = "xyz";      /// The form of the vector.
    enum zero = GVec3!T(0); /// The zero value of the vector.
    enum one = GVec3!T(1);  /// The one value of the vector.

    static if (T.sizeof > float.sizeof) {
        enum is64 = true;
        alias Float = double;
    } else {
        enum is64 = false;
        alias Float = float;
    }

    @safe nothrow @nogc:

    IStr toStr() {
        return "({} {} {})".fmt(x, y, z);
    }

    IStr toString() {
        return toStr();
    }

    @safe nothrow @nogc pure:

    mixin addXyzwOps!(GVec3!T, T, length, form);

    pragma(inline, true) {
        this(T x, T y, T z) {
            this.x = x;
            this.y = y;
            this.z = z;
        }

        this(T x) {
            this(x, x, x);
        }

        this(GVec2!T xy, T z) {
            this(xy.x, xy.y, z);
        }

        @trusted T[] items() => (cast(T*) &this)[0 .. length];
        bool isZero() => x == 0 && y == 0 && z == 0;
        bool isOne() => x == 1 && y == 1 && z == 1;
        GVec2!T chop() => GVec2!T(x, y);
        GVec3!T abs() => GVec3!T(x.abs, y.abs, z.abs);

        GVec3!T floor() {
            static if (isIntegerType!T) {
                return this;
            } else {
                static if (is64) {
                    return GVec3!T(x.floor64, y.floor64, z.floor64);
                } else {
                    return GVec3!T(x.floor, y.floor, z.floor);
                }
            }
        }

        GVec3!T ceil() {
            static if (isIntegerType!T) {
                return this;
            } else {
                static if (is64) {
                    return GVec3!T(x.ceil64, y.ceil64, z.ceil64);
                } else {
                    return GVec3!T(x.ceil, y.ceil, z.ceil);
                }
            }
        }

        GVec3!T round() {
            static if (isIntegerType!T) {
                return this;
            } else {
                static if (is64) {
                    return GVec3!T(x.round64, y.round64, z.round64);
                } else {
                    return GVec3!T(x.round, y.round, z.round);
                }
            }
        }

        GVec3!Float sqrt() {
            static if (is64) {
                return GVec3!Float(x.sqrt64, y.sqrt64, z.sqrt64);
            } else {
                return GVec3!Float(x.sqrt, y.sqrt, z.sqrt);
            }
        }

        GVec3!Float sin() {
            static if (is64) {
                return GVec3!Float(x.sin64, y.sin64, z.sin64);
            } else {
                return GVec3!Float(x.sin, y.sin, z.sin);
            }
        }

        GVec3!Float cos() {
            static if (is64) {
                return GVec3!Float(x.cos64, y.cos64, z.cos64);
            } else {
                return GVec3!Float(x.cos, y.cos, z.cos);
            }
        }

        GVec3!Float tan() {
            static if (is64) {
                return GVec3!Float(x.tan64, y.tan64, z.tan64);
            } else {
                return GVec3!Float(x.tan, y.tan, z.tan);
            }
        }

        GVec3!Float asin() {
            static if (is64) {
                return GVec3!Float(x.asin64, y.asin64, z.asin64);
            } else {
                return GVec3!Float(x.asin, y.asin, z.asin);
            }
        }

        GVec3!Float acos() {
            static if (is64) {
                return GVec3!Float(x.acos64, y.acos64, z.acos64);
            } else {
                return GVec3!Float(x.acos, y.acos, z.acos);
            }
        }

        GVec3!Float atan() {
            static if (is64) {
                return GVec3!Float(x.atan64, y.atan64, z.atan64);
            } else {
                return GVec3!Float(x.atan, y.atan, z.atan);
            }
        }

        Float magnitude() {
            static if (is64) {
                return (x * x + y * y + z * z).sqrt64;
            } else {
                return (x * x + y * y + z * z).sqrt;
            }
        }

        Float magnitudeSquared() {
            return x * x + y * y + z * z;
        }
    }

    GVec3!Float normalize() {
        static if (isIntegerType!T) {
            return GVec3!Float(cast(Float) x, cast(Float) y, cast(Float) z).normalize();
        } else {
            auto m = magnitude;
            if (m == 0.0) return GVec3!Float();
            return this / GVec3!Float(m);
        }
    }

    Float distanceTo(GVec3!T to) {
        return (to - this).magnitude;
    }

    GVec3!Float directionTo(GVec3!T to) {
        return (to - this).normalize();
    }
}

/// A generic 4D vector.
struct GVec4(T) {
    T x = 0; /// The X component of the vector.
    T y = 0; /// The Y component of the vector.
    T z = 0; /// The Z component of the vector.
    T w = 0; /// The W component of the vector.

    enum length = 4;        /// The component count of the vector.
    enum form = "xyzw";     /// The form of the vector.
    enum zero = GVec4!T(0); /// The zero value of the vector.
    enum one = GVec4!T(1);  /// The one value of the vector.

    static if (T.sizeof > float.sizeof) {
        enum is64 = true;
        alias Float = double;
    } else {
        enum is64 = false;
        alias Float = float;
    }

    @safe nothrow @nogc:

    IStr toStr() {
        return "({} {} {} {})".fmt(x, y, z, w);
    }

    IStr toString() {
        return toStr();
    }

    @safe nothrow @nogc pure:

    mixin addXyzwOps!(GVec4!T, T, length, form);

    pragma(inline, true) {
        this(T x, T y, T z, T w) {
            this.x = x;
            this.y = y;
            this.z = z;
            this.w = w;
        }

        this(T x) {
            this(x, x, x, x);
        }

        this(GVec2!T xy, GVec2!T zw) {
            this(xy.x, xy.y, zw.x, zw.y);
        }

        this(GVec3!T xyz, T w) {
            this(xyz.x, xyz.y, xyz.z, w);
        }

        @trusted T[] items() => (cast(T*) &this)[0 .. length];
        bool isZero() => x == 0 && y == 0 && z == 0 && w == 0;
        bool isOne() => x == 1 && y == 1 && z == 1 && w == 1;
        GVec3!T chop() => GVec3!T(x, y, z);
        GVec4!T abs() => GVec4!T(x.abs, y.abs, z.abs, w.abs);

        GVec4!T floor() {
            static if (isIntegerType!T) {
                return this;
            } else {
                static if (is64) {
                    return GVec4!T(x.floor64, y.floor64, z.floor64, w.floor64);
                } else {
                    return GVec4!T(x.floor, y.floor, z.floor, w.floor);
                }
            }
        }

        GVec4!T ceil() {
            static if (isIntegerType!T) {
                return this;
            } else {
                static if (is64) {
                    return GVec4!T(x.ceil64, y.ceil64, z.ceil64, w.ceil64);
                } else {
                    return GVec4!T(x.ceil, y.ceil, z.ceil, w.ceil);
                }
            }
        }

        GVec4!T round() {
            static if (isIntegerType!T) {
                return this;
            } else {
                static if (is64) {
                    return GVec4!T(x.round64, y.round64, z.round64, w.round64);
                } else {
                    return GVec4!T(x.round, y.round, z.round, w.round);
                }
            }
        }

        GVec4!Float sqrt() {
            static if (is64) {
                return GVec4!Float(x.sqrt64, y.sqrt64, z.sqrt64, w.sqrt64);
            } else {
                return GVec4!Float(x.sqrt, y.sqrt, z.sqrt, w.sqrt);
            }
        }

        GVec4!Float sin() {
            static if (is64) {
                return GVec4!Float(x.sin64, y.sin64, z.sin64, w.sin64);
            } else {
                return GVec4!Float(x.sin, y.sin, z.sin, w.sin);
            }
        }

        GVec4!Float cos() {
            static if (is64) {
                return GVec4!Float(x.cos64, y.cos64, z.cos64, w.cos64);
            } else {
                return GVec4!Float(x.cos, y.cos, z.cos, w.cos);
            }
        }

        GVec4!Float tan() {
            static if (is64) {
                return GVec4!Float(x.tan64, y.tan64, z.tan64, w.tan64);
            } else {
                return GVec4!Float(x.tan, y.tan, z.tan, w.tan);
            }
        }

        GVec4!Float asin() {
            static if (is64) {
                return GVec4!Float(x.asin64, y.asin64, z.asin64, w.asin64);
            } else {
                return GVec4!Float(x.asin, y.asin, z.asin, w.asin);
            }
        }

        GVec4!Float acos() {
            static if (is64) {
                return GVec4!Float(x.acos64, y.acos64, z.acos64, w.acos64);
            } else {
                return GVec4!Float(x.acos, y.acos, z.acos, w.acos);
            }
        }

        GVec4!Float atan() {
            static if (is64) {
                return GVec4!Float(x.atan64, y.atan64, z.atan64, w.atan64);
            } else {
                return GVec4!Float(x.atan, y.atan, z.atan, w.atan);
            }
        }

        Float magnitude() {
            static if (is64) {
                return (x * x + y * y + z * z + w * w).sqrt64;
            } else {
                return (x * x + y * y + z * z + w * w).sqrt;
            }
        }

        Float magnitudeSquared() {
            return x * x + y * y + z * z + w * w;
        }
    }

    GVec4!Float normalize() {
        static if (isIntegerType!T) {
            return GVec4!Float(cast(Float) x, cast(Float) y, cast(Float) z, cast(Float) w).normalize();
        } else {
            auto m = magnitude;
            if (m == 0.0) return GVec4!Float();
            return this / GVec4!Float(m);
        }
    }

    Float distanceTo(GVec4!T to) {
        return (to - this).magnitude;
    }

    GVec4!Float directionTo(GVec4!T to) {
        return (to - this).normalize();
    }
}

/// A generic 2D rectangle.
struct GRect(P, S = P) {
    static assert(P.sizeof >= S.sizeof, "Position type must be bigger than size type.");

    GVec2!P position; /// The position of the rectangle.
    GVec2!S size;     /// The size of the rectangle.

    alias Position = P;
    alias Size = S;
    alias Self = GRect!(P, S);
    static if (P.sizeof > float.sizeof) {
        enum is64 = true;
        alias Float = double;
    } else {
        enum is64 = false;
        alias Float = float;
    }

    @safe nothrow @nogc:

    IStr toStr() {
        return "{} {}".fmt(position, size);
    }

    IStr toString() {
        return toStr();
    }

    @safe nothrow @nogc pure:

    pragma(inline, true) {
        this(GVec2!P position, GVec2!S size) {
            this.position = position;
            this.size = size;
        }

        this(GVec2!S size) {
            this(GVec2!P(), size);
        }

        this(P x, P y, S w, S h) {
            this(GVec2!P(x, y), GVec2!S(w, h));
        }

        this(S w, S h) {
            this(GVec2!P(), GVec2!S(w, h));
        }

        this(GVec2!P position, S w, S h) {
            this(position, GVec2!S(w, h));
        }

        this(P x, P y, GVec2!S size) {
            this(GVec2!P(x, y), size);
        }

        static if (!is(P == S)) {
            this(GVec2!P position, GVec2!P size) {
                this.position = position;
                this.size.x = cast(S) size.x;
                this.size.y = cast(S) size.y;
            }

            this(GVec2!P size) {
                this(GVec2!P(), size);
            }

            this(P x, P y, P w, P h) {
                this(GVec2!P(x, y), GVec2!P(w, h));
            }

            this(P w, P h) {
                this(GVec2!P(), GVec2!P(w, h));
            }

            this(GVec2!P position, P w, P h) {
                this(position, GVec2!P(w, h));
            }

            this(P x, P y, GVec2!P size) {
                this(GVec2!P(x, y), size);
            }
        }

        /// The X position of the rectangle.
        @trusted ref P x() => position.x;
        /// The Y position of the rectangle.
        @trusted ref P y() => position.y;
        /// The width of the rectangle.
        @trusted ref S w() => size.x;
        /// The height of the rectangle.
        @trusted ref S h() => size.y;
        bool hasSize() => size.x != 0 && size.y != 0;
        Self abs() => Self(position.abs, size.abs);

        Self floor() {
            static if (isIntegerType!P) {
                return this;
            } else {
                return Self(position.floor, size.floor);
            }
        }

        Self ceil() {
            static if (isIntegerType!P) {
                return this;
            } else {
                return Self(position.ceil, size.ceil);
            }
        }

        Self round() {
            static if (isIntegerType!P) {
                return this;
            } else {
                return Self(position.round, size.round);
            }
        }

        Self area(Hook hook) {
            return Self(
                position - origin(hook),
                size,
            );
        }

        GVec2!P point(Hook hook) {
            return position + origin(hook);
        }

        GVec2!P topLeftPoint() {
            return point(Hook.topLeft);
        }

        GVec2!P topPoint() {
            return point(Hook.top);
        }

        GVec2!P topRightPoint() {
            return point(Hook.topRight);
        }

        GVec2!P leftPoint() {
            return point(Hook.left);
        }

        GVec2!P centerPoint() {
            return point(Hook.center);
        }

        GVec2!P rightPoint() {
            return point(Hook.right);
        }

        GVec2!P bottomLeftPoint() {
            return point(Hook.bottomLeft);
        }

        GVec2!P bottomPoint() {
            return point(Hook.bottom);
        }

        GVec2!P bottomRightPoint() {
            return point(Hook.bottomRight);
        }

        Self topLeftArea() {
            return area(Hook.topLeft);
        }

        Self topArea() {
            return area(Hook.top);
        }

        Self topRightArea() {
            return area(Hook.topRight);
        }

        Self leftArea() {
            return area(Hook.left);
        }

        Self centerArea() {
            return area(Hook.center);
        }

        Self rightArea() {
            return area(Hook.right);
        }

        Self bottomLeftArea() {
            return area(Hook.bottomLeft);
        }

        Self bottomArea() {
            return area(Hook.bottom);
        }

        Self bottomRightArea() {
            return area(Hook.bottomRight);
        }

        bool hasPoint(GVec2!P point) {
            return (
                point.x > position.x &&
                point.x < position.x + size.x &&
                point.y > position.y &&
                point.y < position.y + size.y
            );
        }

        bool hasPointInclusive(GVec2!P point) {
            return (
                point.x >= position.x &&
                point.x <= position.x + size.x &&
                point.y >= position.y &&
                point.y <= position.y + size.y
            );
        }

        bool hasIntersection(Self area) {
            return (
                position.x + size.x > area.position.x &&
                position.x < area.position.x + area.size.x &&
                position.y + size.y > area.position.y &&
                position.y < area.position.y + area.size.y
            );
        }

        bool hasIntersectionInclusive(Self area) {
            return (
                position.x + size.x >= area.position.x &&
                position.x <= area.position.x + area.size.x &&
                position.y + size.y >= area.position.y &&
                position.y <= area.position.y + area.size.y
            );
        }
    }

    void fix() {
        if (size.x < 0) {
            position.x = cast(P) (position.x + size.x);
            size.x = cast(S) (-size.x);
        }
        if (size.y < 0) {
            position.y = cast(P) (position.y + size.y);
            size.y = cast(S) (-size.y);
        }
    }

    GVec2!P origin(Hook hook) {
        static if (isIntegerType!P) {
            auto temp = GRect!Float(cast(Float) position.x, cast(Float) position.y, cast(Float) size.x, cast(Float) size.y).origin(hook);
            return GVec2!P(cast(P) temp.x, cast(P) temp.y);
        } else {
            final switch (hook) {
                case Hook.topLeft: return GVec2!P();
                case Hook.top: return size * GVec2!P(0.5f, 0.0f);
                case Hook.topRight: return size * GVec2!P(1.0f, 0.0f);
                case Hook.left: return size * GVec2!P(0.0f, 0.5f);
                case Hook.center: return size * GVec2!P(0.5f, 0.5f);
                case Hook.right: return size * GVec2!P(1.0f, 0.5f);
                case Hook.bottomLeft: return size * GVec2!P(0.0f, 1.0f);
                case Hook.bottom: return size * GVec2!P(0.5f, 1.0f);
                case Hook.bottomRight: return size;
            }
        }
    }

    Self intersection(Self area) {
        if (!this.hasIntersection(area)) {
            return Self();
        } else {
            auto maxY = max(position.x, area.position.x);
            auto maxX = max(position.y, area.position.y);
            return Self(
                maxX,
                maxY,
                cast(S) (min(position.x + size.x, area.position.x + area.size.x) - maxX),
                cast(S) (min(position.y + size.y, area.position.y + area.size.y) - maxY),
            );
        }
    }

    Self merger(Self area) {
        auto minX = min(position.x, area.position.x);
        auto minY = min(position.y, area.position.y);
        return Self(
            minX,
            minY,
            cast(S) (max(position.x + size.x, area.position.x + area.size.x) - minX),
            cast(S) (max(position.y + size.y, area.position.y + area.size.y) - minY),
        );
    }

    Self addLeft(P amount) {
        position.x -= amount;
        size.x += amount;
        return Self(position.x, position.y, cast(S) amount, size.y);
    }

    Self addRight(P amount) {
        auto w = size.x;
        size.x += amount;
        return Self(w, position.y, cast(S) amount, size.y);
    }

    Self addTop(P amount) {
        position.y -= amount;
        size.y += amount;
        return Self(position.x, position.y, size.x, cast(S) amount);
    }

    Self addBottom(P amount) {
        auto h = size.y;
        size.y += amount;
        return Self(position.x, h, size.x, cast(S) amount);
    }

    Self subLeft(P amount) {
        auto x = position.x;
        position.x = cast(P) min(position.x + amount, position.x + size.x);
        size.x = cast(S) max(size.x - amount, 0);
        return Self(x, position.y, cast(S) amount, size.y);
    }

    Self subRight(P amount) {
        size.x = cast(S) max(size.x - amount, 0);
        return Self(cast(P) (position.x + size.x), position.y, cast(S) amount, size.y);
    }

    Self subTop(P amount) {
        auto y = position.y;
        position.y = cast(P) min(position.y + amount, position.y + size.y);
        size.y = cast(S) max(size.y - amount, 0);
        return Self(position.x, y, size.x, cast(S) amount);
    }

    Self subBottom(P amount) {
        size.y = cast(S) max(size.y - amount, 0);
        return Self(position.x, cast(P) (position.y + size.y), size.x, cast(S) amount);
    }

    Self addLeftRight(P amount) {
        this.addLeft(amount);
        this.addRight(amount);
        return this;
    }

    Self addTopBottom(P amount) {
        this.addTop(amount);
        this.addBottom(amount);
        return this;
    }

    Self addAll(P amount) {
        this.addLeftRight(amount);
        this.addTopBottom(amount);
        return this;
    }

    Self subLeftRight(P amount) {
        this.subLeft(amount);
        this.subRight(amount);
        return this;
    }

    Self subTopBottom(P amount) {
        this.subTop(amount);
        this.subBottom(amount);
        return this;
    }

    Self subAll(P amount) {
        this.subLeftRight(amount);
        this.subTopBottom(amount);
        return this;
    }

    Self left(P amount) {
        Self temp = this;
        return temp.subLeft(amount);
    }

    Self right(P amount) {
        Self temp = this;
        return temp.subRight(amount);
    }

    Self top(P amount) {
        Self temp = this;
        return temp.subTop(amount);
    }

    Self bottom(P amount) {
        Self temp = this;
        return temp.subBottom(amount);
    }
}

/// A generic 2D Circle.
struct GCirc(T) {
    GVec2!T position; /// The position of the circle.
    T radius = 0;     /// The radius of the circle.

    static if (T.sizeof > float.sizeof) {
        enum is64 = true;
        alias Float = double;
    } else {
        enum is64 = false;
        alias Float = float;
    }

    @safe nothrow @nogc:

    IStr toStr() {
        return "{} ({})".fmt(position, radius);
    }

    IStr toString() {
        return toStr();
    }

    @safe nothrow @nogc pure:

    pragma(inline, true) {
        this(GVec2!T position, T radius) {
            this.position = position;
            this.radius = radius;
        }

        this(T x, T y, T radius) {
            this(GVec2!T(x, y), radius);
        }
    }
}

/// A generic 2D Line.
struct GLine(T) {
    GVec2!T a; /// The start point of the line.
    GVec2!T b; /// The end point of the line.

    @safe nothrow @nogc:

    IStr toStr() {
        return "{} {}".fmt(a, b);
    }

    IStr toString() {
        return toStr();
    }

    @safe nothrow @nogc pure:

    pragma(inline, true) {
        this(GVec2!T a, GVec2!T b) {
            this.a = a;
            this.b = b;
        }

        this(T ax, T ay, T bx, T by) {
            this(GVec2!T(ax, ay), GVec2!T(bx, by));
        }

        this(GVec2!T a, T bx, T by) {
            this(a, GVec2!T(bx, by));
        }

        this(T ax, T ay, GVec2!T b) {
            this(GVec2!T(ax, ay), b);
        }
    }
}

/// A generic tween handles the transition from one value to another based on a duration.
struct GTween(T) {
    T a;                   /// The first animation value.
    T b;                   /// The last animation value.
    float time = 0.0f;     /// The current time, in seconds.
    float duration = 0.0f; /// The duration, in seconds.
    TweenMode mode;        /// The mode of the animation.
    Ease type;             /// The function used to ease from the first to the last value.
    bool isYoyoing;        /// Controls if the delta given to the update function is reversed.

    @safe nothrow @nogc pure:

    /// Creates a new tween.
    this(T a, T b, float duration, TweenMode mode = TweenMode.bomb, Ease type = Ease.linear) {
        this.a = a;
        this.b = b;
        this.duration = duration;
        this.mode = mode;
        this.type = type;
    }

    /// Returns true if the current time is equal to zero.
    /// This function makes sense when the tween mode is set to bomb.
    bool isAtStart() {
        return time == 0.0f;
    }

    /// Returns true if the current time is equal to the duration.
    /// This function makes sense when the tween mode is set to bomb.
    bool isAtEnd() {
        return time >= duration;
    }

    /// Returns the current value.
    /// The value is between a and b.
    T now() {
        if (time <= 0.0f) {
            return a;
        } else if (time >= duration) {
            return b;
        } else {
            return a.lerp(b, ease(type)(progress));
        }
    }

    /// Updates the current time by the given delta and returns the current value.
    T update(float delta) {
        setTime(time + (isYoyoing ? -delta : delta));
        return now;
    }

    /// Resets the current time and returns the current value.
    T reset() {
        setTime(0.0f);
        return now;
    }

    /// Returns the current progress.
    /// The progress is between 0.0 and 1.0.
    float progress() {
        return duration == 0.0f ? 0.0f : clamp(time / duration, 0.0f, 1.0f);
    }

    /// Sets the current progress to a specific value.
    /// The progress is between 0.0 and 1.0.
    void setProgress(float value) {
        time = duration * clamp(value, 0.0f, 1.0f);
    }

    /// Sets the current time to a specific value.
    /// Takes the tween mode into account.
    void setTime(float value) {
        final switch (mode) {
            case TweenMode.bomb:
                time = clamp(value, 0.0f, duration);
                break;
            case TweenMode.loop:
                time = wrap(value, 0.0f, duration);
                break;
            case TweenMode.yoyo:
                time = clamp(value, 0.0f, duration);
                if (value < 0.0f) {
                    isYoyoing = false;
                } else if (value > duration) {
                    isYoyoing = true;
                }
                break;
        }
    }
}

// TODO: Add docs.
struct SmoothToggle {
    float progress = 0.0f;
    bool state;

    @safe nothrow @nogc pure:

    this(bool state) {
        this.state = state;
        this.progress = state ? 1.0f : 0.0f;
    }

    bool isAtStart() {
        return progress == 0.0f;
    }

    bool isAtEnd() {
        return progress == 1.0f;
    }

    float now() {
        if (progress <= 0.0f) {
            return 0.0f;
        } else if (progress >= 1.0f) {
            return 1.0f;
        } else {
            return progress;
        }
    }

    float update(float delta) {
        return progress.followState(state, delta);
    }

    float reset() {
        setProgress(0.0f);
        return now;
    }

    void setProgress(float value) {
        progress = clamp(value, 0.0f, 1.0f);
    }

    bool toggle() {
        state = !state;
        return state;
    }

    bool toggleSnap() {
        state = !state;
        progress = state ? 1.0f : 0.0f;
        return state;
    }
}

pragma(inline, true) @trusted {
    T abs(T)(T x) {
        return cast(T) (x < 0 ? -x : x);
    }

    T min(T)(T a, T b) {
        return a < b ? a : b;
    }

    T min3(T)(T a, T b, T c) {
        return min(a, b).min(c);
    }

    T min4(T)(T a, T b, T c, T d) {
        return min(a, b).min(c).min(d);
    }

    T max(T)(T a, T b) {
        return a < b ? b : a;
    }

    T max3(T)(T a, T b, T c) {
        return max(a, b).max(c);
    }

    T max4(T)(T a, T b, T c, T d) {
        return max(a, b).max(c).max(d);
    }

    T sign(T)(T x) {
        return x < 0
            ? -1
            : x > 0
            ? 1
            : 0;
    }

    T clamp(T)(T x, T a, T b) {
        return max(x, a).min(b);
    }

    T wrap(T)(T x, T a, T b) {
        T result = void;
        auto range = cast(T) (b - a);
        static if (isUnsignedType!T) {
            result = cast(T) wrap!long(x, a, b);
        } else static if (isFloatingType!T) {
            result = fmod(x - a, range);
            if (result < 0) result += range;
            result += a;
        } else {
            result = cast(T) ((x - a) % range);
            if (result < 0) result += range;
            result += a;
        }
        return result;
    }

    // TODO: Look at this again because I feel it returns weird values sometimes.
    T snap(T)(T x, T step) {
        static if (isIntegerType!T) {
            return cast(T) snap!double(cast(double) x, cast(double) step).round();
        } else {
            return (x / step).round() * step;
        }
    }

    float fmod(float x, float y) {
        return stdc.fmodf(x, y);
    }

    double fmod64(double x, double y) {
        return stdc.fmod(x, y);
    }

    float remainder(float x, float y) {
        return stdc.remainderf(x, y);
    }

    double remainder64(double x, double y) {
        return stdc.remainder(x, y);
    }

    float exp(float x) {
        return stdc.expf(x);
    }

    double exp64(double x) {
        return stdc.exp(x);
    }

    float exp2(float x) {
        return stdc.exp2f(x);
    }

    double exp264(double x) {
        return stdc.exp2(x);
    }

    float expm1(float x) {
        return stdc.expm1f(x);
    }

    double expm164(double x) {
        return stdc.expm1(x);
    }

    float log(float x) {
        return stdc.logf(x);
    }

    double log64(double x) {
        return stdc.log(x);
    }

    float log10(float x) {
        return stdc.log10f(x);
    }

    double log1064(double x) {
        return stdc.log10(x);
    }

    float log2(float x) {
        return stdc.log2f(x);
    }

    double log264(double x) {
        return stdc.log2(x);
    }

    float log1p(float x) {
        return stdc.log1pf(x);
    }

    double log1p64(double x) {
        return stdc.log1p(x);
    }

    float pow(float base, float exponent) {
        return stdc.powf(base, exponent);
    }

    double pow64(double base, double exponent) {
        return stdc.pow(base, exponent);
    }

    float atan2(float y, float x) {
        return stdc.atan2f(y, x);
    }

    double atan264(double y, double x) {
        return stdc.atan2(y, x);
    }

    float cbrt(float x) {
        return stdc.cbrtf(x);
    }

    double cbrt64(double x) {
        return stdc.cbrt(x);
    }

    float floorX(float x) {
        return (x <= 0.0f && (cast(float) cast(int) x) != x)
            ? (cast(float) cast(int) x) - 1.0f
            : (cast(float) cast(int) x);
    }

    double floorX64(double x) {
        return (x <= 0.0 && (cast(double) cast(long) x) != x)
            ? (cast(double) cast(long) x) - 1.0
            : (cast(double) cast(long) x);
    }

    float floor(float x) {
        return stdc.floorf(x);
    }

    double floor64(double  x) {
        return stdc.floor(x);
    }

    float ceilX(float x) {
        return (x <= 0.0f || (cast(float) cast(int) x) == x)
            ? (cast(float) cast(int) x)
            : (cast(float) cast(int) x) + 1.0f;
    }

    double ceilX64(double x) {
        return (x <= 0.0 || (cast(double) cast(long) x) == x)
            ? (cast(double) cast(long) x)
            : (cast(double) cast(long) x) + 1.0;
    }

    float ceil(float x) {
        return stdc.ceilf(x);
    }

    double ceil64(double x) {
        return stdc.ceil(x);
    }

    float roundX(float x) {
        return (x <= 0.0f)
            ? cast(float) cast(int) (x - 0.5f)
            : cast(float) cast(int) (x + 0.5f);
    }

    double roundX64(double x) {
        return (x <= 0.0)
            ? cast(double) cast(long) (x - 0.5)
            : cast(double) cast(long) (x + 0.5);
    }

    float round(float x) {
        return stdc.roundf(x);
    }

    double round64(double x) {
        return stdc.round(x);
    }

    float sqrt(float x) {
        return stdc.sqrtf(x);
    }

    double sqrt64(double x) {
        return stdc.sqrt(x);
    }

    float sin(float x) {
        return stdc.sinf(x);
    }

    double sin64(double x) {
        return stdc.sin(x);
    }

    float cos(float x) {
        return stdc.cosf(x);
    }

    double cos64(double x) {
        return stdc.cos(x);
    }

    float tan(float x) {
        return stdc.tanf(x);
    }

    double tan64(double x) {
        return stdc.tan(x);
    }

    float asin(float x) {
        return stdc.asinf(x);
    }

    double asin64(double x) {
        return stdc.asin(x);
    }

    float acos(float x) {
        return stdc.acosf(x);
    }

    double acos64(double x) {
        return stdc.acos(x);
    }

    float atan(float x) {
        return stdc.atanf(x);
    }

    double atan64(double x) {
        return stdc.atan(x);
    }

    float lerp(float from, float to, float weight) {
        return from + (to - from) * weight;
    }

    double lerp64(double from, double to, double weight) {
        return from + (to - from) * weight;
    }

    Vec2 lerp(Vec2 from, Vec2 to, float weight) {
        return Vec2(
            lerp(from.x, to.x, weight),
            lerp(from.y, to.y, weight),
        );
    }

    Vec3 lerp(Vec3 from, Vec3 to, float weight) {
        return Vec3(
            lerp(from.x, to.x, weight),
            lerp(from.y, to.y, weight),
            lerp(from.z, to.z, weight),
        );
    }

    Vec4 lerp(Vec4 from, Vec4 to, float weight) {
        return Vec4(
            lerp(from.x, to.x, weight),
            lerp(from.y, to.y, weight),
            lerp(from.z, to.z, weight),
            lerp(from.w, to.w, weight),
        );
    }

    DVec2 lerp(DVec2 from, DVec2 to, double weight) {
        return DVec2(
            lerp64(from.x, to.x, weight),
            lerp64(from.y, to.y, weight),
        );
    }

    DVec3 lerp(DVec3 from, DVec3 to, double weight) {
        return DVec3(
            lerp64(from.x, to.x, weight),
            lerp64(from.y, to.y, weight),
            lerp64(from.z, to.z, weight),
        );
    }

    DVec4 lerp(DVec4 from, DVec4 to, double weight) {
        return DVec4(
            lerp64(from.x, to.x, weight),
            lerp64(from.y, to.y, weight),
            lerp64(from.z, to.z, weight),
            lerp64(from.w, to.w, weight),
        );
    }

    float smoothstep(float from, float to, float weight) {
        auto v = weight * weight * (3.0f - 2.0f * weight);
        return (to * v) + (from * (1.0f - v));
    }

    double smoothstep64(double from, double to, double weight) {
        auto v = weight * weight * (3.0 - 2.0 * weight);
        return (to * v) + (from * (1.0 - v));
    }

    float smootherstep(float from, float to, float weight) {
        auto v = weight * weight * weight * (weight * (weight * 6.0f - 15.0f) + 10.0f);
        return (to * v) + (from * (1.0f - v));
    }

    double smootherstep64(double from, double to, double weight) {
        auto v = weight * weight * weight * (weight * (weight * 6.0 - 15.0) + 10.0);
        return (to * v) + (from * (1.0 - v));
    }

    float easeLinear(float x) {
        return x;
    }

    float easeInSine(float x) {
        return 1.0f - cos((x * pi) / 2.0f);
    }

    float easeOutSine(float x) {
        return sin((x * pi) / 2.0f);
    }

    float easeInOutSine(float x) {
        return -(cos(pi * x) - 1.0f) / 2.0f;
    }

    float easeInCubic(float x) {
        return x * x * x;
    }

    float easeOutCubic(float x) {
        return 1.0f - pow(1.0f - x, 3.0f);
    }

    float easeInOutCubic(float x) {
        return x < 0.5f ? 4.0f * x * x * x : 1.0f - pow(-2.0f * x + 2.0f, 3.0f) / 2.0f;
    }

    float easeInQuint(float x) {
        return x * x * x * x * x;
    }

    float easeOutQuint(float x) {
        return 1.0f - pow(1.0f - x, 5.0f);
    }

    float easeInOutQuint(float x) {
        return x < 0.5f ? 16.0f * x * x * x * x * x : 1.0f - pow(-2.0f * x + 2.0f, 5.0f) / 2.0f;
    }

    float easeInCirc(float x) {
        return 1.0f - sqrt(1.0f - pow(x, 2.0f));
    }

    float easeOutCirc(float x) {
        return sqrt(1.0f - pow(x - 1.0f, 2.0f));
    }

    float easeInOutCirc(float x) {
        return x < 0.5f
            ? (1.0f - sqrt(1.0f - pow(2.0f * x, 2.0f))) / 2.0f
            : (sqrt(1.0f - pow(-2.0f * x + 2.0f, 2.0f)) + 1.0f) / 2.0f;
    }

    float easeInElastic(float x) {
        enum c4 = (2.0f * pi) / 3.0f;

        return x == 0.0f
            ? 0.0f
            : x == 1.0f
            ? 1.0f
            : -pow(2.0f, 10.0f * x - 10.0f) * sin((x * 10.0f - 10.75f) * c4);
    }

    float easeOutElastic(float x) {
        enum c4 = (2.0f * pi) / 3.0f;

        return x == 0.0f
            ? 0.0f
            : x == 1.0f
            ? 1.0f
            : pow(2.0f, -10.0f * x) * sin((x * 10.0f - 0.75f) * c4) + 1.0f;
    }

    float easeInOutElastic(float x) {
        enum c5 = (2.0f * pi) / 4.5f;

        return x == 0.0f
            ? 0.0f
            : x == 1.0f
            ? 1.0f
            : x < 0.5f
            ? -(pow(2.0f, 20.0f * x - 10.0f) * sin((20.0f * x - 11.125f) * c5)) / 2.0f
            : (pow(2.0f, -20.0f * x + 10.0f) * sin((20.0f * x - 11.125f) * c5)) / 2.0f + 1.0f;
    }

    float easeInQuad(float x) {
        return x * x;
    }

    float easeOutQuad(float x) {
        return 1.0f - (1.0f - x) * (1.0f - x);
    }

    float easeInOutQuad(float x) {
        return x < 0.5f ? 2.0f * x * x : 1.0f - pow(-2.0f * x + 2.0f, 2.0f) / 2.0f;
    }

    float easeInQuart(float x) {
        return x * x * x * x;
    }

    float easeOutQuart(float x) {
        return 1.0f - pow(1.0f - x, 4.0f);
    }

    float easeInOutQuart(float x) {
        return x < 0.5f ? 8.0f * x * x * x * x : 1.0f - pow(-2.0f * x + 2.0f, 4.0f) / 2.0f;
    }

    float easeInExpo(float x) {
        return x == 0.0f ? 0.0f : pow(2.0f, 10.0f * x - 10.0f);
    }

    float easeOutExpo(float x) {
        return x == 1.0f ? 1.0f : 1.0f - pow(2.0f, -10.0f * x);
    }

    float easeInOutExpo(float x) {
        return x == 0.0f
            ? 0.0f
            : x == 1.0f
            ? 1.0f
            : x < 0.5f ? pow(2.0f, 20.0f * x - 10.0f) / 2.0f
            : (2.0f - pow(2.0f, -20.0f * x + 10.0f)) / 2.0f;
    }

    float easeInBack(float x) {
        enum c1 = 1.70158f;
        enum c3 = c1 + 1.0f;

        return c3 * x * x * x - c1 * x * x;
    }

    float easeOutBack(float x) {
        enum c1 = 1.70158f;
        enum c3 = c1 + 1.0f;

        return 1.0f + c3 * pow(x - 1.0f, 3.0f) + c1 * pow(x - 1.0f, 2.0f);
    }

    float easeInOutBack(float x) {
        enum c1 = 1.70158f;
        enum c2 = c1 * 1.525f;

        return x < 0.5f
            ? (pow(2.0f * x, 2.0f) * ((c2 + 1.0f) * 2.0f * x - c2)) / 2.0f
            : (pow(2.0f * x - 2.0f, 2.0f) * ((c2 + 1.0f) * (x * 2.0f - 2.0f) + c2) + 2.0f) / 2.0f;
    }

    float easeInBounce(float x) {
        return 1.0f - easeOutBounce(1.0f - x);
    }

    float easeOutBounce(float x) {
        enum n1 = 7.5625f;
        enum d1 = 2.75f;

        return (x < 1.0f / d1)
            ? n1 * x * x
            : (x < 2.0f / d1)
            ? n1 * (x -= 1.5f / d1) * x + 0.75f
            : (x < 2.5f / d1)
            ? n1 * (x -= 2.25f / d1) * x + 0.9375f
            : n1 * (x -= 2.625f / d1) * x + 0.984375f;
    }

    float easeInOutBounce(float x) {
        return x < 0.5f
            ? (1.0f - easeOutBounce(1.0f - 2.0f * x)) / 2.0f
            : (1.0f + easeOutBounce(2.0f * x - 1.0f)) / 2.0f;
    }

    EaseFunc ease(Ease type) {
        final switch (type) {
            case Ease.linear: return &easeLinear;
            case Ease.inSine: return &easeInSine;
            case Ease.outSine: return &easeOutSine;
            case Ease.inOutSine: return &easeInOutSine;
            case Ease.inCubic: return &easeInCubic;
            case Ease.outCubic: return &easeOutCubic;
            case Ease.inOutCubic: return &easeInOutCubic;
            case Ease.inQuint: return &easeInQuint;
            case Ease.outQuint: return &easeOutQuint;
            case Ease.inOutQuint: return &easeInOutQuint;
            case Ease.inCirc: return &easeInCirc;
            case Ease.outCirc: return &easeOutCirc;
            case Ease.inOutCirc: return &easeInOutCirc;
            case Ease.inElastic: return &easeInElastic;
            case Ease.outElastic: return &easeOutElastic;
            case Ease.inOutElastic: return &easeInOutElastic;
            case Ease.inQuad: return &easeInQuad;
            case Ease.outQuad: return &easeOutQuad;
            case Ease.inOutQuad: return &easeInOutQuad;
            case Ease.inQuart: return &easeInQuart;
            case Ease.outQuart: return &easeOutQuart;
            case Ease.inOutQuart: return &easeInOutQuart;
            case Ease.inExpo: return &easeInExpo;
            case Ease.outExpo: return &easeOutExpo;
            case Ease.inOutExpo: return &easeInOutExpo;
            case Ease.inBack: return &easeInBack;
            case Ease.outBack: return &easeOutBack;
            case Ease.inOutBack: return &easeInOutBack;
            case Ease.inBounce: return &easeInBounce;
            case Ease.outBounce: return &easeOutBounce;
            case Ease.inOutBounce: return &easeInOutBounce;
        }
    }

    bool fequals(float a, float b, float localEpsilon = epsilon) {
        return abs(a - b) < localEpsilon;
    }

    bool fequals64(double a, double b, double localEpsilon = epsilon) {
        return abs(a - b) < localEpsilon;
    }

    bool fequals(Vec2 a, Vec2 b, float localEpsilon = epsilon) {
        return fequals(a.x, b.x, localEpsilon) && fequals(a.y, b.y, localEpsilon);
    }

    bool fequals(Vec3 a, Vec3 b, float localEpsilon = epsilon) {
        return fequals(a.x, b.x, localEpsilon) && fequals(a.y, b.y, localEpsilon) && fequals(a.z, b.z, localEpsilon);
    }

    bool fequals(Vec4 a, Vec4 b, float localEpsilon = epsilon) {
        return fequals(a.x, b.x, localEpsilon) && fequals(a.y, b.y, localEpsilon) && fequals(a.z, b.z, localEpsilon) && fequals(a.w, b.w, localEpsilon);
    }

    bool fequals(DVec2 a, DVec2 b, double localEpsilon = epsilon) {
        return fequals(a.x, b.x, localEpsilon) && fequals(a.y, b.y, localEpsilon);
    }

    bool fequals(DVec3 a, DVec3 b, double localEpsilon = epsilon) {
        return fequals(a.x, b.x, localEpsilon) && fequals(a.y, b.y, localEpsilon) && fequals(a.z, b.z, localEpsilon);
    }

    bool fequals(DVec4 a, DVec4 b, double localEpsilon = epsilon) {
        return fequals(a.x, b.x, localEpsilon) && fequals(a.y, b.y, localEpsilon) && fequals(a.z, b.z, localEpsilon) && fequals(a.w, b.w, localEpsilon);
    }

    float toRadians(float degrees) {
        return degrees * pi180;
    }

    double toRadians64(double degrees) {
        return degrees * pi180;
    }

    float toDegrees(float radians) {
        return radians * dpi180;
    }

    double toDegrees64(double radians) {
        return radians * dpi180;
    }

    Rgba toRgb(uint rgb) {
        return Rgba(
            (rgb & 0xFF0000) >> 16,
            (rgb & 0xFF00) >> 8,
            (rgb & 0xFF),
        );
    }

    Rgba toRgba(uint rgba) {
        return Rgba(
            (rgba & 0xFF000000) >> 24,
            (rgba & 0xFF0000) >> 16,
            (rgba & 0xFF00) >> 8,
            (rgba & 0xFF),
        );
    }

    Rgba toRgba(Vec3 vec) {
        return Rgba(
            cast(ubyte) clamp(vec.x, 0.0f, 255.0f),
            cast(ubyte) clamp(vec.y, 0.0f, 255.0f),
            cast(ubyte) clamp(vec.z, 0.0f, 255.0f),
            255,
        );
    }

    Rgba toRgba(Vec4 vec) {
        return Rgba(
            cast(ubyte) clamp(vec.x, 0.0f, 255.0f),
            cast(ubyte) clamp(vec.y, 0.0f, 255.0f),
            cast(ubyte) clamp(vec.z, 0.0f, 255.0f),
            cast(ubyte) clamp(vec.w, 0.0f, 255.0f),
        );
    }

    Rgba toRgba(IStr str) {
        auto startsWithSymbol = str.length == 0 ? false : str[0] == '#';
        auto isRgb = str.length == 6 + startsWithSymbol;
        auto isRgba = str.length == 8 + startsWithSymbol;
        if (!isRgb && !isRgba) return blank;
        uint hex = 0;
        foreach (c; str[startsWithSymbol .. $]) {
            uint digit = 0;
            if (c >= '0' && c <= '9') {
                digit = cast(uint) (c - '0');
            } else if (c >= 'a' && c <= 'f') {
                digit = cast(uint) (10 + (c - 'a'));
            } else if (c >= 'A' && c <= 'F') {
                digit = cast(uint) (10 + (c - 'A'));
            } else {
                return blank;
            }
            hex = (hex << 4) | digit;
        }
        if (isRgb) return hex.toRgb();
        return hex.toRgba();
    }

    alias toColor = toRgba;

    IVec2 toIVec(Vec2 vec) {
        return IVec2(cast(int) vec.x, cast(int) vec.y);
    }

    IVec3 toIVec(Vec3 vec) {
        return IVec3(cast(int) vec.x, cast(int) vec.y, cast(int) vec.z);
    }

    IVec4 toIVec(Vec4 vec) {
        return IVec4(cast(int) vec.x, cast(int) vec.y, cast(int) vec.z, cast(int) vec.w);
    }

    Vec2 toVec(IVec2 vec) {
        return Vec2(vec.x, vec.y);
    }

    Vec2 toVec(GVec2!short vec) {
        return Vec2(vec.x, vec.y);
    }

    Vec3 toVec(IVec3 vec) {
        return Vec3(vec.x, vec.y, vec.z);
    }

    Vec4 toVec(IVec4 vec) {
        return Vec4(vec.x, vec.y, vec.z, vec.w);
    }

    Vec4 toVec(Rgba color) {
        return Vec4(color.r, color.g, color.b, color.a);
    }

    IRect toIRect(Rect rect) {
        return IRect(rect.position.toIVec(), rect.size.toIVec());
    }

    Rect toRect(IRect rect) {
        return Rect(rect.position.toVec(), rect.size.toVec());
    }

    Rect toRect(GRect!(int, short) rect) {
        return Rect(rect.position.toVec(), rect.size.toVec());
    }

    float moveToState(float from, bool to, float delta) {
        return to ? min(1.0f, from + delta) : max(0.0f, from - delta);
    }

    float moveToState64(double from, bool to, double delta) {
        return to ? min(1.0, from + delta) : max(0.0, from - delta);
    }

    float followState(ref float weight, bool target, float speed) {
        weight = weight.moveToState(target, speed);
        return weight;
    }

    double followState64(ref double weight, bool target, double speed) {
        weight = weight.moveToState64(target, speed);
        return weight;
    }

    float moveTo(float from, float to, float delta) {
        return (abs(to - from) > abs(delta))
            ? from + sign(to - from) * delta
            : to;
    }

    float moveTo64(double from, double to, double delta) {
        return (abs(to - from) > abs(delta))
            ? from + sign(to - from) * delta
            : to;
    }

    Vec2 moveTo(Vec2 from, Vec2 to, Vec2 delta) {
        Vec2 result = void;
        auto offset = from.directionTo(to) * delta;
        if (abs(to.x - from.x) > abs(offset.x)) result.x = from.x + offset.x;
        else result.x = to.x;
        if (abs(to.y - from.y) > abs(offset.y)) result.y = from.y + offset.y;
        else result.y = to.y;
        return result;
    }

    Vec3 moveTo(Vec3 from, Vec3 to, Vec3 delta) {
        Vec3 result = void;
        auto offset = from.directionTo(to) * delta;
        if (abs(to.x - from.x) > abs(offset.x)) result.x = from.x + offset.x;
        else result.x = to.x;
        if (abs(to.y - from.y) > abs(offset.y)) result.y = from.y + offset.y;
        else result.y = to.y;
        if (abs(to.z - from.z) > abs(offset.z)) result.z = from.z + offset.z;
        else result.z = to.z;
        return result;
    }

    Vec4 moveTo(Vec4 from, Vec4 to, Vec4 delta) {
        Vec4 result = void;
        auto offset = from.directionTo(to) * delta;
        if (abs(to.x - from.x) > abs(offset.x)) result.x = from.x + offset.x;
        else result.x = to.x;
        if (abs(to.y - from.y) > abs(offset.y)) result.y = from.y + offset.y;
        else result.y = to.y;
        if (abs(to.z - from.z) > abs(offset.z)) result.z = from.z + offset.z;
        else result.z = to.z;
        if (abs(to.w - from.w) > abs(offset.w)) result.w = from.w + offset.w;
        else result.w = to.w;
        return result;
    }

    DVec2 moveTo(DVec2 from, DVec2 to, DVec2 delta) {
        DVec2 result = void;
        auto offset = from.directionTo(to) * delta;
        if (abs(to.x - from.x) > abs(offset.x)) result.x = from.x + offset.x;
        else result.x = to.x;
        if (abs(to.y - from.y) > abs(offset.y)) result.y = from.y + offset.y;
        else result.y = to.y;
        return result;
    }

    DVec3 moveTo(DVec3 from, DVec3 to, DVec3 delta) {
        DVec3 result = void;
        auto offset = from.directionTo(to) * delta;
        if (abs(to.x - from.x) > abs(offset.x)) result.x = from.x + offset.x;
        else result.x = to.x;
        if (abs(to.y - from.y) > abs(offset.y)) result.y = from.y + offset.y;
        else result.y = to.y;
        if (abs(to.z - from.z) > abs(offset.z)) result.z = from.z + offset.z;
        else result.z = to.z;
        return result;
    }

    DVec4 moveTo(DVec4 from, DVec4 to, DVec4 delta) {
        DVec4 result = void;
        auto offset = from.directionTo(to) * delta;
        if (abs(to.x - from.x) > abs(offset.x)) result.x = from.x + offset.x;
        else result.x = to.x;
        if (abs(to.y - from.y) > abs(offset.y)) result.y = from.y + offset.y;
        else result.y = to.y;
        if (abs(to.z - from.z) > abs(offset.z)) result.z = from.z + offset.z;
        else result.z = to.z;
        if (abs(to.w - from.w) > abs(offset.w)) result.w = from.w + offset.w;
        else result.w = to.w;
        return result;
    }

    float moveToWithSlowdown(float from, float to, float delta, float slowdown) {
        if (from.fequals(to)) return to;
        auto target = ((from * (slowdown - 1.0f)) + to) / slowdown;
        return from + (target - from) * delta;
    }

    float moveToWithSlowdown64(double from, double to, double delta, double slowdown) {
        if (from.fequals64(to)) return to;
        auto target = ((from * (slowdown - 1.0)) + to) / slowdown;
        return from + (target - from) * delta;
    }

    Vec2 moveToWithSlowdown(Vec2 from, Vec2 to, Vec2 delta, float slowdown) {
        return Vec2(
            moveToWithSlowdown(from.x, to.x, delta.x, slowdown),
            moveToWithSlowdown(from.y, to.y, delta.y, slowdown),
        );
    }

    Vec3 moveToWithSlowdown(Vec3 from, Vec3 to, Vec3 delta, float slowdown) {
        return Vec3(
            moveToWithSlowdown(from.x, to.x, delta.x, slowdown),
            moveToWithSlowdown(from.y, to.y, delta.y, slowdown),
            moveToWithSlowdown(from.z, to.z, delta.z, slowdown),
        );
    }

    Vec4 moveToWithSlowdown(Vec4 from, Vec4 to, Vec4 delta, float slowdown) {
        return Vec4(
            moveToWithSlowdown(from.x, to.x, delta.x, slowdown),
            moveToWithSlowdown(from.y, to.y, delta.y, slowdown),
            moveToWithSlowdown(from.z, to.z, delta.z, slowdown),
            moveToWithSlowdown(from.w, to.w, delta.w, slowdown),
        );
    }

    DVec2 moveToWithSlowdown(DVec2 from, DVec2 to, DVec2 delta, double slowdown) {
        return DVec2(
            moveToWithSlowdown64(from.x, to.x, delta.x, slowdown),
            moveToWithSlowdown64(from.y, to.y, delta.y, slowdown),
        );
    }

    DVec3 moveToWithSlowdown(DVec3 from, DVec3 to, DVec3 delta, double slowdown) {
        return DVec3(
            moveToWithSlowdown64(from.x, to.x, delta.x, slowdown),
            moveToWithSlowdown64(from.y, to.y, delta.y, slowdown),
            moveToWithSlowdown64(from.z, to.z, delta.z, slowdown),
        );
    }

    DVec4 moveToWithSlowdown(DVec4 from, DVec4 to, DVec4 delta, double slowdown) {
        return DVec4(
            moveToWithSlowdown64(from.x, to.x, delta.x, slowdown),
            moveToWithSlowdown64(from.y, to.y, delta.y, slowdown),
            moveToWithSlowdown64(from.z, to.z, delta.z, slowdown),
            moveToWithSlowdown64(from.w, to.w, delta.w, slowdown),
        );
    }
}

// Function test.
unittest {
    assert(sign(-69) == -1);
    assert(sign(0) == 0);
    assert(sign(420) == 1);
    assert(sign(float.nan) == 0);

    assert(min3(6, 9, 4) == 4);
    assert(max3(6, 9, 4) == 9);
    assert(min4(6, 9, 4, 20) == 4);
    assert(max4(6, 9, 4, 20) == 20);

    assert(clamp(1, 6, 9) == 6);
    assert(clamp(6, 6, 9) == 6);
    assert(clamp(8, 6, 9) == 8);
    assert(clamp(9, 6, 9) == 9);
    assert(clamp(11, 6, 9) == 9);

    assert(wrap!uint(0, 0, 69) == 0);
    assert(wrap!uint(1, 0, 69) == 1);
    assert(wrap!uint(68, 0, 69) == 68);
    assert(wrap!uint(69, 0, 69) == 0);

    assert(wrap!uint(9, 9, 69) == 9);
    assert(wrap!uint(10, 9, 69) == 10);
    assert(wrap!uint(68, 9, 69) == 68);
    assert(wrap!uint(69, 9, 69) == 9);
    assert(wrap!uint(8, 9, 69) == 68);

    assert(cast(int) round(wrap!float(0, 0, 69)) == 0);
    assert(cast(int) round(wrap!float(1, 0, 69)) == 1);
    assert(cast(int) round(wrap!float(68, 0, 69)) == 68);
    assert(cast(int) round(wrap!float(69, 0, 69)) == 0);

    assert(cast(int) round(wrap!float(9, 9, 69)) == 9);
    assert(cast(int) round(wrap!float(10, 9, 69)) == 10);
    assert(cast(int) round(wrap!float(68, 9, 69)) == 68);
    assert(cast(int) round(wrap!float(69, 9, 69)) == 9);
    assert(cast(int) round(wrap!float(8, 9, 69)) == 68);

    assert(wrap!int(0, 0, 69) == 0);
    assert(wrap!int(1, 0, 69) == 1);
    assert(wrap!int(68, 0, 69) == 68);
    assert(wrap!int(69, 0, 69) == 0);

    assert(wrap!int(9, 9, 69) == 9);
    assert(wrap!int(10, 9, 69) == 10);
    assert(wrap!int(68, 9, 69) == 68);
    assert(wrap!int(69, 9, 69) == 9);
    assert(wrap!int(8, 9, 69) == 68);

    assert(snap!int(0, 32) == 0);
    assert(snap!int(-1, 32) == 0);
    assert(snap!int(1, 32) == 0);
    assert(snap!int(-31, 32) == -32);
    assert(snap!int(-32, 32) == -32);
    assert(snap!int(31, 32) == 32);
    assert(snap!int(32, 32) == 32);

    assert(cast(int) round(snap!float(0, 32)) == 0);
    assert(cast(int) round(snap!float(-1, 32)) == 0);
    assert(cast(int) round(snap!float(1, 32)) == 0);
    assert(cast(int) round(snap!float(-31, 32)) == -32);
    assert(cast(int) round(snap!float(-32, 32)) == -32);
    assert(cast(int) round(snap!float(31, 32)) == 32);
    assert(cast(int) round(snap!float(32, 32)) == 32);

    assert(toRgb(0xff0000) == red);
    assert(toRgb(0x00ff00) == green);
    assert(toRgb(0x0000ff) == blue);
    assert(toRgba(0xff0000ff) == red);
    assert(toRgba(0x00ff00ff) == green);
    assert(toRgba(0x0000ffff) == blue);
}

// Vec test.
unittest {
    assert(IVec2(6) + IVec2(4) == IVec2(10));
    assert(IVec3(6) + IVec3(4) == IVec3(10));
    assert(IVec4(6) + IVec4(4) == IVec4(10));

    auto temp2 = IVec2(6);
    auto temp3 = IVec2(6);
    auto temp4 = IVec2(6);
    temp2 += IVec2(4);
    temp3 += IVec2(4);
    temp4 += IVec2(4);
    assert(temp2 == IVec2(10));
    assert(temp3 == IVec2(10));
    assert(temp4 == IVec2(10));
    assert(!temp2.isZero);
    assert(!temp3.isZero);
    assert(!temp4.isZero);
}
