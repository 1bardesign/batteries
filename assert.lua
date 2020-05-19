--[[
	various intuitive assertions that
		- avoid garbage generation upon success,
		- build nice formatted error messages
		- post one level above the call site by default

	default call is builtin global assert

	can call nop() to dummy out everything for "release mode"
	(if you're worried about that sort of thing)
]]

local _assert = assert

--proxy calls to global assert
local assert = setmetatable({}, {
	__call = function(self, ...)
		return _assert(...)
	end,	
})

local function _extra(msg)
	if not msg then
		return ""
	end
	return "(note: " .. msg .. ")"
end

--assert two values are equal
function assert:equals(a, b, msg, stack_level)
	if a ~= b then
		error(("assertion failed: %s is not equal to %s %s"):format(
			tostring(a),
			tostring(b),
			_extra(msg)
		), 2 + (stack_level or 0))
	end
end

--assert a value is of a certain type
function assert:type(a, t, msg, stack_level)
	if type(a) ~= t then
		error(("assertion failed: %s (%s) not of type %s %s"):format(
			tostring(a),
			type(a),
			tostring(t),
			_extra(msg)
		), 2 + (stack_level or 0))
	end
end

--replace everything in assert with nop functions, for near-zero overhead on release
function assert:nop()
	setmetatable(self, {
		__call = function() end,
	})
	for k, v in pairs(self) do
		self[k] = function() end
	end
end

return assert
