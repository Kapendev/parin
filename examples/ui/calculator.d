/// This example shows how to create a simple calculator.

import parin;

bool update(float dt) {
    prepareUi();
    setUiFocus(0);

    auto margin = 6;
    auto options = UiOptions(2);
    auto area = Rect(resolution);
    auto firstLineHeight = resolutionHeight * 0.35;
    auto lineHeight = (resolutionHeight - firstLineHeight - margin * 5) / 5;
    auto buttonWidth = (resolutionWidth - margin * 3) / 4;
    auto temp = Rect();

    temp = area.subTop(firstLineHeight);
    drawRect(temp, defaultUiDisabledColor);
    uiText(temp, "UwU", options);
    area.subTop(margin);

    temp = area.subTop(lineHeight);
    uiButton(temp.subLeft(buttonWidth * 3 + margin * 2), "C", options);
    temp.subLeft(margin);
    uiButton(temp.subLeft(temp.size.x), "/", options);
    area.subTop(margin);

    temp = area.subTop(lineHeight);
    uiButton(temp.subLeft(buttonWidth), "7", options);
    temp.subLeft(margin);
    uiButton(temp.subLeft(buttonWidth), "8", options);
    temp.subLeft(margin);
    uiButton(temp.subLeft(buttonWidth), "9", options);
    temp.subLeft(margin);
    uiButton(temp.subLeft(temp.size.x), "X", options);
    area.subTop(margin);

    temp = area.subTop(lineHeight);
    uiButton(temp.subLeft(buttonWidth), "4", options);
    temp.subLeft(margin);
    uiButton(temp.subLeft(buttonWidth), "5", options);
    temp.subLeft(margin);
    uiButton(temp.subLeft(buttonWidth), "6", options);
    temp.subLeft(margin);
    uiButton(temp.subLeft(temp.size.x), "-", options);
    area.subTop(margin);

    temp = area.subTop(lineHeight);
    uiButton(temp.subLeft(buttonWidth), "1", options);
    temp.subLeft(margin);
    uiButton(temp.subLeft(buttonWidth), "2", options);
    temp.subLeft(margin);
    uiButton(temp.subLeft(buttonWidth), "3", options);
    temp.subLeft(margin);
    uiButton(temp.subLeft(temp.size.x), "+", options);
    area.subTop(margin);

    temp = area.subTop(temp.size.y);
    uiButton(temp.subLeft(buttonWidth * 3 + margin * 2), "0", options);
    temp.subLeft(margin);
    uiButton(temp.subLeft(temp.size.x), "=", options);
    area.subTop(margin);

    return false;
}

mixin runGame!(null, update, null, 306, 450);
