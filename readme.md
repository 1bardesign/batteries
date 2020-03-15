# ⚡ Batteries for Lua

Core dependencies for making games with lua, especially with [love](https://love2d.org).

Does a lot to get projects off the ground faster, filling out lua's standard library and providing implementations of common algorithms and data structures useful for games.

It's a bit of a grab bag of functionality, but quite extensively documented, and currently still under a hundred kb uncompressed, including the license and readme, so you get quite a lot per byte! Of course, feel free to trim it down for your use case as required. Many of the modules are "mostly" standalone.

# Module Overview

- `class` - Single-inheritance oo in a single function.
- `math` - Mathematical extensions.
- `table` - Table handling extensions.
- `stable_sort` - A stable sorting algorithm that is also, as a bonus, faster than table.sort under luajit.
- `functional` - Functional programming facilities. `map`, `reduce`, `any`, `match`, `minmax`, `mean`...
- `sequence` - An oo wrapper on sequential tables so you can do `t:insert(i, v)` instead of `table.insert(t, i, v)`. Also supports chaining the functional interface above.
- `vec2` - 2d vectors with method chaining, garbage saving interface. A bit of a mouthful at times.
- `vec3` - 3d vectors as above.
- `intersect` - 2d intersection routines, a bit sparse at the moment
- `unique_mapping` - Generate a unique mapping from arbitrary lua values to numeric keys - essentially making up a consistent ordering for unordered data. Niche, but useful for optimising draw batches for example, as you can't sort on textures without it.
- `state_machine` - Finite state machine implementation with state transitions and all the rest. Useful for game states, ai, cutscenes...
- `async` - Async operations as coroutines. 
- `manual_gc` - Get GC out of your update/draw calls. Really good when trying to get accurate profiling information; no more spikes. Requires you to think a bit about your garbage budgets though.
- `colour` - Colour conversion routines. Can also be spelled `color` if you're into that.

# PRs

Pull requests are welcome!

If you have something "big" to contribute please get in touch before starting work so we can make sure it fits, but I'm quite open minded!

# Globals?

By default `batteries` will modify builtin lua tables (such as `table` and `math`) as it sees fit, as this eases consumption later on - you don't have to remember if say, `table.remove_value` is built in to lua or not. As the intended use case is fairly pervasive, required early, and "fire and forget", this sits with me just fine.

If however, you'd prefer to require things locally, you can (rather ironically) set a few globals at boot time as documented in each module to change this behaviour, or set `BATTERIES_NO_GLOBALS = true` to make none of them modify anything global. If you really want to you can undefine the behaviour-changing globals after the module is required, as the results are cached.

I'd strongly recommend that if you find yourself defining the above, stop and think why/if you really want to avoid globals for a library intended to be commonly used across your entire codebase!

Some folks will have good reasons, which is why the functionality is present!

Others may wish to reconsider, and save themselves typing `batteries` a few hundred times :)

# Why aren't various types using `class`?

To avoid a dependency on class.lua for those modules

# License

MIT, see [here](license.txt)
