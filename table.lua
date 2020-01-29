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
end

--(might already exist depending on luajit)
if table.clear == nil then
	--destructively clear a numerically keyed table
	--useful when multiple references are floating around
	--so you cannot just pop a new table out of nowhere
	function table.clear(t)
		assert(type(to) == "table", "table.overlay - argument 'to' must be a table")
		while t[1] ~= nil do
			table.remove(t)
		end
	end
end

function table.overlay(to, from)
	assert(type(to) == "table", "table.overlay - argument 'to' must be a table")
	assert(type(from) == "table", "table.overlay - argument 'from' must be a table")
	for k,v in pairs(from) do
		to[k] = v
	end
	return to
end
