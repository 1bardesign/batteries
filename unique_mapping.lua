--generate a mapping from unique values to plain numbers
--useful for arbitrarily ordering things that don't have
--a natural ordering implied (eg textures for batching)

local unique_mapping = {}
unique_mapping.mt = {
	__index = unique_mapping,
	__mode = "kv", --weak refs
}

--(used as storage for non-weak data)
local _MAP_VARS = setmetatable({}, {
	__mode = "k" --only keys are weak
})

function unique_mapping:new()
	local r =  setmetatable({}, unique_mapping.mt)
	--set up the actual vars
	_MAP_VARS[r] = {
		current_index = 0,
	}
	return r
end

function unique_mapping:_increment()
	local vars = _MAP_VARS[self]
	vars.current_index = vars.current_index + 1
	return vars.current_index
end

function unique_mapping:map(value)
	local val = self[value]
	if val then
		return val
	end
	local i = self:_increment()
	self[value] = i
	return i
end

return unique_mapping
