// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `io` module provides input and output functions such as file reading.
module parin.joka.io;

import stdc = parin.joka.stdc;
import parin.joka.memory;
import parin.joka.types;

@trusted:

enum defaultCodePathMessage = "Reached unexpected code path.";

enum StdStream : ubyte {
    input,
    output,
    error,
}

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
        return "{}".fmt(name);
    }

    IStr toString() {
        return toStr();
    }
}

/// A range of parsed tokens from the command-line arguments.
struct ArgTokenRange {
    const(IStr)[] args;

    @safe nothrow @nogc:

    @trusted
    this(const(IStr)[] args...) {
        this.args = args;
    }

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

void printf(StdStream stream = StdStream.output, A...)(IStr fmtStr, A args) {
    static assert(stream != StdStream.input, "Can't print to standard input.");

    auto text = fmt(fmtStr, args);
    auto textData = cast(Str) text.ptr[0 .. defaultAsciiFmtBufferSize];
    if (text.length == 0 || text.length == textData.length) return;
    textData[text.length] = '\0';
    stdc.fputs(textData.ptr, stream == StdStream.output ? stdc.stdout : stdc.stderr);
}

void printf(StdStream stream = StdStream.output, A...)(InterpolationHeader header, A args, InterpolationFooter footer) {
    // NOTE: Both `fmtStr` and `fmtArgs` can be copy-pasted when working with IES. Main copy is in the `fmt` function.
    enum fmtStr = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T) { result ~= args[i].toString(); }
            else static if (isInterExpType!T) { result ~= defaultAsciiFmtArgStr; }
        } return result;
    }();
    enum fmtArgs = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T || isInterExpType!T) {}
            else { result ~= "args[" ~ i.stringof ~ "],"; }
        } return result;
    }();
    mixin("printf(fmtStr,", fmtArgs, ");");
}

void printfln(StdStream stream = StdStream.output, A...)(IStr fmtStr, A args) {
    static assert(stream != StdStream.input, "Can't print to standard input.");

    auto text = fmt(fmtStr, args);
    auto textData = cast(Str) text.ptr[0 .. defaultAsciiFmtBufferSize];
    if (text.length == 0 || text.length == textData.length || text.length + 1 == textData.length) return;
    textData[text.length] = '\n';
    textData[text.length + 1] = '\0';
    stdc.fputs(textData.ptr, stream == StdStream.output ? stdc.stdout : stdc.stderr);
}

void printfln(StdStream stream = StdStream.output, A...)(InterpolationHeader header, A args, InterpolationFooter footer) {
    // NOTE: Both `fmtStr` and `fmtArgs` can be copy-pasted when working with IES. Main copy is in the `fmt` function.
    enum fmtStr = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T) { result ~= args[i].toString(); }
            else static if (isInterExpType!T) { result ~= defaultAsciiFmtArgStr; }
        } return result;
    }();
    enum fmtArgs = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T || isInterExpType!T) {}
            else { result ~= "args[" ~ i.stringof ~ "],"; }
        } return result;
    }();
    mixin("printfln(fmtStr,", fmtArgs, ");");
}

void print(StdStream stream = StdStream.output, A...)(A args) {
    static if (is(A[0] == Sep)) {
        foreach (i, arg; args[1 .. $]) {
            if (i) printf!stream("{}", args[0].value);
            printf!stream("{}", arg);
        }
    } else {
        foreach (arg; args) printf!stream("{}", arg);
    }
}

void println(StdStream stream = StdStream.output, A...)(A args) {
    print!stream(args);
    print!stream("\n");
}

void eprintf(StdStream stream = StdStream.output, A...)(IStr fmtStr, A args) {
    printf!(StdStream.error)(fmtStr, args);
}

void eprintf(StdStream stream = StdStream.output, A...)(InterpolationHeader header, A args, InterpolationFooter footer) {
    printf!(StdStream.error)(header, args, footer);
}

void eprintfln(StdStream stream = StdStream.output, A...)(IStr fmtStr, A args) {
    printfln!(StdStream.error)(fmtStr, args);
}

void eprintfln(StdStream stream = StdStream.output, A...)(InterpolationHeader header, A args, InterpolationFooter footer) {
    printfln!(StdStream.error)(header, args, footer);
}

void eprint(StdStream stream = StdStream.output, A...)(A args) {
    print!(StdStream.error)(args);
}

void eprintln(StdStream stream = StdStream.output, A...)(A args) {
    println!(StdStream.error)(args);
}

IStr sprintf(S = LStr, A...)(ref S buffer, IStr fmtStr, A args) {
    static if (isStrContainerType!S) {
        return fmtIntoList!true(buffer, fmtStr, args);
    } else {
        return fmtIntoBuffer(buffer, fmtStr, args);
    }
}

