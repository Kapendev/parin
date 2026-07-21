# Kapendev Style Guide for D

The **OFFICIAL** Kapendev style guide for D.
This guide should be used as a reference, not as a hard rule.

## Names

- Types use PascalCase: `List`, `Arena`, `Rgba`, `GVec2`
- Generic types are prefixed with "G" when the name without the prefix is reserved for a specific type (`Vec2` -> `GVec2!float`)
- Aliases to `typeof(this)` are called `This`.
- Attribute structs use camelCase: `hiddenMember`, `requiredMember`
- Enum variants use camelCase: `none`, `some`, `topLeft`
- Mixin templates use camelCase: `typed`, `runGame`
- Functions use camelCase: `findListCapacity`, `toForeignSlice`
- Variables use camelCase: `position`, `tileSize`
- Constants use camelCase: `pi`, `epsilon`, `white`
- Constants are prefixed with "default" + group when the name without the prefix is too generic: `defaultEngineTitle`, `defaultAsciiFmtArgStr`
- Internal names use underscore prefix: `_engineState`, `_swizzleN`, `_swizzleC`
- Common temporary loop variable names: `i`, `j`, `k`, `x`, `y`, `z`, `n`, `c`

## Acronyms & Abbreviations

- CSV, JSON, EOL, etc. are treated as regular names
- In PascalCase contexts: `Csv`, `Json`, `Eol`
- In camelCase contexts: `csv`, `json`, `eol`

## Struct & Class Layout

Organize members in this order:

1. Variables
2. Enums
3. Aliases
4. Types
5. Constructors (implementation)
6. Methods (implementation)

With `alias this` being part of the variables.

## Module Structure

Each module should:

1. Start with header comment (copyright, license, etc.)
2. Define the module
3. Import dependencies
4. Define versions/configuration/constants
5. Module body (implementation)

With the body looking like:

1. Variables
2. Enums
3. Aliases
4. Types
5. Functions

## Attributes

- Prefer groupping attributes with `{}`
- Use `:` only at the start of the implementation of a struct, class or module
- Function aliases are inside attribute groups, even if it's only one function
- Attribute order: `@safe nothrow @nogc @customAttribute`
- Never use the `pure` attribute

## Asserts

- Avoid runtime asserts.
- Be explicit about functions that assert: `getOrAssert`
- Use `assert(0, ...)` and not `assert(false, ...)`
