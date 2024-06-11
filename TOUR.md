# Tour

> [!WARNING]  
> I am still working on this.

## Getting Started

### Hello-World

As the first Popka game, let's show the message `Hello world!`.
Write this inside your app.d file:

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

If you see a window with the text `Hello world!`, congratulations, your program works!
So, how the code work?
Well...

```d
import popka;
```

This imports many Popka modules that provide everything you need to make a game. 

```d
bool gameLoop() {
    draw("Hello world!");
    return false;
}
```

This is the main loop of a Popka game. It has to return bool.
True will exit the main loop and false will continue the main loop.

```d
void gameStart() {
    lockResolution(320, 180);
    updateWindow!gameLoop();
}

mixin addGameStart!(gameStart, 640, 360);
```

This is the starting point of a Popka game.
The mixin creates a main function that has the given function in it and adds some extra stuff.

That it. Read it later Alex and tell yourself what you like and what you don't. -.-
