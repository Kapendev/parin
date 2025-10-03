// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

module joka.stdc.errno;

extern(C) nothrow @nogc:

// NOTE: Code from the D standard library.
version (CRuntime_Microsoft) {
    ref int _errno();
    alias errno = _errno;
} else version (CRuntime_Glibc) {
    ref int __errno_location();
    alias errno = __errno_location;
} else version (CRuntime_Musl) {
    ref int __errno_location();
    alias errno = __errno_location;
} else version (CRuntime_Newlib) {
    ref int __errno();
    alias errno = __errno;
} else version (OpenBSD) {
    // https://github.com/openbsd/src/blob/master/include/errno.h
    ref int __errno();
    alias errno = __errno;
} else version (NetBSD) {
    // https://github.com/NetBSD/src/blob/trunk/include/errno.h
    ref int __errno();
    alias errno = __errno;
} else version (FreeBSD) {
    ref int __error();
    alias errno = __error;
} else version (DragonFlyBSD) {
    pragma(mangle, "errno") int __errno;
    ref int __error() => __errno;
    alias errno = __error;
} else version (CRuntime_Bionic) {
    ref int __errno();
    alias errno = __errno;
} else version (CRuntime_UClibc) {
    ref int __errno_location();
    alias errno = __errno_location;
} else version (Darwin) {
    ref int __error();
    alias errno = __error;
} else version (Solaris) {
    ref int ___errno();
    alias errno = ___errno;
} else version (Haiku) {
    // https://github.com/haiku/haiku/blob/master/headers/posix/errno.h
    ref int _errnop();
    alias errno = _errnop;
} else {
    // NOTE: Works with Emscripten, no idea about other stuff.
    ref int __errno_location();
    alias errno = __errno_location;
}
