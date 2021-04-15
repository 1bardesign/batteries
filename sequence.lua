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
function sequence:keys()
	return sequence(table.keys(self))
end

function sequence:values()
	return sequence(table.values(self))
end

function sequence:dedupe()
	return sequence(table.dedupe(self))
end

function sequence:collapse()
	return sequence(table.collapse(self))
end
sequence.flatten = sequence.collapse

function sequence:append(...)
	return sequence(table.append(self, ...))
end

function sequence:overlay(...)
	return sequence(table.overlay(self, ...))
end

function sequence:copy(...)
	return sequence(table.copy(self, ...))
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

--aliases
for _, v in ipairs({
	{"remap", "map_inplace"},
	{"map_stitch", "stitch"},
	{"map_cycle", "cycle"},
}) do
	sequence[v[1]] = sequence[v[2]]
end

--(less common cases where we don't want to construct a new sequence or have more than one return value)
function sequence:foreach(f)
	return functional.foreach(self, f)
end

function sequence:reduce(seed, f)
	return functional.reduce(self, seed, f)
end

function sequence:partition(f)
	local a, b = functional.partition(self, f)
	return sequence(a), sequence(b)
end

return sequence
