-- Run this file with testy:
--	  testy.lua tests.lua
-- testy sets `...` to "module.test", so ignore that and use module top-level paths.
package.path = package.path .. ";../?.lua"

local assert = require("batteries.assert")
local tablex = require("batteries.tablex")


-- tablex {{{

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

