/// This example shows how to use the new UI library.

import parin;
import parin.ui2;

void ready() {
    lockResolution(320, 180);
    ui.readyUiWithEngine();
}

bool update(float dt) {
    auto screen = IRect(resolutionWidth, resolutionHeight);
    screen.subAll(8);

    ui.beginUiFrame();
    scope (exit) ui.endUiFrame();

    // Use TAB, ARROW KEYS, and ENTER to press buttons.
    with (ui.captureFocus(UiKeyNavigation.horizontal)) {
        auto menu = ui.rowItems(screen.subTop(20), 7, 6);
        if (ui.button(menu.pop(), "A")) println("A!");
        if (ui.button(menu.pop(), "B")) println("B!");
        if (ui.button(menu.pop(), "C")) println("C!");

        static number = 20;
        if (ui.stepperRpgm(menu.pop(), number)) println("New number is: ", number);

        static state = false;
        if (ui.toggle(menu.pop(), state)) println("New state is: ", state);

        enum Animal { cat, dog, moose }
        static animal = Animal.moose;
        if (ui.cycler(menu.pop(), animal, true)) println("New animal is: ", animal);

    }

    // Use layouts and options to control how UI elements.
    auto testText = "Hello\nWorldoo";
    auto testPart = ui.colSlice(IRect(screen.x, 40, 75, 130), 24, 7);
    {
        auto testSubPart = ui.rowSlice(testPart.pop(), testPart.w, 7);
        if (ui.button(testSubPart.pop(), testText, UiFlag.none))
            println("Pressed 1!");
        if (ui.button(testSubPart.pop(), testText, UiFlag.alignCenter))
            println("Pressed 2!");
    }
    {
        auto testSubPart = ui.rowSlice(testPart.pop(), testPart.w, 7);
        if (ui.button(testSubPart.pop(), testText, UiFlag.alignRight))
            println("Pressed 3!");
        if (ui.button(testSubPart.pop(), testText, UiFlag.turnOff))
            println("Pressed 4!");
    }

    return false;
}

mixin runGame!(ready, update, null);
