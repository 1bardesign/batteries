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
if ok then
	--we have bit operations module, use the fast path
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
else
	--we don't have bitops, use a slower pure-float path
	local floor = math.floor

	--rgb only (no alpha)
	function colour.pack_rgb(r, g, b)
		local br = floor(0xff * r) % 0x100 * 0x10000
		local bg = floor(0xff * g) % 0x100 * 0x100
		local bb = floor(0xff * b) % 0x100
		return br + bg + bb
	end

	function colour.unpack_rgb(rgb)
		local r = floor(rgb / 0x10000) % 0x100
		local g = floor(rgb / 0x100) % 0x100
		local b = floor(rgb) % 0x100
		return r / 255, g / 255, b / 255
	end

	--argb format (common for shared hex)
	function colour.pack_argb(r, g, b, a)
		local ba = floor(0xff * a) % 0x100 * 0x1000000
		return colour.pack_rgb(r, g, b) + ba
	end

	function colour.unpack_argb(argb)
		local r, g, b = colour.unpack_rgb(argb)
		local a = floor(argb / 0x1000000) % 0x100
		return r, g, b, a / 255
	end

	--rgba format
	function colour.pack_rgba(r, g, b, a)
		local ba = floor(0xff * a) % 0x100
		return colour.pack_rgb(r, g, b) * 0x100 + ba
	end

	function colour.unpack_rgba(rgba)
		local r, g, b = colour.unpack_rgb(floor(rgba / 0x100))
		local a = floor(rgba) % 0x100
		return r, g, b, a
	end
end


-------------------------------------------------------------------------------
-- colour space conversion
-- rgb is the common language for computers
-- but it's useful to have other spaces to work in for us as humans :)

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
	return h / 6, s, l
end

--convert hsv to rgb
--all components are 0-1, hue is fraction of a turn rather than degrees or radians
function colour.hsv_to_rgb(h, s, v)
	--wedge slice
	local w = (math.wrap(h, 0, 1) * 6)
	--chroma
	local c = v * s
	--secondary
	local x = c * (1 - math.abs(w % 2 - 1))
	--match value
	local m = v - c
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

--convert rgb to hsv
function colour.rgb_to_hsv(r, g, b)
	local max, min = math.max(r, g, b), math.min(r, g, b)
	if max == min then return 0, 0, min end
	local v, d = max, max - min
	local s = (max == 0) and 0 or (d / max)
	local h --depends on below
	if max == r then
		h = (g - b) / d
		if g < b then h = h + 6 end
	elseif max == g then
		h = (b - r) / d + 2
	else
		h = (r - g) / d + 4
	end
	return h / 6, s, v
end

--conversion between hsl and hsv
function colour.hsl_to_hsv(h, s, l)
	local v = l + s * math.min(l, 1 - l)
	s = (v == 0) and 0 or (2 * (1 - l / v))
	return h, s, v
end

function colour.hsv_to_hsl(h, s, v)
	local l = v * (1 - s / 2)
	s = (l == 0 or l == 1) and 0 or ((v - l) / math.min(l, 1 - l))
	return h, s, l
end

--oklab https://bottosson.github.io/posts/oklab/
function colour.oklab_to_rgb(l, a, b)
	local _l = l + 0.3963377774 * a + 0.2158037573 * b
	local _m = l - 0.1055613458 * a - 0.0638541728 * b
	local _s = l - 0.0894841775 * a - 1.2914855480 * b

	_l = math.pow(_l, 3.0)
	_m = math.pow(_m, 3.0)
	_s = math.pow(_s, 3.0)

	local red, green, blue = love.math.linearToGamma(
		( 4.0767245293 * _l - 3.3072168827 * _m + 0.2307590544 * _s),
		(-1.2681437731 * _l + 2.6093323231 * _m - 0.3411344290 * _s),
		(-0.0041119885 * _l - 0.7034763098 * _m + 1.7068625689 * _s)
	)
	return red, green, blue
end

function colour.rgb_to_oklab(red, green, blue)
	red, green, blue = love.math.gammaToLinear(red, green, blue)

	local _l = 0.4121656120 * red + 0.5362752080 * green + 0.0514575653 * blue
	local _m = 0.2118591070 * red + 0.6807189584 * green + 0.1074065790 * blue
	local _s = 0.0883097947 * red + 0.2818474174 * green + 0.6302613616 * blue

	_l = math.pow(_l, 1.0 / 3.0)
	_m = math.pow(_m, 1.0 / 3.0)
	_s = math.pow(_s, 1.0 / 3.0)

	local l = 0.2104542553 * _l + 0.7936177850 * _m - 0.0040720468 * _s
	local a = 1.9779984951 * _l - 2.4285922050 * _m + 0.4505937099 * _s
	local b = 0.0259040371 * _l + 0.7827717662 * _m - 0.8086757660 * _s

	return l, a, b
end

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
