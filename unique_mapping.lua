--[[
	unique mapping

	generate a mapping from unique values to plain numbers
	useful for arbitrarily ordering things that don't have
	a natural ordering in lua (eg textures for batching)
]]

local unique_mapping = {}
unique_mapping._mt = {
	__index = unique_mapping,
	__mode = "kv", --weak refs
}

--(used as storage for non-weak data)
local _MAP_VARS = setmetatable({}, {
	__mode = "k" --only keys are weak
})

--create a new unique mapping
function unique_mapping:new()
	local r =  setmetatable({}, self._mt)
	--set up the actual vars
	_MAP_VARS[r] = {
		current_index = 0,
	}
	return r
end

--private;
--get the next index for this mapping
function unique_mapping:_increment()
	local vars = _MAP_VARS[self]
	vars.current_index = vars.current_index + 1
	return vars.current_index
end

--get or build a mapping for a passed value
function unique_mapping:map(value)
	local val = self[value]
	if val then
		return val
	end
	local i = self:_increment()
	self[value] = i
	return i
end

--get a function representing an a < b comparision that can be used
--with table.sort and friends, like `table.sort(values, mapping:compare())`
function unique_mapping:compare()
	--	memoised so it doesn't generate garbage, but also doesn't
	--	allocate until it's actually used
	if not self._compare then
		self._compare = function(a, b)
			return self:map(a) < self:map(b)
		end
	end
	return self._compare
end

return unique_mapping
