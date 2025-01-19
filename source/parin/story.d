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
    SWAP,
    COPY,
    IF,
    THEN,
    END,
    ECHO,
    LEAK,
    GET,
    SET,
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
    FixedList!(StoryValue, 8) stack;
    List!StoryVariable variables;
    int previousMenuResult;

    Fault evaluate(IStr expression) {
        stack.clear();
        auto ifCounter = 0;
        while (true) {
            if (expression.length == 0) break;
            auto token = expression.skipValue(' ');
            if (token.length == 0) continue;
            if (ifCounter > 0) {
                if (token == StoryOp.THEN.toStr()) ifCounter -= 1;
                continue;
            }
            if (token.isMaybeStoryOp) {
                auto tempResult = token.toStoryOp();
                if (tempResult.isNone) return Fault.cantParse;
                auto op = tempResult.value;
                final switch (op) {
                    case StoryOp.ADD:
                    case StoryOp.SUB:
                    case StoryOp.MUL:
                    case StoryOp.DIV:
                    case StoryOp.MOD:
                    case StoryOp.AND:
                    case StoryOp.OR:
                    case StoryOp.LESS:
                    case StoryOp.GREATER:
                    case StoryOp.EQUAL:
                        if (stack.length < 2) return Fault.invalid;
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!db.isType!long || !da.isType!long) return Fault.invalid;
                        auto a = da.get!long;
                        auto b = db.get!long;
                        auto c = 0L;
                        switch (op) {
                            case StoryOp.ADD: c = b + a; break;
                            case StoryOp.SUB: c = b - a; break;
                            case StoryOp.MUL: c = b * a; break;
                            case StoryOp.DIV: c = b / a; break;
                            case StoryOp.MOD: c = b % a; break;
                            case StoryOp.AND: c = b && a; break;
                            case StoryOp.OR: c = b || a; break;
                            case StoryOp.LESS: c = b < a; break;
                            case StoryOp.GREATER: c = b > a; break;
                            case StoryOp.EQUAL: c = b == a; break;
                            default: assert(0, "TODO: {}".format(op));
                        }
                        stack.append(StoryValue(c));
                        break;
                    case StoryOp.NOT:
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        if (!da.isType!long) return Fault.invalid;
                        stack.append(StoryValue(!da.get!long));
                        break;
                    case StoryOp.POP:
                        if (stack.length < 1) return Fault.invalid;
                        stack.pop();
                        break;
                    case StoryOp.SWAP:
                        if (stack.length < 2) return Fault.invalid;
                        auto db = stack.pop();
                        auto da = stack.pop();
                        stack.append(db);
                        stack.append(da);
                        break;
                    case StoryOp.COPY:
                        if (stack.length < 1) return Fault.invalid;
                        stack.append(stack[$ - 1]);
                        break;
                    case StoryOp.IF:
                        if (stack.length < 1) return Fault.invalid;
                        auto da = stack.pop();
                        if (!da.isType!long) return Fault.invalid;
                        if (!da.get!long) ifCounter += 1;
                        break;
                    case StoryOp.THEN:
                        break;
                    case StoryOp.END:
                        return Fault.none;
                    case StoryOp.ECHO:
                        if (stack.length) println(stack[$ - 1]);
                        else println();
                        break;
                    case StoryOp.LEAK:
                        print("[");
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
                        break;
                    case StoryOp.GET:
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
                    case StoryOp.SET:
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
                    case StoryOp.MENU:
                        stack.append(StoryValue(previousMenuResult));
                        break;
                    case StoryOp.INC:
                    case StoryOp.DEC:
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
                                    variable.value.get!StoryNumber() += a * (op == StoryOp.INC ? 1 : -1);
                                } else {
                                    return Fault.invalid;
                                }
                                isNotThere = false;
                                break;
                            }
                        }
                        if (isNotThere) return Fault.invalid;
                        break;
                    case StoryOp.SKIP:
                    case StoryOp.JUMP:
                    case StoryOp.CALL:
                        println("TODO: ", op);
                        break;
                }
            } else if (token.isMaybeStoryNumber) {
                auto tempResult = token.toSigned();
                if (tempResult.isNone) return Fault.cantParse;
                stack.append(StoryValue(tempResult.value));
            } else if (token.isMaybeStoryWord) {
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
    auto isSymbol = (c >= '!' && c <= '/') || (c >= ':' && c <= '@') || (c >= '[' && c <= '`') || (c >= '{' && c <= '~');
    if (isSymbol) {
        if (c == '_') return false;
        return value.length == 1;
    } else {
        return c.isUpper;
    }
}

bool isMaybeStoryNumber(IStr value) {
    if (value.length == 0) return false;
    auto c = value[0];
    auto isSymbol = (c >= '!' && c <= '/') || (c >= ':' && c <= '@') || (c >= '[' && c <= '`') || (c >= '{' && c <= '~');
    if (isSymbol) {
        if (c == '_') return false;
        return value.length >= 2 && value[1].isDigit;
    } else {
        return c.isDigit;
    }
}

bool isMaybeStoryWord(IStr value) {
    if (value.length == 0) return false;
    auto c = value[0];
    auto isSymbol = (c >= '!' && c <= '/') || (c >= ':' && c <= '@') || (c >= '[' && c <= '`') || (c >= '{' && c <= '~');
    return c == '_' || (!c.isUpper && !isSymbol);
}

Result!StoryOp toStoryOp(IStr value) {
    switch (value) {
        case "+": return Result!StoryOp(StoryOp.ADD);
        case "-": return Result!StoryOp(StoryOp.SUB);
        case "*": return Result!StoryOp(StoryOp.MUL);
        case "/": return Result!StoryOp(StoryOp.DIV);
        case "%": return Result!StoryOp(StoryOp.MOD);
        case "&": return Result!StoryOp(StoryOp.AND);
        case "|": return Result!StoryOp(StoryOp.OR);
        case "<": return Result!StoryOp(StoryOp.LESS);
        case ">": return Result!StoryOp(StoryOp.GREATER);
        case "=": return Result!StoryOp(StoryOp.EQUAL);
        case "!": return Result!StoryOp(StoryOp.NOT);
        case "~": return Result!StoryOp(StoryOp.POP);
        default: break;
    }
    return toEnum!StoryOp(value);
}