void sprintf(S = LStr, A...)(ref S buffer, InterpolationHeader header, A args, InterpolationFooter footer) {
    // NOTE: Both `fmtStr` and `fmtArgs` can be copy-pasted when working with IES. Main copy is in the `fmt` function.
    enum fmtStr = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T) { result ~= args[i].toString(); }
            else static if (isInterExpType!T) { result ~= defaultAsciiFmtArgStr; }
        } return result;
    }();
    enum fmtArgs = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T || isInterExpType!T) {}
            else { result ~= "args[" ~ i.stringof ~ "],"; }
        } return result;
    }();
    mixin("sprintf(buffer, fmtStr,", fmtArgs, ");");
}

IStr sprintfln(S = LStr, A...)(ref S buffer, IStr fmtStr, A args) {
    auto text = sprintf(buffer, fmtStr, args);
    if (text.length == 0) return "";
    static if (isStrContainerType!S) {
        static if (isLStrType!S) {
            buffer.append('\n');
            return buffer[];
        } else {
            if (text.length == buffer.capacity) return "";
            buffer.append('\n');
            return buffer[];
        }
    } else {
        if (text.length == buffer.length) return "";
        buffer[text.length] = '\n';
        return buffer[0 .. text.length + 1];
    }
}

void sprintfln(S = LStr, A...)(ref S buffer, InterpolationHeader header, A args, InterpolationFooter footer) {
    // NOTE: Both `fmtStr` and `fmtArgs` can be copy-pasted when working with IES. Main copy is in the `fmt` function.
    enum fmtStr = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T) { result ~= args[i].toString(); }
            else static if (isInterExpType!T) { result ~= defaultAsciiFmtArgStr; }
        } return result;
    }();
    enum fmtArgs = () {
        Str result; static foreach (i, T; A) {
            static if (isInterLitType!T || isInterExpType!T) {}
            else { result ~= "args[" ~ i.stringof ~ "],"; }
        } return result;
    }();
    mixin("sprintfln(buffer, fmtStr,", fmtArgs, ");");
}

void sprint(S = LStr, A...)(ref S buffer, A args) {
    static if (is(A[0] == Sep)) {
        foreach (i, arg; args[1 .. $]) {
            if (i) sprintf(buffer, "{}", args[0].value);
            sprintf(buffer, "{}", arg);
        }
    } else {
        foreach (arg; args) sprintf(buffer, "{}", arg);
    }
}

void sprintln(S = LStr, A...)(ref S buffer, A args) {
    sprint(buffer, args);
    sprint(buffer, "\n");
}

void trace(IStr file = __FILE__, Sz line = __LINE__, A...)(A args) {
    printf("TRACE({}:{}):", file, line);
    foreach (arg; args) printf(" {}", arg);
    printf("\n");
}

void warn(IStr text = defaultCodePathMessage, IStr file = __FILE__, Sz line = __LINE__) {
    printf("WARN({}:{}): {}\n", file, line, text);
}

noreturn todo(IStr text = defaultCodePathMessage, IStr file = __FILE__, Sz line = __LINE__) {
    assert(0, "TODO({}:{}): {}".fmt(file, line, text));
}

@trusted nothrow
IStr memoryTrackingInfo(IStr pathFilter = "", bool canShowEmpty = false) {
    static if (isTrackingMemory) {
        // TODO: This needs to be simpler because it was so hard to remember how it works.
        static void _updateGroupBuffer(T)(ref T table) {
            _memoryTrackingState.groupBuffer.clear();
            foreach (key, value; table) {
                if (value.canIgnore) continue;
                auto groupKey = _MallocInfo(value.file, value.line, 0, false, value.group);
                if (auto groupValue = groupKey in _memoryTrackingState.groupBuffer) {
                    groupValue.size += value.size;
                    groupValue.count += 1;
                } else {
                    _memoryTrackingState.groupBuffer[groupKey] = _MallocGroupInfo(value.size, 1);
                }
            }
        }

        try {
            _memoryTrackingState.infoBuffer.length = 0;
            auto finalLength = _memoryTrackingState.table.length;
            foreach (key, value; _memoryTrackingState.table) if (value.canIgnore) finalLength -= 1;
            auto ignoreCount = _memoryTrackingState.table.length - finalLength;
            auto ignoreText = ignoreCount ? ", {} ignored".fmt(ignoreCount) : "";
            auto filterText = pathFilter.length ? fmt("Filter: \"{}\"\n", pathFilter) : "";

            if (canShowEmpty ? true : finalLength != 0) {
                _memoryTrackingState.infoBuffer ~= fmt("Memory Leaks: {} (total {} bytes{})\n{}", finalLength, _memoryTrackingState.totalBytes, ignoreText, filterText);
            }
            _updateGroupBuffer(_memoryTrackingState.table);
            foreach (key, value; _memoryTrackingState.groupBuffer) {
                if (pathFilter.length && key.file.findEnd(pathFilter) == -1) continue;
                _memoryTrackingState.infoBuffer ~= fmt("  {} leak, {} bytes, {}:{}{}\n", value.count, value.size, key.file, key.line, key.group.length ? " [group: \"{}\"]".fmt(key.group) : "");
            }
            if (canShowEmpty ? true : _memoryTrackingState.invalidFreeTable.length != 0) {
                _memoryTrackingState.infoBuffer ~= fmt("Invalid Frees: {}\n{}", _memoryTrackingState.invalidFreeTable.length, filterText);
            }
            _updateGroupBuffer(_memoryTrackingState.invalidFreeTable);
            foreach (key, value; _memoryTrackingState.groupBuffer) {
                if (pathFilter.length && key.file.findEnd(pathFilter) == -1) continue;
                _memoryTrackingState.infoBuffer ~= fmt("  {} free, {}:{}{}\n", value.count, key.file, key.line, key.group.length ? " [group: \"{}\"]".fmt(key.group) : "");
            }
        } catch (Exception e) {
            return "No memory tracking data available.\n";
        }
        return _memoryTrackingState.infoBuffer;
    } else {
        debug {
            version (D_BetterC) {
                return "No memory tracking data available in BetterC builds.\n";
            }
        } else {
            return "No memory tracking data available in release builds.\n";
        }
    }
}

