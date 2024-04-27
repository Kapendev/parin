// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The dialogue module is a versatile dialogue system,
/// enabling the creation of interactive conversations and branching narratives.

module popka.game.dialogue;

import popka.core;

@safe @nogc nothrow:

enum dialogueUnitKindChars = ".#*@>|^!+-$";

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
    List!char text;
    DialogueUnitKind kind;
}

struct DialogueVariable {
    List!char name;
    long value;
}

alias DialogueFunc = void function(const(char)[][] args);

struct Dialogue {
    List!DialogueUnit units;
    List!DialogueVariable variables;
    List!(const(char)[]) menu;
    List!(const(char)[]) command;
    size_t unitIndex;
    size_t pointCount;
    const(char)[] text;
    const(char)[] actor;

    @safe @nogc nothrow:

    this(const(char)[] path) {
        load(path);
    }

    bool hasChoices() {
        return menu.length != 0;
    }

    bool hasArgs() {
        return command.length != 0;
    }

    bool hasText() {
        return unitIndex < units.length && units[unitIndex].kind != DialogueUnitKind.pause;
    }

    const(char)[][] choices() {
        return menu.items;
    }

    const(char)[][] args() {
        return command.items;
    }

    void reset() {
        unitIndex = 0;
        menu.clear();
        command.clear();
        text = "";
        actor = "";
    }

    void jump(const(char)[] point) {
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

    void jump(size_t i) {
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

    void skip(size_t count) {
        foreach (i; 0 .. count) {
            jump("");
        }
    }

    void select(size_t i) {
        menu.clear();
        skip(i + 1);
        update();
    }

    void run(DialogueFunc func) {
        func(args);
        command.clear();
        update();
    }

    // TODO: Remove the asserts!
    void update() {
        if (units.length != 0 && unitIndex < units.length - 1) {
            unitIndex += 1;
            text = units[unitIndex].text.items;
            final switch (units[unitIndex].kind) {
                case DialogueUnitKind.pause, DialogueUnitKind.line: {
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
                case DialogueUnitKind.menu: {
                    if (text.length == 0) {
                        assert(0, "TODO: An empty menu is an error for now.");
                    }
                    menu.clear();
                    auto view = text;
                    while (view.length != 0) {
                        auto option = trim(skipValue(view, DialogueUnitKind.menu));
                        menu.append(option);
                    }
                    break;
                }
                case DialogueUnitKind.variable: {
                    auto variableIndex = -1;
                    auto view = text;
                    auto name = trim(skipValue(view, '='));
                    auto value = trim(skipValue(view, '='));
                    if (name.length == 0) {
                        assert(0, "TODO: An variable without a name is an error for now.");
                    }
                    // Find if variable exists.
                    foreach (i, variable; variables.items) {
                        if (variable.name.items == name) {
                            variableIndex = cast(int) i;
                            break;
                        }
                    }
                    // Create variable if it does not exist.
                    if (variableIndex < 0) {
                        auto variable = DialogueVariable();
                        variable.name.append(name);
                        variables.append(variable);
                        variableIndex = cast(int) variables.length - 1;
                    }
                    // Set variable value.
                    if (value.length != 0) {
                        auto conv = toSigned(value);
                        if (conv.error) {
                            auto valueVariableIndex = -1;
                            auto valueName = value;
                            // Find if variable exists.
                            foreach (i, variable; variables.items) {
                                if (variable.name.items == valueName) {
                                    valueVariableIndex = cast(int) i;
                                    break;
                                }
                            }
                            if (valueVariableIndex < 0) {
                                assert(0, "TODO: A variable that doesn't exist it an error for now.");
                            } else {
                                variables[variableIndex].value = variables[valueVariableIndex].value;
                            }
                        } else {
                            variables[variableIndex].value = conv.value;
                        }
                    }
                    update();
                    break;
                }
                case DialogueUnitKind.plus, DialogueUnitKind.minus: {
                    auto variableIndex = -1;
                    auto name = text;
                    // Find if variable exists.
                    foreach (i, variable; variables.items) {
                        if (variable.name.items == name) {
                            variableIndex = cast(int) i;
                            break;
                        }
                    }
                    // Add/Remove from variable.
                    if (variableIndex < 0) {
                        assert(0, "TODO: A variable that doesn't exist it an error for now.");
                    }
                    if (units[unitIndex].kind == DialogueUnitKind.plus) {
                        variables[variableIndex].value += 1;
                    } else {
                        variables[variableIndex].value -= 1;
                    }
                    update();
                    break;
                }
                case DialogueUnitKind.command: {
                    if (text.length == 0) {
                        assert(0, "TODO: An empty command is an error for now.");
                    }
                    command.clear();
                    auto view = text;
                    while (view.length != 0) {
                        auto arg = trim(skipValue(view, ' '));
                        command.append(arg);
                    }
                    break;
                }
            }
        }
    }

    void parse(const(char)[] script) {
        free();
        units.append(DialogueUnit(List!char(), DialogueUnitKind.pause));
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
                units.append(DialogueUnit(List!char(text), realKind));
                if (realKind == DialogueUnitKind.point) {
                    pointCount += 1;
                }
            } else {
                free();
                return;
            }
        }
        if (units.items[$ - 1].kind != DialogueUnitKind.pause) {
            units.append(DialogueUnit(List!char(), DialogueUnitKind.pause));
        }
        return;
    }

    void load(const(char)[] path) {
        free();
        if (path.length != 0) {
            auto file = readText(path);
            parse(file.items);
            file.free();
        }
    }

    void free() {
        foreach (ref unit; units) {
            unit.text.free();
        }
        units.free();
        foreach (ref variable; variables) {
            variable.name.free();
        }
        variables.free();
        menu.free();
        command.free();
        reset();
        pointCount = 0;
    }
}

bool isValidDialogueUnitKind(char c) {
    foreach (kind; dialogueUnitKindChars) {
        if (c == kind) {
            return true;
        }
    }
    return false;
}
