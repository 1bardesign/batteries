--[[
	functional programming facilities

	notes:
		be careful about creating closures in hot loops.
		this is this module's achilles heel - there's no special
		syntax for closures so it's not apparent that you're suddenly
		allocating at every call

		reduce has a similar problem, but at least arguments
		there are clear!

	optional:
		set BATTERIES_FUNCTIONAL_MODULE to a table before requiring
		if you don't want this to modify the global `table` table
]]

local _table = BATTERIES_FUNCTIONAL_MODULE or table

--simple sequential iteration, f is called for all elements of t
--f can return non-nil to break the loop (and return the value)
function _table.foreach(t, f)
	for i,v in ipairs(t) do
		local r = f(v, i)
		if r ~= nil then
			return r
		end
	end
end

--performs a left to right reduction of t using f, with o as the initial value
-- reduce({1, 2, 3}, f, 0) -> f(f(f(0, 1), 2), 3)
-- (but performed iteratively, so no stack smashing)
function _table.reduce(t, f, o)
	for i,v in ipairs(t) do
		o = f(o, v)
	end
	return o
end

--maps a sequence {a, b, c} -> {f(a), f(b), f(c)}
-- (automatically drops any nils due to table.insert, which can be used to simultaneously map and filter)
function _table.map(t, f)
	local r = {}
	for i,v in ipairs(t) do
		local mapped = f(v, i)
		if mapped ~= nil then
			table.insert(r, mapped)
		end
	end
	return r
end

--maps a sequence inplace, modifying it {a, b, c} -> {f(a), f(b), f(c)}
-- (automatically drops any nils, which can be used to simultaneously map and filter,
--	but this results in a linear table.remove so "careful" for big working sets)
function _table.remap(t, f)
	local i = 1
	while i <= #t do
		local mapped = f(t[i])
		if mapped ~= nil then
			t[i] = mapped
			i = i + 1
		else
			table.remove(t, i)
		end
	end
	return t
end

--filters a sequence
function _table.filter(t, f)
	local r = {}
	for i,v in ipairs(t) do
		if f(v, i) then
			table.insert(r, v)
		end
	end
	return r
end

--partitions a sequence based on filter criteria
function _table.partition(t, f)
	local a = {}
	local b = {}
	for i,v in ipairs(t) do
		if f(v, i) then
			table.insert(a, v)
		else
			table.insert(b, v)
		end
	end
	return a, b
end

--zips two sequences together into a new table, based on another function
--iteration limited by min(#t1, #t2)
--function receives arguments (t1, t2, i)
--nil results ignored
function _table.zip(t1, t2, f)
	local ret = {}
	local limit = math.min(#t2, #t2)
	for i=1, limit do
		local v1 = t1[i]
		local v2 = t2[i]
		local zipped = f(v1, v2, i)
		if zipped ~= nil then
			table.insert(ret, zipped)
		end
	end
	return ret
end

--return a copy of a sequence with all duplicates removed
--	causes a little "extra" gc churn; one table and one closure
--	as well as the copied deduped table
function _table.dedupe(t)
	local seen = {}
	return _table.filter(t, function(v)
		if seen[v] then
			return false
		end
		seen[v] = true
		return true
	end)
end

--append sequence t2 into t1, modifying t1
function _table.append_inplace(t1, t2)
	for i,v in ipairs(t2) do
		table.insert(t1, v)
	end
	return t1
end

--return a new sequence with the elements of both t1 and t2
function _table.append(t1, t2)
	local r = {}
	append_inplace(r, t1)
	append_inplace(r, t2)
	return r
end

-----------------------------------------------------------
--common queries and reductions
-----------------------------------------------------------

--true if any element of the table matches f
function _table.any(t, f)
	for i,v in ipairs(t) do
		if f(v) then
			return true
		end
	end
	return false
end

--true if no element of the table matches f
function _table.none(t, f)
	for i,v in ipairs(t) do
		if f(v) then
			return false
		end
	end
	return true
end

--true if all elements of the table match f
function _table.all(t, f)
	for i,v in ipairs(t) do
		if not f(v) then
			return false
		end
	end
	return true
end

--counts the elements of t that match f
function _table.count(t, f)
	local c = 0
	for i,v in ipairs(t) do
		if f(v) then
			c = c + 1
		end
	end
	return c
end

--true if the table contains element e
function _table.contains(t, e)
	for i, v in ipairs(t) do
		if v == e then
			return true
		end
	end
	return false
end

--return the numeric sum of all elements of t
function _table.sum(t)
	return _table.reduce(t, function(a, b)
		return a + b
	end, 0)
end

--return the numeric mean of all elements of t
function _table.mean(t)
	local len = #t
	if len == 0 then
		return 0
	end
	return _table.sum(t) / len
end

--return the minimum and maximum of t in one pass
--or zero for both if t is empty
--	(would perhaps more correctly be math.huge, -math.huge
--	 but that tends to be surprising/annoying in practice)
function _table.minmax(t)
	local max, min
	for i,v in ipairs(t) do
		min = not min and v or math.min(min, v)
		max = not max and v or math.max(max, v)
	end
	if min == nil then
		min = 0
		max = 0
	end
	return min, max
end

--return the maximum element of t or zero if t is empty
function _table.max(t)
	local min, max = _table.minmax(t)
	return max
end

--return the minimum element of t or zero if t is empty
function _table.min(t)
	local min, max = _table.minmax(t)
	return min
end

--return the element of the table that results in the greatest numeric value
--(function receives element and key respectively, table evaluated in pairs order)
function _table.find_best(t, f)
	local current = nil
	local current_best = -math.huge
	for k,e in pairs(t) do
		local v = f(e, k)
		if v > current_best then
			current_best = v
			current = e
		end
	end
	return current
end

--return the element of the table that results in the value nearest to the passed value
--todo: optimise as this generates a closure each time
function _table.find_nearest(t, f, v)
	return _table.find_best(t, function(e)
		return -math.abs(f(e) - v)
	end)
end

--return the first element of the table that results in a true filter
function _table.find_match(t, f)
	for i,v in ipairs(t) do
		if f(v) then
			return v
		end
	end
	return nil
end

return _table
