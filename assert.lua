local _assert = assert


--[[ #
	> various intuitive assertions that
		- avoid garbage generation upon success,
		- build nice formatted error messages
		- post one level above the call site by default
		- return their first argument so they can be used inline

	> default call is builtin global assert
	> can call nop() to dummy out everything for "release mode"
]]
---@class Assert
local assert = setmetatable({}, {
	---proxy calls to global assert
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

---assert a value is not nil
---return the value, so this can be chained
---@generic T
---@param v T?
---@param msg string?
---@param stack_level number?
---@return T
function assert:some(v, msg, stack_level)
	if v == nil then
		error(("assertion failed: value is nil %s"):format(
			_extra(msg)
		), 2 + (stack_level or 0))
	end
	return v
end

---assert two values are equal
---@generic T
---@param a T?
---@param b any?
---@param msg string?
---@param stack_level number?
---@return T
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

---assert two values are not equal
---@generic T
---@param a T?
---@param b any?
---@param msg string?
---@param stack_level number?
---@return T
function assert:not_equal(a, b, msg, stack_level)
	if a == b then
		error(("assertion failed: values are equal %s"):format(
			_extra(msg)
		), 2 + (stack_level or 0))
	end
	return a
end

---assert a value is of a certain type
---@generic T
---@param a any?
---@param t T?
---@param msg string?
---@param stack_level number?
---@return T
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

---assert a value is nil or a certain type.
---useful for optional parameters.
---@generic T
---@param a any?
---@param t T?
---@param msg string?
---@param stack_level number?
---@return T|nil
function assert:type_or_nil(a, t, msg, stack_level)
	if a ~= nil then
		assert:type(a, t, msg, stack_level + 1)
	end
	return a
end

---assert a value is one of those in a table of options
---@generic T
---@param a T?
---@param t table
---@param msg string?
---@param stack_level number?
---@return T
function assert:one_of(a, t, msg, stack_level)
	for _, value in ipairs(t) do
		if value == a then
			return a
		end
	end

	local values = {}
	for index = 1, #t do
		values[index] = tostring(t[index])
	end

	error(("assertion failed: %s not one of %s %s"):format(
		tostring(a),
		table.concat(values, ", "),
		_extra(msg)
	), 2 + (stack_level or 0))
end

--replace everything in assert with nop functions that just return their second argument, for near-zero overhead on release
function assert:nop()
	local nop = function(_, a)
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
