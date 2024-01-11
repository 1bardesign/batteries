--[[
	sequence - functional + oo wrapper for ordered tables

	mainly beneficial when used for method chaining
	to save on typing and data plumbing
]]

local path = (...):gsub("sequence", "")
local table = require(path .. "tablex") --shadow global table module
local functional = require(path .. "functional")
local stable_sort = require(path .. "sort").stable_sort

--(not a class, because we want to be able to upgrade tables that are passed in without a copy)
local sequence = {}
sequence.__index = sequence
setmetatable(sequence, {
	__index = table,
	__call = function(self, ...)
		return sequence:new(...)
	end,
})

--iterators as method calls
--(no pairs, sequences are ordered)
--todo: pico8 like `all`
sequence.ipairs = ipairs
sequence.iterate = ipairs

--upgrade a table into a sequence, or create a new sequence
function sequence:new(t)
	return setmetatable(t or {}, sequence)
end

--sorting default to stable
sequence.sort = stable_sort

--patch various interfaces in a type-preserving way, for method chaining

--import copying tablex
--(common case where something returns another sequence for chaining)
for _, v in ipairs({
	"keys",
	"values",
	"dedupe",
	"collapse",
	"append",
	"shallow_overlay",
	"deep_overlay",
	"copy",
	"shallow_copy",
	"deep_copy",
}) do
	local table_f = table[v]
	sequence[v] = function(self, ...)
		return sequence(table_f(self, ...))
	end
end

--aliases
for _, v in ipairs({
	{"flatten", "collapse"},
}) do
	sequence[v[1]] = sequence[v[2]]
end

--import functional interface in method form

--(common case where something returns another sequence for chaining)
for _, v in ipairs({
	"map",
	"map_field",
	"map_call",
	"filter",
	"remove_if",
	"zip",
	"combine",
	"stitch",
	"map_stitch",
	"cycle",
	"map_cycle",
	"chain",
	"map_chain",
}) do
	local functional_f = functional[v]
	sequence[v] = function(self, ...)
		return sequence(functional_f(self, ...))
	end
end

--(cases where we don't want to construct a new sequence)
for _, v in ipairs({
	"map_inplace",
	"filter_inplace",
	"foreach",
	"reduce",
	"any",
	"none",
	"all",
	"count",
	"contains",
	"sum",
	"mean",
	"minmax",
	"max",
	"min",
	"find_min",
	"find_max",
	"find_nearest",
	"find_match",
}) do
	sequence[v] = functional[v]
end


--aliases
for _, v in ipairs({
	{"remap", "map_inplace"},
	{"map_stitch", "stitch"},
	{"map_cycle", "cycle"},
	{"find_best", "find_max"},
}) do
	sequence[v[1]] = sequence[v[2]]
end

--(anything that needs bespoke wrapping)
function sequence:partition(f)
	local a, b = functional.partition(self, f)
	return sequence(a), sequence(b)
end

function sequence:unzip(f)
	local a, b = functional.unzip(self, f)
	return sequence(a), sequence(b)
end

return sequence
