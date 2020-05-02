--[[
	batteries for lua

	a collection of helpful code to get your project off the ground faster
]]

local path = ...
local function require_relative(p)
	return require(table.concat({path, p}, "."))
end

local _class = require_relative("class")

local _mathx = require_relative("mathx")

local _tablex = require_relative("tablex")
local _stable_sort = require_relative("stable_sort")

local _functional = require_relative("functional")

local _sequence = require_relative("sequence")
local _set = require_relative("set")

local _stringx = require_relative("stringx")

local _vec2 = require_relative("vec2")
local _vec3 = require_relative("vec3")
local _intersect = require_relative("intersect")

local _unique_mapping = require_relative("unique_mapping")
local _state_machine = require_relative("state_machine")

local _async = require_relative("async")

local _manual_gc = require_relative("manual_gc")

local _colour = require_relative("colour")

--build the module
local _batteries = {
	--fire and forget mode function
	export = export,
	--
	class = _class,
	--support x and non-x naming
	math = _mathx,
	mathx = _mathx,
	--
	table = _tablex,
	tablex = _tablex,
	--
	string = _stringx,
	stringx = _stringx,
	--sorting routines
	stable_sort = _stable_sort,
	sort = _stable_sort,
	--
	functional = _functional,
	--collections
	sequence = _sequence,
	set = _set,
	--geom
	vec2 = _vec2,
	vec3 = _vec3,
	intersect = _intersect,
	--
	unique_mapping = _unique_mapping,
	state_machine = _state_machine,
	async = _async,
	manual_gc = _manual_gc,
	colour = _colour,
	color = _colour,
}

--easy export globally if required
function _batteries:export(self)
	--export oo
	class = _class

	--overlay tablex and functional and sort routines onto table
	_tablex.overlay(table, _tablex)
	_tablex.overlay(table, _functional)
	_stable_sort:export()
	
	--functional module also available separate from table
	functional = _functional

	--export collections
	sequence = _sequence
	set = _set

	--overlay onto math
	_tablex.overlay(math, _mathx)

	--overlay onto string
	_tablex.overlay(string, _stringx)

	--export geom
	vec2 = _vec2
	vec3 = _vec3
	intersect = _intersect

	--"misc" :)
	unique_mapping = _unique_mapping
	state_machine = _state_machine
	async = _async
	manual_gc = _manual_gc

	--support both spellings
	colour = _colour
	color = _colour

	--export top level module as well for ease of migration for code
	batteries = _batteries

	return self
end

return _batteries
