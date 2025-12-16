// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `io` module provides input and output functions such as file reading.
module parin.joka.io;

import stdioc = parin.joka.stdc.stdio;
import parin.joka.ascii;
import parin.joka.containers;
import parin.joka.memory;
import parin.joka.types;
import parin.joka.interpolation;

@trusted:

enum defaultCodePathMessage = "Reached unexpected code path.";

enum StdStream : ubyte {
    input,
    output,
    error,
}

void printf(StdStream stream = StdStream.output, A...)(IStr fmtStr, A args) {
    static assert(stream != StdStream.input, "Can't print to standard input.");

    auto text = fmt(fmtStr, args);
    auto textData = cast(Str) text.ptr[0 .. defaultAsciiBufferSize];
    if (text.length == 0 || text.length == textData.length) return;
    textData[text.length] = '\0';
    stdioc.fputs(textData.ptr, stream == StdStream.output ? stdioc.stdout : stdioc.stderr);
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
    auto textData = cast(Str) text.ptr[0 .. defaultAsciiBufferSize];
    if (text.length == 0 || text.length == textData.length || text.length + 1 == textData.length) return;
    textData[text.length] = '\n';
    textData[text.length + 1] = '\0';
    stdioc.fputs(textData.ptr, stream == StdStream.output ? stdioc.stdout : stdioc.stderr);
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

void printMemoryTrackingInfo(IStr filter = "", bool canShowEmpty = false) {
    print(memoryTrackingInfo(filter, canShowEmpty));
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

@safe nothrow:

@trusted
Fault readFileIntoBuffer(L = LStr)(IStr path, ref L listBuffer, bool binaryMode) {
    auto file = stdioc.fopen(toStrz(path).getOr(), binaryMode ? "rb" : "r");
    if (file == null) return Fault.cannotOpen;

    if (stdioc.fseek(file, 0, stdioc.SEEK_END) != 0) {
        stdioc.fclose(file);
        return Fault.cannotRead;
    }
    auto fileSize = stdioc.ftell(file);
    if (fileSize < 0) {
        stdioc.fclose(file);
        return Fault.cannotRead;
    }
    if (stdioc.fseek(file, 0, stdioc.SEEK_SET) != 0) {
        stdioc.fclose(file);
        return Fault.cannotRead;
    }

    static if (L.hasFixedCapacity) {
        if (listBuffer.capacity < fileSize) {
            stdioc.fclose(file);
            return Fault.overflow;
        }
    }
    listBuffer.resizeBlank(fileSize);
    if (stdioc.fread(listBuffer.items.ptr, 1, fileSize, file) != fileSize) {
        stdioc.fclose(file);
        return Fault.cannotRead;
    }
    if (stdioc.fclose(file) != 0) return Fault.cannotClose;
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
    auto file = stdioc.fopen(toStrz(path).getOr(), binaryMode ? "wb" : "w");
    if (file == null) return Fault.cannotOpen;
    if (stdioc.fwrite(text.ptr, char.sizeof, text.length, file) != text.length) {
        stdioc.fclose(file);
        return Fault.cannotWrite;
    }
    if (stdioc.fclose(file) != 0) {
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
