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

--import functional interface
function sequence:foreach(f)
	return functional.foreach(self, f)
end

function sequence:reduce(seed, f)
	return functional.reduce(self, seed, f)
end

function sequence:map(f)
	return sequence(functional.map(self, f))
end

function sequence:map_inplace(f)
	return sequence(functional.map_inplace(self, f))
end

sequence.remap = sequence.map_inplace

function sequence:filter(f)
	return sequence(functional.filter(self, f))
end

function sequence:filter_inplace(f)
	return sequence(functional.filter_inplace(self, f))
end

function sequence:remove_if(f)
	return sequence(functional.remove_if(self, f))
end

function sequence:partition(f)
	local a, b = functional.partition(self, f)
	return sequence(a), sequence(b)
end

function sequence:zip(other, f)
	return sequence(functional.zip(self, other, f))
end

return sequence
