# Avoiding The GC in D: Stack, Buffers & Arenas

It's common to see new D users talking about `@nogc` and `-betterC` when discussing Manual Memory Management (MMM).
In a way, it makes sense.
Both are closely related to it based on their names.
One of them is literally called "no GC."

This might sound strange given their names, but neither `@nogc` nor `-betterC` is actually MMM.
They don't tell you how memory is allocated or when allocation happens.
A `@nogc` function could allocate or it could not.
What they do tell you is that one type of allocator, the GC, is not being used.
That only rules out one allocator.

The TL;DR is that both of those features are compiler-enforced GC restrictions with:

- `@nogc`: also being part of the type system.
- `-betterC`: also removing the D runtime.

In this post, I will skip over `-betterC` since removing the D runtime is a topic of its own.
I'll go over how to do manual memory management in D and how to avoid the GC without fighting the language.

## Stack Memory

Let's start with the stack.
It's the simplest option to use and is always available.
To use it, you define a static type and create an instance of it on the stack:

```d
void main() {
    alias StringData = char[64][4]; // The type.
    StringData stringData = void;   // The instance.
}
```

In the code above, the program can store 4 strings containing up to 64 characters each.
The `= void` part tells the compiler to not default initialize the string data because it will be initialized later as needed.

For example:

```d
import std.stdio;

void main() {
    alias StringData = char[64][4];
    StringData stringData = void;

    auto text = stringData[0][0 .. 3]; // Create a string.
    text[] = "Hi!";                    // Initialize the string.
    writeln(text);                     // Use the string.
}
```

The variable `text` points to the 3 first bytes of `stringData` and they are used to print `Hi!` with `writeln`.
A similar pattern in game development is creating temporary strings for things like entities or levels.
With the trick above, we can generate level names without dynamically allocating:

```d
import std.stdio;

void main() {
    alias StringData = char[64][4];
    StringData stringData = void;

    auto level = 68;
    auto name = stringData[0][0 .. 8];
    name[0 .. 6] = "level_";
    name[6] = cast(char) ('0' + (level / 10) % 10);
    name[7] = cast(char) ('0' + level % 10);

    writeln(name); // Output: level_68
}
```

That's nice.
There is no need to free any memory here because the stack will handle it automatically.
The natural next step is to wrap the string generation part of the code into a function so the main function is less noisy:

```d
import std.stdio;

void main() {
    auto level = 68;
    auto name = level.toLevelName();
    writeln(name);
}

const(char)[] toLevelName(int level) {
    alias StringData = char[64][4];
    StringData stringData = void;

    auto name = stringData[0][0 .. 8];
    name[0 .. 6] = "level_";
    name[6] = cast(char) ('0' + (level / 10) % 10);
    name[7] = cast(char) ('0' + level % 10);
    return name;
}
```

You might notice, however, that the output is now not correct.
This happens because the returned slice points to memory owned by the callee's stack frame, which becomes invalid once the function returns.
So, how do we fix that if we want to be able to return some temporary data from a function?

## Static Buffers

The solution is static buffers.
They are valid for the entirety of the program's lifetime, meaning we can pass them around without any issues.
It's also important to note that static variables in D are thread-local by default, so each thread gets its own buffer:

```d
import std.stdio;

void main() {
    auto level = 68;
    auto name = level.toLevelName();
    writeln(name);
}

const(char)[] toLevelName(int level) {
    alias StringData = char[64][4];
    static StringData stringData = void; // <-- The fix.

    auto name = stringData[0][0 .. 8];
    name[0 .. 6] = "level_";
    name[6] = cast(char) ('0' + (level / 10) % 10);
    name[7] = cast(char) ('0' + level % 10);
    return name;
}
```

There is still one issue though: only one of the 4 static strings is being used.
This means that every call to `toLevelName` will always return the same data, potentially invalidating the memory of any variable that holds a result of that function.

For example:

```d
import std.stdio;

void main() {
    auto name1 = 1.toLevelName();
    auto name2 = 2.toLevelName();
    writeln(name1); // Output: level_02
    writeln(name2); // Output: level_02
}

const(char)[] toLevelName(int level) {
    alias StringData = char[64][4];
    static StringData stringData = void;

    auto name = stringData[0][0 .. 8];
    name[0 .. 6] = "level_";
    name[6] = cast(char) ('0' + (level / 10) % 10);
    name[7] = cast(char) ('0' + level % 10);
    return name;
}
```

