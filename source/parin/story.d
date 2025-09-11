// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// ---

// TODO: Update all the doc comments here.

/// The `story` module provides a simple and versatile dialogue system.
module parin.story;

import joka.ascii;
import joka.containers;
import joka.io;
import joka.types;

@safe nothrow:

enum defaultStoryFixedListCapacity = 16;

enum StoryLineKind : ubyte {
    empty = ' ',
    comment = '#',
    label = '*',
    text = '|',
    pause = '.',
    menu = '^',
    expression = '$',
    procedure = '!',
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
    COPYN,
    RANGE,
    IF,
    ELSE,
    THEN,
    CAT,
    SAME,
    WORD,
    NUMBER,
    LINE,
    DEBUG,
    LINEAR,
    ASSERT,
    END,
    ECHO,
    ECHON,
    LEAK,
    LEAKN,
    HERE,
    GET,
    GETN,
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
}

alias StoryWord = char[24];
alias StoryNumber = int;
alias StoryValueData = Union!(StoryWord, StoryNumber);

struct StoryValue {
    StoryValueData data;

    alias data this;

    @safe nothrow @nogc:

    static foreach (Type; StoryValueData.Types) {
        this(Type value) {
            data = value;
        }
    }

    @trusted
    IStr toStr() {
        if (data.isType!StoryNumber) {
            return fmt("{}", data.as!StoryNumber());
        } else {
            auto temp = data.as!(StoryWord)()[];
            return fmt("{}", temp[0 .. temp.findStart(char.init)]);
        }
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
    List!StoryVariable variables;
    StoryNumber lineIndex;
    StoryNumber nextLabelIndex;
    StoryNumber previousMenuResult;
    StoryNumber faultPrepareIndex;
    StoryOp faultOp;
    Sz faultTokenPosition;
    bool debugMode;
    bool linearMode;

    @safe nothrow:

    @nogc
    IStr opIndex(Sz i) {
        if (i >= lineCount) assert(0, "Index `[{}]` does not exist.".fmt(i));
        return script[pairs[i].a .. pairs[i].b + 1];
    }

    @nogc
    StoryNumber lineCount() {
        return cast(StoryNumber) pairs.length;
    }

    @nogc
    bool hasKind(StoryLineKind kind) {
        if (lineIndex >= lineCount) return false;
        auto line = opIndex(lineIndex);
        return line.length && line[0] == kind;
    }

    @nogc
    bool hasEnd() {
        return lineIndex == lineCount;
    }

    @nogc
    bool hasPause() {
        if (hasEnd) return true;
        return hasKind(StoryLineKind.pause);
    }

    @nogc
    bool hasProcedure() {
        return hasKind(StoryLineKind.procedure);
    }

    @nogc
    bool hasMenu() {
        return hasKind(StoryLineKind.menu);
    }

    @nogc
    bool hasText() {
        return hasKind(StoryLineKind.text);
    }

    @nogc
    IStr[] procedure() {
        static FixedList!(IStr, defaultStoryFixedListCapacity) buffer;

        buffer.clear();
        if (!hasProcedure) return [];
        auto view = opIndex(lineIndex)[1 .. $].trimStart();
        while (view.length) {
            buffer.append(view.skipValue(' ').trimEnd());
            view = view.trimStart();
        }
        return buffer[];
    }

    @nogc
    IStr[] menu() {
        static FixedList!(IStr, defaultStoryFixedListCapacity) buffer;

        buffer.clear();
        if (!hasMenu) return [];
        auto view = opIndex(lineIndex)[1 .. $].trimStart();
        while (view.length) {
            buffer.append(view.skipValue(StoryLineKind.menu).trimEnd());
            view = view.trimStart();
        }
        return buffer[];
    }

    @nogc
    IStr text() {
        if (!hasText) return "";
        return opIndex(lineIndex)[1 .. $].trimStart();
    }

    @nogc
    Fault throwOpFault(StoryOp op, Sz position) {
        faultOp = op;
        faultTokenPosition = position;
        return Fault.invalid;
    }

    @nogc
    StoryNumber findVariable(StoryWord name) {
        foreach (i, variable; variables) {
            if (name == variable.name) return cast(StoryNumber) i;
        }
        return -1;
    }

    @nogc
    StoryNumber findLabel(StoryWord name) {
        foreach (i, label; labels) {
            if (name == label.name) return cast(StoryNumber) i;
        }
        return -1;
    }

    @nogc
    void setNextLabelIndex(StoryNumber value) {
        nextLabelIndex = cast(StoryNumber) (value % (labels.length + 1));
    }

    @nogc
    void setLineIndex(StoryNumber value) {
        lineIndex = (value) % (lineCount + 1);
    }

    @nogc
    void resetLineIndex() {
        lineIndex = lineCount;
        nextLabelIndex = 0;
    }

    @nogc
    void jumpLineIndex(StoryNumber labelIndex) {
        lineIndex = labels[labelIndex].value.as!StoryNumber();
        setNextLabelIndex(labelIndex + 1);
    }

    @trusted
    Fault prepare(IStr file = __FILE__, Sz line = __LINE__) {
        previousMenuResult = 0;
        resetLineIndex();
        pairs.clear();
        labels.clear();
        if (script.isEmpty) return Fault.none;
        auto startIndex = StoryNumber.init;
        auto prepareIndex = StoryNumber.init;
        foreach (i, c; script) {
            if (c == '\n') {
                auto pair = StoryStartEndPair(cast(uint) startIndex, cast(uint) i);
                auto scriptLine = script[pair.a .. pair.b + 1];
                pair.a += scriptLine.length - scriptLine.trimStart().length;
                if (pair.a > pair.b) {
                    pair.a = pair.b;
                    scriptLine = script[pair.a .. pair.b];
                } else {
                    pair.b -= scriptLine.length - scriptLine.trimEnd().length;
                    scriptLine = script[pair.a .. pair.b + 1];
                }
                auto kind = toStoryLineKind(scriptLine.length ? script[pair.a] : StoryLineKind.empty);
                if (kind.isNone) {
                    pairs.clear();
                    labels.clear();
                    faultPrepareIndex = prepareIndex;
                    return kind.fault;
                }
                if (kind.xx == StoryLineKind.label) {
                    auto name = scriptLine[1 .. $].trimStart();
                    auto word = StoryWord.init;
                    auto wordRef = word[];
                    if (auto fault = wordRef.copyChars(name)) {
                        pairs.clear();
                        labels.clear();
                        faultPrepareIndex = prepareIndex;
                        return fault;
                    }
                    labels.appendSource(file, line, StoryVariable(word, StoryValue(cast(StoryNumber) pairs.length)));
                }
                pairs.appendSource(file, line, pair);
                prepareIndex += 1;
                startIndex = cast(StoryNumber) (i + 1);
            }
        }
        resetLineIndex();
        return Fault.none;
    }

    Fault parse(IStr text, IStr file = __FILE__, Sz line = __LINE__) {
        script.clear();
        script.appendSource(file, line, text);
        return prepare();
    }

    @trusted
    Fault execute(IStr expression, IStr file = __FILE__, Sz line = __LINE__) {
        static FixedList!(StoryValue, defaultStoryFixedListCapacity) stack;

        stack.clear();
        auto ifCounter = 0;
        auto tokenCount = 0;
        while (true) with (StoryOp) {
            if (expression.length == 0) break;
            auto token = expression.skipValue(' ');
            tokenCount += 1;
            expression = expression.trimStart();
            if (token.length == 0) continue;
            if (ifCounter > 0) {
                if (token == IF.toStr()) ifCounter += 1;
                if (token == ELSE.toStr() || token == THEN.toStr()) ifCounter -= 1;
                continue;
            }
            if (token.isMaybeStoryOp) {
                auto tempOp = token.toStoryOp();
                if (tempOp.isNone) {
                    faultTokenPosition = tokenCount;
                    return tempOp.fault;
                }
                auto op = tempOp.xx;
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
                        if (stack.length < 2) return throwOpFault(op, tokenCount);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!da.isType!StoryNumber || !db.isType!StoryNumber) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryNumber;
                        auto b = db.as!StoryNumber;
                        auto c = StoryNumber.init;
                        switch (op) {
                            case ADD: c = a + b; break;
                            case SUB: c = a - b; break;
                            case MUL: c = a * b; break;
                            case DIV: c = (b != 0) ? (a / b) : 0; break;
                            case MOD: c = (b != 0) ? (a % b) : 0; break;
                            case AND: c = a && b; break;
                            case OR: c = a || b; break;
                            case LESS: c = a < b; break;
                            case GREATER: c = a > b; break;
                            case EQUAL: c = a == b; break;
                            default: assert(0, "WTF!");
                        }
                        stack.append(StoryValue(c));
                        break;
                    case NOT:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryNumber) return throwOpFault(op, tokenCount);
                        stack.append(StoryValue(!da.as!StoryNumber));
                        break;
                    case POP:
                        stack.pop();
                        break;
                    case CLEAR:
                        stack.clear();
                        break;
                    case SWAP:
                        if (stack.length < 2) return throwOpFault(op, tokenCount);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        stack.append(db);
                        stack.append(da);
                        break;
                    case COPY:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        stack.append(stack[$ - 1]);
                        break;
                    case COPYN:
                        if (stack.length < 2) return throwOpFault(op, tokenCount);
                        stack.append(stack[$ - 2]);
                        stack.append(stack[$ - 2]);
                        break;
                    case RANGE:
                        if (stack.length < 3) return throwOpFault(op, tokenCount);
                        auto dc = stack.pop();
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!da.isType!StoryNumber || !db.isType!StoryNumber || !dc.isType!StoryNumber) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryNumber();
                        auto b = db.as!StoryNumber();
                        auto c = dc.as!StoryNumber();
                        stack.append(StoryValue(a >= b && a <= c));
                        break;
                    case IF:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryNumber) return throwOpFault(op, tokenCount);
                        if (!da.as!StoryNumber) ifCounter += 1;
                        break;
                    case ELSE:
                        ifCounter += 1;
                        break;
                    case THEN:
                        break;
                    case CAT:
                        if (stack.length < 2) return throwOpFault(op, tokenCount);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        StoryWord word;
                        auto data = concat(da.toStr(), db.toStr());
                        auto tempWordRef = word[];
                        if (auto fault = tempWordRef.copyChars(data)) {
                            faultTokenPosition = tokenCount;
                            return fault;
                        }
                        stack.append(StoryValue(word));
                        break;
                    case SAME:
                        if (stack.length < 2) return throwOpFault(op, tokenCount);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        auto a = da.as!StoryWord;
                        auto b = db.as!StoryWord;
                        stack.append(StoryValue(a == b));
                        break;
                    case WORD:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        stack.append(StoryValue(da.isType!StoryWord));
                        break;
                    case NUMBER:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        stack.append(StoryValue(da.isType!StoryNumber));
                        break;
                    case LINE:
                        stack.append(StoryValue(lineIndex + 1));
                        break;
                    case DEBUG:
                        stack.append(StoryValue(debugMode));
                        break;
                    case LINEAR:
                        stack.append(StoryValue(linearMode));
                        break;
                    case ASSERT:
                        if (stack.length) {
                            auto da = stack.pop();
                            if (da.isType!StoryWord || (da.isType!StoryNumber && !da.as!StoryNumber())) return Fault.assertion;
                        } else {
                            return Fault.assertion;
                        }
                        break;
                    case END:
                        return Fault.none;
                    case ECHO:
                    case ECHON:
                        auto space = "\n";
                        if (op == ECHON) space = " ";
                        if (stack.length) print(stack.pop(), space);
                        else print(space);
                        break;
                    case LEAK:
                    case LEAKN:
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
                        if (op == LEAKN) {
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
                        }
                        break;
                    case HERE:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        stack.append(StoryValue(findVariable(a) != -1));
                        break;
                    case GET:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            stack.append(variables[aIndex].value);
                        } else {
                            return throwOpFault(op, tokenCount);
                        }
                        break;
                    case GETN:
                        if (stack.length < 2) return throwOpFault(op, tokenCount);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!da.isType!StoryWord || !db.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto b = db.as!StoryWord();
                        auto aIndex = findVariable(a);
                        auto bIndex = findVariable(b);
                        if (aIndex != -1 && bIndex != -1) {
                            stack.append(variables[aIndex].value);
                            stack.append(variables[bIndex].value);
                        } else {
                            return throwOpFault(op, tokenCount);
                        }
                        break;
                    case SET:
                        if (stack.length < 2) return throwOpFault(op, tokenCount);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            variables[aIndex].value = db;
                        } else {
                            variables.appendSource(file, line, StoryVariable(a, db));
                        }
                        break;
                    case INIT:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            variables[aIndex].value = StoryValue(0);
                        } else {
                            variables.appendSource(file, line, StoryVariable(a, StoryValue(0)));
                        }
                        break;
                    case DROP:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            variables.remove(aIndex);
                        }
                        break;
                    case DROPN:
                        variables.clear();
                        break;
                    case INC:
                    case DEC:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            if (variables[aIndex].value.isType!StoryNumber) {
                                variables[aIndex].value.as!StoryNumber() += (op == INC ? 1 : -1);
                                stack.append(variables[aIndex].value);
                            } else {
                                return throwOpFault(op, tokenCount);
                            }
                        } else {
                            return throwOpFault(op, tokenCount);
                        }
                        break;
                    case INCN:
                    case DECN:
                        if (stack.length < 2) return throwOpFault(op, tokenCount);
                        auto db = stack.pop();
                        auto da = stack.pop();
                        if (!da.isType!StoryWord || !db.isType!StoryNumber) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto b = db.as!StoryNumber();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            if (variables[aIndex].value.isType!StoryNumber) {
                                variables[aIndex].value.as!StoryNumber() += b * (op == INCN ? 1 : -1);
                                stack.append(variables[aIndex].value);
                            } else {
                                return throwOpFault(op, tokenCount);
                            }
                        } else {
                            return throwOpFault(op, tokenCount);
                        }
                        break;
                    case TOG:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            if (variables[aIndex].value.isType!StoryNumber) {
                                variables[aIndex].value.as!StoryNumber() = !variables[aIndex].value.as!StoryNumber();
                                stack.append(variables[aIndex].value);
                            } else {
                                return throwOpFault(op, tokenCount);
                            }
                        } else {
                            return throwOpFault(op, tokenCount);
                        }
                        break;
                    case MENU:
                        stack.append(StoryValue(previousMenuResult));
                        break;
                    case LOOP:
                        if (linearMode) break;
                        auto target = nextLabelIndex - 1;
                        if (target < 0 || target >= labels.length || labels.length == 0) {
                            resetLineIndex();
                        } else {
                            jumpLineIndex(target);
                        }
                        break;
                    case SKIP:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryNumber) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryNumber();
                        if (a == 0) break;
                        if (linearMode) break;
                        auto target = nextLabelIndex + (a > 0 ? a - 1 : a);
                        if (target < 0 || target >= labels.length || labels.length == 0) {
                            resetLineIndex();
                        } else {
                            jumpLineIndex(target);
                        }
                        break;
                    case JUMP:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.as!StoryWord();
                        auto aIndex = findLabel(a);
                        if (aIndex != -1) {
                            if (linearMode) break;
                            jumpLineIndex(aIndex);
                        } else {
                            return throwOpFault(op, tokenCount);
                        }
                        break;
                }
            } else if (token.isMaybeStoryNumber) {
                auto number = token.toSigned();
                if (number.isNone) {
                    faultTokenPosition = tokenCount;
                    return number.fault;
                }
                stack.append(StoryValue(cast(StoryNumber) number.xx));
            } else if (token.isMaybeStoryWord) {
                auto word = StoryWord.init;
                auto wordRef = word[];
                if (auto fault = wordRef.copyChars(token)) {
                    faultTokenPosition = tokenCount;
                    return fault;
                }
                stack.append(StoryValue(word));
            } else {
                faultTokenPosition = tokenCount;
                return Fault.cantParse;
            }
        }
        return Fault.none;
    }

    Fault update() {
        if (lineCount == 0) return Fault.none;
        setLineIndex(lineIndex + 1);
        while (lineIndex < lineCount && !hasPause && !hasProcedure && !hasMenu && !hasText) {
            auto line = opIndex(lineIndex);
            if (line.length) {
                if (line[0] == StoryLineKind.expression) {
                    auto fault = execute(line[1 .. $].trimStart());
                    if (fault) return fault;
                } else if (line[0] == StoryLineKind.label) {
                    setNextLabelIndex(nextLabelIndex + 1);
                }
            }
            setLineIndex(lineIndex + 1);
        }
        if (hasPause && lineIndex == lineCount) resetLineIndex();
        return Fault.none;
    }

    Fault select(Sz i) {
        previousMenuResult = cast(StoryNumber) (i + 1);
        return update();
    }

    void reserve(Sz capacity) {
        script.reserve(capacity);
        pairs.reserve(capacity);
        labels.reserve(capacity);
        variables.reserve(capacity);
    }

    @nogc
    void free() {
        script.free();
        pairs.free();
        labels.free();
        variables.free();
        this = Story();
    }
}

