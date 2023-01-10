--[[
	functional programming facilities

	be wary of use in performance critical code under luajit

		absolute performance is this module's achilles heel;
		you're generally allocating more garbage than is strictly necessary,
		plus inline anonymous will be re-created each call, which is NYI

		this can be a Bad Thing and means probably this isn't a great module
		to heavily leverage in the middle of your action game's physics update

		but, there are many cases where it matters less than you'd think
		generally, if it wasn't hot enough to get compiled anyway, you're fine

	(if all this means nothing to you, just don't worry about it)
]]

local path = (...):gsub("functional", "")
local tablex = require(path .. "tablex")
local mathx = require(path .. "mathx")

local functional = setmetatable({}, {
	__index = tablex,
})

--the identity function
function functional.identity(v)
	return v
end

--simple sequential iteration, f is called for all elements of t
--f can return non-nil to break the loop (and return the value)
--otherwise returns t for chaining
function functional.foreach(t, f)
	for i = 1, #t do
		local result = f(t[i], i)
		if result ~= nil then
			return result
		end
	end
	return t
end

--performs a left to right reduction of t using f, with seed as the initial value
-- reduce({1, 2, 3}, 0, f) -> f(f(f(0, 1), 2), 3)
-- (but performed iteratively, so no stack smashing)
function functional.reduce(t, seed, f)
	for i = 1, #t do
		seed = f(seed, t[i], i)
	end
	return seed
end

--maps a sequence {a, b, c} -> {f(a), f(b), f(c)}
-- (automatically drops any nils to keep a sequence, so can be used to simultaneously map and filter)
function functional.map(t, f)
	local result = {}
	for i = 1, #t do
		local v = f(t[i], i)
		if v ~= nil then
			table.insert(result, v)
		end
	end
	return result
end

--maps a sequence inplace, modifying it {a, b, c} -> {f(a), f(b), f(c)}
-- (automatically drops any nils, which can be used to simultaneously map and filter)
function functional.map_inplace(t, f)
	local write_i = 0
	local n = #t --cache, so splitting the sequence doesn't stop iteration
	for i = 1, n do
		local v = f(t[i], i)
		if v ~= nil then
			write_i = write_i + 1
			t[write_i] = v
		end
		if i ~= write_i then
			t[i] = nil
		end
	end
	return t
end

--alias
functional.remap = functional.map_inplace

--maps a sequence {a, b, c} -> {a[k], b[k], c[k]}
-- (automatically drops any nils to keep a sequence)
function functional.map_field(t, k)
	local result = {}
	for i = 1, #t do
		local v = t[i][k]
		if v ~= nil then
			table.insert(result, v)
		end
	end
	return result
end

--maps a sequence by a method call
-- if m is a string method name like "position", {a, b} -> {a:m(...), b:m(...)}
-- if m is function reference like player.get_position, {a, b} -> {m(a, ...), m(b, ...)}
-- (automatically drops any nils to keep a sequence)
function functional.map_call(t, m, ...)
	local result = {}
	for i = 1, #t do
		local v = t[i]
		local f = type(m) == "function" and m or v[m]
		v = f(v, ...)
		if v ~= nil then
			table.insert(result, v)
		end
	end
	return result
end

--maps a sequence into a new index space (see functional.map)
-- the function may return an index where the value will be stored in the result
-- if no index (or a nil index) is provided, it will insert as normal
function functional.splat(t, f)
	local result = {}
	for i = 1, #t do
		local v, pos = f(t[i], i)
		if v ~= nil then
			if pos == nil then
				pos = #result + 1
			end
			result[pos] = v
		end
	end
	return result
end

--filters a sequence
-- returns a table containing items where f(v, i) returns truthy
function functional.filter(t, f)
	local result = {}
	for i = 1, #t do
		local v = t[i]
		if f(v, i) then
			table.insert(result, v)
		end
	end
	return result
end

--filters a sequence in place, modifying it
function functional.filter_inplace(t, f)
	local write_i = 0
	local n = #t --cache, so splitting the sequence doesn't stop iteration
	for i = 1, n do
		local v = t[i]
		if f(v, i) then
			write_i = write_i + 1
			t[write_i] = v
		end
		if i ~= write_i then
			t[i] = nil
		end
	end
	return t
end

-- complement of filter
-- returns a table containing items where f(v) returns falsey
-- nil results are included so that this is an exact complement of filter; consider using partition if you need both!
function functional.remove_if(t, f)
	local result = {}
	for i = 1, #t do
		local v = t[i]
		if not f(v, i) then
			table.insert(result, v)
		end
	end
	return result
end

--partitions a sequence into two, based on filter criteria
--simultaneous filter and remove_if
function functional.partition(t, f)
	local a = {}
	local b = {}
	for i = 1, #t do
		local v = t[i]
		if f(v, i) then
			table.insert(a, v)
		else
			table.insert(b, v)
		end
	end
	return a, b
end

-- returns a table where the elements in t are grouped into sequential tables by the result of f on each element.
--	more general than partition, but requires you to know your groups ahead of time
--	(or use numeric grouping and pre-seed) if you want to avoid pairs!
function functional.group_by(t, f)
	local result = {}
	for i = 1, #t do
		local v = t[i]
		local group = f(v, i)
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
--specialised maps
--	(experimental: let me know if you have better names for these!)
-----------------------------------------------------------

--maps a sequence {a, b, c} -> collapse { f(a), f(b), f(c) }
-- (ie results from functions should generally be sequences,
--  which are appended onto each other, resulting in one big sequence)
-- (automatically drops any nils, same as map)
function functional.stitch(t, f)
	local result = {}
	for i, v in ipairs(t) do
		v = f(v, i)
		if v ~= nil then
			if type(v) == "table" then
				for _, e in ipairs(v) do
					table.insert(result, e)
				end
			else
				table.insert(result, v)
			end
		end
	end
	return result
end

--alias
functional.map_stitch = functional.stitch

--maps a sequence {a, b, c} -> { f(a, b), f(b, c), f(c, a) }
-- useful for inter-dependent data
-- (automatically drops any nils, same as map)

function functional.cycle(t, f)
	local result = {}
	for i, a in ipairs(t) do
		local b = t[mathx.wrap(i + 1, 1, #t + 1)]
		local v = f(a, b)
		if v ~= nil then
			table.insert(result, v)
		end
	end
	return result
end

functional.map_cycle = functional.cycle

--maps a sequence {a, b, c} -> { f(a, b), f(b, c) }
-- useful for inter-dependent data
-- (automatically drops any nils, same as map)

function functional.chain(t, f)
	local result = {}
	for i = 2, #t do
		local a = t[i-1]
		local b = t[i]
		local v = f(a, b)
		if v ~= nil then
			table.insert(result, v)
		end
	end
	return result
end

functional.map_chain = functional.chain


-----------------------------------------------------------
--generating data
-----------------------------------------------------------

--generate data into a table
--basically a map on numeric values from 1 to count
--nil values are omitted in the result, as for map
function functional.generate(count, f)
	local result = {}
	for i = 1, count do
		local v = f(i)
		if v ~= nil then
			table.insert(result, v)
		end
	end
	return result
end

--2d version of the above
--note: ends up with a 1d table;
--	if you need a 2d table, you should nest 1d generate calls
function functional.generate_2d(width, height, f)
	local result = {}
	for y = 1, height do
		for x = 1, width do
			local v = f(x, y)
			if v ~= nil then
				table.insert(result, v)
			end
		end
	end
	return result
end

-----------------------------------------------------------
--common queries and reductions
-----------------------------------------------------------

--true if any element of the table matches f
function functional.any(t, f)
	for i = 1, #t do
		if f(t[i], i) then
			return true
		end
	end
	return false
end

--true if no element of the table matches f
function functional.none(t, f)
	for i = 1, #t do
		if f(t[i], i) then
			return false
		end
	end
	return true
end

--true if all elements of the table match f
function functional.all(t, f)
	for i = 1, #t do
		if not f(t[i], i) then
			return false
		end
	end
	return true
end

--counts the elements of t that match f
function functional.count(t, f)
	local c = 0
	for i = 1, #t do
		if f(t[i], i) then
			c = c + 1
		end
	end
	return c
end

--true if the table contains element e
function functional.contains(t, e)
	for i = 1, #t do
		if t[i] == e then
			return true
		end
	end
	return false
end

--return the numeric sum of all elements of t
function functional.sum(t)
	local c = 0
	for i = 1, #t do
		c = c + t[i]
	end
	return c
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
	local n = #t
	if n == 0 then
		return 0, 0
	end
	local max = t[1]
	local min = t[1]
	for i = 2, n do
		local v = t[i]
		min = math.min(min, v)
		max = math.max(max, v)
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
	for i = 1, #t do
		local e = t[i]
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
	for i = 1, #t do
		local e = t[i]
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
--todo: optimise, inline as this generates a closure each time
function functional.find_nearest(t, f, target)
	local current = nil
	local current_min = math.huge
	for i = 1, #t do
		local e = t[i]
		local v = math.abs(f(e, i) - target)
		if v and v < current_min then
			current_min = v
			current = e
			if v == 0 then
				break
			end
		end
	end
	return current
end

--return the first element of the table that results in a true filter
function functional.find_match(t, f)
	for i = 1, #t do
		local v = t[i]
		if f(v) then
			return v
		end
	end
	return nil
end

return functional
