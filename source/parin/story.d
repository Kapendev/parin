// TODO: skipValue might need some work. Not clear how splitting works.
// TODO: toStr char arrays might need some work. It has bad error messages for them.
// TODO: concat and others might need a "intoBuffer" vesion.
// TODO: Look at CAT case and think about how to make it better with joka.
// NOTE: Was about to add the dialogue stuff like jumping skipping...
// NOTE: Remember to update both joka and parin at the same time because there was a evil change.
// NOTE: The point it to get something working. Clean later.

/// The `story` module provides a simple and versatile dialogue system.
module parin.story;

import joka.types;
import joka.containers;
import joka.ascii;
import joka.io;
import joka.unions;

enum defaultStoryWord = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

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
    IF,
    ELSE,
    THEN,
    CAT,
    WORD,
    NUM,
    END,
    ECHO,
    LEAK,
    LOOK,
    HERE,
    GET,
    SET,
    INIT,
    DROP,
    INC,
    DEC,
    TOG,
    MENU,
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
                if (temp[i] == 0) {
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
    List!StoryStartEndPair startEndPairs;
    int previousMenuResult;
    List!StoryVariable variables;

    void prepare() {
        startEndPairs.clear();
        previousMenuResult = 0;
        if (script.isEmpty) return;
        auto start = 0;
        foreach (i, c; script) {
            if (c == '\n') {
                auto pair = StoryStartEndPair(cast(uint) start, cast(uint) i);
                if (pair.a == pair.b) continue; // Might not work with windows. (\n or \r\n)
                startEndPairs.append(pair);
                start = pair.b + 1;
            }
        }
    }

    Fault evaluate(IStr expression) {
        static FixedList!(StoryValue, 16) stack;

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
                        if (stack.length < 2) return Fault.invalid;
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!db.isType!StoryNumber || !da.isType!StoryNumber) return Fault.invalid;
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
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        if (!da.isType!StoryNumber) return Fault.invalid;
                        stack.append(StoryValue(!da.get!StoryNumber));
                        break;
                    case POP:
                        stack.pop();
                        break;
                    case CLEAR:
                        stack.clear();
                        break;
                    case SWAP:
                        if (stack.length < 2) return Fault.invalid;
                        auto db = stack.pop();
                        auto da = stack.pop();
                        stack.append(db);
                        stack.append(da);
                        break;
                    case COPY:
                        if (stack.length < 1) return Fault.invalid;
                        stack.append(stack[$ - 1]);
                        break;
                    case IF:
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        if (!da.isType!StoryNumber) return Fault.invalid;
                        if (!da.get!StoryNumber) ifCounter += 1;
                        break;
                    case ELSE:
                        ifCounter += 1;
                        break;
                    case THEN:
                        break;
                    case CAT:
                        if (stack.length < 2) return Fault.invalid;
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!db.isType!StoryWord || !da.isType!StoryWord) return Fault.invalid;
                        StoryWord word = defaultStoryWord;
                        auto data = concat(concat(db.toStr()), da.toStr());
                        if (data.length > word.length) return Fault.overflow;
                        auto tempWordRef = word[];
                        tempWordRef.copy(data);
                        stack.append(StoryValue(word));
                        break;
                    case WORD:
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        stack.append(StoryValue(da.isType!StoryWord));
                        break;
                    case NUM:
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        stack.append(StoryValue(da.isType!StoryNumber));
                        break;
                    case END:
                        return Fault.none;
                    case ECHO:
                        if (stack.length) println(stack[$ - 1]);
                        else println();
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
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return Fault.invalid;
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
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return Fault.invalid;
                        auto a = da.get!StoryWord();
                        auto isNotThere = true;
                        foreach (variable; variables) {
                            if (a == variable.name) {
                                stack.append(variable.value);
                                isNotThere = false;
                                break;
                            }
                        }
                        if (isNotThere) return Fault.invalid;
                        break;
                    case SET:
                        if (stack.length < 2) return Fault.invalid;
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!db.isType!StoryWord) return Fault.invalid;
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
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return Fault.invalid;
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
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return Fault.invalid;
                        auto a = da.get!StoryWord();
                        auto isNotThere = true;
                        foreach (i, variable; variables) {
                            if (a == variable.name) {
                                variables.remove(i);
                                break;
                            }
                        }
                        break;
                    case INC:
                    case DEC:
                        if (stack.length < 2) return Fault.invalid;
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!db.isType!StoryWord || !da.isType!StoryNumber) return Fault.invalid;
                        auto b = db.get!StoryWord();
                        auto a = da.get!StoryNumber();
                        auto isNotThere = true;
                        foreach (ref variable; variables) {
                            if (b == variable.name) {
                                if (variable.value.isType!StoryNumber) {
                                    variable.value.get!StoryNumber() += a * (op == INC ? 1 : -1);
                                    stack.append(variable.value);
                                } else {
                                    return Fault.invalid;
                                }
                                isNotThere = false;
                                break;
                            }
                        }
                        if (isNotThere) return Fault.invalid;
                        break;
                    case TOG:
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return Fault.invalid;
                        auto a = da.get!StoryWord();
                        auto isNotThere = true;
                        foreach (ref variable; variables) {
                            if (a == variable.name) {
                                if (variable.value.isType!StoryNumber) {
                                    variable.value.get!StoryNumber() = !variable.value.get!StoryNumber();
                                    stack.append(variable.value);
                                } else {
                                    return Fault.invalid;
                                }
                                isNotThere = false;
                                break;
                            }
                        }
                        if (isNotThere) return Fault.invalid;
                        break;
                    case MENU:
                        stack.append(StoryValue(previousMenuResult));
                        break;
                    case SKIP:
                    case JUMP:
                    case CALL:
                        println("TODO: ", op);
                        break;
                }
            } else if (token.isMaybeStoryNumber) {
                auto tempResult = token.toSigned();
                if (tempResult.isNone) return tempResult.fault;
                stack.append(StoryValue(cast(StoryNumber) tempResult.value));
            } else if (token.isMaybeStoryWord) {
                if (token.length > 16) return Fault.overflow;
                StoryWord temp = defaultStoryWord;
                foreach (i, c; token) temp[i] = c;
                stack.append(StoryValue(temp));
            } else {
                return Fault.cantParse;
            }
        }
        return Fault.none;
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
