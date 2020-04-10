--[[
	extra table routines
]]

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

--insert to the back of a table
function tablex.push(t, v)
	return table.insert(t, v)
end

--remove the front element of a table and return it
function tablex.shift(t)
	return table.remove(t, 1)
end

--insert to the front of a table
function tablex.unshift(t, v)
	return table.insert(t, 1, v)
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
		assert(type(t) == "table", "table.clear - argument 't' must be a table")
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
	assert(type(t) == "table", "table.copy - argument 't' must be a table")
	local is_bool = type(deep_or_into) == "boolean"
	local istablex = type(deep_or_into) == "table"

	local deep = (is_bool and deep_or_into) or istablex
	local into = istablex and deep_or_into or {}
	for k,v in pairs(t) do
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

--overlay one table directly onto another, shallow only
function tablex.overlay(to, from)
	assert(type(to) == "table", "table.overlay - argument 'to' must be a table")
	assert(type(from) == "table", "table.overlay - argument 'from' must be a table")
	for k,v in pairs(from) do
		to[k] = v
	end
	return to
end

--turn a table into a vaguely easy to read string
--which is also able to be parsed by lua in most cases
function tablex.stringify(t)
	--if the input is not a table, or it has a tostring metamethod
	--just use tostring
	local mt = getmetatable(t)
	if type(t) ~= "table" or mt and mt.__tostring then
		return tostring(t)
	end

	--otherwise, collate into member chunks
	local chunks = {}
	--(tracking for already-seen elements from ipairs)
	local seen = {}
	--sequential part first
	for i, v in ipairs(t) do
		seen[i] = true
		table.insert(chunks, tablex.stringify(v))
	end
	--non sequential follows
	for k, v in pairs(t) do
		if not seen[k] then
			--encapsulate anything that's not a string
			--todo: also keywords
			if type(k) ~= "string" then
				k = "[" .. tostring(k) .. "]"
			end
			table.insert(chunks, k .. " = " .. tablex.stringify(v))
		end
	end
	return "{" .. table.concat(chunks, ", ") .. "}"
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