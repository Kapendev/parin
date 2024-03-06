// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT

module popka.game.dialogue;

/// The dialogue module is a versatile dialogue system for games,
/// enabling the creation of interactive conversations and branching narratives.

import popka.core.basic;

// TODO: This module needs a lot of work and testing.

struct DialogueUnit {
    alias Kind = char;
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
}

struct Dialogue {
    List!DialogueUnit units;
    size_t index;

    this(const(char)[] path) {
        read(path);
    }

    DialogueUnit* now() {
        return &units[index];
    }

    void update() {
        if (units.length != 0 && index < units.length - 1) {
            index += 1;
        }
    }

    void free() {
        foreach (ref unit; units.items) {
            unit.content.free();
        }
        units.free();
    }

    void read(const(char)[] path) {
        free();
        units.append(DialogueUnit(List!char(), DialogueUnit.pause));

        auto file = readText(path);
        const(char)[] view = file.items;
        auto lineNumber = 0;
        while (view.length != 0) {
            auto line = skipLine(view);
            if (line.length == 0) {
                continue;
            }
            lineNumber += 1;
            if (lineNumber == 1 && line[0] == DialogueUnit.pause) {
                continue;
            }

            units.append(DialogueUnit(List!char(trimStart(line[1 .. $])), line[0]));
        }
        if (units.items[$ - 1].kind != DialogueUnit.pause) {
            units.append(DialogueUnit(List!char(), DialogueUnit.pause));
        }
        file.free();
    }
}

unittest {}
