# ⚡ Batteries for Lua

> Helpful stuff for making games with lua, especially with [löve](https://love2d.org).

Get your projects off the ground faster! `batteries` provides implementations of many common algorithms and data structures useful for games.

# Getting Started

## How does `that module` work?

Examples are [in another repo](https://github.com/1bardesign/batteries-examples).

## Installation

`batteries` works straight out of the repo with no separate build step. The license file required for use is included.

- Put the files in their own directory (e.g `lib/batteries`), somewhere your project can access them.
- `require` the base `batteries` directory - the one with `init.lua` in it.
- With a normal `require` setup (ie stock LÖVE or lua), `init.lua` will pull in all the submodules.

```lua
local batteries = require("lib.batteries")
```

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
- [`make_pooled`](./make_pooled.lua) - add pooling/recycling capability to a class

# License

- [original license](batteries.LICENSE)
- [this fork's license](wired_batteries.LICENSE) (only applies to the files prefixed with the matching MIT LICENSE text, e.g [logger.lua](./logger.lua)). Any file not prefixed with the specified text is under the original [zlib license](./batteries.LICENSE)
