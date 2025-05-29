/// This example serves as a classic hello world program, introducing the structure of a Parin program.
/// The goal here compared to `hello.d` is to keep the example as compact as possible.

import parin;

bool update(float dt) {
    drawDebugText("Hello world!", Vec2(8), DrawOptions(Vec2(4)));
    return false;
}

mixin runGame!(null, update, null);
