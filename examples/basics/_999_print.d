/// This file is used for testing if IES is working.

import parin;

void ready() {
    lockResolution(320, 180);
}

bool update(float dt) {
    auto buffer = FStr!256();
    auto i = 0;

    i = 1;
    printf(i"Time $(i): $(elapsedTime)\n");
    print(i"Time $(i): $(elapsedTime)\n");
    printfln(i"Time $(i): $(elapsedTime)");
    println(i"Time $(i): $(elapsedTime)");
    println();

    i = 2;
    eprintf(i"Time $(i): $(elapsedTime)\n");
    eprint(i"Time $(i): $(elapsedTime)\n");
    eprintfln(i"Time $(i): $(elapsedTime)");
    eprintln(i"Time $(i): $(elapsedTime)");
    eprintln();

    i = 3;
    sprintf(buffer, i"Time $(i): $(elapsedTime)\n");
    sprint(buffer, i"Time $(i): $(elapsedTime)\n");
    sprintfln(buffer, i"Time $(i): $(elapsedTime)");
    sprintln(buffer, i"Time $(i): $(elapsedTime)");
    sprintln(buffer);
    println(buffer);

    i = 4;
    dprintfln(i"Time $(i): $(elapsedTime)");
    dprintln(i"Time $(i): $(elapsedTime)");

    i = 5;
    drawText(i"Time $(i): $(elapsedTime)", resolution * 0.5);
    drawText(engineFont, i"Time $(i): $(elapsedTime)", resolution * 0.5 + Vec2(0, 32));

    i = 6;
    fmt(i"Time $(i): $(elapsedTime)");
    fmtIntoBuffer(buffer[], i"Time $(i): $(elapsedTime)");
    fmtIntoList(buffer, i"Time $(i): $(elapsedTime)");
    return false;
}

mixin runGame!(ready, update, null);
