import parin;

auto csv = "090300,3a3432,4a4543,5c5855,807d7c,a5a2a2,d6d5d4,f7f7f7,db2d20,e8bbd0,fded02,01a252,b5e4f4,01a0e4,a16a94,cdab53
1C2023,393F45,565E65,747C84,ADB3BA,C7CCD1,DFE2E5,F3F4F5,C7AE95,C7C795,AEC795,95C7AE,95AEC7,AE95C7,C795AE,C79595
f4f3ec,e7e6df,929181,878573,6c6b5a,5f5e4e,302f27,22221b,ba6236,ae7313,a5980d,7d9726,5b9d48,36a166,5f9182,9d6c7c";

void ready() {
    println(1);
    foreach (item; csvRowToPalette!16(csv, 0, 0)) {
        println(item);
    }
    println(2);
    foreach (item; csvRowToPalette!16(csv, 1, 0)) {
        println(item);
    }
    println(3);

    foreach (item; csvRowToPalette!16(csv, 2, 0)) {
        println(item);
    }
    println(4);
    foreach (item; csvRowToPalette!16(csv, 3, 0)) {
        println(item);
    }
}

bool update(float dt) {
    if ('q'.isPressed) toggleIsFullscreen();
    drawText("Hello world!\nYep.\nHAHAHAHAHHAHA...", Vec2(8));
    return false;
}

mixin runGame!(ready, update, null);
