import parin;
import parin.addons.microui;

bool showDetails = true;
float speed = 1.0f;
int health = 100;
IStr name;

void ready() {
    enum scale = 2;
    readyUi(scale);
    uiStyle.size.x = 200 * scale;
}

bool update(float dt) {
    beginUiFrame();
    scope (exit) endUiFrame();

    auto windowWidth  = uiStyle.size.x * 2;
    auto windowHeight = uiStyle.size.y * 30;
    auto spacing      = uiStyle.spacing;
    auto border       = uiStyle.border;
    // Inner width is the usable space after accounting for left/right spacing and border.
    auto innerWidth = windowWidth - spacing * 2 - border * 2;
    // Half is used to split the window into two equal columns.
    auto columnHalf = (innerWidth - spacing) / 2;
    // Label width for the inspector section (wide enough to fit the longest label).
    auto inspectorLabel = 160;

    if (beginWindow("Layout System", 32, 32, windowWidth, windowHeight)) {
        // Without a row() call, each item uses style.size.x as its width.
        text("Without row(), items use style.size.x:");
        button("Default Width");

        // Passing explicit widths sets each item's width in pixels.
        text("Explicit pixel widths (80, 80, 80):");
        row(0, 80, 80, 80);
        button("A");
        button("B");
        button("C");

        // A width of 0 means use style.size.x for that item.
        // A negative width is relative to the right edge: -1 reaches it exactly.
        row(0, 0);
        text("0 = style.size.x, -1 = from right edge:");
        row(0, 80, -1);
        button("80px");
        button("-1 (fill)");

        // Mixing fixed and negative widths: left and right are fixed,
        // the middle item fills what remains.
        row(0, 0);
        text("Fixed left and right, fill middle:");
        row(0, 60, -60 - spacing - border, -1);
        button("Left");
        button("Mid");
        button("Right");

        // Calling row() with a 0 item count makes subsequent items
        // fall back to style.size.x width until row() is called again.
        row(0, 0);
        text("row(0, 0): items use style.size.x again:");
        button("Default Width");

        // The row height (first argument) can be set explicitly.
        // 0 means use style.size.y.
        row(0, 0);
        text("Explicit row height (60px):");
        row(60, 0);
        button("Tall");

        // Columns let you nest rows inside a fixed-width cell.
        // Negative widths inside a column are relative to the column body.
        row(0, 0);
        text("Columns let you place rows side by side. Each column has its own independent rows.");
        row(0, columnHalf, columnHalf);

        beginColumn();
            row(0, 0);
            text("Column A");
            button("A1");
            button("A2");
            button("A3");
        endColumn();

        beginColumn();
            row(0, 0);
            text("Column B");
            button("B1");
            button("B2");
            button("B3");
        endColumn();

        // A common pattern: fixed-width label on the left, control stretches to fill the remaining space with -1.
        row(0, 0);
        text("Fixed label, control fills the rest:");
        row(0, inspectorLabel, -1);
        label("Show Details");
        checkbox(showDetails);
        label("Speed");
        slider(speed, 0.0f, 10.0f);
        label("Health");
        number(health, 1);
        label("Name");
        textBox(name);

        endWindow();
    }
    return false;
}

mixin runGame!(ready, update, null);
