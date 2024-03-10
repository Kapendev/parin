// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

/// The dialogue module is a versatile dialogue system for games,
/// enabling the creation of interactive conversations and branching narratives.

// TODO: This module needs a lot of work and testing.

module popka.game.dialogue;

import popka.core.basic;

struct DialogueUnit {
    alias Kind = char;

    enum kindChars = "-#*@>|";
    enum : Kind {
        pause = '-',
        comment = '#',
        point = '*',
        target = '@',
        actor = '>',
        line = '|',
    }

    List!char content;
    Kind kind = pause;

    bool isOneOf(const(Kind)[] args...) {
        foreach (arg; args) {
            if (arg == kind) {
                return true;
            }
        }
        return false;
    }

    bool isValid() {
        return isOneOf(kindChars);
    }
}

struct Dialogue {
    List!DialogueUnit units;
    size_t unitIndex;
    const(char)[] actor;
    const(char)[] content;

    this(const(char)[] path) {
        load(path);
    }

    DialogueUnit now() {
        return units[unitIndex];
    }

    void reset() {
        unitIndex = 0;
    }

    void update() {
        if (units.length != 0 && unitIndex < units.length - 1) {
            unitIndex += 1;
            auto unit = units[unitIndex];
            content = unit.content.items;
            if (unit.isOneOf(DialogueUnit.comment, DialogueUnit.point)) {
                update();
            }
            if (unit.kind == DialogueUnit.actor) {
                actor = unit.content.items;
                update();
            }
            if (unit.kind == DialogueUnit.target) {
                foreach (i, item; units.items) {
                    if (item.kind == DialogueUnit.point && item.content.items == unit.content.items) {
                        unitIndex = i;
                        break;
                    }
                }
                update();
            }
        }
    }

    bool canUpdate() {
        return unitIndex < units.length && units[unitIndex].kind != DialogueUnit.pause;
    }

    void free() {
        foreach (ref unit; units.items) {
            unit.content.free();
        }
        units.free();
    }

    void parse(const(char)[] text) {
        free();
        units.append(DialogueUnit(List!char(), DialogueUnit.pause));
        auto isFirstLine = true;
        auto view = text;
        while (view.length != 0) {
            auto line = trim(skipLine(view));
            if (line.length == 0) {
                continue;
            }
            auto content = trimStart(line[1 .. $]);
            auto kind = line[0];
            if (isFirstLine && kind == DialogueUnit.pause) {
                isFirstLine = false;
                continue;
            }
            auto unit = DialogueUnit(List!char(), kind);
            if (unit.isValid) {
                unit.content = List!char(content);
                units.append(unit);
            } else {
                free();
                return;
            }
        }
        if (units.items[$ - 1].kind != DialogueUnit.pause) {
            units.append(DialogueUnit(List!char(), DialogueUnit.pause));
        }
        return;
    }

    void load(const(char)[] path) {
        auto file = readText(path);
        parse(file.items);
        file.free();
    }
}

unittest {}
