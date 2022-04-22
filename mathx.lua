--[[
	extra mathematical functions
]]

local mathx = setmetatable({}, {
	__index = math,
})

--wrap v around range [lo, hi)
function mathx.wrap(v, lo, hi)
	return (v - lo) % (hi - lo) + lo
end

--wrap i around the indices of t
function mathx.wrap_index(i, t)
	return math.floor(mathx.wrap(i, 1, #t + 1))
end

--clamp v to range [lo, hi]
function mathx.clamp(v, lo, hi)
	return math.max(lo, math.min(v, hi))
end

--clamp v to range [0, 1]
function mathx.clamp01(v)
	return mathx.clamp(v, 0, 1)
end

--round v to nearest whole, away from zero
function mathx.round(v)
	if v < 0 then
		return math.ceil(v - 0.5)
	end
	return math.floor(v + 0.5)
end

--round v to one-in x
-- (eg x = 2, v rounded to increments of 0.5)
function mathx.to_one_in(v, x)
	return mathx.round(v * x) / x
end

--round v to a given decimal precision
function mathx.to_precision(v, decimal_points)
	return mathx.to_one_in(v, math.pow(10, decimal_points))
end

--0, 1, -1 sign of a scalar
--todo: investigate if a branchless or `/abs` approach is faster in general case
function mathx.sign(v)
	if v < 0 then return -1 end
	if v > 0 then return 1 end
	return 0
end

--linear interpolation between a and b
function mathx.lerp(a, b, t)
	return a * (1.0 - t) + b * t
end

--linear interpolation with a minimum "final step" distance
--useful for making sure dynamic lerps do actually reach their final destination
function mathx.lerp_eps(a, b, t, eps)
	local v = mathx.lerp(a, b, t)
	if math.abs(v - b) < eps then
		v = b
	end
	return v
end

--bilinear interpolation between 4 samples
function mathx.bilerp(a, b, c, d, u, v)
	return mathx.lerp(
		mathx.lerp(a, b, u),
		mathx.lerp(c, d, u),
		v
	)
end

--easing curves
--(generally only "safe" for 0-1 range, see mathx.clamp01)

--classic smoothstep
function mathx.smoothstep(f)
	return f * f * (3 - 2 * f)
end

--classic smootherstep; zero 2nd order derivatives at 0 and 1
function mathx.smootherstep(f)
	return f * f * f * (f * (f * 6 - 15) + 10)
end

--pingpong from 0 to 1 and back again
function mathx.pingpong(f)
	return 1 - math.abs(f - 0.5) * 2
end

--quadratic ease in
function mathx.ease_in(f)
	return f * f
end

--quadratic ease out
function mathx.ease_out(f)
	local oneminus = (1 - f)
	return 1 - oneminus * oneminus
end

--quadratic ease in and out
--(a lot like smoothstep)
function mathx.ease_inout(f)
	if f < 0.5 then
		return f * f * 2
	end
	local oneminus = (1 - f)
	return 1 - 2 * oneminus * oneminus
end

--branchless but imperfect quartic in/out
--either smooth or smootherstep are usually a better alternative
function mathx.ease_inout_branchless(f)
	local halfsquared = f * f / 2
	return halfsquared * (1 - halfsquared) * 4
end

--todo: more easings - back, bounce, elastic

--(internal; use a provided random generator object, or not)
local function _random(rng, ...)
	if rng then return rng:random(...) end
	if love then return love.math.random(...) end
	return math.random(...)
end

--return a random sign
function mathx.random_sign(rng)
	return _random(rng) < 0.5 and -1 or 1
end

--return a random value between two numbers (continuous)
function mathx.random_lerp(min, max, rng)
	return mathx.lerp(min, max, _random(rng))
end

--nan checking
function mathx.isnan(v)
	return v ~= v
end

--angle handling stuff
--superior constant handy for expressing things in turns
mathx.tau = math.pi * 2

--normalise angle onto the interval [-math.pi, math.pi)
--so each angle only has a single value representing it
function mathx.normalise_angle(a)
	return mathx.wrap(a, -math.pi, math.pi)
end

--alias for americans
mathx.normalize_angle = mathx.normalise_angle

--get the normalised difference between two angles
function mathx.angle_difference(a, b)
	a = mathx.normalise_angle(a)
	b = mathx.normalise_angle(b)
	return mathx.normalise_angle(b - a)
end

--mathx.lerp equivalent for angles
function mathx.lerp_angle(a, b, t)
	local dif = mathx.angle_difference(a, b)
	return mathx.normalise_angle(a + dif * t)
end

--mathx.lerp_eps equivalent for angles
function mathx.lerp_angle_eps(a, b, t, eps)
	--short circuit to avoid having to wrap so many angles
	if a == b then
		return a
	end
	--same logic as lerp_eps
	local v = mathx.lerp_angle(a, b, t)
	if math.abs(mathx.angle_difference(v, b)) < eps then
		v = b
	end
	return v
end

--geometric functions standalone/"unpacked" components and multi-return
--consider using vec2 if you need anything complex!

--rotate a point around the origin by an angle
function mathx.rotate(x, y, r)
	local s = math.sin(r)
	local c = math.cos(r)
	return c * x - s * y, s * x + c * y
end

--get the length of a vector from the origin
function mathx.length(x, y)
	return math.sqrt(x * x + y * y)
end

--get the distance between two points
function mathx.distance(x1, y1, x2, y2)
	local dx = x1 - x2
	local dy = y1 - y2
	return mathx.length(dx, dy)
end

return mathx
