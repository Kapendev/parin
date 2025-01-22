// TODO: skipValue might need some work. Not clear how splitting works.
// TODO: toStr char arrays might need some work. It has bad error messages for them.
// TODO: concat and others might need a "intoBuffer" vesion.
// TODO: Look at CAT case and think about how to make it better with joka.
// NOTE: Remember to update both joka and parin at the same time because there was a evil change.
// NOTE: I will start cleanning and then will add CALL.

/// The `story` module provides a simple and versatile dialogue system.
module parin.story;

import joka.types;
import joka.containers;
import joka.ascii;
import joka.io;
import joka.unions;

enum StoryLineKind : ubyte {
    empty = ' ',
    comment = '#',
    label = '*',
    text = '|',
    pause = '.',
    menu = '^',
    expression = '$',
}

enum StoryOp : ubyte {
    ADD = '+',
    SUB = '-',
    MUL = '*',
    DIV = '/',
    MOD = '%',
    AND = '&',
    OR = '|',
    LESS = '<',
    GREATER = '>',
    EQUAL = '=',
    NOT = '!',
    POP = '~',
    CLEAR,
    SWAP,
    COPY,
    RANGE,
    IF,
    ELSE,
    THEN,
    CAT,
    WORD,
    NUM,
    DEBUG,
    END,
    ECHO,
    ECHON,
    LEAK,
    LOOK,
    HERE,
    GET,
    SET,
    INIT,
    DROP,
    DROPN,
    INC,
    DEC,
    INCN,
    DECN,
    TOG,
    MENU,
    LOOP,
    SKIP,
    JUMP,
    CALL,
}

alias StoryWord = char[24];
alias StoryNumber = int;
alias StoryValueData = Variant!(StoryWord, StoryNumber);

struct StoryValue {
    StoryValueData data;

    alias data this;

    static foreach (Type; StoryValueData.Types) {
        this(Type value) {
            data = value;
        }
    }

    IStr toStr() {
        static char[64] buffer = void;

        auto result = buffer[];
        if (data.isType!StoryNumber) {
            result.copy(data.get!StoryNumber().toStr());
        } else {
            auto temp = data.get!(StoryWord)()[];
            foreach (i, c; temp) {
                if (temp[i] == char.init) {
                    temp = temp[0 .. i];
                    break;
                }
            }
            result.copy(temp);
        }
        return result;
    }
}

struct StoryVariable {
    StoryWord name;
    StoryValue value;
}

struct StoryStartEndPair {
    uint a;
    uint b;
}

struct Story {
    LStr script;
    List!StoryStartEndPair pairs;
    List!StoryVariable labels;
    List!StoryValue stack;
    List!StoryVariable variables;
    StoryNumber lineIndex;
    StoryNumber nextLabelIndex;
    StoryNumber previousMenuResult;
    StoryNumber faultPrepareIndex;
    StoryOp faultOp;
    bool debugMode;

    IStr opIndex(Sz i) {
        if (i >= lineCount) {
            assert(0, "Index `{}` does not exist.".format(i));
        }
        auto pair = pairs[i];
        return script[pair.a .. pair.b];
    }

    Fault throwOpFault(StoryOp op) {
        faultOp = op;
        return Fault.invalid;
    }

    StoryNumber lineCount() {
        return cast(StoryNumber) pairs.length;
    }

    bool hasPause() {
        if (lineIndex == lineCount) return true;
        if (lineIndex >= lineCount) return false;
        auto line = opIndex(lineIndex);
        return line.length && line[0] == StoryLineKind.pause;
    }

    bool hasMenu() {
        if (lineIndex >= lineCount) return false;
        auto line = opIndex(lineIndex);
        return line.length && line[0] == StoryLineKind.menu;
    }

    bool hasText() {
        if (lineIndex >= lineCount) return false;
        auto line = opIndex(lineIndex);
        return line.length && line[0] == StoryLineKind.text;
    }

    IStr text() {
        if (hasText) return opIndex(lineIndex)[1 .. $].trimStart();
        else return "";
    }

