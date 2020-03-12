--[[
	functional programming facilities
]]

--collect all keys of a table into a sequence
function table.keys(t)
	local r = {}
	for k,v in pairs(t) do
		table.insert(r, k)
	end
	return r
end

--collect all values of a table into a sequence
--(shallow copy if it's already a sequence)
function table.values(t)
	local r = sequence:new()
	for k,v in pairs(t) do
		table.insert(r, v)
	end
	return r
end

--simple sequential iteration, f is called for all elements of t
--f can return non-nil to break the loop (and return the value)
function table.foreach(t, f)
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
function table.reduce(t, f, o)
	for i,v in ipairs(t) do
		o = f(o, v)
	end
	return o
end

--maps a sequence {a, b, c} -> {f(a), f(b), f(c)}
-- (automatically drops any nils due to table.insert, which can be used to simultaneously map and filter)
function table.map(t, f)
	local r = {}
	for i,v in ipairs(t) do
		local mapped = f(v, i)
		if mapped ~= nil then
			table.insert(r, mapped)
		end
	end
	return r
end

--filters a sequence
function table.filter(t, f)
	local r = {}
	for i,v in ipairs(t) do
		if f(v, i) then
			table.insert(r, v)
		end
	end
	return r
end

--partitions a sequence based on filter criteria
function table.partition(t, f)
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
function table.zip(t1, t2, f)
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
function table.dedupe(t)
	local seen = {}
	return table.filter(t, function(v)
		if seen[v] then
			return false
		end
		seen[v] = true
		return true
	end)
end

--append sequence t2 into t1, modifying t1
function table.append_inplace(t1, t2)
	table.foreach(t2, function(v)
		table.insert(t1, v)
	end)
	return t1
end

--return a new sequence with the elements of both t1 and t2
function table.append(t1, t2)
	local r = {}
	append_inplace(r, t1)
	append_inplace(r, t2)
	return r
end

-----------------------------------------------------------
--common queries and reductions
-----------------------------------------------------------

--true if any element of the table matches f
function table.any(t, f)
	for i,v in ipairs(t) do
		if f(v) then
			return true
		end
	end
	return false
end

--true if no element of the table matches f
function table.none(t, f)
	for i,v in ipairs(t) do
		if f(v) then
			return false
		end
	end
	return true
end

--true if all elements of the table match f
function table.all(t, f)
	for i,v in ipairs(t) do
		if not f(v) then
			return false
		end
	end
	return true
end

--counts the elements of t that match f
function table.count(t, f)
	local c = 0
	for i,v in ipairs(t) do
		if f(v) then
			c = c + 1
		end
	end
	return c
end

--true if the table contains element e
function table.contains(t, e)
	for i, v in ipairs(t) do
		if v == e then
			return true
		end
	end
	return false
end

--return the numeric sum of all elements of t
function table.sum(t)
	return table.reduce(t, function(a, b)
		return a + b
	end, 0)
end

--return the numeric mean of all elements of t
function table.mean(t)
	local len = #t
	if len == 0 then
		return 0
	end
	return table.sum(t) / len
end

--return the minimum and maximum of t in one pass
function table.minmax(t)
	local a = table.reduce(t, function(a, b)
		a.min = a.min and math.min(a.min, b) or b
		a.max = a.max and math.max(a.max, b) or b
		return a
	end, {})
	if a.min == nil then
		a.min = 0
		a.max = 0
	end
	return a.min, a.max
end

function table.max(t)
	local min, max = table.minmax(t)
	return max
end

function table.min(t)
	local min, max = table.minmax(t)
	return min
end

--return the element of the table that results in the greatest numeric value
--(function receives element and key respectively, table evaluated in pairs order)
function table.find_best(t, f)
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
function table.find_nearest(t, f, v)
	return table.find_best(t, function(e)
		return -math.abs(f(e) - v)
	end)
end

--return the first element of the table that results in a true filter
function table.find_match(t, f)
	for i,v in ipairs(t) do
		if f(v) then
			return v
		end
	end
	return nil
end
