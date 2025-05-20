// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.44
// ---

// TODO: Update all the doc comments here.

/// The `story` module provides a simple and versatile dialogue system.
module parin.story;

import joka.ascii;
import joka.containers;
import joka.io;
import joka.types;

@safe @nogc nothrow:

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

    @safe @nogc nothrow:

    static foreach (Type; StoryValueData.Types) {
        this(Type value) {
            data = value;
        }
    }

    @trusted
    IStr toStr() {
        if (data.isType!StoryNumber) {
            return fmt("{}", data.get!StoryNumber());
        } else {
            auto temp = data.get!(StoryWord)()[];
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

    @safe @nogc nothrow:

    IStr opIndex(Sz i) {
        if (i >= lineCount) assert(0, "Index `[{}]` does not exist.".fmt(i));
        return script[pairs[i].a .. pairs[i].b + 1];
    }

    StoryNumber lineCount() {
        return cast(StoryNumber) pairs.length;
    }

    bool hasKind(StoryLineKind kind) {
        if (lineIndex >= lineCount) return false;
        auto line = opIndex(lineIndex);
        return line.length && line[0] == kind;
    }

    bool hasEnd() {
        return lineIndex == lineCount;
    }

    bool hasPause() {
        if (hasEnd) return true;
        return hasKind(StoryLineKind.pause);
    }

    bool hasProcedure() {
        return hasKind(StoryLineKind.procedure);
    }

    bool hasMenu() {
        return hasKind(StoryLineKind.menu);
    }

    bool hasText() {
        return hasKind(StoryLineKind.text);
    }

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

    IStr text() {
        if (!hasText) return "";
        return opIndex(lineIndex)[1 .. $].trimStart();
    }

    Fault throwOpFault(StoryOp op, Sz position) {
        faultOp = op;
        faultTokenPosition = position;
        return Fault.invalid;
    }

    StoryNumber findVariable(StoryWord name) {
        foreach (i, variable; variables) {
            if (name == variable.name) return cast(StoryNumber) i;
        }
        return -1;
    }

    StoryNumber findLabel(StoryWord name) {
        foreach (i, label; labels) {
            if (name == label.name) return cast(StoryNumber) i;
        }
        return -1;
    }

    void setNextLabelIndex(StoryNumber value) {
        nextLabelIndex = cast(StoryNumber) (value % (labels.length + 1));
    }

    void setLineIndex(StoryNumber value) {
        lineIndex = (value) % (lineCount + 1);
    }

    void resetLineIndex() {
        lineIndex = lineCount;
        nextLabelIndex = 0;
    }

    void jumpLineIndex(StoryNumber labelIndex) {
        lineIndex = labels[labelIndex].value.get!StoryNumber();
        setNextLabelIndex(labelIndex + 1);
    }

    @trusted
    Fault prepare() {
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
                auto line = script[pair.a .. pair.b + 1];
                pair.a += line.length - line.trimStart().length;
                if (pair.a > pair.b) {
                    pair.a = pair.b;
                    line = script[pair.a .. pair.b];
                } else {
                    pair.b -= line.length - line.trimEnd().length;
                    line = script[pair.a .. pair.b + 1];
                }
                auto kind = toStoryLineKind(line.length ? script[pair.a] : StoryLineKind.empty);
                if (kind.isNone) {
                    pairs.clear();
                    labels.clear();
                    faultPrepareIndex = prepareIndex;
                    return kind.fault;
                }
                if (kind.value == StoryLineKind.label) {
                    auto name = line[1 .. $].trimStart();
                    auto word = StoryWord.init;
                    auto wordRef = word[];
                    if (auto fault = wordRef.copyChars(name)) {
                        pairs.clear();
                        labels.clear();
                        faultPrepareIndex = prepareIndex;
                        return fault;
                    }
                    labels.append(StoryVariable(word, StoryValue(cast(StoryNumber) pairs.length)));
                }
                pairs.append(pair);
                prepareIndex += 1;
                startIndex = cast(StoryNumber) (i + 1);
            }
        }
        resetLineIndex();
        return Fault.none;
    }

    Fault parse(IStr text) {
        script.clear();
        script.append(text);
        return prepare();
    }

    @trusted
    Fault execute(IStr expression) {
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
                auto op = tempOp.value;
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
                        auto a = da.get!StoryNumber;
                        auto b = db.get!StoryNumber;
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
                        stack.append(StoryValue(!da.get!StoryNumber));
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
                        auto a = da.get!StoryNumber();
                        auto b = db.get!StoryNumber();
                        auto c = dc.get!StoryNumber();
                        stack.append(StoryValue(a >= b && a <= c));
                        break;
                    case IF:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryNumber) return throwOpFault(op, tokenCount);
                        if (!da.get!StoryNumber) ifCounter += 1;
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
                        auto a = da.get!StoryWord;
                        auto b = db.get!StoryWord;
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
                            if (da.isType!StoryWord || (da.isType!StoryNumber && !da.get!StoryNumber())) return Fault.assertion;
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
                        auto a = da.get!StoryWord();
                        stack.append(StoryValue(findVariable(a) != -1));
                        break;
                    case GET:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.get!StoryWord();
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
                        auto a = da.get!StoryWord();
                        auto b = db.get!StoryWord();
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
                        auto a = da.get!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            variables[aIndex].value = db;
                        } else {
                            variables.append(StoryVariable(a, db));
                        }
                        break;
                    case INIT:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.get!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            variables[aIndex].value = StoryValue(0);
                        } else {
                            variables.append(StoryVariable(a, StoryValue(0)));
                        }
                        break;
                    case DROP:
                        if (stack.length < 1) return throwOpFault(op, tokenCount);
                        auto da = stack.pop();
                        if (!da.isType!StoryWord) return throwOpFault(op, tokenCount);
                        auto a = da.get!StoryWord();
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
                        auto a = da.get!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            if (variables[aIndex].value.isType!StoryNumber) {
                                variables[aIndex].value.get!StoryNumber() += (op == INC ? 1 : -1);
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
                        auto a = da.get!StoryWord();
                        auto b = db.get!StoryNumber();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            if (variables[aIndex].value.isType!StoryNumber) {
                                variables[aIndex].value.get!StoryNumber() += b * (op == INCN ? 1 : -1);
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
                        auto a = da.get!StoryWord();
                        auto aIndex = findVariable(a);
                        if (aIndex != -1) {
                            if (variables[aIndex].value.isType!StoryNumber) {
                                variables[aIndex].value.get!StoryNumber() = !variables[aIndex].value.get!StoryNumber();
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
                        auto a = da.get!StoryNumber();
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
                        auto a = da.get!StoryWord();
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
                stack.append(StoryValue(cast(StoryNumber) number.value));
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

    void free() {
        script.free();
        pairs.free();
        labels.free();
        variables.free();
        this = Story();
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
        case '!': return Result!StoryLineKind(procedure);
        default: return Result!StoryLineKind(Fault.cantParse);
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
