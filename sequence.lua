--[[
	sequence - functional + oo wrapper for ordered tables

	sort of depends on functional.lua but can be used without it, will just
	crash if you call the functional interface

	in that case, you can still use the table methods that accept a table
	first as method calls.
]]
local sequence = {}

sequence.mt = {__index = sequence}

--proxy missing table fns to table
sequence._mt = {__index = table}
setmetatable(sequence, sequence._mt)

--upgrade a table into a functional sequence
function sequence:new(t)
	return setmetatable(t or {}, sequence.mt)
end

--import table functions to sequence as-is
sequence.join = table.concat                --alias

--sorting default to stable if present
sequence.sort = table.stable_sort or table.sort

--import functional interface to sequence in a sequence preserving way
function sequence:keys()
	return sequence:new(table.keys(self))
end

function sequence:values()
	return sequence:new(table.values(self))
end

function sequence:foreach(f)
	return table.foreach(self, f)
end

function sequence:reduce(f, o)
	return table.foreach(self, f, o)
end

function sequence:map(f)
	return sequence:new(table.map(self, f))
end

function sequence:filter(f)
	return sequence:new(table.filter(self, f))
end

function sequence:partition(f)
	local a, b = table.partition(self, f)
	return sequence:new(a), sequence:new(b)
end

function sequence:zip(other, f)
	return sequence:new(table.zip(self, other, f))
end

function sequence:dedupe()
	return table.dedupe(self)
end

function sequence:append_inplace(other)
	return table.append_inplace(self, other)
end

function sequence:append(other)
	return sequence:new():append_inplace(self):append_inplace(other)
end

function sequence:copy(deep)
	return sequence:new(table.copy(self, deep))
end

return sequence