local path = ...
local function require_relative(p)
	return require(table.concat({ path, p }, "."))
end

---@class Batteries
---@field class Class
---@field assert Assert
---@field mathx MathX
---@field tablex TableX
---@field stringx StringX
---@field sort Sort
---@field functional Functional
---@field sequence Sequence
---@field set Set
---@field vec2 Vec2
---@field vec3 Vec3
---@field intersect Intersect
---@field timer Timer
---@field pubsub PubSub
---@field state_machine StateMachine
---@field async Async
---@field manual_gc fun(time_budget: number, memory_ceiling: number, disable_otherwise: boolean)
---@field colour Colour
---@field pretty Pretty
---@field measure Measure
---@field make_pooled fun(class: Class, limit: number): Class
---@field pathfind fun(args: PathFindArgs): boolean|table
---@field identifier Identifier
---@field logger Logger

---A collection of helpful code to get your project off the ground faster
local _batteries = {
	class = require_relative("class"),
	assert = require_relative("assert"),
	mathx = require_relative("mathx"),
	tablex = require_relative("tablex"),
	stringx = require_relative("stringx"),
	sort = require_relative("sort"),
	functional = require_relative("functional"),
	sequence = require_relative("sequence"),
	set = require_relative("set"),
	vec2 = require_relative("vec2"),
	vec3 = require_relative("vec3"),
	intersect = require_relative("intersect"),
	timer = require_relative("timer"),
	pubsub = require_relative("pubsub"),
	state_machine = require_relative("state_machine"),
	async = require_relative("async"),
	manual_gc = require_relative("manual_gc"),
	colour = require_relative("colour"),
	pretty = require_relative("pretty"),
	measure = require_relative("measure"),
	make_pooled = require_relative("make_pooled"),
	pathfind = require_relative("pathfind"),
	identifier = require_relative("identifier"),
	logger = require_relative("logger")
}

return _batteries --[[@as Batteries]]
