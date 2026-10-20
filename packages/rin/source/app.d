/// A Parin script interpreter.

import parin.joka;
import parin.joka.game;
import stdc = parin.joka.stdc;

RinState rinState;

extern(C) int fflush(stdc.FILE* stream) nothrow @nogc;

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

    IStr toStr(IStr f = __FILE__, Sz l = __LINE__) {
        return fmt("{}, {}", f, l);
    }
}

IStr prepareErrorMsg(Fault fault) {
    switch (fault) with (Fault) {
        case overflow: return "Label is too long.";
        case invalid: return "Invalid character at the beginning of the line.";
        default: return "WTF!";
    }
}

IStr updateErrorMsg(Fault fault) {
    switch (fault) with (Fault) {
        case assertion: return "Assertion failed.";
        case invalid: return "Invalid value, operator or symbol at token position {}.".fmt(rinState.story.faultTokenPosition);
        case overflow: return "A value is too long at token position {}.".fmt(rinState.story.faultTokenPosition);
        default: return "WTF!";
    }
}

void printScriptError(Sz index, IStr text) {
    printfln("ERROR({}:{}): {}", rinState.scriptPath, index, text);
}

Fault prepareStory() {
    if (auto fault = rinState.story.prepare()) {
        printScriptError(rinState.story.faultPrepareIndex + 1, prepareErrorMsg(fault));
        return fault;
    }
    return Fault.none;
}

@trusted
bool readLine(char[] buffer, ref IStr line) {
    auto length = 0LU;
    char c;
    while (stdc.fread(&c, 1, 1, stdc.stdin) == 1) {
        if (c == '\n') {
            line = buffer[0 .. length];
            return true;
        }
        if (length < buffer.length) {
            buffer[length] = c;
            length += 1;
        }
    }
    line = buffer[0 .. length];
    return length != 0;
}

Fault readMenuOption(ref Sz option) {
    auto options = rinState.story.menu;
    foreach (i, item; options) printfln("{} | {}", i + 1, item);
    char[64] buffer;
    IStr line;
    while (true) {
        // Flush so the prompt shows before reading.
        print(">>> ");
        fflush(stdc.stdout);
        if (!readLine(buffer, line)) break;
        auto number = line.trim().toUnsigned();
        if (!number.isNone && number.xx >= 1 && number.xx <= options.length) {
            option = cast(Sz) (number.xx - 1);
            return Fault.none;
        }
        printfln("Pick a number from 1 to {}.", options.length);
    }
    println("\nNo option was picked.");
    return Fault.cannotRead;
}

Fault updateStory() {
    auto fault = Fault.none;
    if (rinState.story.hasText) println(rinState.story.text);
    if (rinState.story.hasMenu) {
        auto option = Sz.init;
        if (auto readFault = readMenuOption(option)) return readFault;
        fault = rinState.story.select(option);
    } else {
        fault = rinState.story.update();
    }
    if (fault) printScriptError(rinState.story.lineIndex + 1, updateErrorMsg(fault));
    return fault;
}

int rinMain(string[] args) {
    if (args.length == 1) {
        println(helpMsg);
        return 0;
    }
    rinState.story.echonFunc = &echon;
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
                case cannotOpen: printfln("Can't open `{}`.", rinState.scriptPath); break;
                case cannotRead: printfln("Can't read `{}`.", rinState.scriptPath); break;
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
