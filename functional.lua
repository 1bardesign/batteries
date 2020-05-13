--[[
	functional programming facilities

	notes:
		be careful about creating closures in hot loops.
		this is this module's achilles heel - there's no special
		syntax for closures so it's not apparent that you're suddenly
		allocating at every call

		reduce has a similar problem, but at least arguments
		there are clear!
]]

local path = (...):gsub("functional", "")
local tablex = require(path .. "tablex")

local functional = setmetatable({}, {
	__index = tablex,
})

--simple sequential iteration, f is called for all elements of t
--f can return non-nil to break the loop (and return the value)
function functional.foreach(t, f)
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
function functional.reduce(t, f, o)
	for i,v in ipairs(t) do
		o = f(o, v)
	end
	return o
end

--maps a sequence {a, b, c} -> {f(a), f(b), f(c)}
-- (automatically drops any nils due to table.insert, which can be used to simultaneously map and filter)
function functional.map(t, f)
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
function functional.remap(t, f)
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
-- returns a table containing items where f(v) returns truthy
function functional.filter(t, f)
	local r = {}
	for i,v in ipairs(t) do
		if f(v, i) then
			table.insert(r, v)
		end
	end
	return r
end

-- complement of filter
-- returns a table containing items where f(v) returns falsey
-- nil results are included so that this is an exact complement of filter; consider using partition if you need both!
function functional.remove_if(t, f)
	local r = {}
	for i, v in ipairs(t) do
		if not f(v, i) then
			table.insert(r, v)
		end
	end
	return r
end

--partitions a sequence into two, based on filter criteria
--simultaneous filter and remove_if
function functional.partition(t, f)
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

-- returns a table where the elements in t are grouped into sequential tables by the result of f on each element.
-- more general than partition, but requires you to know your groups ahead of time (or use numeric grouping) if you want to avoid pairs!
function functional.group_by(t, f)
	local result = {}
	for i, v in ipairs(t) do
		local group = f(v)
		if result[group] == nil then
			result[group] = {}
		end
		table.insert(result[group], v)
	end
	return result
end

--zips two sequences together into a new table, based on another function
--iteration limited by min(#t1, #t2)
--function receives arguments (t1, t2, i)
--nil results ignored
function functional.zip(t1, t2, f)
	local ret = {}
	local limit = math.min(#t1, #t2)
	for i = 1, limit do
		local v1 = t1[i]
		local v2 = t2[i]
		local zipped = f(v1, v2, i)
		if zipped ~= nil then
			table.insert(ret, zipped)
		end
	end
	return ret
end

-----------------------------------------------------------
--generating data
-----------------------------------------------------------

--generate data into a table
--basically a map on numeric values from 1 to count
--nil values are omitted in the result, as for map
function functional.generate(count, f)
	local r = {}
	for i = 1, count do
		local v = f(i)
		if v ~= nil then
			table.insert(r, v)
		end
	end
	return r
end

--2d version of the above
--note: ends up with a 1d table;
--	if you need a 2d table, nest 1d generate calls
function functional.generate_2d(width, height, f)
	local r = {}
	for y = 1, height do
		for x = 1, width do
			local v = f(x, y)
			if v ~= nil then
				table.insert(r, v)
			end
		end
	end
	return r
end

-----------------------------------------------------------
--common queries and reductions
-----------------------------------------------------------

--true if any element of the table matches f
function functional.any(t, f)
	for i,v in ipairs(t) do
		if f(v) then
			return true
		end
	end
	return false
end

--true if no element of the table matches f
function functional.none(t, f)
	for i,v in ipairs(t) do
		if f(v) then
			return false
		end
	end
	return true
end

--true if all elements of the table match f
function functional.all(t, f)
	for i,v in ipairs(t) do
		if not f(v) then
			return false
		end
	end
	return true
end

--counts the elements of t that match f
function functional.count(t, f)
	local c = 0
	for i,v in ipairs(t) do
		if f(v) then
			c = c + 1
		end
	end
	return c
end

--true if the table contains element e
function functional.contains(t, e)
	for i, v in ipairs(t) do
		if v == e then
			return true
		end
	end
	return false
end

--return the numeric sum of all elements of t
function functional.sum(t)
	return functional.reduce(t, function(a, b)
		return a + b
	end, 0)
end

--return the numeric mean of all elements of t
function functional.mean(t)
	local len = #t
	if len == 0 then
		return 0
	end
	return functional.sum(t) / len
end

--return the minimum and maximum of t in one pass
--or zero for both if t is empty
--	(would perhaps more correctly be math.huge, -math.huge
--	 but that tends to be surprising/annoying in practice)
function functional.minmax(t)
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
function functional.max(t)
	local min, max = functional.minmax(t)
	return max
end

--return the minimum element of t or zero if t is empty
function functional.min(t)
	local min, max = functional.minmax(t)
	return min
end

--return the element of the table that results in the lowest numeric value
--(function receives element and index respectively)
function functional.find_min(t, f)
	local current = nil
	local current_min = math.huge
	for i, e in ipairs(t) do
		local v = f(e, i)
		if v and v < current_min then
			current_min = v
			current = e
		end
	end
	return current
end

--return the element of the table that results in the greatest numeric value
--(function receives element and index respectively)
function functional.find_max(t, f)
	local current = nil
	local current_max = -math.huge
	for i, e in ipairs(t) do
		local v = f(e, i)
		if v and v > current_max then
			current_max = v
			current = e
		end
	end
	return current
end

--alias
functional.find_best = functional.find_max

--return the element of the table that results in the value nearest to the passed value
--todo: optimise as this generates a closure each time
function functional.find_nearest(t, f, v)
	return functional.find_min(t, function(e)
		return math.abs(f(e) - v)
	end)
end

--return the first element of the table that results in a true filter
function functional.find_match(t, f)
	for i,v in ipairs(t) do
		if f(v) then
			return v
		end
	end
	return nil
end

return functional
