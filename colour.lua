--[[
	colour handling stuff
]]

local path = (...):gsub("colour", "")

local bit = require("bit")
local band, bor = bit.band, bit.bor
local lshift, rshift = bit.lshift, bit.rshift

local math = require(path.."mathx")

local colour = {}

-------------------------------------------------------------------------------
-- hex handling routines
-- pack and unpack into 24 or 32 bit hex numbers

--rgb only (no alpha)

function colour.pack_rgb(r, g, b)
	local br = lshift(band(0xff, r * 255), 16)
	local bg = lshift(band(0xff, g * 255), 8)
	local bb = lshift(band(0xff, b * 255), 0)
	return bor( br, bg, bb )
end

function colour.unpack_rgb(rgb)
	local r = rshift(band(rgb, 0x00ff0000), 16) / 255.0
	local g = rshift(band(rgb, 0x0000ff00), 8)  / 255.0
	local b = rshift(band(rgb, 0x000000ff), 0)  / 255.0
	return r, g, b
end

--argb format (common for shared hex)

function colour.pack_argb(r, g, b, a)
	local ba = lshift(band(0xff, a * 255), 24)
	local br = lshift(band(0xff, r * 255), 16)
	local bg = lshift(band(0xff, g * 255), 8)
	local bb = lshift(band(0xff, b * 255), 0)
	return bor( br, bg, bb, ba )
end

function colour.unpack_argb(argb)
	local r = rshift(band(argb, 0x00ff0000), 16) / 255.0
	local g = rshift(band(argb, 0x0000ff00), 8)  / 255.0
	local b = rshift(band(argb, 0x000000ff), 0)  / 255.0
	local a = rshift(band(argb, 0xff000000), 24) / 255.0
	return r, g, b, a
end

--rgba format

function colour.pack_rgba(r, g, b, a)
	local br = lshift(band(0xff, r * 255), 24)
	local bg = lshift(band(0xff, g * 255), 16)
	local bb = lshift(band(0xff, b * 255), 8)
	local ba = lshift(band(0xff, a * 255), 0)
	return bor( br, bg, bb, ba )
end

function colour.unpack_rgba(rgba)
	local r = rshift(band(rgba, 0xff000000), 24) / 255.0
	local g = rshift(band(rgba, 0x00ff0000), 16) / 255.0
	local b = rshift(band(rgba, 0x0000ff00), 8)  / 255.0
	local a = rshift(band(rgba, 0x000000ff), 0)  / 255.0
	return r, g, b, a
end

-------------------------------------------------------------------------------
-- colour space conversion
-- rgb is the common language but it's useful to have other spaces to work in
-- for us as humans :)

--convert hsl to rgb
--all components are 0-1, hue is fraction of a turn rather than degrees or radians
function colour.hsl_to_rgb(h, s, l)
	--wedge slice
	local w = (math.wrap(h, 0, 1) * 6)
	--chroma
	local c = (1 - math.abs(2 * l - 1)) * s
	--secondary
	local x = c * (1 - math.abs(w % 2 - 1))
	--lightness boost
	local m = l - c / 2
	--per-wedge logic
	local r, g, b = m, m, m
	if w < 1 then
		r = r + c
		g = g + x
	elseif w < 2 then
		r = r + x
		g = g + c
	elseif w < 3 then
		g = g + c
		b = b + x
	elseif w < 4 then
		g = g + x
		b = b + c
	elseif w < 5 then
		b = b + c
		r = r + x
	else
		b = b + x
		r = r + c
	end
	return r, g, b
end

-------------------------------------------------------------------------------
--convert hex to rgb
function colour.hex2RGB(hex)
	local h = h:gsub("#", "")
	local r = tonumber("0x" .. h:sub(1, 2))
	local g = tonumber("0x" .. h:sub(3, 4))
	local b = tonumber("0x" .. h:sub(5, 6))
	return r, g, b
end

--todo: hsl, hsv, other colour spaces
--todo: rgb to hsl
--todo: hsv, other colour spaces

return colour