    IStr[] menu() {
        static FixedList!(IStr, 16) buffer;

        buffer.clear();
        auto view = hasMenu ? opIndex(lineIndex)[1 .. $].trimStart() : "";
        while (view.length) {
            if (buffer.length == buffer.capacity) return buffer[];
            buffer.append(view.skipValue(StoryLineKind.menu).trim());
        }
        return buffer[];
    }

    Fault prepare() {
        lineIndex = 0;
        previousMenuResult = 0;
        pairs.clear();
        labels.clear();
        if (script.isEmpty) return Fault.none;
        auto start = 0;
        auto prepareIndex = 0;
        foreach (i, c; script) {
            if (c == '\n') {
                auto pair = StoryStartEndPair(start, cast(uint) i);
                auto line = script[pair.a .. pair.b];
                auto trimmedLine = line.trim();
                pair.a += line.length - line.trimStart().length;
                pair.b -= line.length - line.trimEnd().length;
                auto lineResult = toStoryLineKind(trimmedLine.length ? script[pair.a] : StoryLineKind.empty);
                if (lineResult.isNone) {
                    pairs.clear();
                    faultPrepareIndex = prepareIndex;
                    return Fault.cantParse;
                }
                auto kind = lineResult.value;
                if (kind == StoryLineKind.label) {
                    // TODO: Make words easier to use doooood.
                    auto name = trimmedLine[1 .. $].trimStart();
                    auto temp = StoryWord.init;
                    auto tempRef = temp[];
                    tempRef.copyChars(name); // TODO: Should maybe return a fault if it can't.
                    labels.append(StoryVariable(temp, StoryValue(cast(StoryNumber) pairs.length)));
                }
                pairs.append(pair);
                start = cast(int) (i + 1);
                prepareIndex += 1;
            }
        }
        lineIndex = lineCount;
        return Fault.none;
    }

    void parse(IStr text) {
        script.clear();
        script.append(text);
        prepare();
    }

