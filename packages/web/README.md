# Web

A helper script to assist with the web export process.
Building for the web also requires [Emscripten](https://emscripten.org/).

**Running the script with DUB**:

```sh
dub run parin:web
```

**Without DUB**:

```sh
ldc2 -J=parin_package/packages/web/source -run parin_package/packages/web/source/app.d
# Or: opend -run parin_package/packages/web/source/app.d
```
