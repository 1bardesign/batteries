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
	state_machine = require_relative("state_machine"),
	async = require_relative("async"),
	manual_gc = require_relative("manual_gc"),
	colour = require_relative("colour"),
	pretty = require_relative("pretty"),
	measure = require_relative("measure"),
	make_pooled = require_relative("make_pooled"),
	pathfind = require_relative("pathfind"),
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
	--export all key strings globally, if doesn't already exist
	for k, v in pairs(self) do
		if _G[k] == nil then
			_G[k] = v
		end
	end

	--overlay tablex and functional and sort routines onto table
	self.tablex.shallow_overlay(table, self.tablex)
	--now we can use it through table directly
	table.shallow_overlay(table, self.functional)
	self.sort:export()

	--overlay onto global math table
	table.shallow_overlay(math, self.mathx)

	--overlay onto string
	table.shallow_overlay(string, self.stringx)

	--overwrite assert wholesale (it's compatible)
	assert = self.assert

	--like ipairs, but in reverse
	ripairs = self.tablex.ripairs

	--export the whole library to global `batteries`
	batteries = self

	return self
end


--convert naming, for picky eaters
--experimental, let me know how it goes
function _batteries:camelCase()
	--not part of stringx for now, because it's not necessarily utf8 safe
	local function capitalise(s)
		local head = s:sub(1,1)
		local tail = s:sub(2)
		return head:upper() .. tail
	end

	--any acronyms to fully capitalise to avoid "Rgb" and the like
	local acronyms = _batteries.set{"rgb", "rgba", "argb", "hsl", "xy", "gc", "aabb",}
	local function caps_acronym(s)
		if acronyms:has(s) then
			s = s:upper()
		end
		return s
	end

	--convert something_like_this to somethingLikeThis
	local function snake_to_camel(s)
		local chunks = _batteries.sequence(_batteries.stringx.split(s, "_"))
		chunks:remap(caps_acronym)
		local first = chunks:shift()
		chunks:remap(capitalise)
		chunks:unshift(first)
		return chunks:concat("")
	end
	--convert all named properties
	--(keep the old ones around as well)
	--(we take a copy of the keys here cause we're going to be inserting new keys as we go)
	for _, k in ipairs(_batteries.tablex.keys(self)) do
		local v = self[k]
		if
			--only convert string properties
			type(k) == "string"
			--ignore private and metamethod properties
			and not _batteries.stringx.starts_with(k, "_")
		then
			--convert
			local camel = snake_to_camel(k)
			if type(v) == "table" then
				--capitalise classes
				if v.__index == v then
					camel = capitalise(camel)
					--modify the internal name for :type()
					--might be a problem for serialisation etc,
					--but i imagine converting to/from camelCase mid-project is rare
					v.__name = camel
				end
				--recursively convert anything nested as well
				_batteries.camelCase(v)
			end
			--assign if the key changed and there isn't a matching key
			if k ~= camel and self[camel] == nil then
				self[camel] = v
			end
		end
	end

	return self
end

return _batteries
