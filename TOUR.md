# Tour (WIP)

## Understanding the Code

To begin, open the main project file and copy-paste the following code:

```d
import parin;

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

In essence, a Parin game typically relies on three key functions:

* A ready function.
* An update function.
* A finish function.

## Input

Parin provides a set of input functions inside the `parin.engine` module.

```d
bool isDown(char key);
bool isDown(Keyboard key);
bool isDown(Mouse key);
bool isDown(Gamepad key, int id = 0);

bool isPressed(char key);
bool isPressed(Keyboard key);
bool isPressed(Mouse key);
bool isPressed(Gamepad key, int id = 0);

bool isReleased(char key);
bool isReleased(Keyboard key);
bool isReleased(Mouse key);
bool isReleased(Gamepad key, int id = 0);

Vec2 wasd();
Vec2 wasdPressed();
Vec2 wasdReleased();

Vec2 mouse();
Vec2 deltaMouse();
float deltaWheel();
```

## Sound

Parin provides a set of sound functions inside the `parin.engine` module.

```d
void playSound(Sound sound);
void stopSound(Sound sound);
void pauseSound(Sound sound);
void resumeSound(Sound sound);
void updateSound(Sound sound);
```

## Drawing

Parin provides a set of drawing functions inside the `parin.engine` module.
While drawing is not pixel-perfect by default, it can be by calling the `setIsPixelPerfect` or `setIsPixelSnapped` functions.

```d
void drawRect(Rect area, Color color = white);
void drawVec2(Vec2 point, float size, Color color = white);
void drawCirc(Circ area, Color color = white);
void drawLine(Line area, float size, Color color = white);

void drawTexture(Texture texture, Vec2 position, DrawOptions options = DrawOptions());
void drawTextureArea(Texture texture, Rect area, Vec2 position, DrawOptions options = DrawOptions());

void drawViewport(Viewport viewport, Vec2 position, DrawOptions options = DrawOptions());
void drawViewportArea(Viewport viewport, Rect area, Vec2 position, DrawOptions options = DrawOptions());

void drawRune(Font font, dchar rune, Vec2 position, DrawOptions options = DrawOptions());
void drawText(Font font, IStr text, Vec2 position, DrawOptions options = DrawOptions());
void drawDebugText(IStr text, Vec2 position, DrawOptions options = DrawOptions());
```

Some of these functions also accept managed resources.
Additional drawing functions can be found in other modules, such as `parin.sprite`.

### Draw Options

Draw options are used for configuring drawing parameters. The data structure looks something like this:

```d
struct DrawOptions {
    float rotation = 0.0f;                /// The rotation of the drawn object, in degrees.
    Color color = white;                  /// The color of the drawn object.
    Hook hook = Hook.topLeft;             /// A value representing the origin point of the drawn object when origin is set to zero.
    Flip flip = Flip.none;                /// A value representing flipping orientations.
    Alignment alignment = Alignment.left; /// A value represeting alignment orientations.
    int alignmentWidth = 0;               /// The width of the aligned object. Used as a hint and it is not enforced. Mostly used for text drawing.
    float visibilityRatio = 1.0f;         /// Controls the visibility ratio of the object, where 0.0 means fully hidden and 1.0 means fully visible. Mostly used for text drawing.
    bool isRightToLeft = false;           /// Indicates whether the content of the object flows in a right-to-left direction, such as for Arabic or Hebrew text. Usually used for text drawing.
}
```

Some of these parameters can also be configured via the constructors.

```d
this(float rotation);
this(Vec2 scale);
this(Color color);
this(Hook hook);
this(Flip flip);
this(Alignment alignment, int alignmentWidth = 0);
```

## Loading and Saving Resources

Parin provides a set of loading functions inside the `parin.engine` module.
Functions that start with the word load/save will always try to read/write resources from/to the assets folder.
These functions handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.

```d
TextId loadText(IStr path, Sz tag = 0);
TextureId loadTexture(IStr path, Sz tag = 0);
FontId loadFont(IStr path, int size, int runeSpacing, int lineSpacing, IStr32 runes = "", Sz tag = 0);
FontId loadFontFromTexture(IStr path, int tileWidth, int tileHeight, Sz tag = 0);
SoundId loadSound(IStr path, float volume, float pitch, Sz tag = 0);

Result!LStr loadRawText(IStr path);
Result!Texture loadRawTexture(IStr path);
Result!Font loadRawFont(IStr path, int size, int runeSpacing, int lineSpacing, IStr32 runes = "");
Result!Font loadRawFontFromTexture(IStr path, int tileWidth, int tileHeight);
Result!Sound loadRawSound(IStr path, float volume, float pitch);

Result!IStr loadTempText(IStr path);

Fault saveText(IStr path, IStr text);
```

Additional loading functions can be found in other modules, such as `parin.map`.

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

## Sprites and Tile Maps

Sprites and tile maps can be implemented in various ways.
To avoid enforcing a specific approach, Parin provides optional modules for these features, allowing users to include or omit them as needed.
Parin provides a sprite type inside the `parin.sprite` module and a tile map type inside the `parin.map` module.
