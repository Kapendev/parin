# Tour !TODO!: FIX EXAMPLES

> [!WARNING]  
> I am still working on this.

## Your First Popka Game

Let's get started with Popka by creating a simple game that displays the classic message "Hello world!". Open your app.d file and paste the following code:

```d
import popka;

bool gameLoop() {
    draw("Hello world!");
    return false;
}

void gameStart() {
    lockResolution(320, 180);
    updateWindow!gameLoop();
}

mixin addGameStart!(gameStart, 640, 360);
```

Once you've saved the code, you should be able to compile/run with:

```bash
dub run
```

You should see a window with the text "Hello world!" displayed.
Congratulations, you've created your first Popka game!

### Understanding the Code

1. Import

    ```d
    import popka;
    ```

    This line imports some basic Popka modules that are needed to make your game.

2. Game Loop

    ```d
    bool gameLoop() {
        draw("Hello world!");
        return false;
    }
    ```

    This function is the main loop of your game. It runs every frame, and on each frame in this example, it draws the message "Hello world!" on the game window.
    The `return false` statement tells the game to keep running. If true is returned, then the game will stop running.

3. Game Start and Mixin

    ```d
    void gameStart() {
        lockResolution(320, 180);
        updateWindow!gameLoop();
    }

    mixin addGameStart!(gameStart, 640, 360);
    ```

    This function is the starting point of your game. It runs only one time, and in this example, it locks the game resolution to 320 pixels wide and 180 pixels tall, and the `updateWindow!gameLoop()` call starts the game loop.
    The `mixin addGameStart!(gameStart, 640, 360)` line might seem a bit complex right now, but it makes sure the `gameStart` function runs when your game starts and creates a game window that is 640 pixels wide and 360 pixels tall.

In essence, a Popka game typically relies on two key functions:

* A game loop function.
* A game start function.

## Drawing

Popka provides a set of drawing functions for creating various graphical elements.
While drawing is not pixel-perfect by default, you can enable pixel-perfect drawing by calling the `togglePixelPerfect()` function.

```d
// Rectangle Drawing
void draw(Rect area, Color color = white);

// Circle Drawing
void draw(Circ area, Color color = white);

// Line Drawing
void draw(Line area, float size, Color color = white);

// Point Drawing
void draw(Vec2 point, float size, Color color = white);

// Sprite Drawing
void draw(Sprite sprite, Rect area, Vec2 position, DrawOptions options = DrawOptions());
void draw(Sprite sprite, Vec2 position, DrawOptions options = DrawOptions());
void draw(Sprite sprite, Vec2 tileSize, int tileID, Vec2 position, DrawOptions options = DrawOptions());
void draw(Sprite sprite, TileMap tileMap, Camera camera, Vec2 position, DrawOptions options = DrawOptions());

// Font Drawing
void draw(Font font, dchar rune, Vec2 position, DrawOptions options = DrawOptions());
void draw(Font font, const(char)[] text, Vec2 position, DrawOptions options = DrawOptions());

// Debug Drawing
void draw(const(char)[] text, Vec2 position = Vec2(8.0f), DrawOptions options = DrawOptions());
```

## Loading and Saving

Functions that start with the word load/save will always try to read/write from/to the assets folder.
These functions handle both forward slashes and backslashes in file paths, ensuring compatibility across operating systems.
For instance, `loadText("levels/level5.txt")` and `loadText("levels\\level5.txt")` will function identically on any operating system.
