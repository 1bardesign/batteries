--[[
	sequence - functional + oo wrapper for ordered tables

	mainly beneficial when used for method chaining
	to save on typing and data plumbing
]]

local path = (...):gsub("sequence", "")
local class = require(path .. "class")
local table = require(path .. "tablex") --shadow global table module
local functional = require(path .. "functional")

local sequence = class(table) --proxy missing table fns to tablex api

--upgrade a table into a sequence, or create a new sequence
function sequence:new(t)
	return self:init(t or {})
end

--alias
sequence.join = table.concat

--sorting default to stable if present
sequence.sort = table.stable_sort or table.sort

--patch various interfaces in a type-preserving way, for method chaining

--import copying tablex
function sequence:keys()
	return sequence(self:keys())
end

function sequence:values()
	return sequence(self:values())
end

function sequence:append(other)
	return sequence(self:append(other))
end

function sequence:dedupe()
	return sequence(self:dedupe())
end

--import functional interface
function sequence:foreach(f)
	return functional.foreach(self, f)
end

function sequence:reduce(f, o)
	return functional.reduce(self, f, o)
end

function sequence:map(f)
	return sequence(functional.map(self, f))
end

function sequence:remap(f)
	return functional.remap(self, f)
end

function sequence:filter(f)
	return sequence(functional.filter(self, f))
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