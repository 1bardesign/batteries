# ⚡ Batteries for Lua

> Helpful stuff for making games with lua, especially with [löve](https://love2d.org).

Get your projects off the ground faster! `batteries` fills out lua's sparse standard library, and provides implementations of many common algorithms and data structures useful for games.

General purpose and special case, extensively documented in-line, and around a hundred kilobytes uncompressed - including the license and this readme - so you get quite a lot per byte! Of course, feel free to trim it down for your use case as required (see [below](#stripping-down-batteries)).

# Getting Started

## How does `that module` work?

Examples are [in another repo](https://github.com/1bardesign/batteries-examples) to avoid cluttering the repo history and your project/filesystem when used as a submodule.

They have short, straightforward usage examples of much of the provided functionality.

Documentation is provided as comments alongside the code, because that is the most resilient place for it. Even auto-generated docs often end up out of date and the annotations bloat the code.

Use find-in-all from your editor, or just browse through the code. The [module overview](#module-overview) below is the only non-code documentation - it is a jumping off point, not a reference.

## Installation

`batteries` works straight out of the repo with no separate build step. The license file required for use is included.

- Put the files in their own directory, somewhere your project can access them.
- `require` the base `batteries` directory - the one with `init.lua` in it.
	- Don't forget to use dot syntax on the path!
	- With a normal `require` setup (ie stock LÖVE or lua), `init.lua` will pull in all the submodules.
	- Batteries uses the (very common) init.lua convention. If your installation doesn't already have init.lua support (eg plain 5.1 on windows), add `package.path = package.path .. ";./?/init.lua"` before the require line. You can also modify your `LUA_PATH` environment variable.
- (optionally) `export` everything to the global environment.

```lua
--everything as globals
require("path.to.batteries"):export()

-- OR --

--self-contained
local batteries = require("path.to.batteries")
```

See [below](#export-globals) for a discussion of the pros and cons of `export`.

# Library Culture and Contributing

`batteries` aims to be approachable to almost everyone, but I _do_ expect you to get your hands dirty. I'm very open to collaboration, and happy to talk through issues or shortcomings in good faith.

Pull requests are welcome for anything - positive changes will be merged optimistically, and I'm happy to work with you to get anything sensible ready for inclusion.

If you have something "big" to contribute _please_ get in touch before starting work so we can make sure it fits. I'm quite open minded!

If you've had a good look for the answer but something remains unclear, raise an issue and I'll address it. If you _haven't_ had a good look for the answer, checking the source _always_ helps!

If you'd prefer to talk with me about `batteries` in real time, I'm often available on the love2d discord.

# Module Overview

**Lua Core Extensions:**

Extensions to existing lua core modules to provide missing features.

- [`mathx`](./mathx.lua) - Mathematical extensions. Alias `math`.
- [`tablex`](./tablex.lua) - Table handling extensions. Alias `table`.
- [`stringx`](./stringx.lua) - String handling extensions. Alias `string`.

**General Utility:**

General utility data structures and algorithms to speed you along your way.

- [`class`](./class.lua) - OOP with inheritance and interfaces in a single function.
- [`functional`](./functional.lua) - Functional programming facilities. `map`, `reduce`, `any`, `match`, `minmax`, `mean`...
- [`sequence`](./sequence.lua) - An oo wrapper on sequential tables, so you can do `t:insert(i, v)` instead of `table.insert(t, i, v)`. Also supports method chaining for the `functional` interface above, which can save a lot of needless typing!
- [`set`](./set.lua) - A set type supporting a full suite of set operations with fast membership testing and `ipairs`-style iteration.
- [`sort`](./sort.lua) - Provides a stable merge+insertion sorting algorithm that is also, as a bonus, often faster than `table.sort` under luajit. Also exposes `insertion_sort` if needed. Alias `stable_sort`.
- [`state_machine`](./state_machine.lua) - Finite state machine implementation with state transitions and all the rest. Useful for game states, AI, cutscenes...
- [`timer`](./timer.lua) - a "countdown" style timer with progress and completion callbacks.
- [`pubsub`](./pubsub.lua) - a self-contained publish/subscribe message bus. Immediate mode rather than queued, local rather than networked, but if you were expecting mqtt in 60 lines I don't know what to tell you. Scales pretty well nonetheless.
- [`pretty`](./pretty.lua) - pretty printing tables for debug inspection.

**Geometry:**

Modules to help work with spatial concepts.

- [`intersect`](./intersect.lua) - 2d intersection routines, a bit sparse at the moment.
- [`vec2`](./vec2.lua) - 2d vectors with method chaining, and garbage saving modifying operations. A bit of a mouthful at times, but you get used to it. (there's an issue discussing future solutions).
- [`vec3`](./vec3.lua) - 3d vectors as above.

**Special Interest:**

These modules are probably only useful to some folks in some circumstances, or are under-polished for one reason or another.

- [`async`](./async.lua) - Asynchronous/"Background" task management.
- [`colour`](./colour.lua) - Colour conversion routines. Alias `color`.
- [`manual_gc`](./manual_gc.lua) - Get GC out of your update/draw calls. Useful when trying to get accurate profiling information; moves "randomness" of GC. Requires you to think a bit about your garbage budgets though.
- [`measure`](./measure.lua) - Benchmarking helpers - measure the time or memory taken to run some code.
- [`unique_mapping`](./unique_mapping.lua) - Generate a unique mapping from arbitrary lua values to numeric keys - essentially making up a consistent ordering for unordered data. Niche, but can be used to optimise draw batches for example, as you can't sort on textures without it.
- [`make_pooled`](./make_pooled.lua) - add pooling/recycling capability to a class

Any aliases are provided at both the `batteries` module level, and globally when exported.

# Work in Progress, or TODO

Endless, of course :)

- `colour` - Bidirectional hsv/hsl/etc conversion would fit nicely here.
- Geometry:
	- `vec3` - Needs more fleshing out for serious use, and a refactor to fit the same naming patterns as `vec2`.
	- `matrix` - A geometry focussed matrix module would made 3d work a lot nicer. Possibly just `mat4`.
	- `intersect` - More routines, more optimisation :)
- Network:
	- Various helpers for networked systems, game focus of course.
	- `rpc` - Remote procedure call system on top of `enet` or `socket` or both.
	- `delta` - Detect and sync changes to objects.
- Broadphase:
	- Spatial simplification systems for different needs. Probably AABB or point insertion of data.
	- `bucket_grid` - Dumb 2d bucket broadphase.
	- `sweep_and_prune` - Popular for bullet hell games.
	- `quadtree`/`octree` - Everyone's favourite ;)
- UI
	- Maybe adopt [partner](https://github.com/1bardesign/partner) in here, or something evolved from it.
- Image
	- Maybe adopt [chromatic](https://github.com/1bardesign/chromatic) in here, or something evolved from it.

# FAQ

## Export Globals

You are strongly encouraged to use the library in a "fire and forget" manner through `require("batteries"):export()` (or whatever appropriate module path), which will modify builtin lua modules (such as `table` and `math`), and expose all the other modules directly as globals for your convenience.

This eases consumption across your project - you don't have to require modules everywhere, or remember if say, `table.remove_value` is built in to lua or not, or get used to accessing the builtin table functions through `batteries.table` or `tablex`.

While this will likely sit badly with anyone who's had "no globals! ever!" hammered into them, I believe that for `batteries` (and many foundational libraries) it makes sense to just import once at boot. You're going to be pulling it in almost everywhere anyway; why bother making yourself jump through more hoops?

You can, of course, use the separate modules on their own, either requiring individual modules explicitly, or a single require for all of `batteries` and use through something like `batteries.functional.map`. This more involved approach _will_ let you be more clear about your dependencies, if you care deeply about that - at the cost of more setup work needing to re-require batteries everywhere you use it, or expose it as a global in the first place.

I'd strongly recommend that if you find yourself frustrated with the above, stop and think why/if you really want to avoid globals for something intended to be commonly used across your entire codebase! Are you explicitly `require`ing `math` and `table` everywhere you use it too? Are you just as ideologically opposed to `require` being a global?

You may wish to reconsider, and save yourself typing `batteries` a few hundred times :)

## Git Submodule or Static Install?

`batteries` is fairly easily used as a git submodule - this is how I use it in my own projects, because updating is as quick and easy as a `git pull`, and it's easy to roll back changes if needed, and to contribute changes back upstream.

A static install is harder to update, but easier to trim down if you only need some of the functionality provided. It can also _never_ mysteriously break when updating, which might be appealing to those who just cant stop themselves using the latest and greatest.

## Stripping down `batteries`

Many of the modules "just work" on their own, if you just want to grab something specific.

Some of them depend on `class`, which can be included alongside pretty easily.

There are some other inter-dependencies in the larger modules, which should be straightforward to detect and figure out the best course of action (either include the dependency or strip out dependent functionality), if you want to make a stripped-down version for your specific use case.

Currently (july 2021) the lib is 40kb or so compressed, including this readme, so do think carefully whether you really need to worry about it!

## Versioning?

Currently, the library is operated in a rolling-release manner - the head of the master branch is intended for public consumption. While this is kept as stable as practical, breaking API changes _do_ happen, and more are planned!

For this reason, you should try to check the commit history for what has changed rather than blindly updating. If you let me know that you're using it actively, I'm generally happy to let you know when something breaking is on its way to `master` as well.

If there is a large enough user base in the future to make a versioning scheme + non-repo changelog make sense, I will accomodate.

## snake_case? Why?

I personally prefer it, but I accept that it's a matter of taste and puts some people off.

I've implemented experimental automatic API conversion (UpperCamelCase for types, lowerCamelCase for methods) that you can opt in to by calling `:camelCase()` before `:export()`, let me know if you use it and encounter any issues.

# License

zlib, see [here](license.txt)
