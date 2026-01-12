/// This example serves as a classic hello world program, introducing the structure of a Parin program.
/// The goal here compared to `_001_hello.d` is to keep the example as compact as possible.

import parin;

bool update(float dt) {
    // The `lockResolution` call does nothing if the target resolution is the same as the current one.
    lockResolution(320, 180);
    drawText("Hello world!", Vec2(8));
    return false;
}

mixin runGame!(null, update, null);
