// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/popka
// Version: v0.0.14
// ---

/// The `chat` module provides a simple and versatile dialogue system.
module popka.chat;

import popka.engine;
public import joka;

@safe @nogc nothrow:

enum ChatUnitKindChars = ".#*@>|^!+-$";

enum ChatUnitKind {
    pause = '.',
    comment = '#',
    point = '*',
    jump = '@',
    actor = '>',
    line = '|',
    menu = '^',
    variable = '!',
    plus = '+',
    minus = '-',
    command = '$',
}

struct ChatUnit {
    LStr text;
    ChatUnitKind kind;

    @safe @nogc nothrow:

    void free() {
        text.free();
    }
}

struct ChatValue {
    LStr name;
    long value;

    @safe @nogc nothrow:

    void free() {
        name.free();
    }
}

alias ChatCommandRunner = void function(IStr[] args);

struct Chat {
    List!ChatUnit units;
    List!ChatValue values;
    IStr text;
    IStr actor;
    Sz unitIndex;

    @safe @nogc nothrow:

    bool isEmpty() {
        return units.length == 0;
    }

    bool isKind(ChatUnitKind kind) {
        return unitIndex < units.length && units[unitIndex].kind == kind;
    }

    bool hasChoices() {
        return isKind(ChatUnitKind.menu);
    }

    bool hasArgs() {
        return isKind(ChatUnitKind.command);
    }

    bool hasEnded() {
        return isKind(ChatUnitKind.pause);
    }

    bool canUpdate() {
        return !hasEnded;
    }

    IStr[] choices() {
        static IStr[16] buffer;

        auto length = 0;
        auto temp = hasChoices ? units[unitIndex].text.items : "";
        while (temp.length != 0) {
            buffer[length] = temp.skipValue(ChatUnitKind.menu).trim();
            length += 1;
        }
        return buffer[0 .. length];
    }

    IStr[] args() {
        static IStr[16] buffer;

        auto length = 0;
        auto temp = hasArgs ? units[unitIndex].text.items : "";
        while (temp.length != 0) {
            buffer[length] = temp.skipValue(' ').trim();
            length += 1;
        }
        return buffer[0 .. length];
    }

    void reset() {
        text = "";
        actor = "";
        unitIndex = 0;
    }

    void jump(IStr point) {
        if (point.length == 0) {
            foreach (i; unitIndex + 1 .. units.length) {
                auto unit = units[i];
                if (unit.kind == ChatUnitKind.point) {
                    unitIndex = i;
                    break;
                }
            }
        } else {
            foreach (i; 0 .. units.length) {
                auto unit = units[i];
                if (unit.kind == ChatUnitKind.point && unit.text.items == point) {
                    unitIndex = i;
                    break;
                }
            }
        }
    }

    void jump(Sz i) {
        auto currPoint = 0;
        foreach (j, unit; units.items) {
            if (unit.kind == ChatUnitKind.point) {
                if (currPoint == i) {
                    unitIndex = j;
                    break;
                }
                currPoint += 1;
            }
        }
    }

    void skip(Sz count) {
        foreach (i; 0 .. count) {
            jump("");
        }
    }

    void pick(Sz i) {
        skip(i + 1);
        update();
    }

    void run(ChatCommandRunner runner) {
        runner(args);
        update();
    }

