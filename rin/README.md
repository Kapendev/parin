# Rin

A script interpreter for Rin.
It helps with error checking and debugging, making it easier to work with Rin scripts.

## Usage

* With DUB: `dub run parin:rin`
* Without DUB: `dmd -run -Ijoka_path -Iparin_path source/app.d`

## Options

* -debug: Runs the script in debug mode. This will change the value of DEBUG.
* -linear: Runs the script in linear mode. This will force the interpreter to go over every line.

## Editor Themes

Rin syntax highlighting files for various text editors are available in the [assets](./assets/) folder.
