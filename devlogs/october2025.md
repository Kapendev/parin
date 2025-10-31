# Parin Game Engine Devlog – October 2025

*Welcome to the October 2025 devlog for [Parin](https://github.com/Kapendev/parin).*

## 🫐 Backend Support

A lot of time this month went into adding support for multiple backends. By "backend," I mean the ability to swap the current platform layer, **raylib**, for a different one. This required some breaking changes to make everything work correctly and pushed Parin toward a more abstract design.

In practice, this means that every engine resource (`Texture`, `Font`, `Sound`, `Viewport`) is now only represented by an ID and the backend is responsible for what is will do with that ID. For example, `Viewport` as a structure no longer exists and you have to use something called a `ViewportId`. As with every ID before this change, you'll need to use one of the `load*` functions to obtain a new ID. A nice side effect of this system is that engine resources are safer to use (no state bugs, etc.) and the Parin API is simpler since there's only one way to do things.

The main benefit of this change is that Parin will be able to use something like [SDL](https://www.libsdl.org/), [PixelPerfectEngine](https://github.com/ZILtoid1991/pixelperfectengine),  or even [Godot](https://godotengine.org/) as a platform layer in the future. In the case of Godot, it would take a lot of work because of how Godot works, but it's definitely possible. The Godot backend is on my "for fun" TODO list.

## 🍵 Deprecation Removal & Changes

Because of the changes mentioned above, I figured it was a good time to remove all the deprecated names and functions that had built up over time for backward compatibility. For example, the alias `format` for the `fmt` function no longer exists.

Loading functions also changed a bit. They now support absolute paths and always return a value directly, instead of sometimes wrapping it in an option/maybe type. If an error occurred while loading, then a "null" value is returned. To get more information about what kind of error happened, you can use the `lastLoadOrSaveFault` function. This is similar to how Godot handles errors and over time I have come to think it's a perfectly fine way of doing things, at least for game code.

The next big deprecation removal will come with version **0.2.0**.

## 📦 No External Dependencies

After thinking about this for a long long long time, I decided it was finally the right moment to vendor every dependency Parin had. This means Parin can now be built simply by cloning the repository. No dependency management through DUB or Git is needed.

> But why? Don't you like package managers?

It is not about liking or disliking package managers. I just prefer simple things. Being able to download Parin and use it right away feels great. Building is simpler, [grepping](https://en.wikipedia.org/wiki/Grep) is simpler, [grokking](https://grok.com/) is simpler, ... This change just makes everything nicer overall, for both DUB and no DUB users.

Don't worry, I'm not about to go on a "unstructured" package-manager rant like [gingerBill](https://www.gingerbill.org/article/2025/09/08/package-managers-are-evil/) or [monkeyyyy](https://forum.dlang.org/post/dycuopbvjjqiwkzadnyd@forum.dlang.org).

![ME IRL](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/to5pbqa2lu8q7xplhimg.png)

## 🧭 Documentation

I went over some code in `math.d`, `ascii.d`, and `engine.d`, and refactored parts of them. Functions should now follow a more logical order in most places and a lot of code that previously lacked documentation comments now has them. Overall, this should make things much easier to understand.

The [Parin cheatsheet](https://github.com/Kapendev/parin/blob/main/CHEATSHEET.md) also got an update. Its structure changed and now includes the first line of each function's documentation comment, making it easier to rely on it for quick information on how to do things.

## 🌤️ What's Next

Well, no idea. Parin is in a good state right now. Mostly bug-free and provides a nice experience for the types of games I want to make. The thing I'll probably focus on next is Parin UI, the WebAssembly scripts, and maybe shaders. The next Parin devlog will likely take a bit longer to release.

That's mostly it. If you try Parin out, let me know what you think in the [GitHub discussions](https://github.com/Kapendev/parin/discussions).
