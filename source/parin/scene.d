// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.27
// ---

// TODO: Update all the doc comments here.

/// The `scene` module provides a simple scene manager.
module parin.scene;

import stdc = joka.stdc;
import joka.types;

@safe:

struct Scene {
    void delegate() @trusted ready;
    bool delegate(float dt) @trusted update;
    void delegate() @trusted finish;
}

struct SceneManager {
    Scene* scene;
    Scene* nextScene;
    Sz tag;

    @trusted:

    void enter(T)() {
        if (nextScene) return;
        auto temp = cast(T*) stdc.malloc(T.sizeof);
        *temp = T();
        temp.prepare();
        nextScene = cast(Scene*) temp;
    }

    bool update(float dt) {
        if (nextScene) {
            if (scene) {
                if (scene.finish) scene.finish();
                stdc.free(scene);
            }
            scene = nextScene;
            nextScene = null;
            tag = (tag + 1) % Sz.max;
            if (tag == 0) tag = 1;
            if (scene.ready) scene.ready();
            if (scene.update) return scene.update(dt);
            return true;
        }
        if (scene && scene.update) return scene.update(dt);
        return true;
    }

    void free() {
        if (scene) {
            if (scene.finish) scene.finish();
            stdc.free(scene);
            scene = null;
        }
        if (nextScene) {
            stdc.free(nextScene);
            nextScene = null;
        }
        tag = 0;
    }
}

mixin template extendScene() {
    Scene base;

    @trusted
    void prepare() {
        auto base = mixin("&", this.tupleof[0].stringof);
        base.ready = cast(void delegate() @trusted) &this.ready;
        base.update = cast(bool delegate(float dt) @trusted) &this.update;
        base.finish = cast(void delegate() @trusted) &this.finish;
    }
}