@safe nothrow:

@trusted
Fault readFileIntoBuffer(L = LStr)(IStr path, ref L listBuffer, bool binaryMode) {
    auto file = stdc.fopen(toStrz(path).getOr(), binaryMode ? "rb" : "r");
    if (file == null) return Fault.cannotOpen;

    if (stdc.fseek(file, 0, stdc.SEEK_END) != 0) {
        stdc.fclose(file);
        return Fault.cannotRead;
    }
    auto fileSize = stdc.ftell(file);
    if (fileSize < 0) {
        stdc.fclose(file);
        return Fault.cannotRead;
    }
    if (stdc.fseek(file, 0, stdc.SEEK_SET) != 0) {
        stdc.fclose(file);
        return Fault.cannotRead;
    }

    static if (L.hasFixedCapacity) {
        if (listBuffer.capacity < fileSize) {
            stdc.fclose(file);
            return Fault.overflow;
        }
    }
    listBuffer.resizeBlank(fileSize);
    if (stdc.fread(listBuffer.items.ptr, 1, fileSize, file) != fileSize) {
        stdc.fclose(file);
        return Fault.cannotRead;
    }
    if (stdc.fclose(file) != 0) return Fault.cannotClose;
    return Fault.none;
}

Fault readTextIntoBuffer(L = LStr)(IStr path, ref L listBuffer) {
    return readFileIntoBuffer(path, listBuffer, false);
}

Fault readBytesIntoBuffer(L = LStr)(IStr path, ref L listBuffer) {
    return readFileIntoBuffer(path, listBuffer, true);
}

Maybe!LStr readFile(IStr path, bool binaryMode) {
    LStr value;
    auto fault = readFileIntoBuffer(path, value, binaryMode);
    auto result = Maybe!LStr(value, fault);
    return result;
}

Maybe!LStr readText(IStr path) {
    return readFile(path, false);
}

Maybe!LStr readBytes(IStr path, bool binaryMode) {
    return readFile(path, true);
}

@trusted @nogc
Fault writeFile(IStr path, IStr text, bool binaryMode) {
    auto file = stdc.fopen(toStrz(path).getOr(), binaryMode ? "wb" : "w");
    if (file == null) return Fault.cannotOpen;
    if (stdc.fwrite(text.ptr, char.sizeof, text.length, file) != text.length) {
        stdc.fclose(file);
        return Fault.cannotWrite;
    }
    if (stdc.fclose(file) != 0) {
        return Fault.cannotClose;
    }
    return Fault.none;
}

@nogc
Fault writeText(IStr path, IStr text) {
    return writeFile(path, text, false);
}

@nogc
Fault writeBytes(IStr path, IStr bytes) {
    return writeFile(path, bytes, true);
}

// Function test.
unittest {
    assert(readText("").isSome == false);
    assert(writeText("", "") != Fault.none);
}

// Arg test.
unittest {
    foreach (token; ArgTokenRange("b", "-c", "--d")) {
        with (ArgType) final switch (token.type) {
            case singleItem: assert(token.name == "b"); break;
            case shortOption: assert(token.name == "c"); break;
            case longOption: assert(token.name == "d"); break;
        }
    }

    foreach (token; ArgTokenRange("b=2", "-c=3", "--d=4")) {
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
