// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/parin
// Version: v0.0.28
// ---

// TODO: The DialogueCommandRunner should work with gc functions too. Think about how to do it.
// TODO: Update all the doc comments here.

/// The `dialogue` module provides a simple and versatile dialogue system.
module parin.dialogue;

import joka.ascii;
import parin.engine;
public import joka.containers;
public import joka.faults;
public import joka.types;

@safe:

enum DialogueUnitKindChars = ".#*@>|^!+-$";

enum DialogueUnitKind {
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

struct DialogueUnit {
    LStr text;
    DialogueUnitKind kind;

    @safe @nogc nothrow:

    void free() {
        text.free();
        this = DialogueUnit();
    }
}

struct DialogueValue {
    LStr name;
    long value;

    @safe @nogc nothrow:

    void free() {
        name.free();
        this = DialogueValue();
    }
}

alias DialogueCommandRunner = void function(IStr[] args) @trusted;

struct Dialogue {
    List!DialogueUnit units;
    List!DialogueValue values;
    IStr text;
    IStr actor;
    Sz unitIndex;

    @trusted
    void run(DialogueCommandRunner runner) {
        runner(args);
        update();
    }

    @safe @nogc nothrow:

    bool isEmpty() {
        return units.length == 0;
    }

    bool hasKind(DialogueUnitKind kind) {
        return unitIndex < units.length && units[unitIndex].kind == kind;
    }

    bool hasPause() {
        return hasKind(DialogueUnitKind.pause);
    }

    bool hasChoices() {
        return hasKind(DialogueUnitKind.menu);
    }

    bool hasArgs() {
        return hasKind(DialogueUnitKind.command);
    }

    bool canUpdate() {
        return !hasPause;
    }

    IStr[] choices() {
        static IStr[16] buffer;

        auto length = 0;
        auto temp = hasChoices ? units[unitIndex].text.items : "";
        while (temp.length != 0) {
            buffer[length] = temp.skipValue(DialogueUnitKind.menu).trim();
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
                if (unit.kind == DialogueUnitKind.point) {
                    unitIndex = i;
                    break;
                }
            }
        } else {
            foreach (i; 0 .. units.length) {
                auto unit = units[i];
                if (unit.kind == DialogueUnitKind.point && unit.text.items == point) {
                    unitIndex = i;
                    break;
                }
            }
        }
    }

    void jump(Sz i) {
        auto currPoint = 0;
        foreach (j, unit; units.items) {
            if (unit.kind == DialogueUnitKind.point) {
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

    // TODO: Remove the asserts!
    void update() {
        if (units.length != 0 && unitIndex < units.length - 1) {
            unitIndex += 1;
            text = units[unitIndex].text.items;
            final switch (units[unitIndex].kind) {
                case DialogueUnitKind.line, DialogueUnitKind.menu, DialogueUnitKind.command, DialogueUnitKind.pause: {
                    break;
                }
                case DialogueUnitKind.comment, DialogueUnitKind.point: {
                    update();
                    break;
                }
                case DialogueUnitKind.actor: {
                    actor = text;
                    update();
                    break;
                }
                case DialogueUnitKind.jump: {
                    jump(text);
                    update();
                    break;
                }
                case DialogueUnitKind.variable: {
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
                        auto variable = DialogueValue();
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
                case DialogueUnitKind.plus, DialogueUnitKind.minus: {
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
                    if (units[unitIndex].kind == DialogueUnitKind.plus) {
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

        units.append(DialogueUnit(LStr(), DialogueUnitKind.pause));
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
                if (kind == DialogueUnitKind.pause) {
                    continue;
                }
            }
            if (isValidDialogueUnitKind(kind)) {
                auto realKind = cast(DialogueUnitKind) kind;
                units.append(DialogueUnit(LStr(text), realKind));
            } else {
                clear();
                return Fault.invalid;
            }
        }
        if (units.items[$ - 1].kind != DialogueUnitKind.pause) {
            units.append(DialogueUnit(LStr(), DialogueUnitKind.pause));
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

@safe @nogc nothrow:

bool isValidDialogueUnitKind(char c) {
    foreach (kind; DialogueUnitKindChars) {
        if (c == kind) {
            return true;
        }
    }
    return false;
}

Result!Dialogue toDialogue(IStr script) {
    auto value = Dialogue();
    auto fault = value.parse(script);
    if (fault) {
        value.free();
    }
    return Result!Dialogue(value, fault);
}

Result!Dialogue loadRawDialogue(IStr path) {
    auto temp = loadTempText(path);
    if (temp.isNone) {
        return Result!Dialogue(temp.fault);
    }
    return toDialogue(temp.get());
}
