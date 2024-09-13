// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/popka
// Version: v0.0.23
// ---

// TODO: Update all the doc comments here.

/// The `scene` module provides a simple scene manager.
module popka.scene;

import stdc = joka.stdc;
import joka.traits;
import joka.types;

struct Scene {
    void delegate() ready;
    bool delegate(float dt) update;
    void delegate() finish;
}

struct SceneManager {
    Scene* scene;
    Scene* nextScene;
    Sz tag;

    @trusted @nogc nothrow
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

    @safe @nogc nothrow
    void prepare() {
        import joka.traits;

        auto base = mixin("&", this.tupleof[0].stringof);
        static if (hasMember!(typeof(this), "ready")) {
            base.ready = &this.ready;
        } else {
            base.ready = null;
        }
        static if (hasMember!(typeof(this), "update")) {
            base.update = &this.update;
        } else {
            base.update = null;
        }
        static if (hasMember!(typeof(this), "finish")) {
            base.finish = &this.finish;
        } else {
            base.finish = null;
        }
    }
}
