--[[
	extra table routines
]]

--apply prototype to module if it isn't the global table
--so it works "as if" it was the global table api
--upgraded with these routines

local path = (...):gsub(".tablex", ".")
local assert = require(path .. "assert")

local tablex = setmetatable({}, {
	__index = table,
})

--alias
tablex.join = tablex.concat

--return the front element of a table
function tablex.front(t)
	return t[1]
end

--return the back element of a table
function tablex.back(t)
	return t[#t]
end

--remove the back element of a table and return it
function tablex.pop(t)
	return table.remove(t)
end

--insert to the back of a table, returning the table for possible chaining
function tablex.push(t, v)
	table.insert(t, v)
	return t
end

--remove the front element of a table and return it
function tablex.shift(t)
	return table.remove(t, 1)
end

--insert to the front of a table, returning the table for possible chaining
function tablex.unshift(t, v)
	table.insert(t, 1, v)
	return t
end

--insert to the first position before the first larger element in the table
--if this is used on an already sorted table, the table will remain sorted and not need re-sorting
--todo: make it do binary search rather than linear to improve performance
--return the table for possible chaining
function tablex.insert_sorted(t, v, less)
	local inserted = false
	for i = 1, #t do
		if less(v, t[i]) then
			table.insert(t, i, v)
			inserted = true
			break
		end
	end
	if not inserted then
		table.insert(t, v)
	end
	return t
end

--find the index in a sequential table that a resides at
--or nil if nothing was found
function tablex.index_of(t, a)
	if a == nil then return nil end
	for i,b in ipairs(t) do
		if a == b then
			return i
		end
	end
	return nil
end

--find the key in a keyed table that a resides at
--or nil if nothing was found
function tablex.key_of(t, a)
	if a == nil then return nil end
	for k, v in pairs(t) do
		if a == v then
			return k
		end
	end
	return nil
end

--remove the first instance of value from a table (linear search)
--returns true if the value was removed, else false
function tablex.remove_value(t, a)
	local i = tablex.index_of(t, a)
	if i then
		table.remove(t, i)
		return true
	end
	return false
end

--add a value to a table if it doesn't already exist (linear search)
--returns true if the value was added, else false
function tablex.add_value(t, a)
	local i = tablex.index_of(t, a)
	if not i then
		table.insert(t, a)
		return true
	end
	return false
end

--note: keyed versions of the above aren't required; you can't double
--up values under keys

--helper for optionally passed random; defaults to love.math.random if present, otherwise math.random
local _global_random = math.random
if love and love.math and love.math.random then
	_global_random = love.math.random
end
local function _random(min, max, r)
	return r and r:random(min, max) 
		or _global_random(min, max)
end

--pick a random value from a table (or nil if it's empty)
function tablex.pick_random(t, r)
	if #t == 0 then
		return nil
	end
	return t[_random(1, #t, r)]
end

--shuffle the order of a table
function tablex.shuffle(t, r)
	for i = 1, #t do
		local j = _random(1, #t, r)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

--reverse the order of a table
function tablex.reverse(t)
	for i = 1, #t / 2 do
		local j = #t - i + 1
		t[i], t[j] = t[j], t[i]
	end
	return t
end

--collect all keys of a table into a sequential table
--(useful if you need to iterate non-changing keys often and want an nyi tradeoff;
--	this call will be slow but then following iterations can use ipairs)
function tablex.keys(t)
	local r = {}
	for k,v in pairs(t) do
		table.insert(r, k)
	end
	return r
end

--collect all values of a keyed table into a sequential table
--(shallow copy if it's already sequential)
function tablex.values(t)
	local r = {}
	for k,v in pairs(t) do
		table.insert(r, v)
	end
	return r
end

--append sequence t2 into t1, modifying t1
function tablex.append_inplace(t1, t2)
	for i,v in ipairs(t2) do
		table.insert(t1, v)
	end
	return t1
end

--return a new sequence with the elements of both t1 and t2
function tablex.append(t1, t2)
	local r = {}
	tablex.append_inplace(r, t1)
	tablex.append_inplace(r, t2)
	return r
end

--return a copy of a sequence with all duplicates removed
--	causes a little "extra" gc churn of one table to track the duplicates internally
function tablex.dedupe(t)
	local seen = {}
	local r = {}
	for i,v in ipairs(t) do
		if not seen[v] then
			seen[v] = true
			table.insert(r, v)
		end
	end
	return r
end

--(might already exist depending on luajit)
if table.clear then
	--import from global if it exists
	tablex.clear = table.clear
else
	--remove all values from a table
	--useful when multiple references are being held
	--so you cannot just create a new table
	function tablex.clear(t)
		assert:type(t, "table", "tablex.clear - t", 1)
		local k = next(t)
		while k ~= nil do
			t[k] = nil
			k = next(t)
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
function tablex.copy(t, deep_or_into)
	assert:type(t, "table", "tablex.copy - t", 1)
	local is_bool = type(deep_or_into) == "boolean"
	local is_table = type(deep_or_into) == "table"

	local deep = is_bool and deep_or_into or is_table
	local into = is_table and deep_or_into or {}
	for k, v in pairs(t) do
		if deep and type(v) == "table" then
			if type(v.copy) == "function" then
				v = v:copy()
			else
				v = tablex.copy(v, deep)
			end
		end
		into[k] = v
	end
	return into
end

--overlay tables directly onto one another, shallow only
--takes as many tables as required,
--overlays them in passed order onto the first,
--and returns the first table with the overlay(s) applied
function tablex.overlay(a, b, ...)
	assert:type(a, "table", "tablex.overlay - a", 1)
	assert:type(b, "table", "tablex.overlay - b", 1)
	for k,v in pairs(b) do
		a[k] = v
	end
	if ... then
		return tablex.overlay(a, ...)
	end
	return a
end

--collapse the first level of a table into a new table of reduced dimensionality
--will collapse {{1, 2}, 3, {4, 5, 6}} into {1, 2, 3, 4, 5, 6}
--useful when collating multiple result sets, or when you got 2d data when you wanted 1d data.
--in the former case you may just want to append_inplace though :)
--note that non-tabular elements in the base level are preserved,
--	but _all_ tables are collapsed; this includes any table-based types (eg a batteries.vec2),
--	so they can't exist in the base level
--	(... or at least, their non-ipairs members won't survive the collapse)
function tablex.collapse(t)
	assert:type(t, "table", "tablex.collapse - t", 1)
	local r = {}
	for _, v in ipairs(t) do
		if type(v) == "table" then
			for _, v in ipairs(v) do
				table.insert(r, v)
			end
		else
			table.insert(r, v)
		end
	end
	return r
end

--faster unpacking for known-length tables up to 8
--gets around nyi in luajit
--note: you can use a larger unpack than you need as the rest
--		can be discarded, but it "feels dirty" :)

function tablex.unpack2(t)
	return t[1], t[2]
end

function tablex.unpack3(t)
	return t[1], t[2], t[3]
end

function tablex.unpack4(t)
	return t[1], t[2], t[3], t[4]
end

function tablex.unpack5(t)
	return t[1], t[2], t[3], t[4], t[5]
end

function tablex.unpack6(t)
	return t[1], t[2], t[3], t[4], t[5], t[6]
end

function tablex.unpack7(t)
	return t[1], t[2], t[3], t[4], t[5], t[6], t[7]
end

function tablex.unpack8(t)
	return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8]
end

return tablex