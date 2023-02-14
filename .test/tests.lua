-- Run this file with testy from within batteries
--	  testy.lua .tests/tests.lua
-- testy sets `...` to "module.test", so ignore that and use module top-level paths.
package.path = package.path .. ";../?.lua"

local assert = require("batteries.assert")
local tablex = require("batteries.tablex")
local identifier = require("batteries.identifier")
local stringx = require("batteries.stringx")

-- tablex {{{

local function test_shallow_copy()
	local x,r
	x = { a = 1, b = 2, c = 3 }
	r = tablex.shallow_copy(x)
	assert:equal(r.a, 1)
	assert:equal(r.b, 2)
	assert:equal(r.c, 3)

	x = { a = { b = { 2 }, c = { 3 }, } }
	r = tablex.shallow_copy(x)
	assert:equal(r.a, x.a)
end

local function test_deep_copy()
	local x,r
	x = { a = 1, b = 2, c = 3 }
	r = tablex.deep_copy(x)
	assert:equal(r.a, 1)
	assert:equal(r.b, 2)
	assert:equal(r.c, 3)

	x = { a = { b = { 2 }, c = { 3 }, } }
	r = tablex.deep_copy(x)
	assert(r.a ~= x.a)
	assert:equal(r.a.b[1], 2)
	assert:equal(r.a.c[1], 3)
end


local function test_shallow_overlay()
	local x,y,r
	x = { a = 1, b = 2, c = 3 }
	y = { c = 8, d = 9 }
	r = tablex.shallow_overlay(x, y)
	assert(
		tablex.deep_equal(
			r,
			{ a = 1, b = 2, c = 8, d = 9 }
		)
	)

	x = { b = { 2 }, c = { 3 }, }
	y = { c = { 8 }, d = { 9 }, }
	r = tablex.shallow_overlay(x, y)
	assert(r.b == x.b)
	assert(r.c == y.c)
	assert(r.d == y.d)
	assert(
		tablex.deep_equal(
			r,
			{ b = { 2 }, c = { 8 }, d = { 9 }, }
		)
	)
end

local function test_deep_overlay()
	local x,y,r
	x = { a = 1, b = 2, c = 3 }
	y = { c = 8, d = 9 }
	r = tablex.deep_overlay(x, y)
	assert(
		tablex.deep_equal(
			r,
			{ a = 1, b = 2, c = 8, d = 9 }
		)
	)

	x = { a = { b = { 2 }, c = { 3 }, } }
	y = { a = { c = { 8 }, d = { 9 }, } }
	r = tablex.deep_overlay(x, y)
	assert(
		tablex.deep_equal(
			r,
			{ a = { b = { 2 }, c = { 8 }, d = { 9 }, } }
		)
	)
end


local function test_shallow_equal()
	local x,y
	x = { a = { b = { 2 }, } }
	y = { a = { b = { 2 }, } }
	assert(not tablex.shallow_equal(x, y))

	x = { 3, 4, "hello", [20] = "end", }
	y = { 3, 4, "hello", [20] = "end", }
	assert(tablex.shallow_equal(x, y))

	local z = { 1, 2, }
	x = { a = z, b = 10, c = true, }
	y = { a = z, b = 10, c = true, }
	assert(tablex.shallow_equal(x, y))
	assert(tablex.shallow_equal(y, x))
end

local function test_deep_equal()
	local x,y
	x = { a = { b = { 2 }, c = { 3 }, } }
	y = { a = { b = { 2 }, c = { 3 }, } }
	assert(tablex.deep_equal(x, y))

	x = { a = { b = { 1, 2 }, c = { 3 }, } }
	y = { a = { c = { 3 }, b = { [2] = 2, [1] = 1 }, } }
	assert(tablex.deep_equal(x, y))
	assert(tablex.deep_equal(y, x))

	x = { a = { b = { 2 }, c = { 3 }, 2 } }
	y = { a = { b = { 2 }, c = { 3 }, } }
	assert(not tablex.deep_equal(x, y))
	assert(not tablex.deep_equal(y, x))
end

local function test_spairs()
	local t = {
		player1 = {
			name = "Joe",
			score = 8
		},
		player2 = {
			name = "Robert",
			score = 7
		},
		player3 = {
			name = "John",
			score = 10
		}
	}

	local sorted_names = {}
	local sorted_score = {}

	for k, v in tablex.spairs(t, function(a, b)
		return t[a].score > t[b].score
	end) do
		tablex.push(sorted_names, v.name)
		tablex.push(sorted_score, v.score)
	end

	assert(tablex.deep_equal(sorted_names, {
		"John", "Joe", "Robert"
	}))

	assert(tablex.deep_equal(sorted_score, {
		10, 8, 7
	}))
end

local function test_uuid4()
	for i = 1, 5 do
		local id = identifier.uuid4()

		-- right len
		assert(#id == 36)
		-- right amount of non hyphen characters
		assert(#id:gsub("-", "") == 32)

		-- 15th char is always a 4
		assert(id:sub(15, 15) == "4")
		-- 20th char is always between 0x8 and 0xb
		local y = tonumber("0x" .. id:sub(20, 20))
		assert(y >= 0x8 and y <= 0xb)

		-- everything is a valid 8 bit num
		for char in id:gsub("-", ""):gmatch(".") do
			local num = assert(tonumber("0x" .. char))
			assert(num >= 0 and num <= 0xf)
		end
	end
end

local function test_ulid()
	-- bail if there's no appropriate time func
	if select(2, pcall(identifier.ulid)):find('time function') then return end

	for i = 1, 5 do
		local ulid = assert(identifier.ulid())

		-- right len
		assert(#ulid == 26)
		-- have the same timestamp with the same time
		local a, b = identifier.ulid(nil, 1):sub(1, 10), identifier.ulid(nil, 1):sub(1, 10)
		assert(a == b)
		-- don't have characters out of crockford base32
		assert(not ulid:match("[ILOU%l]"))
	end
end

-- stringx
local function test_title_case()
    local str = "the quick brown fox jumps over the lazy dog"

    assert(stringx.title_case(str) == "The Quick Brown Fox Jumps Over The Lazy Dog")
end
