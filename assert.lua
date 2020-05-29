--[[
	various intuitive assertions that
		- avoid garbage generation upon success,
		- build nice formatted error messages
		- post one level above the call site by default
		- return their first argument so they can be used inline

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
	return "\n\n\t(note: " .. msg .. ")"
end

--assert a value is not nil
--return the value, so this can be chained
function assert:some(v, msg, stack_level)
	if v == nil then
		error(("assertion failed: value is nil %s"):format(
			_extra(msg)
		), 2 + (stack_level or 0))
	end
	return v
end

--assert two values are equal
function assert:equal(a, b, msg, stack_level)
	if a ~= b then
		error(("assertion failed: %s is not equal to %s %s"):format(
			tostring(a),
			tostring(b),
			_extra(msg)
		), 2 + (stack_level or 0))
	end
	return a
end

--assert two values are not equal
function assert:not_equal(a, b, msg, stack_level)
	if a == b then
		error(("assertion failed: values are equal %s"):format(
			_extra(msg)
		), 2 + (stack_level or 0))
	end
	return a
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
	return a
end

--replace everything in assert with nop functions that just return their second argument, for near-zero overhead on release
function assert:nop()
	local nop = function(self, a)
		return a
	end
	setmetatable(self, {
		__call = nop,
	})
	for k, v in pairs(self) do
		self[k] = nop
	end
end

return assert
