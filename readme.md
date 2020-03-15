# batteries

Core dependencies for making games with lua, especially with [love](https://love2d.org).

Does a lot to get projects off the ground faster, filling out lua's standard library and providing implementations of common algorithms and data structures useful for games.

# Module Overview

- `class` - single-inheritance oo in a single function
- `math` - mathematical extensions
- `table` - table handling extensions
- `stable_sort` - a stable sorting algorithm that is also faster than table.sort under luajit
- `functional` - functional programming facilities. `map`, `reduce`, `any`, `match`, `minmax`, `mean`...
- `sequence` - an oo wrapper on sequential tables so you can do `t:insert(i, v)` instead of `table.insert(t, i, v)`. Also supports the functional interfance.
- `vec2` - 2d vectors with method chaining, garbage saving interface
- `vec3` - 3d vectors as above
- `intersect` - 2d intersection routines, a bit sparse at the moment
- `unique_mapping` - generate a unique mapping from arbitrary lua values to numeric keys - essentially making up a consistent ordering for unordered data. niche, but useful for optimising draw batches for example, as you can't sort on textures without it.
- `state_machine` - finite state machine implementation with state transitions and all the rest. useful for game states, ai, cutscenes...
- `async` - async operations as coroutines. 
- `manual_gc` - get gc out of your update/draw calls. really good when trying to get accurate profiling information. requires you to think a bit about your garbage budgets though.
- `colour` - colour conversion routines. can also be spelled `color` if you're into that.

# PRs

Pull requests are welcome. If you have something "big" to add please get in touch before starting work, but I'm quite open minded!

# Globals?

By default `batteries` will modify builtin lua tables (such as `table` and `math`) as it sees fit, as this eases consumption later on - you don't have to remember if say, `table.remove_value` is built in to lua or not. As the intended use case is fairly pervasive, required early, and "fire and forget", this sits with me just fine.

If however, you'd prefer to require things locally, you can (rather ironically) set a few globals at boot time as documented in each module to change this behaviour, or set `BATTERIES_NO_GLOBALS = true` to make none of them modify anything global. If you really want to you can undefine the behaviour-changing globals after the module is required, as the results are cached.

I'd strongly recommend that if you find yourself defining the above, stop and think why/if you really want to avoid globals for a library intended to be commonly used across your entire codebase!

Some folks will have good reasons, which is why the functionality is present!

Others may wish to reconsider and save themselves typing batteries a few hundred times :)
