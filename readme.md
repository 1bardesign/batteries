# ⚡ Batteries for Lua

Core dependencies for making games with lua, especially with [love](https://love2d.org).

Does a lot to get projects off the ground faster, filling out lua's sparse standard library a little and providing implementations of common algorithms and data structures useful for games.

It's a bit of a grab bag of functionality, but quite extensively documented, and currently still under a hundred kb uncompressed, including the license and readme, so you get quite a lot per byte! Of course, feel free to trim it down for your use case as required (see [below](#stripping-down-batteries)).

Examples [in another repo](https://github.com/1bardesign/batteries-examples) to avoid cluttering the history and filesystem here.

# Module Overview

- `class` - Single-inheritance oo in a single function.
- `mathx` - Mathematical extensions. Alias `math`.
- `tablex` - Table handling extensions. Alias `table`.
- `stable_sort` - A stable sorting algorithm that is also, as a bonus, often faster than table.sort under luajit.
- `functional` - Functional programming facilities. `map`, `reduce`, `any`, `match`, `minmax`, `mean`...
- `sequence` - An oo wrapper on sequential tables, so you can do `t:insert(i, v)` instead of `table.insert(t, i, v)`. Also supports method chaining for the `functional` interface above, which can save a lot of typing!
- `vec2` - 2d vectors with method chaining, garbage saving interface. A bit of a mouthful at times, but you get used to it.
- `vec3` - 3d vectors as above.
- `intersect` - 2d intersection routines, a bit sparse at the moment
- `unique_mapping` - Generate a unique mapping from arbitrary lua values to numeric keys - essentially making up a consistent ordering for unordered data. Niche, but useful for optimising draw batches for example, as you can't sort on textures without it.
- `state_machine` - Finite state machine implementation with state transitions and all the rest. Useful for game states, ai, cutscenes...
- `async` - Async operations as coroutines. 
- `manual_gc` - Get GC out of your update/draw calls. Really good when trying to get accurate profiling information; no more spikes. Requires you to think a bit about your garbage budgets though.
- `colour` - Colour conversion routines. Alias `color`.

# Todo/WIP list

Endless, of course :)

- `stringx` - As for `tablex` and `mathx`, would be good to have a more filled out string handling API.
- `colour` - Bidirectional hsv conversion and friends would fit nicely here.
- Geometry:
	- `vec3` - Needs more fleshing out for serious use.
	- `matrix` - A geometry focussed matrix module would made 3d work nicer. Possibly just `mat4`.
	- `intersect` - More routines, more optimisation :)
- Network:
	- Various helpers for networked systems, game focus of course.
	- `rpc` - Remote procedure call system on top of `enet` or `socket`.
	- `delta` - Detect and sync changes to objects.
- Broadphase:
	- Spatial simplification systems for different needs. Probably AABB or point insertion of data.
	- `bucket_grid` - Dumb 2d bucket broadphase.
	- `quadtree`/`octree` - Everyone's favourite ;)
- UI
	- Maybe adopt 1bardesign/partner in here, maybe not?

# PRs

Pull requests are welcome for anything!

If you have something "big" to contribute please get in touch before starting work so we can make sure it fits, but I'm quite open minded!

# Export Globals

You are strongly encouraged to use the library in a "fire and forget" manner through `require("batteries"):export()` (or whatever appropriate module path), which will modify builtin lua modules (such as `table` and `math`) and expose all the modules directly as globals for convenience.

This eases consumption later on - you don't have to remember if say, `table.remove_value` is built in to lua or not, or get used to accessing the builtin table functions through `batteries.table` or `tablex`.

While this will likely sit badly with anyone who's had "no globals!" hammered into them, I believe for `batteries` (and many foundational libraries) it makes sense to just import once at boot. You're going to be pulling it in almost everywhere anyway; why bother making yourself jump through more hoops.

You can of course use the separate modules on their own, either with a single require for all of `batteries`, and use through something like `batteries.functional.map`, or requiring individual modules explicitly. This more careful approach _will_ let you be more clear about your dependencies, at the cost of more setup work needing to re-require batteries everywhere, or expose it as a global in the first place.

I'd strongly recommend that if you find yourself frustrated with the above, stop and think why/if you really want to avoid globals for a library intended to be commonly used across your entire codebase! You may wish to reconsider, and save yourself typing `batteries` a few hundred times :)

# Stripping down `batteries`

Many of the modules "just work" on their own if you just want to vendor in something specific.

There are some inter-dependencies in the more complex modules, which should be straightforward to detect and figure out the best course of action (include or strip out) if you want to make a stripped-down version for distribution.

Currently the lib is 30kb or so compressed, including the readme, so think carefully whether you really need to worry!

# License

MIT, see [here](license.txt)
