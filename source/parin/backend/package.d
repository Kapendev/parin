// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

module parin.backend;

version (ParinBackendWeb) {
    public import parin.backend.web;
} else {
    public import parin.backend.rl;
}
