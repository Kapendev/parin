// TODO: skipValue might need some work. Not clear how splitting works.
// TODO: toStr char arrays might need some work. It has bad error messages for them.
// NOTE: Was about to add the dialogue stuff like jumping skipping...
// NOTE: Remember to update both joka and parin at the same time because there was a evil change.

/// The `story` module provides a simple and versatile dialogue system.
module parin.story;

import joka.types;
import joka.containers;
import joka.ascii;
import joka.io;
import joka.unions;

//Story Syntax:
//    #      Comment
//    *      Point
//    |      Line
//    >      Jump
//    ^      Menu
//    $      Expression

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
    THEN,
    NEXT,
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
    MENU,
    SKIP,
    JUMP,
    CALL,
}

alias StoryWord = char[16];
alias StoryNumber = long;
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
        if (data.isType!long) {
            result.copy(data.get!long().toStr());
        } else {
            auto temp = data.get!(char[16])()[];
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

struct Story {
    LStr script;
    List!uint startPoints;
    List!StoryVariable variables;
    int previousMenuResult;

    void prepare() {
        // TODO: Add stuff like points.
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
                if (token == NEXT.toStr()) ifCounter -= 1;
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
                        if (!db.isType!long || !da.isType!long) return Fault.invalid;
                        auto a = da.get!long;
                        auto b = db.get!long;
                        auto c = 0L;
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
                        if (!da.isType!long) return Fault.invalid;
                        stack.append(StoryValue(!da.get!long));
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
                    case THEN:
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        if (!da.isType!long) return Fault.invalid;
                        if (!da.get!long) ifCounter += 1;
                        break;
                    case NEXT:
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
                stack.append(StoryValue(tempResult.value));
            } else if (token.isMaybeStoryWord) {
                if (token.length > 16) return Fault.overflow;
                char[16] temp = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
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