Both `name1` and `name2` should have different values, yet they are the same because of the mentioned issue.
To avoid this, a new static variable needs to be created that changes the current string used by the `toLevelName` function:

```d
import std.stdio;

void main() {
    auto name1 = 1.toLevelName();
    auto name2 = 2.toLevelName();
    writeln(name1); // Output: level_01
    writeln(name2); // Output: level_02
}

const(char)[] toLevelName(int level) {
    alias StringData = char[64][4];
    static StringData stringData = void;
    static ubyte stringDataIndex = 0; // <-- Fix 1.

    stringDataIndex = (stringDataIndex + 1) % stringData.length; // <-- Fix 2.
    auto name = stringData[stringDataIndex][0 .. 8]; // <-- Fix 3.
    name[0 .. 6] = "level_";
    name[6] = cast(char) ('0' + (level / 10) % 10);
    name[7] = cast(char) ('0' + level % 10);
    return name;
}
```

This works because `stringDataIndex` cycles through the 4 available strings in order, wrapping back to the beginning once it reaches the end.
This is called a [circular buffer](https://en.wikipedia.org/wiki/Circular_buffer), and it is a common pattern for managing a fixed pool of temporary data without dynamic allocation.

Static buffers work well for short-lived data with a known maximum size, but they force the function to manage its own memory.
What if you don't want that?

## Passing Memory

One solution is to pass the memory to it instead:

```d
import std.stdio;

void main() {
    char[256] buffer = void;
    auto name1 = 1.toLevelName(buffer[0 .. 16]);
    auto name2 = 2.toLevelName(buffer[16 .. 32]);
    writeln(name1); // Output: level_01
    writeln(name2); // Output: level_02
}

const(char)[] toLevelName(int level, char[] data) {
    auto name = data[0 .. 8];
    name[0 .. 6] = "level_";
    name[6] = cast(char) ('0' + (level / 10) % 10);
    name[7] = cast(char) ('0' + level % 10);
    return name;
}
```

The buffer here is a stack allocation in `main`, but it could come from anywhere.
It could be memory from `malloc` or even the GC.

This example works, but manually tracking which slice of the buffer is free like the code above quickly becomes tedious.
That's the job of an allocator.

## Allocators

At this point we are manually tracking regions in a buffer.
Allocators exist to automate exactly that.
For this code, it makes sense to make an [arena/bump allocator](https://en.wikipedia.org/wiki/Region-based_memory_management).
An arena allocator works by keeping a pointer into a buffer and bumping it forward with each allocation.
When the buffer is full, it returns null.

The arena will look like this:

```d
struct Arena {
    char[] buffer;
    size_t offset;

    char[] makeChars(size_t size) {
        if (offset + size > buffer.length) return null;
        auto result = buffer[offset .. offset + size];
        offset += size;
        return result;
    }
}
```

Then update `toLevelName` to use it:

```d
const(char)[] toLevelName(int level, ref Arena arena) {
    auto name = arena.makeChars(8);
    if (name.length == 0) return null;
    name[0 .. 6] = "level_";
    name[6] = cast(char) ('0' + (level / 10) % 10);
    name[7] = cast(char) ('0' + level % 10);
    return name;
}
```

And finally update `main`:

```d
void main() {
    char[256] buffer = void;
    auto arena = Arena(buffer);
    auto name1 = 1.toLevelName(arena);
    auto name2 = 2.toLevelName(arena);
    writeln(name1); // Output: level_01
    writeln(name2); // Output: level_02
}
```

The arena owns the buffer and handles the slicing.
To free all the memory at once, just reset the offset back to zero.

## Abstracting Allocators

Like every solution before, passing allocators around has also an issue: they color functions, meaning a specific allocator must be passed to every function that needs it.
A way to somewhat avoid this is by abstracting allocators behind one or more function pointers.
That mechanism is referred to as an allocator API.
It is slower than using them directly, but avoids specialization.
Whether that tradeoff makes sense depends on the situation.

If you need one, below is the allocator API of [Joka](https://github.com/Kapendev/joka) that can be easily copy-pasted into a project:

```d
struct MemoryContext {
    void* allocatorState;
    AllocatorReallocFunc reallocFunc;

    void* malloc(size_t alignment, size_t size, const(char)[] file, size_t line) {
        return reallocFunc(allocatorState, alignment, null, 0, size, file, line);
    }

    void* realloc(size_t alignment, void* oldPtr, size_t oldSize, size_t newSize, const(char)[] file, size_t line) {
        return reallocFunc(allocatorState, alignment, oldPtr, oldSize, newSize, file, line);
    }

    void free(size_t alignment, void* oldPtr, size_t oldSize, const(char)[] file, size_t line) {
        reallocFunc(allocatorState, alignment, oldPtr, oldSize, 0, file, line);
    }
}

alias AllocatorReallocFunc = void* function(void* allocatorState, size_t alignment, void* oldPtr, size_t oldSize, size_t newSize, const(char)[] file, size_t line);
```

## What About The GC?

Now that we covered the basics, let's focus on a common question: how do I know that the GC is not being used without `@nogc`?
There are some things to be aware of.

The first is array literals.
They allocate when assigned to slices because the slice by itself can't store the data:

```d
// Allocates.
int[] a = [1, 2, 3];

// Does not allocate.
int[3] b = [1, 2, 3];
```

The second is delegates that capture variables from an outer scope.
They allocate because the captured variables need to outlive the current stack frame:

```d
// Allocates.
auto offset = 10;
auto a = (int x) => x + offset;

// Does not allocate.
auto b = (int x) => x + 10;
auto c = function(int x) => x + 10;
```

The third is the `~` operator.
It allocates sometimes because it needs to create a new array at runtime:

```d
// Allocates.
import std.conv;
auto a = "level_" ~ to!string(9);

// Does not allocate.
enum b = "level_" ~ to!string(9);
```

One way to detect implicit allocations like the ones mentioned above is by using the `-vgc` flag:

```sh
dmd -vgc app.d
# Or: ldc2 --vgc app.d
# Or: gdc -ftransition=nogc app.d
```

Example output:

```console
[alex/Documents/code] dmd -vgc app.d 
app.d(31): vgc: array literal may cause a GC allocation
app.d(33): vgc: operator `~` may cause a GC allocation
app.d(28): vgc: using closure causes GC allocation
```

For functions in precompiled code not covered by `-vgc`, it's usually easy to tell by reading the code.
Take `writeln` as an example: it might allocate if you pass a number (it doesn't, just assume), but it will not if you pass a string, since there is nothing to convert to a string.

`writeln` is also a great example of why you should not mark everything as `@nogc`. Its job is simply to print text. It shouldn't care whether the `toString` method of a type allocates with the GC or not.
That is a decision the caller has to make, and for templated functions the compiler can infer `@nogc` (can't with `writeln` because of [exceptions](https://dlang.org/library/std/stdio/writeln.html)).

Because `@nogc` is part of a function, it becomes an API contract the moment a function accepts a user-provided callback.
That is a strong constraint, so it should preferably appear where it genuinely makes sense: at API boundaries, or for self-contained functions like `makeChars` and `toLevelName` that never touch the GC.
A question to ask before using `@nogc` is whether this guarantee needs to be enforced by the compiler, or whether a comment could do a similar job.

A couple of additional notes worth mentioning:

Note 1: Debugging `@nogc` functions can be tricky since `writeln` is not allowed. A simple workaround is using [debug statements](https://dlang.org/spec/version.html#DebugStatement):

```d
void debugWriteln(A...)(A args) {
    import std.stdio;
    debug writeln(args);
}

@nogc
void myFunction() {
    debugWriteln("Something only for debugging.");
}
```

Note 2: The `-profile=gc` flag can be used to create a `profilegc.log` file.
I never needed it personally, but from what I understand it tracks what allocated at runtime rather than what could allocate.

## Conclusion

Manual memory management in D does not require `@nogc` or `-betterC`.
As shown above, you can do a lot with just the stack, static buffers, and a simple arena allocator.

A basic table of what and when to use from the discussed topics:

| Situation                         | Use           |
| :-------------------------------- | :------------ |
| Temporary & self-contained        | Stack         |
| Needs to outlive function         | Static buffer |
| Multiple callers & self-contained | Passed memory |
| Many allocations or bulk free     | Arena         |

One last thing worth exploring is using MMM libraries like [NuMem](https://github.com/Inochi2D/numem), [Joka](https://github.com/Kapendev/joka), or [core.stdc.stdlib](https://dlang.org/library/core/stdc/stdlib.html). NuMem is used in some D libraries, while Joka is a personal project of mine.
