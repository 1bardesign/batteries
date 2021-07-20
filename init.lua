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
	pretty = require_relative("pretty"),
	make_pooled = require_relative("make_pooled"),
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


--convert naming, for picky eaters
--experimental, let me know how it goes
function _batteries:camelCase()
	--convert something_like_this to somethingLikeThis
	local function snake_to_camel(s)
		local chunks = _batteries.sequence(_batteries.stringx.split(s, "_"))
		local first = chunks:shift()
		chunks:remap(function(v)
			local head = v:sub(1,1)
			local tail = v:sub(2)
			return head:upper() .. tail
		end)
		chunks:unshift(first)
		return chunks:concat("")
	end
	--convert all named properties
	--(keep the old ones around as well)
	for k, v in pairs(self) do
		if
			--only convert string properties
			type(k) == "string"
			--ignore private and metamethod properties
			and not _batteries.stringx.starts_with(k, "_")
		then
			--convert and assign
			local camel = snake_to_camel(k)
			if k ~= camel and self[camel] == nil then
				self[camel] = v
			end
			--recursively convert anything nested as well
			if type(v) == "table" then
				_batteries.camelCase(v)
			end
		end
	end

	return self
end

return _batteries
