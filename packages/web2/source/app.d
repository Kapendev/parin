#!/bin/env -S dmd -run

void main(string[] args) {
    // TODO: Think about how to do the project this time with the new backend.
    //   Probably easier than the older setup because we don't depend on stuff.
    writeln("Hello world!");
}

enum indexText      = import("index.html");
enum wasip1libcText = import(".wasip1libc.d");

import std.stdio;
