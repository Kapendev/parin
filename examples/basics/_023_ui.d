/// This example shows how to use the new UI library.
/// EXPERIMENTAL!!!

import parin;
import parin.ui2;

auto ui = UiContext();

void ready() {
    lockResolution(320, 180);
    ui.readyUiWithEngine(null, null);
}

bool update(float dt) {
    ui.setBuffers(frameMakeSlice!UiCommand(256), frameMakeSlice!char(2048));
    ui.beginUiFrame();
    scope (exit) ui.endUiFrame();

    auto screen = IRect(resolutionWidth, resolutionHeight);
    screen.subAll(8);

    // Use TAB, ARROW KEYS, and ENTER to interact with the buttons.
    with (ui.captureFocus(UiKeyNavigation.horizontal)) {
        auto menu = ui.rowItems(screen.subTop(20), 7, 6);
        if (ui.button(menu.pop(), "A")) println("A!");
        if (ui.button(menu.pop(), "B")) println("B!");
        if (ui.button(menu.pop(), "C")) println("C!");

        static number = 20;
        if (ui.stepper(menu.pop(), number)) println("New number is: ", number);

        static state = true;
        if (ui.toggle(menu.pop(), state)) println("New state is: ", state);

        enum Animal { cat, dog, moose }
        static animal = Animal.moose;
        if (ui.cycler(menu.pop(), animal)) println("New animal is: ", animal);
    }

    // Use layouts and options to control the UI elements.
    auto testText = "Hello\nWorldoo";
    auto testPart = ui.colSlice(IRect(screen.x, 45, 75, 130), 24, 7);
    {
        auto subPart = ui.rowSlice(testPart.pop(), testPart.w, 7);
        ui.button(subPart.pop(), testText, UiFlag.none);
        ui.button(subPart.pop(), testText, UiFlag.alignCenter);
    }
    {
        auto subPart = ui.rowSlice(testPart.pop(), testPart.w, 7);
        ui.button(subPart.pop(), testText, UiFlag.alignRight);
        ui.button(subPart.pop(), testText, UiFlag.turnOff);
    }
    {
        static numberWithName = 80;
        ui.stepper(
            ui.rowSlice(testPart.pop(), testPart.w * 2 + testPart.spacing, 0).pop(),
            numberWithName,
            "BGM Volume",
        );

        static stateWithName = false;
        ui.toggle(
            ui.rowSlice(testPart.pop(), testPart.w * 2 + testPart.spacing, 0).pop(),
            stateWithName,
            "Always Dash",
        );
    }

    return false;
}

mixin runGame!(ready, update, null);
