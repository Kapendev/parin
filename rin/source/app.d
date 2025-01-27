/// A Parin script interpreter.

import joka;
import parin.story;

RinState rinState;

struct RinState {
    IStr scriptPath;
    Story story;
}

void printError(Sz index, IStr text) {
    printfln("\n{}({}): {}", rinState.scriptPath, index, text);
}

Fault prepareStory() {
    if (auto fault = rinState.story.prepare()) {
        auto index = rinState.story.faultPrepareIndex + 1;
        switch (fault) with (Fault) {
            overflow: printError(index, "Label is too long."); break;
            cantParse: printError(index, "Invalid character at the beginning of the line."); break;
            default: break;
        }
        return fault;
    }
    return Fault.none;
}

Fault updateStory() {
    if (rinState.story.hasText) println(rinState.story.text);
    if (auto fault = rinState.story.update()) {
        auto index = rinState.story.lineIndex + 1;
        switch (fault) with (Fault) {
            case assertion: printError(index, "Assertion failed."); break;
            case invalid: printError(index, "Invalid arguments passed to the `{}` operator.".format(rinState.story.faultOp)); break;
            case overflow: printError(index, "A word or number is too long."); break;
            case cantParse: printError(index, "A word, number, or operator contains invalid characters."); break;
            default: break;
        }
        return fault;
    }
    return Fault.none;
}

int rinMain(string[] args) {
    if (args.length == 1) {
        println("Usage: rin [options] script");
        println("Options: -debug -linear");
        return 0;
    }
    foreach (arg; args[1 .. $ - 1]) {
        if (arg == "-debug") rinState.story.debugMode = true;
        if (arg == "-linear") rinState.story.linearMode = true;
    }
    rinState.scriptPath = args[$ - 1];
    if (auto fault = readTextIntoBuffer(rinState.scriptPath, rinState.story.script)) {
        switch (fault) {
            case Fault.cantOpen: println("Can't open `{}`.".format(rinState.scriptPath)); break;
            case Fault.cantRead: println("Can't read `{}`.".format(rinState.scriptPath)); break;
            default: break;
        }
        return 1;
    }
    if (prepareStory()) return 1;
    if (updateStory()) return 1;
    while (rinState.story.lineIndex != rinState.story.lineCount) {
        if (updateStory()) return 1;
    }
    return 0;
}

int main(string[] args) {
    return rinMain(args);
}
