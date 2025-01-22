/// A Parin script interpreter.

import joka;
import parin.story;

IStr path;
Story story;

void printError(Sz index, IStr text) {
    printfln("{}({}): {}", path, index, text);
}

Fault prepareStory() {
    if (auto fault = story.prepare()) {
        auto index = story.faultPrepareIndex + 1;
        printError(index, "Invalid character at the beginning of the line.");
        return fault;
    }
    return Fault.none;
}

Fault updateStory() {
    if (story.hasText) println(story.text);
    if (auto fault = story.update()) {
        auto index = story.lineIndex + 1;
        switch (fault) with (Fault) {
            case invalid: printError(index, "Invalid arguments passed to the `{}` operator.".format(story.faultOp)); break;
            case overflow: printError(index, "A word or number is too long."); break;
            case cantParse: printError(index, "A word, number, or operator contains invalid characters."); break;
            default: break;
        }
        return fault;
    }
    return Fault.none;
}

int main(string[] args) {
    if (args.length == 1) {
        println("Usage: rin [options] script");
        println("Options: -debug");
        return 0;
    }
    foreach (arg; args[1 .. $ - 1]) {
        if (arg == "-debug") story.debugMode = true;
    }
    path = args[$ - 1];
    if (auto fault = readTextIntoBuffer(path, story.script)) {
        switch (fault) {
            case Fault.cantOpen: println("Can't find file `{}`.".format(path)); break;
            case Fault.cantRead: println("Can't read file `{}`.".format(path)); break;
            default: break;
        }
        return 1;
    }
    if (prepareStory()) return 1;
    if (updateStory()) return 1;
    while (story.lineIndex != story.lineCount) {
        if (updateStory()) return 1;
    }
    return 0;
}
