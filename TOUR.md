# Tour

> [!WARNING]  
> I am still working on this.

## Understanding the Code

Let's get started with Popka by creating a simple game that displays the classic message "Hello world!".
Open your app.d file and paste the following code:

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

mixin addGameStart!(gameStart, 640, 360);
```

Let's see how everything works:

1. Game Loop

    ```d
    bool gameLoop() {
        drawDebugText("Hello world!");
        return false;
    }
    ```

    This function is the main loop of the game.
    It runs every frame, and in this example, it draws the message "Hello world!" on the window.
    The `return false` statement tells the game to keep running.
    If true is returned, then the program will stop running.

2. Game Start

    ```d
    void gameStart() {
        lockResolution(320, 180);
        updateWindow!gameLoop();
    }

    mixin addGameStart!(gameStart, 640, 360);
    ```

    This function is the starting point of the game.
    It runs only once, and in this example, it locks the game resolution to 320 pixels wide and 180 pixels tall.
    The `updateWindow!gameLoop()` call starts the game loop.

3. Mixin

    ```d
    mixin addGameStart!(gameStart, 640, 360)
    ```

    The line makes sure the `gameStart` function runs when your game starts,
    and in this example, it creates a game window that is 640 pixels wide and 360 pixels tall.

In essence, a Popka game typically relies on two key functions:

* A game loop function.
* A game start function.

## Drawing

Popka provides a set of drawing functions.
While drawing is not pixel-perfect by default, you can enable pixel-perfect drawing by calling the `togglePixelPerfect` function.

```d
// Basic Drawing Functions
void drawRect(Rect area, Color color = white);
void drawVec2(Vec2 point, float size, Color color = white);
void drawCirc(Circ area, Color color = white);
void drawLine(Line area, float size, Color color = white);
void drawTexture(Texture texture, Vec2 position, Rect area, DrawOptions options = DrawOptions());
void drawTexture(Texture texture, Vec2 position, DrawOptions options = DrawOptions());
void drawRune(Font font, Vec2 position, dchar rune, DrawOptions options = DrawOptions());
void drawText(Font font, Vec2 position, IStr text, DrawOptions options = DrawOptions());
void drawDebugText(IStr text, Vec2 position = Vec2(8.0f), DrawOptions options = DrawOptions());

// Tile Map Drawing Functions
void drawTile(Texture texture, Vec2 position, int tileID, Vec2 tileSize, DrawOptions options = DrawOptions());
void drawTileMap(Texture texture, Vec2 position, TileMap tileMap, Camera camera, DrawOptions options = DrawOptions());
```

## Loading and Saving

Functions that start with the word load/save will always try to read/write from/to the assets folder.
These functions handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.
For instance, `loadText("levels/level5.txt")` and `loadText("levels\\level5.txt")` will function identically on any operating system.
Also, if you need text data for just a single frame, consider using the `loadTempText` function.
