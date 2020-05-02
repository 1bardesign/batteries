--[[
	set type with appropriate operations
]]

local path = (...):gsub("set", "")
local class = require(path .. "class")
local table = require(path .. "tablex") --shadow global table module

local set = class()

--construct a new set
--elements is an optional ordered table of elements to be added to the set
function set:new(elements)
	self = self:init({
		_keyed = {},
		_ordered = {},
	})
	if elements then
		for _, v in ipairs(elements) do
			self:add(v)
		end
	end
	return self
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

--iterate the values in the set, along with their index
--the index is useless but harmless, and adding a custom iterator seems
--like a really easy way to encourage people to use slower-than-optimal code
function set:ipairs()
	return ipairs(self._ordered)
end

--get a copy of the values in the set, as a simple table
function set:values()
	return table.copy(self._ordered)
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
	return set:new():add_set(self)
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
	local r = set:new()
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
	local r = set:new()
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
