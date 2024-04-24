--[[
	extra table routines
]]

local path = (...):gsub("tablex", "")
local assert = require(path .. "assert")

--for spairs
--(can be replaced with eg table.sort to use that instead)
local sort = require(path .. "sort")
local spairs_sort = sort.stable_sort

--apply prototype to module if it isn't the global table
--so it works "as if" it was the global table api
--upgraded with these routines
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

--swap two indices of a table
--(easier to read and generally less typing than the common idiom)
function tablex.swap(t, i, j)
	t[i], t[j] = t[j], t[i]
end

--swap the element at i to the back of the table, and remove it
--avoids linear cost of removal at the expense of messing with the order of the table
function tablex.swap_and_pop(t, i)
	tablex.swap(t, i, #t)
	return tablex.pop(t)
end

--rotate the elements of a table t by amount slots
-- amount 1: {1, 2, 3, 4} -> {2, 3, 4, 1}
-- amount -1: {1, 2, 3, 4} -> {4, 1, 2, 3}
function tablex.rotate(t, amount)
	if #t > 1 then
		while amount >= 1 do
			tablex.push(t, tablex.shift(t))
			amount = amount - 1
		end
		while amount <= -1 do
			tablex.unshift(t, tablex.pop(t))
			amount = amount + 1
		end
	end
	return t
end

--default comparison from sort.lua
local default_less = sort.default_less

--check if a function is sorted based on a "less" or "comes before" ordering comparison
--if any item is "less" than the item before it, we are not sorted
--(use stable_sort to )
function tablex.is_sorted(t, less)
	less = less or default_less
	for i = 1, #t - 1 do
		if less(t[i + 1], t[i]) then
			return false
		end
	end
	return true
end

--insert to the first position before the first larger element in the table
-- ({1, 2, 2, 3}, 2) -> {1, 2, 2, 2 (inserted here), 3}
--if this is used on an already sorted table, the table will remain sorted and not need re-sorting
--(you can sort beforehand if you don't know)
--return the table for possible chaining
function tablex.insert_sorted(t, v, less)
	less = less or default_less
	local low = 1
	local high = #t
	while low <= high do
		local mid = math.floor((low + high) / 2)
		local mid_val = t[mid]
		if less(v, mid_val) then
			high = mid - 1
		else
			low = mid + 1
		end
	end
	table.insert(t, low, v)
	return t
end

--find the index in a sequential table that a resides at
--or nil if nothing was found
function tablex.index_of(t, a)
	if a == nil then return nil end
	for i, b in ipairs(t) do
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

--get the next element in a sequential table
--	wraps around such that the next element to the last in sequence is the first
--	exists because builtin next may not behave as expected for mixed array/hash tables
--	if the element passed is not present or is nil, will also get the first element
--		but this should not be used to iterate the whole table; just use ipairs for that
function tablex.next_element(t, v)
	local i = tablex.index_of(t, v)
	--not present? just get the front of the table
	if not i then
		return tablex.front(t)
	end
	--(not using mathx to avoid inter-dependency)
	i = (i % #t) + 1
	return t[i]
end

function tablex.previous_element(t, v)
	local i = tablex.index_of(t, v)
	--not present? just get the front of the table
	if not i then
		return tablex.front(t)
	end
	--(not using mathx to avoid inter-dependency)
	i = i - 1
	if i == 0 then
		i = #t
	end
	return t[i]
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
function tablex.random_index(t, r)
	if #t == 0 then
		return 0
	end
	return _random(1, #t, r)
end

--pick a random value from a table (or nil if it's empty)
function tablex.pick_random(t, r)
	if #t == 0 then
		return nil
	end
	return t[tablex.random_index(t, r)]
end

--take a random value from a table (or nil if it's empty)
function tablex.take_random(t, r)
	if #t == 0 then
		return nil
	end
	return table.remove(t, tablex.random_index(t, r))
end

--return a random value from table t based on weights w provided (or nil empty)
--	w should be the same length as t
-- todo:
--	provide normalisation outside of this function, require normalised weights
function tablex.pick_weighted_random(t, w, r)
	if #t == 0 then
		return nil
	end
	if #w ~= #t then
		error("tablex.pick_weighted_random weight and value tables should be the same length")
	end
	local sum = 0
	for _, weight in ipairs(w) do
		sum = sum + weight
	end
	local rnd = _random(nil, nil, r) * sum
	sum = 0
	for i, weight in ipairs(w) do
		sum = sum + weight
		if rnd <= sum then
			return t[i]
		end
	end
	--shouldn't get here but safety if using a random that returns >= 1
	return tablex.back(t)
end

--shuffle the order of a table
function tablex.shuffle(t, r)
	for i = 1, #t do
		local j = _random(i, #t, r)
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

--trim a table to a certain maximum length
function tablex.trim(t, l)
	while #t > l do
		table.remove(t)
	end
	return t
end

--collect all keys of a table into a sequential table
--(useful if you need to iterate non-changing keys often and want an nyi tradeoff;
--	this call will be slow but then following iterations can use ipairs)
function tablex.keys(t)
	local r = {}
	for k, v in pairs(t) do
		table.insert(r, k)
	end
	return r
end

--collect all values of a keyed table into a sequential table
--(shallow copy if it's already sequential)
function tablex.values(t)
	local r = {}
	for k, v in pairs(t) do
		table.insert(r, v)
	end
	return r
end

--collect all values over a range into a new sequential table
--useful where a range may have been modified to contain nils
--	range can be a number, where it is used as a numeric limit (ie [1-range])
--	range can be a table, where the sequential values are used as keys
function tablex.compact(t, range)
	local r = {}
	if type(range) == "table" then
		for _, k in ipairs(range) do
			local v = t[k]
			if v then
				table.insert(r, v)
			end
		end
	elseif type(range) == "number" then
		for i = 1, range do
			local v = t[i]
			if v then
				table.insert(r, v)
			end
		end
	else
		error("tablex.compact - range must be a number or table", 2)
	end
	return r

end

--append sequence t2 into t1, modifying t1
function tablex.append_inplace(t1, t2, ...)
	for i, v in ipairs(t2) do
		table.insert(t1, v)
	end
	if ... then
		return tablex.append_inplace(t1, ...)
	end
	return t1
end

--return a new sequence with the elements of both t1 and t2
function tablex.append(t1, ...)
	local r = {}
	tablex.append_inplace(r, t1, ...)
	return r
end

--return a copy of a sequence with all duplicates removed
--	causes a little "extra" gc churn of one table to track the duplicates internally
function tablex.dedupe(t)
	local seen = {}
	local r = {}
	for i, v in ipairs(t) do
		if not seen[v] then
			seen[v] = true
			table.insert(r, v)
		end
	end
	return r
end

--(might already exist depending on environment)
if not tablex.clear then
	local imported
	--pull in from luajit if possible
	imported, tablex.clear = pcall(require, "table.clear")
	if not imported then
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
end

-- Copy a table
--	See shallow_overlay to shallow copy into an existing table to avoid garbage.
function tablex.shallow_copy(t)
	assert:type(t, "table", "tablex.shallow_copy - t", 1)
	local into = {}
	for k, v in pairs(t) do
		into[k] = v
	end
	return into
end

--alias
tablex.copy = tablex.shallow_copy

--implementation for deep copy
--traces stuff that has already been copied, to handle circular references
local function _deep_copy_impl(t, already_copied)
	local clone = t
	if type(t) == "table" then
		if already_copied[t] then
			--something we've already encountered before
			clone = already_copied[t]
		elseif type(t.copy) == "function" then
			--something that provides its own copy function
			clone = t:copy()
			assert:type(clone, "table", "member copy() function didn't return a copy")
		else
			--a plain table to clone
			clone = {}
			already_copied[t] = clone
			for k, v in pairs(t) do
				clone[k] = _deep_copy_impl(v, already_copied)
			end
			setmetatable(clone, getmetatable(t))
		end
	end
	return clone
end

-- Recursively copy values of a table.
-- Retains the same keys as original table -- they're not cloned.
function tablex.deep_copy(t)
	assert:type(t, "table", "tablex.deep_copy - t", 1)
	return _deep_copy_impl(t, {})
end

-- Overlay tables directly onto one another, merging them together.
-- Doesn't merge tables within.
-- Takes as many tables as required,
-- overlays them in passed order onto the first,
-- and returns the first table.
function tablex.shallow_overlay(dest, ...)
	assert:type(dest, "table", "tablex.shallow_overlay - dest", 1)
	for i = 1, select("#", ...) do
		local t = select(i, ...)
		assert:type(t, "table", "tablex.shallow_overlay - ...", 1)
		for k, v in pairs(t) do
			dest[k] = v
		end
	end
	return dest
end

tablex.overlay = tablex.shallow_overlay

-- Overlay tables directly onto one another, merging them together into something like a union.
-- Also overlays nested tables, but doesn't clone them (so a nested table may be added to dest).
-- Takes as many tables as required,
-- overlays them in passed order onto the first,
-- and returns the first table.
function tablex.deep_overlay(dest, ...)
	assert:type(dest, "table", "tablex.deep_overlay - dest", 1)
	for i = 1, select("#", ...) do
		local t = select(i, ...)
		assert:type(t, "table", "tablex.deep_overlay - ...", 1)
		for k, v in pairs(t) do
			if type(v) == "table" and type(dest[k]) == "table" then
				tablex.deep_overlay(dest[k], v)
			else
				dest[k] = v
			end
		end
	end
	return dest
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
			for _, w in ipairs(v) do
				table.insert(r, w)
			end
		else
			table.insert(r, v)
		end
	end
	return r
end

--extract values of a table into nested tables of a set length
--	extract({1, 2, 3, 4}, 2) -> {{1, 2}, {3, 4}}
--	useful for working with "inlined" data in a more structured way
--	can use collapse (or functional.stitch) to reverse the process once you're done if needed
--	todo: support an ordered list of keys passed and extract them to names
function tablex.extract(t, n)
	assert:type(t, "table", "tablex.extract - t", 1)
	assert:type(n, "number", "tablex.extract - n", 1)
	local r = {}
	for i = 1, #t, n do
		r[i] = {}
		for j = 1, n do
			table.insert(r[i], t[i + j])
		end
	end
	return r
end

--check if two tables have equal contents at the first level
--slow, as it needs two loops
function tablex.shallow_equal(a, b)
	if a == b then return true end
	for k, v in pairs(a) do
		if b[k] ~= v then
			return false
		end
	end
	-- second loop to ensure a isn't missing any keys from b.
	-- we don't compare the values - if any are missing we're not equal
	for k, v in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

--check if two tables have equal contents all the way down
--slow, as it needs two potentially recursive loops
function tablex.deep_equal(a, b)
	if a == b then return true end
	--not equal on type
	if type(a) ~= type(b) then
		return false
	end
	--bottomed out
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in pairs(a) do
		if not tablex.deep_equal(v, b[k]) then
			return false
		end
	end
	-- second loop to ensure a isn't missing any keys from b
	-- we don't compare the values - if any are missing we're not equal
	for k, v in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

--alias
tablex.flatten = tablex.collapse

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

--internal: reverse iterator function
local function _ripairs_iter(t, i)
	i = i - 1
	local v = t[i]
	if v then
		return i, v
	end
end

--iterator that works like ipairs, but in reverse order, with indices from #t to 1
--similar to ipairs, it will only consider sequential until the first nil value in the table.
function tablex.ripairs(t)
	return _ripairs_iter, t, #t + 1
end

--works like pairs, but returns sorted table
--	generates a fair bit of garbage but very nice for more stable output
--	less function gets keys the of the table as its argument; if you want to sort on the values they map to then
--		you'll likely need a closure
function tablex.spairs(t, less)
	less = less or default_less
	--gather the keys
	local keys = tablex.keys(t)

	spairs_sort(keys, less)

	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end


return tablex
