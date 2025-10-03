// ---
// Copyright 2024 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `cli` module provides command-line parsing utilities.
module joka.cli;

import joka.ascii;
import joka.types;

@safe nothrow @nogc:

/// Command-line argument types.
enum ArgType {
    singleItem,  /// A standalone argument (e.g. file.txt)
    shortOption, /// A short option (e.g. -v)
    longOption,  /// A long option (e.g. --verbose)
}

/// A parsed token from the command-line arguments.
struct ArgToken {
    ArgType type; /// The type of the argument.
    IStr name;    /// The name of the argument. Always present.
    IStr value;   /// The value of the argument. May be empty.

    @safe nothrow @nogc:

    IStr toStr() {
        return "{\"{}\":\"{}\"}".fmt(name, value);
    }

    IStr toString() {
        return toStr();
    }
}

/// A range of parsed tokens from the command-line arguments.
struct ArgTokenRange {
    const(IStr)[] args;

    @safe nothrow @nogc:

    bool empty() {
        return args.length == 0;
    }

    ArgToken front() {
        auto cleanArg = args[0].trim();
        auto equalIndex = cleanArg.findEnd("=");
        if (cleanArg.length == 0) return ArgToken();
        else if (cleanArg == "-") return ArgToken(ArgType.singleItem, "-", "");
        else if (cleanArg == "--") return ArgToken(ArgType.singleItem, "--", "");

        auto a = cleanArg.startsWith("-") ? (cleanArg.startsWith("--") ? ArgType.longOption : ArgType.shortOption) : ArgType.singleItem;
        auto startIndex = a == ArgType.singleItem ? 0 : a == ArgType.shortOption ? 1 : 2;
        auto b = cleanArg[startIndex .. equalIndex != -1 ? equalIndex : $];
        auto c = cleanArg[equalIndex != -1 ? equalIndex + 1 : $ .. $];
        return ArgToken(a, b, c);
    }

    void popFront() {
        args = args[1 .. $];
    }
}

/// Splits a command-line string into an array of individual arguments.
@trusted
IStr[] toCliArgs(IStr str) {
    static IStr[defaultAsciiBufferSize][defaultAsciiBufferCount] buffers = void;
    static byte bufferIndex = 0;

    bufferIndex = (bufferIndex + 1) % buffers.length;
    auto length = 0;
    while (str.length != 0) {
        buffers[bufferIndex][length] = str.skipValue(" ").trim();
        if (buffers[bufferIndex][length].length == 0) continue;
        length += 1;
    }
    return buffers[bufferIndex][0 .. length];
}

/// Parses command-line arguments into structured tokens.
@trusted
ArgTokenRange toArgTokens(const(IStr)[] args...) {
    static const(IStr)[] buffer = void;
    buffer = args;
    return ArgTokenRange(buffer);
}

/// Parses command-line arguments into structured tokens from a string.
auto toArgTokensFromStr(IStr args) {
    return toArgTokens(args.toCliArgs());
}

/// Returns true if the first argument matches the given command.
bool hasCommand(const(IStr)[] args, IStr command) {
    auto tokens = args.toArgTokens();
    if (tokens.empty) return false;
    auto front = tokens.front;
    if (front.type != ArgType.singleItem || front.value.length != 0) return false;

    // Remove path argument.
    if (front.name.findStart(pathSep) != -1) {
        tokens.popFront();
        if (tokens.empty) return false;
        front = tokens.front;
        if (front.type != ArgType.singleItem || front.value.length != 0) return false;
    }
    return front.name == command;
}

/// Returns true if the second argument matches the given subcommand.
bool hasSubcommand(const(IStr)[] args, IStr command) {
    auto tokens = args.toArgTokens();
    if (tokens.empty) return false;
    auto front = tokens.front;
    if (front.type != ArgType.singleItem || front.value.length != 0) return false;

    // Remove path argument.
    if (front.name.findStart(pathSep) != -1) {
        tokens.popFront();
        if (tokens.empty) return false;
        front = tokens.front;
        if (front.type != ArgType.singleItem || front.value.length != 0) return false;
    }
    // Get sub command.
    tokens.popFront();
    if (tokens.empty) return false;
    front = tokens.front;
    if (front.type != ArgType.singleItem || front.value.length != 0) return false;
    return front.name == command;
}

unittest {
    assert(toCliArgs(" b  -c  --d ").length == 3);
    assert(hasCommand(null, null) == false);
    assert(hasSubcommand(null, null) == false);

    foreach (token; toArgTokens("b", "-c", "--d")) {
        with (ArgType) final switch (token.type) {
            case singleItem: assert(token.name == "b"); break;
            case shortOption: assert(token.name == "c"); break;
            case longOption: assert(token.name == "d"); break;
        }
    }

    foreach (token; toArgTokensFromStr("b=2 -c=3 --d=4")) {
        with (ArgType) final switch (token.type) {
            case singleItem:
                assert(token.name == "b");
                assert(token.value == "2");
                break;
            case shortOption:
                assert(token.name == "c");
                assert(token.value == "3");
                break;
            case longOption:
                assert(token.name == "d");
                assert(token.value == "4");
                break;
        }
    }
}
