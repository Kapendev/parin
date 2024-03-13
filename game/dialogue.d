// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The dialogue module is a versatile dialogue system for games,
/// enabling the creation of interactive conversations and branching narratives.

// TODO: API might need some work.

module popka.game.dialogue;

import popka.core.basic;

enum dialogueUnitKindChars = "-#.@>|^";

enum DialogueUnitKind {
    pause = '-',
    comment = '#',
    point = '.',
    jump = '@',
    actor = '>',
    line = '|',
    menu = '^',
}

struct DialogueUnit {
    List!char text;
    DialogueUnitKind kind;

    bool isOneOf(const(DialogueUnitKind)[] args...) {
        foreach (arg; args) {
            if (arg == kind) {
                return true;
            }
        }
        return false;
    }
}

struct Dialogue {
    List!DialogueUnit units;
    List!(const(char)[]) options;
    size_t unitIndex;
    size_t pointCount;
    const(char)[] text;
    const(char)[] actor;

    this(const(char)[] path) {
        load(path);
    }

    bool hasOptions() {
        return options.length != 0;
    }

    bool canUpdate() {
        return unitIndex < units.length && units[unitIndex].kind != DialogueUnitKind.pause;
    }

    DialogueUnit now() {
        return units[unitIndex];
    }

    void reset() {
        unitIndex = 0;
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

    void selectOption(size_t i) {
        skip(i + 1);
        options.clear();
    }

    void update() {
        if (units.length != 0 && unitIndex < units.length - 1) {
            unitIndex += 1;
            auto unit = units[unitIndex];
            text = unit.text.items;
            if (unit.isOneOf(DialogueUnitKind.comment, DialogueUnitKind.point)) {
                update();
            } else if (unit.kind == DialogueUnitKind.actor) {
                actor = unit.text.items;
                update();
            } else if (unit.kind == DialogueUnitKind.jump) {
                jump(unit.text.items);
                update();
            } else if (unit.kind == DialogueUnitKind.menu) {
                options.clear();
                const(char)[] view = unit.text.items;
                while (view.length != 0) {
                    auto option = trim(skipValue(view, DialogueUnitKind.menu));
                    options.append(option);
                }
            }
        }
    }

    void free() {
        foreach (ref unit; units.items) {
            unit.text.free();
        }
        units.free();
        reset();
        pointCount = 0;
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
        auto file = readText(path);
        parse(file.items);
        file.free();
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

unittest {}
