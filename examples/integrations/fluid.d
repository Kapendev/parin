/// This example shows how to use Parin with Fluid.
/// Repository: https://github.com/Samerion/Fluid

import parin;
import fluid;

Space root;

void ready() {
    void onButton() => println("Pressed button!");
    void onTextInput() => println("Pressed text input!");

    setBackgroundColor(gray3);
    root = vspace(
        .layout!"center",
        label("Hello from Fluid!"),
        button("My Button", &onButton),
        textInput("Write something...", &onTextInput),
    );
}

bool update(float dt) {
    root.draw();
    return false;
}

mixin runGame!(ready, update, null);
