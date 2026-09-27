void main(string[] args) {
    if (args.length != 2) {
        import std.stdio;
        writeln("Usage:\n  dub run parin:server -- localhost:8383");
        return;
    }

    auto sourcePath = "source";
    if (!sourcePath.exists) sourcePath = "src";
    if (!sourcePath.exists) sourcePath = ".";
    auto webPath = "web";
    if (!webPath.exists) webPath = sourcePath;

    chdir(webPath);
    writeln("Open: http://" ~ args[1] ~ "/index.html");
    args = [args[0], "--listen"] ~ args[1 .. $];
    cgiMainImpl!requestHandler(args);
}

void requestHandler(Cgi cgi) {
    cgi.dispatcher!("/".serveStaticFileDirectory("./", true));
}

import arsd.cgi;
import std.stdio;
import std.file;