    Fault execute(IStr expression) {
        stack.clear();
        auto ifCounter = 0;
        while (true) with (StoryOp) {
            if (expression.length == 0) break;
            auto token = expression.skipValue(' ');
            if (token.length == 0) continue;
            if (ifCounter > 0) {
                if (token == IF.toStr()) ifCounter += 1;
                if (token == ELSE.toStr() || token == THEN.toStr()) ifCounter -= 1;
                continue;
            }
            if (token.isMaybeStoryOp) {
                auto tempResult = token.toStoryOp();
                if (tempResult.isNone) return Fault.cantParse;
                auto op = tempResult.value;
                final switch (op) {
                    case ADD:
                    case SUB:
                    case MUL:
                    case DIV:
                    case MOD:
                    case AND:
                    case OR:
                    case LESS:
                    case GREATER:
                    case EQUAL:
                        if (stack.length < 2) return throwOpFault(op);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!db.isType!StoryNumber || !da.isType!StoryNumber) return throwOpFault(op);
                        auto a = da.get!StoryNumber;
                        auto b = db.get!StoryNumber;
                        auto c = StoryNumber.init;
                        switch (op) {
                            case ADD: c = b + a; break;
                            case SUB: c = b - a; break;
                            case MUL: c = b * a; break;
                            case DIV: c = b / a; break;
                            case MOD: c = b % a; break;
                            case AND: c = b && a; break;
                            case OR: c = b || a; break;
                            case LESS: c = b < a; break;
                            case GREATER: c = b > a; break;
                            case EQUAL: c = b == a; break;
                            default: assert(0, "TODO: {}".format(op));
                        }
                        stack.append(StoryValue(c));
                        break;
                    case NOT:
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        if (!da.isType!StoryNumber) return throwOpFault(op);
                        stack.append(StoryValue(!da.get!StoryNumber));
                        break;
                    case POP:
                        stack.pop();
                        break;
                    case CLEAR:
                        stack.clear();
                        break;
                    case SWAP:
                        if (stack.length < 2) return throwOpFault(op);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        stack.append(db);
                        stack.append(da);
                        break;
                    case COPY:
                        if (stack.length < 1) return throwOpFault(op);
                        stack.append(stack[$ - 1]);
                        break;
                    case RANGE:
                        if (stack.length < 3) return throwOpFault(op);
                        auto dc = stack.pop();
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!dc.isType!StoryNumber || !db.isType!StoryNumber || !da.isType!StoryNumber) return throwOpFault(op);
                        auto a = da.get!StoryNumber();
                        auto b = db.get!StoryNumber();
                        auto c = dc.get!StoryNumber();
                        stack.append(StoryValue(c >= b && c <= a));
                        break;
                    case IF:
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        if (!da.isType!StoryNumber) return throwOpFault(op);
                        if (!da.get!StoryNumber) ifCounter += 1;
                        break;
                    case ELSE:
                        ifCounter += 1;
                        break;
                    case THEN:
                        break;
                    case CAT:
                        if (stack.length < 2) return throwOpFault(op);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!db.isType!StoryWord) return throwOpFault(op);
                        StoryWord word;
                        auto data = concat(concat(db.toStr()), da.toStr());
                        if (data.length > word.length) return Fault.overflow;
                        auto tempWordRef = word[];
                        tempWordRef.copy(data);
                        stack.append(StoryValue(word));
                        break;
                    case WORD:
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        stack.append(StoryValue(da.isType!StoryWord));
                        break;
                    case NUM:
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        stack.append(StoryValue(da.isType!StoryNumber));
                        break;
                    case DEBUG:
                        stack.append(StoryValue(debugMode));
                        break;
                    case END:
                        return Fault.none;
                    case ECHO:
                        if (stack.length) println(stack[$ - 1]);
                        else println();
                        break;
                    case ECHON:
                        if (stack.length) print(stack[$ - 1], " ");
                        else print(" ");
                        break;
                    case LEAK:
                        print("Stack: [");
                        foreach (i, item; stack) {
                            auto space = " ";
                            auto separator = ",";
                            if (i == stack.length - 1) {
                                space = "";
                                separator = "";
                            }
                            print(item, separator, space);
                        }
                        println("]");
                        print("Variables: [");
                        foreach (i, item; variables) {
                            auto space = " ";
                            auto separator = ",";
                            if (i == variables.length - 1) {
                                space = "";
                                separator = "";
                            }
                            print(StoryValue(item.name), ": ", item.value, separator, space);
                        }
                        println("]");
                        break;
                    case LOOK:
                        if (stack.length) {
                            auto da = stack[$ - 1];
                            if (!da.isType!StoryWord) {
                                println();
                                break;
                            }
                            auto a = da.get!StoryWord();
                            auto isNotThere = true;
                            foreach (variable; variables) {
                                if (a == variable.name) {
                                    isNotThere = false;
                                    println(variable.value);
                                    break;
                                }
                            }
                            if (isNotThere) {
                                println();
                                break;
                            }
                        } else {
                            println();
                            break;
                        }
                        break;
                    case HERE:
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op);
                        auto a = da.get!StoryWord();
                        auto isNotThere = true;
                        foreach (variable; variables) {
                            if (a == variable.name) {
                                isNotThere = false;
                                break;
                            }
                        }
                        stack.append(StoryValue(!isNotThere));
                        break;
                    case GET:
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op);
                        auto a = da.get!StoryWord();
                        auto isNotThere = true;
                        foreach (variable; variables) {
                            if (a == variable.name) {
                                stack.append(variable.value);
                                isNotThere = false;
                                break;
                            }
                        }
                        if (isNotThere) return throwOpFault(op);
                        break;
                    case SET:
                        if (stack.length < 2) return throwOpFault(op);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!db.isType!StoryWord) return throwOpFault(op);
                        auto b = db.get!StoryWord();
                        auto isNotThere = true;
                        foreach (ref variable; variables) {
                            if (b == variable.name) {
                                variable.value = da;
                                isNotThere = false;
                                break;
                            }
                        }
                        if (isNotThere) variables.append(StoryVariable(b, da));
                        break;
                    case INIT:
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op);
                        auto a = da.get!StoryWord();
                        auto isNotThere = true;
                        foreach (ref variable; variables) {
                            if (a == variable.name) {
                                variable.value = StoryValue(0);
                                isNotThere = false;
                                break;
                            }
                        }
                        if (isNotThere) variables.append(StoryVariable(a, StoryValue(0)));
                        break;
                    case DROP:
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op);
                        auto a = da.get!StoryWord();
                        auto isNotThere = true;
                        foreach (i, variable; variables) {
                            if (a == variable.name) {
                                variables.remove(i);
                                break;
                            }
                        }
                        break;
                    case DROPN:
                        variables.clear();
                        break;
                    case INC:
                    case DEC:
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op);
                        auto a = da.get!StoryWord();
                        auto isNotThere = true;
                        foreach (ref variable; variables) {
                            if (a == variable.name) {
                                if (variable.value.isType!StoryNumber) {
                                    variable.value.get!StoryNumber() += (op == INC ? 1 : -1);
                                    stack.append(variable.value);
                                } else {
                                    return throwOpFault(op);
                                }
                                isNotThere = false;
                                break;
                            }
                        }
                        if (isNotThere) return throwOpFault(op);
                        break;
                    case INCN:
                    case DECN:
                        if (stack.length < 2) return throwOpFault(op);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!db.isType!StoryWord || !da.isType!StoryNumber) return throwOpFault(op);
                        auto b = db.get!StoryWord();
                        auto a = da.get!StoryNumber();
                        auto isNotThere = true;
                        foreach (ref variable; variables) {
                            if (b == variable.name) {
                                if (variable.value.isType!StoryNumber) {
                                    variable.value.get!StoryNumber() += a * (op == INCN ? 1 : -1);
                                    stack.append(variable.value);
                                } else {
                                    return throwOpFault(op);
                                }
                                isNotThere = false;
                                break;
                            }
                        }
                        if (isNotThere) return throwOpFault(op);
                        break;
                    case TOG:
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op);
                        auto a = da.get!StoryWord();
                        auto isNotThere = true;
                        foreach (ref variable; variables) {
                            if (a == variable.name) {
                                if (variable.value.isType!StoryNumber) {
                                    variable.value.get!StoryNumber() = !variable.value.get!StoryNumber();
                                    stack.append(variable.value);
                                } else {
                                    return throwOpFault(op);
                                }
                                isNotThere = false;
                                break;
                            }
                        }
                        if (isNotThere) return throwOpFault(op);
                        break;
                    case MENU:
                        stack.append(StoryValue(previousMenuResult));
                        break;
                    case LOOP:
                        if (debugMode) break;
                        auto target = nextLabelIndex - 1;
                        if (target < 0 || target >= labels.length || labels.length == 0) {
                            lineIndex = lineCount;
                            nextLabelIndex = 0;
                        } else {
                            lineIndex = labels[target].value.get!StoryNumber();
                            nextLabelIndex = cast(StoryNumber) ((target + 1) % (labels.length + 1));
                        }
                        break;
                    case SKIP:
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        if (!da.isType!StoryNumber) return throwOpFault(op);
                        auto a = da.get!StoryNumber();
                        if (a == 0) break;
                        if (debugMode) break;
                        auto target = nextLabelIndex + (a > 0 ? a - 1 : a);
                        if (target < 0 || target >= labels.length || labels.length == 0) {
                            lineIndex = lineCount;
                            nextLabelIndex = 0;
                        } else {
                            lineIndex = labels[target].value.get!StoryNumber();
                            nextLabelIndex = cast(StoryNumber) ((target + 1) % (labels.length + 1));
                        }
                        break;
                    case JUMP:
                        // TODO: Write a find function like a normal person.
                        // TODO: Might need some error check for -1.
                        if (stack.length < 1) return throwOpFault(op);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op);
                        auto a = da.get!StoryWord();
                        auto isNotThere = true;
                        foreach (i, ref label; labels) {
                            if (a == label.name) {
                                isNotThere = false;
                                if (debugMode) break;
                                lineIndex = label.value.get!StoryNumber();
                                nextLabelIndex = cast(StoryNumber) ((i + 1) % (labels.length + 1));
                                break;
                            }
                        }
                        if (isNotThere) return throwOpFault(op);
                        break;
                    case CALL:
                        println("TODO: ", op);
                        return Fault.none;
                }
            } else if (token.isMaybeStoryNumber) {
                auto tempResult = token.toSigned();
                if (tempResult.isNone) return tempResult.fault;
                stack.append(StoryValue(cast(StoryNumber) tempResult.value));
            } else if (token.isMaybeStoryWord) {
                if (token.length > StoryWord.length) return Fault.overflow;
                StoryWord temp;
                foreach (i, c; token) temp[i] = c;
                stack.append(StoryValue(temp));
            } else {
                return Fault.cantParse;
            }
        }
        return Fault.none;
    }

    Fault update() {
        if (lineCount == 0) return Fault.none;
        lineIndex = (lineIndex + 1) % (lineCount + 1);
        while (lineIndex < lineCount && !hasPause && !hasMenu && !hasText) {
            auto line = opIndex(lineIndex);
            if (line.length) {
                if (line[0] == StoryLineKind.expression) {
                    auto fault = execute(line[1 .. $].trimStart());
                    if (fault) return fault;
                } else if (line[0] == StoryLineKind.label) {
                    nextLabelIndex = cast(StoryNumber) ((nextLabelIndex + 1) % (labels.length + 1));
                }
            }
            lineIndex = (lineIndex + 1) % (lineCount + 1);
        }
        return Fault.none;
    }

    Fault select(Sz i) {
        previousMenuResult = cast(StoryNumber) (i + 1);
        return update();
    }
}

