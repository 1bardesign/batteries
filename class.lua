--[[
	barebones oop basics
	supports basic inheritance and means you don't have to build/set your own metatable each time

	todo: collect some stats on classes/optional global class registry
]]

local function class(inherits)
	local c = {}
	--class metatable
	setmetatable(c, {
		--wire up call as ctor
		__call = function(self, ...)
			return self:new(...)
		end,
		--handle single inheritence chain
		__index = inherits,
	})
	--instance metatable
	c.__mt = {
		__index = c,
	}
	--common class functions

	--internal initialisation
	--sets up an initialised object with a default value table
	--performing a super construction if necessary, and (re-)assigning the right metatable
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
		return inherits
	end

	--delegate a call to the superclass, by name
	--still a bit clumsy but much cleaner than the inline equivalent,
	--plus handles heirarchical complications, and detects various mistakes
	function c:super_call(func_name, ...)
		--
		if type(func_name) ~= "string" then
			error("super_call requires a string function name to look up, got "..tostring(func_name))
		end
		--todo: memoize the below :)
		local previous_impl = c:super()
		--find the first superclass that actually has the method
		while previous_impl and not rawget(previous_impl, func_name) do
			previous_impl = previous_impl:super()
		end
		if not previous_impl then
			error("failed super call - no superclass in the chain has an implementation of "..func_name)
		end
		-- get the function
		local f = previous_impl[func_name]
		if not f then -- this should never happen because we bail out earlier
			error("failed super call - missing function "..func_name.." in superclass")
		end
		-- check if someone reuses that reference
		if f == self[func_name] then
			error("failed super call - function "..func_name.." is same in superclass as in derived; this will be a infinite recursion!")
		end
		-- call that function
		return f(self, ...)
	end

	--done
	return c
end

return class
