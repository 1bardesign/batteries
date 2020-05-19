--[[
	barebones oop basics
	supports basic inheritance and means you don't have to build/set your own metatable each time

	todo: collect some stats on classes/optional global class registry
]]

local function class(inherits)
	local c = {}
	c.__mt = {
		__index = c,
	}
	setmetatable(c, {
		--wire up call as ctor
		__call = function(self, ...)
			return self:new(...)
		end,
		--handle single inheritence
		__index = inherits,
	})
	--common class functions

	--internal initialisation
	--sets up an initialised object with a default value table
	--performing a super construction if necessary and assigning the right metatable
	function c:init(t, ...)
		if inherits and inherits.new then
			--construct superclass instance, then overlay args table
			local ct = inherits:new(...)
			for k,v in pairs(t) do
				ct[k] = v
			end
			t = ct
		end
		--upgrade to this class and return
		return setmetatable(t, self.__mt)
	end

	--constructor
	--generally to be overridden
	function c:new()
		return self:init({})
	end

	--get the inherited class for super calls if/as needed
	--allows overrides that still refer to superclass behaviour
	function c:super()
		return inherits or c
	end

	--delegate a call to the super class, by name
	--still a bit clumsy but cleaner than the inline equivalent
	function c:super_call(func_name, ...)
		local f = self:super()[func_name]
		if f then
			return f(self, ...)
		end
		error("failed super call - missing function "..tostring(func_name).." in superclass")
	end

	--done
	return c
end

return class