@nogc
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

@nogc
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

@nogc
bool isMaybeStoryWord(IStr value) {
    if (value.length == 0) return false;
    auto c = value[0];
    return c == '_' || (!c.isUpper && !c.isSymbol);
}

@nogc
Maybe!StoryLineKind toStoryLineKind(char from) {
    with (Maybe!StoryLineKind) with (StoryLineKind) switch (from) {
        case ' ': return some(empty);
        case '#': return some(comment);
        case '*': return some(label);
        case '|': return some(text);
        case '.': return some(pause);
        case '^': return some(menu);
        case '$': return some(expression);
        case '!': return some(procedure);
        default: return none(Fault.cantParse);
    }
}

@nogc
Maybe!StoryOp toStoryOp(IStr from) {
    with (Maybe!StoryOp) with (StoryOp) switch (from) {
        case "+": return some(ADD);
        case "-": return some(SUB);
        case "*": return some(MUL);
        case "/": return some(DIV);
        case "%": return some(MOD);
        case "&": return some(AND);
        case "|": return some(OR);
        case "<": return some(LESS);
        case ">": return some(GREATER);
        case "=": return some(EQUAL);
        case "!": return some(NOT);
        case "~": return some(POP);
        default: break;
    }
    return toEnum!StoryOp(from);
}
