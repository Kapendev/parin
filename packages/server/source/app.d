void main(string[] args) {
    auto sourcePath = "source";
    if (!sourcePath.exists) sourcePath = "src";
    if (!sourcePath.exists) sourcePath = ".";
    auto webPath = "web";
    if (!webPath.exists) webPath = sourcePath;

    if (args.length == 1) args ~= "8383";
    if (args.length == 3) webPath = args[2];
    if (!args[1].isNumeric || args.length > 3) {
        writeln("Usage:\n  dub run parin:server -- [port] [folder]");
        return;
    }

    auto cgiArg = "localhost:" ~ args[1];
    chdir(webPath);
    writeln("Open: http://" ~ cgiArg ~ "/index.html");
    cgiMainImpl!requestHandler([args[0], "--listen", cgiArg]);
}

void requestHandler(Cgi cgi) {
    cgi.dispatcher!("/".serveStaticFileDirectory("./", true));
}

import arsd.cgi;
import std.stdio;
import std.file;
import std.string;