bool isMaybeStoryOp(IStr value) {
    if (value.length == 0) return false;
    auto c = value[0];
    if (c.isSymbol) {
        if (c == '_') return false;
        return value.length == 1;
    } else {
        return c.isUpper;
    }
}

bool isMaybeStoryNumber(IStr value) {
    if (value.length == 0) return false;
    auto c = value[0];
    if (c.isSymbol) {
        if (c == '_') return false;
        return value.length >= 2 && value[1].isDigit;
    } else {
        return c.isDigit;
    }
}

bool isMaybeStoryWord(IStr value) {
    if (value.length == 0) return false;
    auto c = value[0];
    return c == '_' || (!c.isUpper && !c.isSymbol);
}

Result!StoryLineKind toStoryLineKind(char value) {
    switch (value) with (StoryLineKind) {
        case ' ': return Result!StoryLineKind(empty);
        case '#': return Result!StoryLineKind(comment);
        case '*': return Result!StoryLineKind(label);
        case '|': return Result!StoryLineKind(text);
        case '.': return Result!StoryLineKind(pause);
        case '^': return Result!StoryLineKind(menu);
        case '$': return Result!StoryLineKind(expression);
        default: return Result!StoryLineKind(Fault.invalid);
    }
}

Result!StoryOp toStoryOp(IStr value) {
    switch (value) with (StoryOp) {
        case "+": return Result!StoryOp(ADD);
        case "-": return Result!StoryOp(SUB);
        case "*": return Result!StoryOp(MUL);
        case "/": return Result!StoryOp(DIV);
        case "%": return Result!StoryOp(MOD);
        case "&": return Result!StoryOp(AND);
        case "|": return Result!StoryOp(OR);
        case "<": return Result!StoryOp(LESS);
        case ">": return Result!StoryOp(GREATER);
        case "=": return Result!StoryOp(EQUAL);
        case "!": return Result!StoryOp(NOT);
        case "~": return Result!StoryOp(POP);
        default: break;
    }
    return toEnum!StoryOp(value);
}
