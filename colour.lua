--[[
	colour handling stuff

	feel free to alias to `color` :)
]]

local bit = require("bit")
local band, bor = bit.band, bit.bor
local lshift, rshift = bit.lshift, bit.rshift

local colour = {}

function colour.packRGB(r, g, b)
	local br = lshift(band(0xff, r * 255), 16)
	local bg = lshift(band(0xff, g * 255), 8)
	local bb = lshift(band(0xff, b * 255), 0)
	return bor( br, bg, bb )
end

function colour.packARGB(r, g, b, a)
	local ba = lshift(band(0xff, a * 255), 24)
	local br = lshift(band(0xff, r * 255), 16)
	local bg = lshift(band(0xff, g * 255), 8)
	local bb = lshift(band(0xff, b * 255), 0)
	return bor( br, bg, bb, ba )
end

function colour.packRGBA(r, g, b, a)
	local br = lshift(band(0xff, r * 255), 24)
	local bg = lshift(band(0xff, g * 255), 16)
	local bb = lshift(band(0xff, b * 255), 8)
	local ba = lshift(band(0xff, a * 255), 0)
	return bor( br, bg, bb, ba )
end

function colour.unpackARGB(argb)
	local r = rshift(band(argb, 0x00ff0000), 16) / 255.0
	local g = rshift(band(argb, 0x0000ff00), 8)  / 255.0
	local b = rshift(band(argb, 0x000000ff), 0)  / 255.0
	local a = rshift(band(argb, 0xff000000), 24) / 255.0
	return r, g, b, a
end

function colour.unpackRGBA(rgba)
	local r = rshift(band(rgba, 0xff000000), 24) / 255.0
	local g = rshift(band(rgba, 0x00ff0000), 16) / 255.0
	local b = rshift(band(rgba, 0x0000ff00), 8)  / 255.0
	local a = rshift(band(rgba, 0x000000ff), 0)  / 255.0
	return r, g, b, a
end

function colour.unpackRGB(rgb)
	local r = rshift(band(rgb, 0x00ff0000), 16) / 255.0
	local g = rshift(band(rgb, 0x0000ff00), 8)  / 255.0
	local b = rshift(band(rgb, 0x000000ff), 0)  / 255.0
	local a = 1.0
	return r, g, b, a
end

--todo: hsl, hsv, other colour spaces

return colour