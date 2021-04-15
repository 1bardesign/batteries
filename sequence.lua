--[[
	sequence - functional + oo wrapper for ordered tables

	mainly beneficial when used for method chaining
	to save on typing and data plumbing
]]

local path = (...):gsub("sequence", "")
local class = require(path .. "class")
local table = require(path .. "tablex") --shadow global table module
local functional = require(path .. "functional")
local stable_sort = require(path .. "sort").stable_sort

local sequence = class(table) --proxy missing table fns to tablex api

--upgrade a table into a sequence, or create a new sequence
function sequence:new(t)
	return self:init(t or {})
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
	"overlay",
	"copy",
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
	"map_inplace",
	"filter",
	"filter_inplace",
	"remove_if",
	"zip",
	"stitch",
	"cycle",
}) do
	local functional_f = functional[v]
	sequence[v] = function(self, ...)
		return sequence(functional_f(self, ...))
	end
end

--(cases where we don't want to construct a new sequence)
for _, v in ipairs({
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

return sequence
