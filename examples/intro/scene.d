import parin;

enum short resolutionWidth = 320;
enum short resolutionHeight = 180;

struct SquareScene
{
    mixin extendScene;

    float rectSpeed;
    float velocityX;
    Rect demoRect;

    void ready()
    {
        rectSpeed = 140f;
        demoRect = Rect(0, resolutionHeight / 2f - 8f, 16, 16);
        velocityX = 0f;
    }

    bool update(float dt)
    {
        if (demoRect.position.x <= 0) velocityX = 1;
        else if (demoRect.position.x >= resolutionWidth - 16) velocityX = -1;

        demoRect.position.x += (velocityX * rectSpeed) * dt;

        drawDebugText("Square scene", Vec2.zero);
        drawRect(demoRect);
        return false;
    }

    void finish()
    {
        println("Square scene finish");
    }
}

struct CircleScene
{
    mixin extendScene;

    float speed;
    float radius;
    Vec2 velocity;
    Circ circle;

    void ready()
    {
        speed = 110f;
        radius = 8f;
        velocity = Vec2.one;
        circle = Circ(Vec2(resolutionWidth / 2f - radius / 2f, resolutionHeight / 2f - radius / 2f), radius);
    }

    bool update(float dt)
    {
        circle.position += (velocity * Vec2(speed)) * Vec2(dt);

        if (circle.position.x - radius < 0) velocity.x = 1;
        else if (circle.position.x + radius > resolutionWidth) velocity.x = -1;
        else if (circle.position.y - radius < 0) velocity.y = 1;
        else if (circle.position.y + radius > resolutionHeight) velocity.y = -1;

        drawDebugText("Circle scene", Vec2.zero);
        drawCirc(circle, pink);

        return false;
    }

    void finish()
    {
        println("Circle scene finish");
    }
}

struct TextScene
{
    mixin extendScene;

    Vec2 textParinPosition;
    Vec2 textCoolPosition;
    Vec2 textRaylibPosition;

    void ready()
    {
        immutable float centerWidth = resolutionWidth / 2f - 10f;
        textParinPosition = Vec2(centerWidth, 40);
        textCoolPosition = Vec2(centerWidth, resolutionHeight / 2f - 10f);
        textRaylibPosition = Vec2(centerWidth, 120);
    }

    bool update(float dt)
    {
        drawDebugText("Text Scene", Vec2.zero);

        drawDebugText("Parin", textParinPosition);
        drawDebugText("Cool!", textCoolPosition);
        drawDebugText("raylib", textRaylibPosition);

        return false;
    }

    void finish()
    {
        println("Text scene finish");
    }
}

SceneManager sceneManager;

void ready() {
    lockResolution(resolutionWidth, resolutionHeight);
    sceneManager.enter!SquareScene();
}

bool update(float dt) {
    // Honestly, I didn't know how to organize this better lmto
    drawDebugText("1. Square Scene | 2. Circle Scene | 3. Text Scene", Vec2(40, resolutionHeight - 20));

    if ('1'.isPressed) sceneManager.enter!SquareScene();
    if ('2'.isPressed) sceneManager.enter!CircleScene();
    if ('3'.isPressed) sceneManager.enter!TextScene();

    sceneManager.update(dt);

    return false;
}

void finish() { 
    sceneManager.free();
    freeResources();
}

mixin runGame!(ready, update, finish);

