--[[
	extra table routines

	optional:
		set BATTERIES_TABLE_MODULE to a table before requiring
		if you don't want this to modify the global `table` table
]]

local _table = BATTERIES_TABLE_MODULE or table

--apply prototype to module if it isn't the global table
--so it works "as if" it was the global table api
--upgraded with these routines
if _table ~= table then
	setmetatable(_table, {
		__index = table,
	})
end

--alias
_table.join = _table.concat

--return the back element of a table
function _table.back(t)
	return t[#t]
end

--remove the back element of a table and return it
function _table.pop(t)
	return table.remove(t)
end

--insert to the back of a table
function _table.push(t, v)
	return table.insert(t, v)
end

--remove the front element of a table and return it
function _table.shift(t)
	return table.remove(t, 1)
end

--insert to the front of a table
function _table.unshift(t, v)
	return table.insert(t, 1, v)
end

--find the index in a sequential table that a resides at
--or nil if nothing was found
--(todo: consider pairs version?)
function _table.index_of(t, a)
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
function _table.remove_value(t, a)
	local i = _table.index_of(t, a)
	if i then
		table.remove(t, i)
		return true
	end
	return false
end

--add a value to a table if it doesn't already exist (linear search)
--returns true if the value was added, else false
function _table.add_value(t, a)
	local i = _table.index_of(t, a)
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
function _table.pick_random(t, r)
	if #t == 0 then
		return nil
	end
	return t[_random(1, #t, r)]
end

--shuffle the order of a table
function _table.shuffle(t, r)
	for i = 1, #t do
		local j = _random(1, #t, r)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

--reverse the order of a table
function _table.reverse(t)
	for i = 1, #t / 2 do
		local j = #t - i + 1
		t[i], t[j] = t[j], t[i]
	end
	return t
end

--collect all keys of a table into a sequential table
--(useful if you need to iterate non-changing keys often and want an nyi tradeoff;
--	this call will be slow but then following iterations can use ipairs)
function _table.keys(t)
	local r = {}
	for k,v in pairs(t) do
		table.insert(r, k)
	end
	return r
end

--collect all values of a keyed table into a sequential table
--(shallow copy if it's already sequential)
function _table.values(t)
	local r = {}
	for k,v in pairs(t) do
		table.insert(r, v)
	end
	return r
end

--(might already exist depending on luajit)
if _table.clear == nil then
	if _table ~= table and table.clear then
		--import from global if it exists
		_table.clear = table.clear
	else
		--remove all values from a table
		--useful when multiple references are floating around
		--so you cannot just pop a new table out of nowhere
		function _table.clear(t)
			assert(type(t) == "table", "table.clear - argument 't' must be a table")
			local k = next(t)
			while k ~= nil do
				t[k] = nil
				k = next(t)
			end
		end
	end
end

--note: 
--	copies and overlays are currently not satisfactory
--
--	i feel that copy especially tries to do too much and
--	probably they should be split into separate functions
--	to be both more explicit and performant, ie
--
--	shallow_copy, deep_copy, shallow_overlay, deep_overlay
--
--	input is welcome on this :)

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
function _table.copy(t, deep_or_into)
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
				v = _table.copy(v, deep)
			end
		end
		into[k] = v
	end
	return into
end

--overlay one table directly onto another, shallow only
function _table.overlay(to, from)
	assert(type(to) == "table", "table.overlay - argument 'to' must be a table")
	assert(type(from) == "table", "table.overlay - argument 'from' must be a table")
	for k,v in pairs(from) do
		to[k] = v
	end
	return to
end

--faster unpacking for known-length tables up to 8
--gets around nyi in luajit
--note: you can use a larger unpack than you need as the rest
--		can be discarded, but it "feels dirty" :)

function _table.unpack2(t)
	return t[1], t[2]
end

function _table.unpack3(t)
	return t[1], t[2], t[3]
end

function _table.unpack4(t)
	return t[1], t[2], t[3], t[4]
end

function _table.unpack5(t)
	return t[1], t[2], t[3], t[4], t[5]
end

function _table.unpack6(t)
	return t[1], t[2], t[3], t[4], t[5], t[6]
end

function _table.unpack7(t)
	return t[1], t[2], t[3], t[4], t[5], t[6], t[7]
end

function _table.unpack8(t)
	return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8]
end
