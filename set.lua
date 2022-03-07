--[[
	set type with appropriate operations

	NOTE: This is actually a unique list (ordered set). So it's more than just
	a table with keys for values.
]]

local path = (...):gsub("set", "")
local class = require(path .. "class")
local table = require(path .. "tablex") --shadow global table module

local set = class({
	name = "set",
})

--construct a new set
--elements is an optional ordered table of elements to be added to the set
function set:new(elements)
	self._keyed = {}
	self._ordered = {}
	if elements then
		for _, v in ipairs(elements) do
			self:add(v)
		end
	end
end

--check if an element is present in the set
function set:has(v)
	return self._keyed[v] or false
end

--add a value to the set, if it's not already present
function set:add(v)
	if not self:has(v) then
		self._keyed[v] = true
		table.insert(self._ordered, v)
	end
	return self
end

--remove a value from the set, if it's present
function set:remove(v)
	if self:has(v) then
		self._keyed[v] = nil
		table.remove_value(self._ordered, v)
	end
	return self
end

--remove all elements from the set
function set:clear()
	if table.clear then
		table.clear(self._keyed)
		table.clear(self._ordered)
	else
		self._keyed = {}
		self._ordered = {}
	end
end

--get the number of distinct values in the set
function set:size()
	return #self._ordered
end

--return a value from the set
--index must be between 1 and size() inclusive
--adding/removing invalidates indices
function set:get(index)
	return self._ordered[index]
end

--iterate the values in the set, along with their index
--the index is useless but harmless, and adding a custom iterator seems
--like a really easy way to encourage people to use slower-than-optimal code
function set:ipairs()
	return ipairs(self._ordered)
end

--get a copy of the values in the set, as a simple table
function set:values()
	return table.shallow_copy(self._ordered)
end

--get a direct reference to the internal list of values in the set
--do NOT modify the result, or you'll break the set!
--for read-only access it avoids a needless table copy
--(eg this is sensible to pass to functional apis)
function set:values_readonly()
	return self._ordered
end

--convert to an ordered table, destroying set-like properties
--and deliberately disabling the initial set object
function set:to_table()
	local r = self._ordered
	self._ordered = nil
	self._keyed = nil
	return r
end

--modifying operations

--add all the elements present in the other set
function set:add_set(other)
	for i, v in other:ipairs() do
		self:add(v)
	end
	return self
end

--remove all the elements present in the other set
function set:subtract_set(other)
	for i, v in other:ipairs() do
		self:remove(v)
	end
	return self
end

--new collection operations

--copy a set
function set:copy()
	return set():add_set(self)
end

--create a new set containing the complement of the other set contained in this one
--the elements present in this set but not present in the other set will remain in the result
function set:complement(other)
	return self:copy():subtract_set(other)
end

--alias
set.difference = set.complement

--create a new set containing the union of this set with another
--an element present in either set will be present in the result
function set:union(other)
	return self:copy():add_set(other)
end

--create a new set containing the intersection of this set with another
--only the elements present in both sets will remain in the result
function set:intersection(other)
	local r = set()
	for i, v in self:ipairs() do
		if other:has(v) then
			r:add(v)
		end
	end
	return r
end

--create a new set containing the symmetric difference of this set with another
--only the elements not present in both sets will remain in the result
--similiar to a logical XOR operation
--
--equal to self:union(other):subtract_set(self:intersection(other))
--	but with much less wasted effort
function set:symmetric_difference(other)
	local r = set()
	for i, v in self:ipairs() do
		if not other:has(v) then
			r:add(v)
		end
	end
	for i, v in other:ipairs() do
		if not self:has(v) then
			r:add(v)
		end
	end
	return r
end

--alias
set.xor = set.symmetric_difference

--
return set
