/// This example shows how to use the scene manager of Popka.
import popka;

// The game variables.
auto sceneManager = SceneManager();

// The first scene.
struct Scene1 {
    mixin extendScene;

    float counter = 0;

    void ready() {
        println("Entering scene 1.");
        setBackgroundColor(gray1);
    }

    bool update(float dt) {
        if (Keyboard.space.isPressed) {
            sceneManager.enter!Scene2();
        }

        counter += 5 * dt;

        drawDebugText("Press enter to change scene.", resolution * Vec2(0.5), DrawOptions(Hook.center));
        drawDebugText("Scene 1\nCounter: {}".format(cast(int) counter), Vec2(8));
        return false;
    }

    void finish() {
        println("Exiting scene 1.");
    }
}

// The second scene.
struct Scene2 {
    mixin extendScene;

    void ready() {
        println("Entering scene 2.");
        setBackgroundColor(gray2);
    }

    bool update(float dt) {
        if (Keyboard.space.isPressed) {
            sceneManager.enter!Scene1();
        }

        drawDebugText("Press enter to change scene.", resolution * Vec2(0.5), DrawOptions(Hook.center));
        drawDebugText("Scene 2\nNo counter here.", Vec2(8));
        return false;
    }

    void finish() {
        println("Exiting scene 2.");
    }
}

void ready() {
    lockResolution(320, 180);
    // Enter the first scene. This will call the ready function of that scene.
    sceneManager.enter!Scene1();
}

bool update(float dt) {
    // Update the current scene.
    return sceneManager.update(dt);
}

void finish() {
    // Free the scene manager. This will call the finish function of the current scene.
    sceneManager.free();
}

mixin runGame!(ready, update, finish);
