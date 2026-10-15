int main(string[] args) {
    string[] extraLibs;
    auto flags = Flags();
    foreach (arg; args[1 .. $]) {
        if (arg.length < 2) arg = "lol";
        auto isFlag = arg[0] == '-';
        if (arg[0] == '-') arg = arg[1 .. $];
        if (arg[0] == '-') arg = arg[1 .. $];
        auto hasInvalidFlag = true;
        static foreach (i, m; flags.tupleof) {
            if (m.stringof == arg) {
                flags.tupleof[i] = true;
                hasInvalidFlag = false;
            }
        }
        if (hasInvalidFlag) {
            if (!isFlag) extraLibs ~= arg;
            else {
                writeln(helpText);
                return 0;
            }
        }
    }

    if (flags.help) {
        writeln(helpText);
        return 0;
    }

    auto sourcePath = "source";
    if (!sourcePath.exists) sourcePath = "src";
    if (!sourcePath.exists) sourcePath = ".";
    auto webPath = "web";
    if (!webPath.exists) webPath = sourcePath;
    auto parinImportPath = buildPath(sourcePath, "parin").exists ? sourcePath : "";
    if (!parinImportPath.exists) parinImportPath = getImportPathFromDub("parin");

    foreach (entry; dirEntries(webPath, SpanMode.shallow)) {
        if (entry.name.endsWith(".a")) extraLibs ~= entry.name;
    }

    auto indexPath = buildPath(webPath, "index.html");
    if (!indexPath.exists) std.file.write(indexPath, indexText);

    auto mainFilePaths = dirEntries(sourcePath, SpanMode.shallow)
        .filter!(entry => entry.name.endsWith(".d"))
        .map!((entry => entry.name))
        .array;

    auto dflags = [
        "-i",
        "--d-version=WASI_EMULATED_MMAN",
        "--d-version=WASI_EMULATED_SIGNAL",
        "--d-version=ParinBackendWeb",
    ];
    if (flags.betterc) dflags ~= "-betterC";
    dflags ~= flags.release ? ["-release", "-O2"] : ["--d-debug", "-g"];

    auto command = ["ldc2", "--mtriple=wasm32-wasip1"] ~ dflags;
    command ~= mainFilePaths;
    command ~= extraLibs;
    if (sourcePath != parinImportPath) command ~= "-I=" ~ sourcePath;
    command ~= "-I=" ~ parinImportPath;
    command ~= "-J=" ~ buildPath(parinImportPath, "parin");
    if (!flags.libc) {
        command ~= ["-link-internally", "wasip1libc.o", "--of=" ~ buildPath(webPath, "index.wasm")];
        std.file.write("wasip1libc.d", wasip1libcText);
        if (run(["ldc2", "--mtriple=wasm32-wasip1"] ~ dflags ~ ["-c", "wasip1libc.d"])) return 1;
        std.file.remove("wasip1libc.d");
    }
    if (run(command)) return 1;

    foreach (entry; dirEntries(".", SpanMode.shallow)) {
        if (entry.name.endsWith(".o") || entry.name.endsWith(".obj")) entry.remove();
    }
    return 0;
}

import std.stdio;
import std.file;
import std.process;
import std.array;
import std.algorithm;
import std.path;
import std.string;

enum indexText      = import("index.html");
enum wasip1libcText = import("wasip1libc");

enum helpText = "
Usage:
  dub run parin:web-wasi -- [flags] [libs]
Flags:
  -help     Show this.
  -betterc  Use the `-betterC` flag.
  -libc     Use wasi-libc instead of the wasip1libc module.
  -release  Use the `-release` flag.
Libs:
  Any non-flag argument is linked as an extra library.
  Example: dub run parin:web-wasi -- web/libbox2d.a
"[1 .. $ - 1];

struct Flags {
    bool help;    // Show this.
    bool betterc; // Use the `-betterC` flag.
    bool libc;    // Use wasi-libc instead of the wasip1libc module.
    bool release; // Use the `-release` flag.
}

int run(string[] args...) {
    writeln("COMMAND: ", args);
    try {
        return spawnProcess(args).wait();
    } catch (Exception e) {
        return 1;
    }
}

string getImportPathFromDub(string packageName, string packageSourceName = "source") {
    auto target = buildPath(packageName, packageSourceName);
    version (Windows) {
        target ~= `\"`;
    } else {
        target ~= `/"`;
    }

    auto content = execute(["dub", "describe"]).output;
    auto lineIndex = 0UL;
    foreach (i, c; content) {
        if (c != '\n') continue;
        auto line = content[lineIndex .. i].strip().strip(",");
        if (line.endsWith(target)) {
            return line[line.indexOf('"') + 1 .. $ - 1];
        }
        lineIndex = i + 1;
    }

    return "";
}
