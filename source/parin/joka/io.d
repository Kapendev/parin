// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `io` module provides input and output functions such as file reading.
module parin.joka.io;

import parin.joka.ascii;
import parin.joka.containers;
import parin.joka.memory;
import parin.joka.types;
import stdioc = parin.joka.stdc.stdio;

enum StdStream : ubyte {
    input,
    output,
    error,
}

@trusted
void printf(StdStream stream = StdStream.output, A...)(IStr fmtStr, A args) {
    static assert(stream != StdStream.input, "Can't print to standard input.");

    auto text = fmt(fmtStr, args);
    auto textData = cast(Str) text.ptr[0 .. defaultAsciiBufferSize];
    if (text.length == 0 || text.length == textData.length) return;
    textData[text.length] = '\0';
    stdioc.fputs(textData.ptr, stream == StdStream.output ? stdioc.stdout : stdioc.stderr);
}

@trusted
void printfln(StdStream stream = StdStream.output, A...)(IStr fmtStr, A args) {
    static assert(stream != StdStream.input, "Can't print to standard input.");

    auto text = fmt(fmtStr, args);
    auto textData = cast(Str) text.ptr[0 .. defaultAsciiBufferSize];
    if (text.length == 0 || text.length == textData.length || text.length + 1 == textData.length) return;
    textData[text.length] = '\n';
    textData[text.length + 1] = '\0';
    stdioc.fputs(textData.ptr, stream == StdStream.output ? stdioc.stdout : stdioc.stderr);
}

@safe
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

@safe
void println(StdStream stream = StdStream.output, A...)(A args) {
    print!stream(args);
    print!stream("\n");
}

@trusted
IStr sprintf(S = LStr, A...)(ref S buffer, IStr fmtStr, A args) {
    static if (isStrContainerType!S) {
        return fmtIntoList!true(buffer, fmtStr, args);
    } else {
        return fmtIntoBuffer(buffer, fmtStr, args);
    }
}

@trusted
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

@safe
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

@safe
void sprintln(S = LStr, A...)(ref S buffer, A args) {
    sprint(buffer, args);
    sprint(buffer, "\n");
}

@safe
void printMemoryTrackingInfo(IStr filter = "", bool canShowEmpty = false) {
    print(memoryTrackingInfo(filter, canShowEmpty));
}

@safe
void tracef(IStr file = __FILE__, Sz line = __LINE__, A...)(IStr fmtStr, A args) {
    printf("TRACE({}:{}): {}\n", file, line, fmtStr.fmt(args));
}

@safe
void trace(IStr file = __FILE__, Sz line = __LINE__, A...)(A args) {
    printf("TRACE({}:{}):", file, line);
    foreach (arg; args) printf(" {}", arg);
    printf("\n");
}

@safe
void warn(IStr text = "Not implemented.", IStr file = __FILE__, Sz line = __LINE__) {
    printf("WARN({}:{}): {}\n", file, line, text);
}

@safe
noreturn todo(IStr text = "Not implemented.", IStr file = __FILE__, Sz line = __LINE__) {
    assert(0, "TODO({}:{}): {}".fmt(file, line, text));
}

@safe nothrow:

// NOTE: Also maybe think about errno lol.
@trusted
Fault readTextIntoBuffer(L = LStr)(IStr path, ref L listBuffer) {
    auto file = stdioc.fopen(toStrz(path).getOr(), "r");
    if (file == null) return Fault.cannotOpen;

    if (stdioc.fseek(file, 0, stdioc.SEEK_END) != 0) {
        stdioc.fclose(file);
        return Fault.cannotRead;
    }
    auto fileSize = stdioc.ftell(file);
    if (fileSize == -1) {
        stdioc.fclose(file);
        return Fault.cannotRead;
    }
    if (stdioc.fseek(file, 0, stdioc.SEEK_SET) != 0) {
        stdioc.fclose(file);
        return Fault.cannotRead;
    }

    static if (L.hasFixedCapacity) {
        if (listBuffer.capacity < fileSize) {
            if (stdioc.fclose(file) != 0) return Fault.cannotClose;
            return Fault.overflow;
        }
    }
    listBuffer.resizeBlank(fileSize);
    stdioc.fread(listBuffer.items.ptr, fileSize, 1, file);
    if (stdioc.fclose(file) != 0) return Fault.cannotClose;
    return Fault.none;
}

Maybe!LStr readText(IStr path) {
    LStr value;
    auto fault = readTextIntoBuffer(path, value);
    return Maybe!LStr(value, fault);
}

// NOTE: Also maybe think about errno lol.
@trusted @nogc
Fault writeText(IStr path, IStr text) {
    auto file = stdioc.fopen(toStrz(path).getOr(), "w");
    if (file == null) return Fault.cannotOpen;
    stdioc.fwrite(text.ptr, char.sizeof, text.length, file);
    if (stdioc.fclose(file) != 0) return Fault.cannotClose;
    return Fault.none;
}

// Function test.
unittest {
    assert(readText("").isSome == false);
    assert(writeText("", "") != Fault.none);
}
