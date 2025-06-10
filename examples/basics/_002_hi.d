/// This example serves as a classic hello world program, introducing the structure of a Parin program.
/// The goal here compared to `_001_hello.d` is to keep the example as compact as possible.

import parin;

bool update(float dt) {
    lockResolution(320, 180);
    drawDebugText("Hello world!", Vec2(8));
    return false;
}

mixin runGame!(null, update, null);
