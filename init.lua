--[[
	batteries for lua

	a collection of helpful code to get your project off the ground faster
]]

local path = ...
local function require_relative(p)
	return require(table.concat({path, p}, "."))
end

--build the module
local _batteries = {
	--
	class = require_relative("class"),
	--
	assert = require_relative("assert"),
	--extension libraries
	mathx = require_relative("mathx"),
	tablex = require_relative("tablex"),
	stringx = require_relative("stringx"),
	--sorting routines
	sort = require_relative("sort"),
	--
	functional = require_relative("functional"),
	--collections
	sequence = require_relative("sequence"),
	set = require_relative("set"),
	--geom
	vec2 = require_relative("vec2"),
	vec3 = require_relative("vec3"),
	intersect = require_relative("intersect"),
	--
	timer = require_relative("timer"),
	pubsub = require_relative("pubsub"),
	unique_mapping = require_relative("unique_mapping"),
	state_machine = require_relative("state_machine"),
	async = require_relative("async"),
	manual_gc = require_relative("manual_gc"),
	colour = require_relative("colour"),
}

--assign aliases
for _, alias in ipairs({
	{"mathx", "math"},
	{"tablex", "table"},
	{"stringx", "string"},
	{"sort", "stable_sort"},
	{"colour", "color"},
}) do
	_batteries[alias[2]] = _batteries[alias[1]]
end

--easy export globally if required
function _batteries:export()
	--export all key strings globally, if doesn't always exist
	for k, v in pairs(self) do
		if not _G[k] then
			_G[k] = v
		end
	end

	--overlay tablex and functional and sort routines onto table
	self.tablex.overlay(table, self.tablex)
	--now we can use it through table directly
	table.overlay(table, self.functional)
	self.sort:export()

	--overlay onto global math table
	table.overlay(math, self.mathx)

	--overlay onto string
	table.overlay(string, self.stringx)

	--overwrite assert wholesale (it's compatible)
	assert = self.assert

	--export the whole library to global `batteries`
	batteries = self

	return self
end

return _batteries
