# ⚡ Batteries for Lua

> Core dependencies for making games with lua, especially with [LÖVE](https://love2d.org).

Get projects off the ground faster! `batteries` fills out lua's sparse standard library a little, and provides implementations of common algorithms and data structures useful for games.

It's a bit of a mixture of functionality, but quite extensively documented in-line, and currently still under a hundred kb uncompressed - including the license and this readme - so you get quite a lot per byte! Of course, feel free to trim it down for your use case as required (see [below](#stripping-down-batteries)).

Examples [in another repo](https://github.com/1bardesign/batteries-examples) to avoid cluttering the repo history and your project/filesystem when used as a submodule.

# Installation

`batteries` works straight out of the repo with no separate build step. The license file required for use is included.

- Put the files in their own directory, somewhere your project can access them.
- `require` the base `batteries` directory - the one with `init.lua` in it.
	- Don't forget to use dot syntax on the path!
	- With a normal `require` setup (ie stock LÖVE or lua), `init.lua` will pull in all the submodules.
- Optionally `export` everything to the global environment.

```lua
--everything as globals
require("path.to.batteries"):export()

-- OR --

--self-contained
local batteries = require("path.to.batteries")
```

See [below](#export-globals) for a discussion of the pros and cons of `export`.

## Git Submodule or Static Install

`batteries` is fairly easily used as a git submodule - this is how I use it in my own projects, because updating is just a `git pull`.

A static install is harder to update, but easier to trim down if you only need some of the functionality provided. It can also _never_ mysteriously break when updating, which might be appealing to those who just cant help themselves from using the latest and greatest.

# Versioning?

Currently, the library is operated in a rolling-release manner - the head of the master branch is intended for public consumption. While this is kept as stable as practical, breaking API changes _do_ happen, and more are planned!

For this reason, you should try to check the commit history for what has changed rather than blindly updating. If you let me know that you're using it actively, I'm generally happy to let you know when something breaking is on its way to `master` as well.

If there is a large enough user base in the future to make a versioning scheme + non-repo changelog make sense, I will accomodate.

# Module Overview

**Lua Core Extensions:**

Extensions to existing lua core modules to patch up some missing features.

- `mathx` - Mathematical extensions. Alias `math`.
- `tablex` - Table handling extensions. Alias `table`.
- `stringx` - String handling extensions. Alias `string`.

**General Utility:**

General utility data structures and algorithms to speed you along your way.

- `class` - Single-inheritance oo in a single function.
- `functional` - Functional programming facilities. `map`, `reduce`, `any`, `match`, `minmax`, `mean`...
- `sequence` - An oo wrapper on sequential tables, so you can do `t:insert(i, v)` instead of `table.insert(t, i, v)`. Also supports method chaining for the `functional` interface above, which can save a lot of needless typing!
- `set` - A set type supporting a full suite of set operations with fast membership testing and `ipairs`-style iteration.
- `sort` - Provides a stable merge+insertion sorting algorithm that is also, as a bonus, often faster than `table.sort` under luajit. Also exposes `insertion_sort` if needed. Alias `stable_sort`.
- `state_machine` - Finite state machine implementation with state transitions and all the rest. Useful for game states, AI, cutscenes...
- `timer` - a "countdown" style timer with progress and completion callbacks.
- `pubsub` - a self-contained publish/subscribe message bus. Immediate mode rather than queued, local rather than networked, but if you were expecting mqtt in 60 lines I don't know what to tell you. Scales pretty well nonetheless.
- `pretty` - pretty printing tables for debug inspection

**Geometry:**

Modules to help work with spatial concepts.

- `intersect` - 2d intersection routines, a bit sparse at the moment.
- `vec2` - 2d vectors with method chaining, and garbage saving modifying operations. A bit of a mouthful at times, but you get used to it. (there's an issue discussing future solutions).
- `vec3` - 3d vectors as above.

**Special Interest:**

These modules are probably only useful to some folks in some circumstances, or are under-polished for one reason or another.

- `async` - Asynchronous/"Background" task management.
- `colour` - Colour conversion routines. Alias `color`.
- `manual_gc` - Get GC out of your update/draw calls. Useful when trying to get accurate profiling information; moves "randomness" of GC. Requires you to think a bit about your garbage budgets though.
- `unique_mapping` - Generate a unique mapping from arbitrary lua values to numeric keys - essentially making up a consistent ordering for unordered data. Niche, but can be used to optimise draw batches for example, as you can't sort on textures without it.

Aliases are provided at both the `batteries` level and globally when exported.

# Todo/WIP list

Endless, of course :)

- `stringx` - Needs extension, very minimal currently.
- `colour` - Bidirectional hsv/hsl/etc conversion would fit nicely here.
- Geometry:
	- `vec3` - Needs more fleshing out for serious use.
	- `matrix` - A geometry focussed matrix module would made 3d work a lot nicer. Possibly just `mat4`.
	- `intersect` - More routines, more optimisation :)
- Network:
	- Various helpers for networked systems, game focus of course.
	- `rpc` - Remote procedure call system on top of `enet` or `socket`.
	- `delta` - Detect and sync changes to objects.
- Broadphase:
	- Spatial simplification systems for different needs. Probably AABB or point insertion of data.
	- `bucket_grid` - Dumb 2d bucket broadphase.
	- `sweep_and_prune` - Popular for bullet hell games.
	- `quadtree`/`octree` - Everyone's favourite ;)
- UI
	- Maybe adopt 1bardesign/partner in here, or something evolved from it.

# PRs

Pull requests are welcome for anything - positive changes will be merged optimistically, and I'm happy to work with you to get anything sensible ready for inclusion.

If you have something "big" to contribute _please_ do get in touch before starting work so we can make sure it fits, but I'm quite open minded!

# Export Globals

You are strongly encouraged to use the library in a "fire and forget" manner through `require("batteries"):export()` (or whatever appropriate module path), which will modify builtin lua modules (such as `table` and `math`) and expose all the other modules directly as globals for convenience.

This eases consumption later on - you don't have to remember if say, `table.remove_value` is built in to lua or not, or get used to accessing the builtin table functions through `batteries.table` or `tablex`.

While this will likely sit badly with anyone who's had "no globals!" hammered into them, I believe for `batteries` (and many foundational libraries) it makes sense to just import once at boot. You're going to be pulling it in almost everywhere anyway; why bother making yourself jump through more hoops?

You can of course use the separate modules on their own, either with a single require for all of `batteries`, with use through something like `batteries.functional.map`; or requiring individual modules explicitly. This more careful approach _will_ let you be more clear about your dependencies, at the cost of more setup work needing to re-require batteries everywhere, or expose it as a global in the first place.

I'd strongly recommend that if you find yourself frustrated with the above, stop and think why/if you really want to avoid globals for a library intended to be commonly used across your entire codebase! You may wish to reconsider, and save yourself typing `batteries` a few hundred times :)

# Stripping down `batteries`

Many of the modules "just work" on their own if you just want to grab something specific.

There are some inter-dependencies in the more complex modules, which should be straightforward to detect and figure out the best course of action (include or strip out) if you want to make a stripped-down version for distribution.

Currently the lib is 30kb or so compressed, including this readme, so do think carefully whether you really need to worry!

# License

MIT, see [here](license.txt)
