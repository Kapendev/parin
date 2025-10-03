// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

module joka.stdc.math;

extern(C) nothrow @nogc pure:

int abs(int x);
long labs(long x);

float fabsf(float x);
double fabs(double x);

float fmodf(float x, float y);
double fmod(double x, double y);

float remainderf(float x, float y);
double remainder(double x, double y);

float expf(float x);
double exp(double x);

float exp2f(float x);
double exp2(double x);

float expm1f(float x);
double expm1(double x);

float logf(float x);
double log(double x);

float log10f(float x);
double log10(double x);

float log2f(float x);
double log2(double x);

float log1pf(float x);
double log1p(double x);

float powf(float base, float exponent);
double pow(double base, double exponent);

float sqrtf(float x);
double sqrt(double x);

float cbrtf(float x);
double cbrt(double x);

float hypotf(float x, float y);
double hypot(double x, double y);

float sinf(float x);
double sin(double x);

float cosf(float x);
double cos(double x);

float tanf(float x);
double tan(double x);

float asinf(float x);
double asin(double x);

float acosf(float x);
double acos(double x);

float atanf(float x);
double atan(double x);

float atan2f(float y, float x);
double atan2(double y, double x);

float ceilf(float x);
double ceil(double x);

float floorf(float x);
double floor(double x);

float roundf(float x);
double round(double x);
