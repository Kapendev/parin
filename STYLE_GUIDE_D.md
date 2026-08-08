# Kapendev Style Guide for D

The **official** Kapendev style guide for D.
This guide should be used as a reference, not as a hard rule.

## Comments

- Prefer using `//` instead of `/* */`
- Prefer ending comments with a `.`
- Prefer using `///` for documentation comments
- Comments are always above attributes and functions
- Use `// --- Title Case` for splitting code into sections
- Use `// +-- Title Case` for creating a section with an end. The section should end with `// +--`
- Use `// @--` for attribute groups that use `:`

## Names

- Structs, classes and enums use PascalCase: `List`, `Arena`, `Rgba`, `GVec2`
- Generic types are prefixed with "G" when the name without the prefix is reserved for a specific type: `Vec2` -> `GVec2!float`
- Aliases use PascalCase or camelCase based on what they are pointing to
- Aliases to `typeof(this)` are called `This`
- Custom attributes use camelCase: `hiddenMember`, `requiredMember`
- Enum variants use camelCase: `none`, `some`, `topLeft`
- Templates use PascalCase or camelCase based on what they are pointing to
- Mixin templates use camelCase: `typed`, `runGame`
- Functions use camelCase: `findListCapacity`, `toForeignSlice`
- Variables use camelCase: `position`, `tileSize`
- Constants use camelCase: `pi`, `epsilon`, `white`
- Constants are prefixed with "default" + group when the name without the prefix is too generic: `defaultEngineTitle`, `defaultAsciiFmtArgStr`
- Internal names use underscore prefix: `_engineState`, `_swizzleN`, `_swizzleC`
- Prefer using one underscore in most cases
- Common temporary loop variable names: `i`, `j`, `k`, `x`, `y`, `z`, `n`, `c`, `e`, `index`, `item`

## Acronyms & Abbreviations

- CSV, JSON, EOL, etc. are treated as regular names
- In PascalCase contexts: `Csv`, `Json`, `Eol`
- In camelCase contexts: `csv`, `json`, `eol`

## Struct & Class Layout

Organize members in this order:

1. Variables
2. Aliases
3. Enums
4. Structs and classes (implementation)
5. Constructors (implementation)
6. Methods (implementation)

With `alias this` being part of the variables,
and with `@disable this();` being the first constructor (if it exists).
Immutables variables can be placed after enums.

## Module Layout

Each module should:

1. Start with header comment (copyright, license, etc.)
2. Define the module name
3. Import dependencies
4. Define versions/configurations
5. Define the module body

With the body following this order:

1. Variables
2. Aliases
3. Enums
4. Structs and classes (implementation)
5. Functions (implementation)

Only excpetion to the above points are types that follow this pattern:

```d
// NOTE: Writting `Attached!Camera(camera)` would look bad, so a function is used.
struct _Attached(T) {
    T* _attachedObject;

    @trusted nothrow @nogc:

    @disable this();

    this(ref T object) {
        this._attachedObject = &object;
        attach(*this._attachedObject);
    }

    ~this() {
        detach(*this._attachedObject);
    }
}

/// Attaches the camera for the scope and detaches automatically.
/// Designed to be used with the `with` keyword.
@trusted nothrow @nogc
_Attached!T Attached(T)(ref T object) {
    return _Attached!T(object);
}
```

In this specific case it's fine to have functions after the struct definition and then continue with other structs or classes.

## Project Layout

- Avoid cross-module dependencies
- Try to keep the module dependency count low
- Prefer big modules that include eveything instead of smaller modules that split things into specific groups

## Attributes & Pragmas

- Attributes and pragmas should always be on a different line than a function or type definition
- Prefer groupping attributes with `{}`
- Prefer using `:` only at the start of an implementation section (see structs, classes and modules)
- If `:` needs to be used more than one time in the same implementation section, then add a `// @--` comment above every use of `:`
- Function aliases should be inside attribute groups, even if it's only one function
- Preferred order of attributes and pragmas: `pragma(xyz) @safe nothrow @nogc @customAttribute`
- Never use the `pure` attribute
- Avoid writting code in an "attribute-oriented" style: don't always add `@nogc` to a nogc function when it accepts a callback
- Attributes should mainly be used for library code and not application code

## Asserts

- Avoid runtime asserts
- Be explicit about functions that assert: `getOrAssert`
- Use `assert(0, ...)` and not `assert(false, ...)`
