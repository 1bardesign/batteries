--[[
	colour handling stuff
]]

local path = (...):gsub("colour", "")


local math = require(path.."mathx")

local colour = {}

-------------------------------------------------------------------------------
-- hex handling routines
-- pack and unpack into 24 or 32 bit hex numbers

local ok, bit = pcall(require, "bit")
if not ok then
	for _, v in ipairs{
		"pack_rgb",
		"unpack_rgb",
		"pack_argb",
		"unpack_argb",
		"pack_rgba",
		"unpack_rgba",
	} do
		colour[v] = function()
			error(
				"batteries.colour requires the bit operations module for pack/unpack functionality.\n"
				.."\tsee https://bitop.luajit.org/\n\n"
				.."error from require(\"bit\"):\n\n"..bit)
		end
	end
else
	local band, bor = bit.band, bit.bor
	local lshift, rshift = bit.lshift, bit.rshift

	--rgb only (no alpha)

	function colour.pack_rgb(r, g, b)
		local br = lshift(band(0xff, r * 255), 16)
		local bg = lshift(band(0xff, g * 255), 8)
		local bb = lshift(band(0xff, b * 255), 0)
		return bor( br, bg, bb )
	end

	function colour.unpack_rgb(rgb)
		local r = rshift(band(rgb, 0x00ff0000), 16) / 255
		local g = rshift(band(rgb, 0x0000ff00), 8)  / 255
		local b = rshift(band(rgb, 0x000000ff), 0)  / 255
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
		local r = rshift(band(argb, 0x00ff0000), 16) / 255
		local g = rshift(band(argb, 0x0000ff00), 8)  / 255
		local b = rshift(band(argb, 0x000000ff), 0)  / 255
		local a = rshift(band(argb, 0xff000000), 24) / 255
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
		local r = rshift(band(rgba, 0xff000000), 24) / 255
		local g = rshift(band(rgba, 0x00ff0000), 16) / 255
		local b = rshift(band(rgba, 0x0000ff00), 8)  / 255
		local a = rshift(band(rgba, 0x000000ff), 0)  / 255
		return r, g, b, a
	end
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

--convert rgb to hsl
function colour.rgb_to_hsl(r, g, b)
	local max, min = math.max(r, g, b), math.min(r, g, b)
	if max == min then return 0, 0, min end

	local l, d = max + min, max - min
	local s = d / (l > 1 and (2 - l) or l)
	l = l / 2
	local h --depends on below
	if max == r then
		h = (g - b) / d
		if g < b then h = h + 6 end
	elseif max == g then
		h = (b - r) / d + 2
	else
		h = (r - g) / d + 4
	end
	assert(h)
	return h / 6, s, l
end

--todo: hsv, other colour spaces
--todo: oklab https://bottosson.github.io/posts/oklab/

--colour distance functions
--distance of one colour to another (linear space)
--can be used for finding nearest colours for palette mapping, for example

function colour.distance_rgb(
	ar, ag, ab,
	br, bg, bb
)
	local dr, dg, db = ar - br, ag - bg, ab - bb
	return math.sqrt(dr * dr + dg * dg + db * db)
end

function colour.distance_packed_rgb(a, b)
	local ar, ag, ab = colour.unpack_rgb(a)
	local br, bg, bb = colour.unpack_rgb(b)
	return colour.distance_rgb(
		ar, ag, ab,
		br, bg, bb
	)
end

--todo: rgba and various other unpacks

return colour
