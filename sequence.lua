--[[
	sequence - functional + oo wrapper for ordered tables

	sort of depends on functional.lua but can be used without it, will just
	crash if you call the functional interface

	in that case, you can still use the table methods that accept a table
	first as method calls.
]]

local sequence = {}

sequence._mt = {__index = sequence}

--proxy missing table fns to global table api
sequence.__mt = {__index = table}
setmetatable(sequence, sequence.__mt)

--upgrade a table into a sequence, or create a new sequence
function sequence:new(t)
	return setmetatable(t or {}, sequence._mt)
end

--alias
sequence.join = table.concat

--sorting default to stable if present
sequence.sort = table.stable_sort or table.sort

--(handle functional module delegation correctly)
local _func = BATTERIES_FUNCTIONAL_MODULE or table

--import functional interface to sequence in a type preserving way
function sequence:keys()
	return sequence:new(_func.keys(self))
end

function sequence:values()
	return sequence:new(_func.values(self))
end

function sequence:foreach(f)
	return _func.foreach(self, f)
end

function sequence:reduce(f, o)
	return _func.foreach(self, f, o)
end

function sequence:map(f)
	return sequence:new(_func.map(self, f))
end

function sequence:remap(f)
	return _func.remap(self, f)
end

function sequence:filter(f)
	return sequence:new(_func.filter(self, f))
end

function sequence:partition(f)
	local a, b = _func.partition(self, f)
	return sequence:new(a), sequence:new(b)
end

function sequence:zip(other, f)
	return sequence:new(_func.zip(self, other, f))
end

function sequence:dedupe()
	return _func.dedupe(self)
end

function sequence:append_inplace(other)
	return _func.append_inplace(self, other)
end

function sequence:append(other)
	return sequence:new():append_inplace(self):append_inplace(other)
end

function sequence:copy(deep)
	return sequence:new(_func.copy(self, deep))
end

return sequence