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
		assert(type(func_name) == "string", "super_call requires a string function name to look up")
		--todo: memoize the below :)
		local first_impl = c
		--find the first superclass that actually has the method
		while first_impl and not rawget(first_impl, func_name) do
			first_impl = first_impl:super()
		end
		if not first_impl then
			error("failed super call - no superclass in the chain has an implementation of "..func_name)
		end
		--get the superclass of that
		local super = first_impl:super()
		if not super then
			error("failed super call - no superclass to call from")
		end

		local f = super[func_name]
		if not f then
			error("failed super call - missing function "..func_name.." in superclass")
		end
		if f == self[func_name] then
			error("failed super call - function "..func_name.." is same in superclass as in derived; this will be a infinite recursion!")
		end
		return f(self, ...)
	end

	--done
	return c
end

return class
