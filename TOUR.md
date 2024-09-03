# Tour (WIP)

## Understanding the Code

To begin, open the main project file and copy-paste the following code:

```d
import popka;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    drawDebugText("Hello world!", Vec2(8));
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
        drawDebugText("Hello world!", Vec2(8));
        return false;
    }
    ```

    This function is the main loop of the game.
    It is called every frame while the game is running and, in this example, draws the message "Hello world!" at position `Vec2(8)`.
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
void drawTexture(TextureId texture, Vec2 position, DrawOptions options = DrawOptions());
void drawTextureArea(Texture texture, Rect area, Vec2 position, DrawOptions options = DrawOptions());
void drawTextureArea(TextureId texture, Rect area, Vec2 position, DrawOptions options = DrawOptions());

void drawRune(Font font, dchar rune, Vec2 position, DrawOptions options = DrawOptions());
void drawRune(FontId font, dchar rune, Vec2 position, DrawOptions options = DrawOptions());
void drawText(Font font, IStr text, Vec2 position, DrawOptions options = DrawOptions());
void drawText(FontId font, IStr text, Vec2 position, DrawOptions options = DrawOptions());
void drawDebugText(IStr text, Vec2 position, DrawOptions options = DrawOptions());
```

Additional drawing functions can be found in other modules, such as `popka.sprite`.

## Loading and Saving Resources

Functions that start with the word load/save will always try to read/write resources from/to the assets folder.
These functions handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.

```d
Result!TextId loadText(IStr path, Sz tag = 0);
Result!TextureId loadTexture(IStr path, Sz tag = 0);
Result!FontId loadFont(IStr path, int size, int runeSpacing, int lineSpacing, const(dchar)[] runes = [], Sz tag = 0);
Result!SoundId loadSound(IStr path, float volume, float pitch, Sz tag = 0);

Result!LStr loadRawText(IStr path);
Result!Texture loadRawTexture(IStr path);
Result!Font loadRawFont(IStr path, int size, int runeSpacing, int lineSpacing, const(dchar)[] runes = []);
Result!Sound loadRawSound(IStr path, float volume, float pitch);

Result!IStr loadTempText(IStr path);

Fault saveText(IStr path, IStr text);
```

### Managed Resources

Managed resources are cached by their path and grouped based on the tag they were loaded with.
To free these resources, use the `freeResources` function or the `free` method on the resource identifier.
The resource identifier is automatically invalidated when the resource is freed.

### Raw Resources

Raw resources are managed directly by the user and are not cached or grouped.
They must be freed manually when no longer needed.

### Temporary Resources

Temporary resources are only valid until the function that provided them is called again.
They don’t need to be freed manually.