    // TODO: Remove the asserts!
    void update() {
        if (units.length != 0 && unitIndex < units.length - 1) {
            unitIndex += 1;
            text = units[unitIndex].text.items;
            final switch (units[unitIndex].kind) {
                case ChatUnitKind.line, ChatUnitKind.menu, ChatUnitKind.command, ChatUnitKind.pause: {
                    break;
                }
                case ChatUnitKind.comment, ChatUnitKind.point: {
                    update();
                    break;
                }
                case ChatUnitKind.actor: {
                    actor = text;
                    update();
                    break;
                }
                case ChatUnitKind.jump: {
                    jump(text);
                    update();
                    break;
                }
                case ChatUnitKind.variable: {
                    auto variableIndex = -1;
                    auto view = text;
                    auto name = trim(skipValue(view, '='));
                    auto value = trim(skipValue(view, '='));
                    if (name.length == 0) {
                        assert(0, "TODO: A variable without a name is an error for now.");
                    }
                    // Find if variable exists.
                    foreach (i, variable; values.items) {
                        if (variable.name.items == name) {
                            variableIndex = cast(int) i;
                            break;
                        }
                    }
                    // Create variable if it does not exist.
                    if (variableIndex < 0) {
                        auto variable = ChatValue();
                        variable.name.append(name);
                        values.append(variable);
                        variableIndex = cast(int) values.length - 1;
                    }
                    // Set variable value.
                    if (value.length != 0) {
                        auto conv = toSigned(value);
                        if (conv.isNone) {
                            auto valueVariableIndex = -1;
                            auto valueName = value;
                            // Find if variable exists.
                            foreach (i, variable; values.items) {
                                if (variable.name.items == valueName) {
                                    valueVariableIndex = cast(int) i;
                                    break;
                                }
                            }
                            if (valueVariableIndex < 0) {
                                assert(0, "TODO: A variable that does not exist it an error for now.");
                            } else {
                                values[variableIndex].value = values[valueVariableIndex].value;
                            }
                        } else {
                            values[variableIndex].value = conv.value;
                        }
                    }
                    update();
                    break;
                }
                case ChatUnitKind.plus, ChatUnitKind.minus: {
                    auto variableIndex = -1;
                    auto name = text;
                    // Find if variable exists.
                    foreach (i, variable; values.items) {
                        if (variable.name.items == name) {
                            variableIndex = cast(int) i;
                            break;
                        }
                    }
                    // Add/Remove from variable.
                    if (variableIndex < 0) {
                        assert(0, "TODO: A variable that does not exist it an error for now.");
                    }
                    if (units[unitIndex].kind == ChatUnitKind.plus) {
                        values[variableIndex].value += 1;
                    } else {
                        values[variableIndex].value -= 1;
                    }
                    update();
                    break;
                }
            }
        }
    }

    Fault parse(IStr script) {
        clear();
        if (script.length == 0) {
            return Fault.invalid;
        }

        units.append(ChatUnit(LStr(), ChatUnitKind.pause));
        auto isFirstLine = true;
        auto view = script;
        while (view.length != 0) {
            auto line = trim(skipLine(view));
            if (line.length == 0) {
                continue;
            }
            auto text = trimStart(line[1 .. $]);
            auto kind = line[0];
            if (isFirstLine) {
                isFirstLine = false;
                if (kind == ChatUnitKind.pause) {
                    continue;
                }
            }
            if (isValidChatUnitKind(kind)) {
                auto realKind = cast(ChatUnitKind) kind;
                units.append(ChatUnit(LStr(text), realKind));
            } else {
                clear();
                return Fault.invalid;
            }
        }
        if (units.items[$ - 1].kind != ChatUnitKind.pause) {
            units.append(ChatUnit(LStr(), ChatUnitKind.pause));
        }
        return Fault.none;
    }

    void clear() {
        foreach (ref unit; units) {
            unit.free();
        }
        units.clear();
        foreach (ref variable; values) {
            variable.free();
        }
        values.clear();
        reset();
    }

    void free() {
        foreach (ref unit; units) {
            unit.free();
        }
        units.free();
        foreach (ref variable; values) {
            variable.free();
        }
        values.free();
        reset();
    }
}

bool isValidChatUnitKind(char c) {
    foreach (kind; ChatUnitKindChars) {
        if (c == kind) {
            return true;
        }
    }
    return false;
}

Result!Chat toChat(IStr script) {
    auto value = Chat();
    auto fault = value.parse(script);
    if (fault) {
        value.free();
    }
    return Result!Chat(value, fault);
}

Result!Chat loadChat(IStr path) {
    auto temp = loadTempText(path);
    if (temp.isNone) {
        return Result!Chat(temp.fault);
    }
    return toChat(temp.unwrap());
}
