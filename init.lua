--[[
	batteries for lua

	if required as the "entire library" (ie by this file), puts everything into
	global namespace by default as it'll presumably be commonly used

	if not, several of the modules work as normal lua modules and return a table
	for local-friendly use

	the others that modify some global table can be talked into behaving as normal
	lua modules as well by setting appropriate globals prior to inclusion

	you can avoid modifying any global namespace by setting

		BATTERIES_NO_GLOBALS = true

	before requiring, then everything can be accessed as eg

		batteries.table.stable_sort
]]

local path = ...
local function require_relative(p)
	return require(table.concat({path, p}, "."))
end

if BATTERIES_NO_GLOBALS then
	--define local tables for everything to go into
	BATTERIES_MATH_MODULE = {}
	BATTERIES_TABLE_MODULE = {}
	BATTERIES_FUNCTIONAL_MODULE = {}
end

local _class = require_relative("class")

local _math = require_relative("math")

local _table = require_relative("table")
local _stable_sort = require_relative("stable_sort")

local _functional = require_relative("functional")
local _sequence = require_relative("sequence")

local _vec2 = require_relative("vec2")
local _vec3 = require_relative("vec3")
local _intersect = require_relative("intersect")

local _unique_mapping = require_relative("unique_mapping")
local _state_machine = require_relative("state_machine")

local _async = require_relative("async")

local _manual_gc = require_relative("manual_gc")

local _colour = require_relative("colour")

--export globally if required
if not BATTERIES_NO_GLOBALS then
	class = _class
	sequence = _sequence
	
	vec2 = _vec2
	vec3 = _vec3
	intersect = _intersect

	unique_mapping = _unique_mapping
	state_machine = _state_machine
	async = _async
	manual_gc = _manual_gc

	--support both spellings
	colour = _colour
	color = _colour
end

--either way, export to package registry
return {
	class = _class,
	math = _math,
	table = _table,
	stable_sort = _stable_sort,
	functional = _functional,
	sequence = _sequence,
	vec2 = _vec2,
	vec3 = _vec3,
	intersect = _intersect,
	unique_mapping = _unique_mapping,
	state_machine = _state_machine,
	async = _async,
	manual_gc = _manual_gc,
	colour = _colour,
	color = _colour,
}
