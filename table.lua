--[[
	extra table routines
]]

--return the back element of a table
function table.back(t)
	return t[#t]
end

--remove the back element of a table and return it
function table.pop(t)
	return table.remove(t)
end

--insert to the back of a table
function table.push(t, v)
	return table.insert(t, v)
end

--remove the front element of a table and return it
function table.shift(t)
	return table.remove(t, 1)
end

--insert to the front of a table
function table.unshift(t, v)
	return table.insert(t, 1, v)
end

--find the index in a sequential table that a resides at
--or nil if nothing was found
--(todo: consider pairs version?)
function table.index_of(t, a)
	if a == nil then return nil end
	for i,b in ipairs(t) do
		if a == b then
			return i
		end
	end
	return nil
end

--remove the first instance of value from a table (linear search)
--returns true if the value was removed, else false
function table.remove_value(t, a)
	local i = table.index_of(t, a)
	if i then
		table.remove(t, i)
		return true
	end
	return false
end

--add a value to a table if it doesn't already exist (linear search)
--returns true if the value was added, else false
function table.add_value(t, a)
	local i = table.index_of(t, a)
	if not i then
		table.insert(t, a)
		return true
	end
	return false
end

--helper for optionally passed random
local _global_random = love.math.random or math.random
local function _random(min, max, r)
	return r and r:random(min, max) 
		or _global_random(min, max)
end

--pick a random value from a table (or nil if it's empty)
function table.pick_random(t, r)
	if #t == 0 then
		return nil
	end
	return t[_random(1, #t, r)]
end

--shuffle the order of a table
function table.shuffle(t, r)
	for i = 1, #t do
		local j = _random(1, #t, r)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

--reverse the order of a table
function table.reverse(t)
	for i = 1, #t / 2 do
		local j = #t - i + 1
		t[i], t[j] = t[j], t[i]
	end
	return t
end

--(might already exist depending on luajit)
if table.clear == nil then
	--destructively clear a numerically keyed table
	--useful when multiple references are floating around
	--so you cannot just pop a new table out of nowhere
	function table.clear(t)
		assert(type(to) == "table", "table.clear - argument 't' must be a table")
		while t[1] ~= nil do
			table.remove(t)
		end
	end
end

--overlay one table directly onto another, shallow only
function table.overlay(to, from)
	assert(type(to) == "table", "table.overlay - argument 'to' must be a table")
	assert(type(from) == "table", "table.overlay - argument 'from' must be a table")
	for k,v in pairs(from) do
		to[k] = v
	end
	return to
end

--copy a table
--	deep_or_into is either:
--		a boolean value, used as deep flag directly
--		or a table to copy into, which implies a deep copy
--	if deep specified:
--		calls copy method of member directly if it exists
--		and recurses into all "normal" table children
--	if into specified, copies into that table
--		but doesn't clear anything out
--		(useful for deep overlays and avoiding garbage)
function table.copy(t, deep_or_into)
	assert(type(t) == "table", "table.copy - argument 't' must be a table")
	local is_bool = type(deep_or_into) == "boolean"
	local is_table = type(deep_or_into) == "table"

	local deep = (is_bool and deep_or_into) or is_table
	local into = is_table and deep_or_into or {}
	for k,v in pairs(t) do
		if deep and type(v) == "table" then
			if type(v.copy) == "function" then
				v = v:copy()
			else
				v = table.copy(v, deep)
			end
		end
		into[k] = v
	end
	return into
end

