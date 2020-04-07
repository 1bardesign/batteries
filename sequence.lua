--[[
	sequence - functional + oo wrapper for ordered tables

	sort of depends on functional.lua but can be used without it, will just
	crash if you call the functional interface

	in that case, you can still use the table methods that accept a table
	first as method calls.
]]

local path = (...):gsub("sequence", "")
local class = require(path .. "class")
local table = require(path .. "tablex") --shadow global table module
local functional = require(path .. "functional")

local sequence = class()
--proxy missing table fns to global table api
setmetatable(sequence, {__index = table})

--upgrade a table into a sequence, or create a new sequence
function sequence:new(t)
	return self:init(t or {})
end

--alias
sequence.join = table.concat

--sorting default to stable if present
sequence.sort = table.stable_sort or table.sort

--import functional interface to sequence in a type-preserving way, for method chaining
function sequence:keys()
	return sequence:new(functional.keys(self))
end

function sequence:values()
	return sequence:new(functional.values(self))
end

function sequence:foreach(f)
	return functional.foreach(self, f)
end

function sequence:reduce(f, o)
	return functional.foreach(self, f, o)
end

function sequence:map(f)
	return sequence:new(functional.map(self, f))
end

function sequence:remap(f)
	return functional.remap(self, f)
end

function sequence:filter(f)
	return sequence:new(functional.filter(self, f))
end

function sequence:partition(f)
	local a, b = functional.partition(self, f)
	return sequence:new(a), sequence:new(b)
end

function sequence:zip(other, f)
	return sequence:new(functional.zip(self, other, f))
end

function sequence:dedupe()
	return functional.dedupe(self)
end

function sequence:append_inplace(other)
	return functional.append_inplace(self, other)
end

function sequence:append(other)
	return sequence:new():append_inplace(self):append_inplace(other)
end

function sequence:copy(deep)
	return sequence:new(functional.copy(self, deep))
end

return sequence