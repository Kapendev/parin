# Tour (WIP)

## Understanding the Code

To begin, open the main file of your project and copy-paste the following code:

```d
import popka;

bool gameLoop() {
    drawDebugText("Hello world!");
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    updateWindow!gameLoop();
}

mixin callGameStart!(gameStart, 640, 360);
```

This code will create a window that displays the message "Hello world!".
Here is a breakdown of how this code works:

1. Game Loop

    ```d
    bool gameLoop() {
        drawDebugText("Hello world!");
        return false;
    }
    ```

    This function is the main loop of the game.
    It runs every frame and, in this example, draws the message "Hello world!".
    The `return false` statement indicates that the game should continue running.
    If `true` were returned, the game would stop.

2. Game Start

    ```d
    void gameStart() {
        lockResolution(320, 180);
        updateWindow!gameLoop();
    }
    ```

    This function is the starting point of the game.
    It runs only once and, in this example, locks the game resolution to 320 pixels wide and 180 pixels tall.
    The `updateWindow!gameLoop` call starts the main game loop.

3. Mixin

    ```d
    mixin callGameStart!(gameStart, 640, 360)
    ```

    This line sets up the `gameStart` function to run when the game starts
    and, in this example, creates a game window that is 640 pixels wide and 360 pixels tall.

In essence, a Popka game typically relies on two key functions:

* A loop function.
* A start function.

## Drawing

Popka provides a set of drawing functions.
While drawing is not pixel-perfect by default, you can enable pixel-perfect drawing by calling the `togglePixelPerfect` function.

```d
void drawRect(Rect area, Color color = white);
void drawVec2(Vec2 point, float size, Color color = white);
void drawCirc(Circ area, Color color = white);
void drawLine(Line area, float size, Color color = white);

void drawTexture(Texture texture, Vec2 position, Rect area, DrawOptions options = DrawOptions());
void drawTexture(Texture texture, Vec2 position, DrawOptions options = DrawOptions());

void drawRune(Font font, Vec2 position, dchar rune, DrawOptions options = DrawOptions());
void drawText(Font font, Vec2 position, IStr text, DrawOptions options = DrawOptions());
void drawDebugText(IStr text, Vec2 position = Vec2(8.0f), DrawOptions options = DrawOptions());

void drawTile(Texture texture, Vec2 position, int tileID, Vec2 tileSize, DrawOptions options = DrawOptions());
void drawTileMap(Texture texture, Vec2 position, TileMap tileMap, Camera camera, DrawOptions options = DrawOptions());
```

## Loading and Saving

Functions that start with the word load/save will always try to read/write from/to the assets folder.
These functions handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.

```d
loadText("levels/level5.txt");
loadText("levels\\level5.txt");
```

Both of these calls will function identically on any operating system.
Also, if text is needed for only a single frame, use the `loadTempText` function.
