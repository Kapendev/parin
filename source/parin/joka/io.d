// ---
// Copyright 2026 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/joka
// ---

/// The `io` module provides input and output functions such as file reading.
module parin.joka.io;

import parin.joka.memory;
import parin.joka.types;

// TODO: Should be changed with something better?
//   I added this import to get the print functions working with WASI P1.
//   Can be removed later.
version (WASI) {
    import wasi = parin.joka.wasip1;
} else {
    import stdc = parin.joka.stdc;
}

@trusted:

enum StdStream : ubyte {
    input,
    output,
    error,
}

/// Prints formatted text to stdout.
/// For details on formatting, see the `fmtIntoBuffer` function.
void printf(StdStream stream = StdStream.output, A...)(IStr fmtStr, A args) {
    static assert(stream != StdStream.input, "Can't print to standard input.");

    auto text = fmt(fmtStr, args);
    auto textData = cast(Str) text.ptr[0 .. defaultAsciiFmtBufferSize];
    if (text.length == 0 || text.length == textData.length) return;
    textData[text.length] = '\0';
    version (WASI) {
        auto bytes = wasi.Size();
        auto wasiText = wasi.toCiovec(textData[0 .. text.length]);
        wasi.fdWrite(stream == StdStream.output ? wasi.stdout : wasi.stderr, &wasiText, 1, &bytes);
    } else {
        stdc.fputs(textData.ptr, stream == StdStream.output ? stdc.stdout : stdc.stderr);
    }
}

/// Prints formatted text to stdout.
/// For details on formatting, see the `fmtIntoBuffer` function.
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

/// Prints formatted text with a new line at the end to stdout.
/// For details on formatting, see the `fmtIntoBuffer` function.
void printfln(StdStream stream = StdStream.output, A...)(IStr fmtStr, A args) {
    static assert(stream != StdStream.input, "Can't print to standard input.");

    auto text = fmt(fmtStr, args);
    auto textData = cast(Str) text.ptr[0 .. defaultAsciiFmtBufferSize];
    if (text.length == 0 || text.length == textData.length || text.length + 1 == textData.length) return;
    textData[text.length] = '\n';
    textData[text.length + 1] = '\0';
    version (WASI) {
        auto bytes = wasi.Size();
        auto wasiText = wasi.toCiovec(textData[0 .. text.length + 1]);
        wasi.fdWrite(stream == StdStream.output ? wasi.stdout : wasi.stderr, &wasiText, 1, &bytes);
    } else {
        stdc.fputs(textData.ptr, stream == StdStream.output ? stdc.stdout : stdc.stderr);
    }
}

/// Prints formatted text with a new line at the end to stdout.
/// For details on formatting, see the `fmtIntoBuffer` function.
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

/// Prints text to stdout.
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

/// Prints text with a new line at the end to stdout.
void println(StdStream stream = StdStream.output, A...)(A args) {
    print!stream(args);
    print!stream("\n");
}

/// Prints formatted text to stderr.
/// For details on formatting, see the `fmtIntoBuffer` function.
void eprintf(StdStream stream = StdStream.output, A...)(IStr fmtStr, A args) {
    printf!(StdStream.error)(fmtStr, args);
}

/// Prints formatted text to stderr.
/// For details on formatting, see the `fmtIntoBuffer` function.
void eprintf(StdStream stream = StdStream.output, A...)(InterpolationHeader header, A args, InterpolationFooter footer) {
    printf!(StdStream.error)(header, args, footer);
}

/// Prints formatted text with a new line at the end to stderr.
/// For details on formatting, see the `fmtIntoBuffer` function.
void eprintfln(StdStream stream = StdStream.output, A...)(IStr fmtStr, A args) {
    printfln!(StdStream.error)(fmtStr, args);
}

/// Prints formatted text with a new line at the end to stderr.
/// For details on formatting, see the `fmtIntoBuffer` function.
void eprintfln(StdStream stream = StdStream.output, A...)(InterpolationHeader header, A args, InterpolationFooter footer) {
    printfln!(StdStream.error)(header, args, footer);
}

/// Prints text to stderr.
void eprint(StdStream stream = StdStream.output, A...)(A args) {
    print!(StdStream.error)(args);
}

/// Prints text with a new line at the end to stderr.
void eprintln(StdStream stream = StdStream.output, A...)(A args) {
    println!(StdStream.error)(args);
}

/// Prints values and their source location to stdout.
void trace(IStr file = __FILE__, Sz line = __LINE__, A...)(A args) {
    printf("TRACE({}:{}):", file, line);
    foreach (arg; args) printf(" {}", arg);
    printf("\n");
}

@safe nothrow:

/// Reads an file in one go and store the data inside a buffer.
@trusted
Fault readFileIntoBuffer(L = LStr)(IStr path, ref L listBuffer, bool binaryMode) {
    version (WASI) {
        return Fault.some;
    } else {
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
}

/// Reads an file in one go and store the data inside a buffer.
Fault readTextIntoBuffer(L = LStr)(IStr path, ref L listBuffer) {
    return readFileIntoBuffer(path, listBuffer, false);
}

/// Reads an file in one go and store the data inside a buffer.
Fault readBytesIntoBuffer(L = LStr)(IStr path, ref L listBuffer) {
    return readFileIntoBuffer(path, listBuffer, true);
}

/// Reads an file in one go and store the data inside a new list. The list must be freed.
Maybe!LStr readFile(IStr path, bool binaryMode) {
    LStr value;
    auto fault = readFileIntoBuffer(path, value, binaryMode);
    auto result = Maybe!LStr(value, fault);
    return result;
}

/// Reads an file in one go and store the data inside a new list. The list must be freed.
Maybe!LStr readText(IStr path) {
    return readFile(path, false);
}

/// Reads an file in one go and store the data inside a new list. The list must be freed.
Maybe!LStr readBytes(IStr path) {
    return readFile(path, true);
}

/// Writes a file.
@trusted @nogc
Fault writeFile(IStr path, IStr text, bool binaryMode) {
    version (WASI) {
        return Fault.some;
    } else {
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
}

/// Writes a file.
@nogc
Fault writeText(IStr path, IStr text) {
    return writeFile(path, text, false);
}

/// Writes a file.
@nogc
Fault writeBytes(IStr path, IStr bytes) {
    return writeFile(path, bytes, true);
}

// Function test.
unittest {
    assert(readText("").isSome == false);
    assert(writeText("", "") != Fault.none);
}
