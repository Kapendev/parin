# Tour (WIP)

## Understanding the Code

To begin, open the main file of your project and copy-paste the following code:

```d
import popka;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    drawDebugText("Hello world!", Vec2(8.0));
    return false;
}

void finish() { }

mixin runGame!(ready, update, finish);
```

This code will create a window that displays the message "Hello world!".
Here is a breakdown of how this code works:

1. The Ready Function

    ```d
    void ready() {
        lockResolution(320, 180);
    }
    ```

    This function is the starting point of the game.
    It is called once when the game starts and, in this example, locks the game resolution to 320 pixels wide and 180 pixels tall.

2. The Update Function

    ```d
    bool update(float dt) {
        drawDebugText("Hello world!", Vec2(8.0));
        return false;
    }
    ```

    This function is the main loop of the game.
    It is called every frame while the game is running and, in this example, draws the message "Hello world!" at position `Vec2(8.0)`.
    The `return false` statement indicates that the game should continue running.
    If `true` were returned, the game would stop running.

3. The Finish Function

    ```d
    void finish() { }
    ```

    This function is the ending point of the game.
    It is called once when the game ends and, in this example, does nothing.

4. The Mixin

    ```d
    mixin runGame!(ready, update, finish);
    ```

    This line sets up a main function that will run the game.

In essence, a Popka game typically relies on three key functions:

* A ready function.
* An update function.
* A finish function.

## Drawing

Popka provides a set of drawing functions inside the `popka.engine` module.
While drawing is not pixel-perfect by default, you can enable pixel-perfect drawing by calling the `setIsPixelPerfect` function.

```d
void drawRect(Rect area, Color color = white);
void drawVec2(Vec2 point, float size, Color color = white);
void drawCirc(Circ area, Color color = white);
void drawLine(Line area, float size, Color color = white);

void drawTexture(Texture texture, Vec2 position, DrawOptions options = DrawOptions());
void drawTextureArea(Texture texture, Rect area, Vec2 position, DrawOptions options = DrawOptions());

void drawRune(Font font, dchar rune, Vec2 position, DrawOptions options = DrawOptions());
void drawText(Font font, IStr text, Vec2 position, DrawOptions options = DrawOptions());
void drawDebugText(IStr text, Vec2 position, DrawOptions options = DrawOptions());
```

Additional drawing functions can be found in other modules, such as `popka.tilemap`.

## Loading and Saving Resources

Functions that start with the word load/save will always try to read/write resources from/to the assets folder.
These functions handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.

```d
loadText("levels/level5.txt");  // Works on Windows, Linux and MacOS.
loadText("levels\\level5.txt"); // Works on Windows, Linux and MacOS.
```

If text is needed for only a single frame, use the `loadTempText` function.
