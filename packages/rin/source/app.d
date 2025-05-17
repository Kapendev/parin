/// A Parin script interpreter.

import joka;
import parin.story;

RinState rinState;

enum helpMsg = `
Usage
 rin [options] script
 rin [options] -e expression
Options
 -d  Executes in debug mode.
 -l  Executes in linear mode.
 -e  Executes a single expression.
`[1 .. $ - 1];

struct RinState {
    IStr scriptPath;
    Story story;
    bool executeMode;
}

IStr prepareErrorMsg(Fault fault) {
    switch (fault) with (Fault) {
        case overflow: return "Label is too long.";
        case cantParse: return "Invalid character at the beginning of the line.";
        default: return "WTF!";
    }
}

IStr updateErrorMsg(Fault fault) {
    switch (fault) with (Fault) {
        case assertion: return "Assertion failed.";
        case invalid: return "Invalid values passed to `{}` at token position `{}`.".fmt(rinState.story.faultOp, rinState.story.faultTokenPosition);
        case overflow: return "A value is too long at token position `{}`.".fmt(rinState.story.faultTokenPosition);
        case cantParse: return "A value or operator contains invalid characters at token position `{}`.".fmt(rinState.story.faultTokenPosition);
        default: return "WTF!";
    }
}

void printScriptError(Sz index, IStr text) {
    printfln("{}:{}\n {}", rinState.scriptPath, index, text);
}

Fault prepareStory() {
    if (auto fault = rinState.story.prepare()) {
        printScriptError(rinState.story.faultPrepareIndex + 1, prepareErrorMsg(fault));
        return fault;
    }
    return Fault.none;
}

Fault updateStory() {
    if (rinState.story.hasText) println(rinState.story.text);
    if (auto fault = rinState.story.update()) {
        printScriptError(rinState.story.lineIndex + 1, updateErrorMsg(fault));
        return fault;
    }
    return Fault.none;
}

int rinMain(string[] args) {
    if (args.length == 1) {
        println(helpMsg);
        return 0;
    }
    auto executeIndex = 0LU;
    foreach (i, arg; args) {
        switch (arg) {
            case "-d": rinState.story.debugMode = true; break;
            case "-l": rinState.story.linearMode = true; break;
            case "-e": rinState.executeMode = true; executeIndex = i; break;
            default: break;
        }
    }
    if (rinState.executeMode) {
        List!char expression;
        foreach (arg; args[executeIndex + 1 .. $]) {
            expression.append(arg);
            expression.append(' ');
        }
        if (auto fault = rinState.story.execute(expression[])) {
            println(updateErrorMsg(fault));
            return 1;
        }
    } else {
        rinState.scriptPath = args[$ - 1];
        if (auto fault = readTextIntoBuffer(rinState.scriptPath, rinState.story.script)) {
            switch (fault) with (Fault) {
                case cantOpen: printfln("Can't open `{}`.", rinState.scriptPath); break;
                case cantRead: printfln("Can't read `{}`.", rinState.scriptPath); break;
                default: break;
            }
            return 1;
        }
        if (prepareStory()) return 1;
        if (updateStory()) return 1;
        while (rinState.story.lineIndex != rinState.story.lineCount) {
            if (updateStory()) return 1;
        }
    }
    return 0;
}

int main(string[] args) {
    return rinMain(args);
}
