--[[
	geometric intersection routines

	from simple point tests to shape vs shape tests

	optimised pretty well in most places

	tests provided:
		overlap
			boolean "is overlapping"
		collide
			nil for no collision
			minimum separating vector on collision
				provided in the direction of the first object
			optional output parameters to avoid garbage generation
]]

local path = (...):gsub("intersect", "")
local vec2 = require(path .. "vec2")
local mathx = require(path .. "mathx")

--module storage
local intersect = {}

--epsilon for collisions
local COLLIDE_EPS = 1e-6

------------------------------------------------------------------------------
-- circles

function intersect.circle_point_overlap(pos, rad, v)
	return pos:distance_squared(v) <= rad * rad
end

function intersect.circle_circle_overlap(a_pos, a_rad, b_pos, b_rad)
	local rad = a_rad + b_rad
	return a_pos:distance_squared(b_pos) <= rad * rad
end

function intersect.circle_circle_collide(a_pos, a_rad, b_pos, b_rad, into)
	--get delta
	local delta = a_pos
		:pooled_copy()
		:vector_sub_inplace(b_pos)
	--squared threshold
	local rad = a_rad + b_rad
	local dist = delta:length_squared()
	local res = false
	if dist <= rad * rad then
		if dist == 0 then
			--singular case; just resolve vertically
			dist = 1
			delta:scalar_set(0, 1)
		else
			--get actual distance
			dist = math.sqrt(dist)
		end
		--allocate if needed
		if into == nil then
			into = vec2(0)
		end
		--normalise, scale to separating distance
		res = into:set(delta)
			:scalar_div_inplace(dist)
			:scalar_mul_inplace(rad - dist)
	end
	delta:release()
	return res
end

function intersect.circle_point_collide(a_pos, a_rad, b, into)
	return intersect.circle_circle_collide(a_pos, a_rad, b, 0, into)
end

------------------------------------------------------------------------------
-- line segments
-- todo: separate double-sided, one-sided, and pull-through (along normal) collisions?

--get the nearest point on the line segment a from point b
function intersect.nearest_point_on_line(a_start, a_end, b_pos, into)
	if into == nil then into = vec2(0) end
	--direction of segment
	local segment = a_end:pooled_copy()
		:vector_sub_inplace(a_start)
	--detect degenerate case
	local lensq = segment:length_squared()
	if lensq <= COLLIDE_EPS then
		into:set(a_start)
	else
		--solve for factor along segment
		local point_to_start = b_pos:pooled_copy()
			:vector_sub_inplace(a_start)
		local factor = mathx.clamp01(point_to_start:dot(segment) / lensq)
		into:set(segment)
			:scalar_mul_inplace(factor)
			:vector_add_inplace(a_start)
		point_to_start:release()
	end
	segment:release()
	return into
end

--internal
--vector from line seg origin to point
function intersect._line_to_point(a_start, a_end, b_pos, into)
	return intersect.nearest_point_on_line(a_start, a_end, b_pos, into)
		:vector_sub_inplace(b_pos)
end

--internal
--line displacement vector from separation vector
function intersect._line_displacement_to_sep(a_start, a_end, separation, total_rad)
	local distance = separation:normalise_len_inplace()
	local sep = distance - total_rad
	if sep <= 0 then
		if distance <= COLLIDE_EPS then
			--point intersecting the line; push out along normal
			separation:set(a_end)
				:vector_sub_inplace(a_start)
				:normalise_inplace()
				:rot90l_inplace()
		else
			separation:scalar_mul_inplace(-sep)
		end
		return separation
	end
	return false
end

--overlap a line segment with a circle
function intersect.line_circle_overlap(a_start, a_end, a_rad, b_pos, b_rad)
	local nearest = intersect.nearest_point_on_line(a_start, a_end, b_pos, vec2:pooled())
	local overlapped = intersect.circle_point_overlap(b_pos, a_rad + b_rad, nearest)
	nearest:release()
	return overlapped
end

--collide a line segment with a circle
function intersect.line_circle_collide(a_start, a_end, a_rad, b_pos, b_rad, into)
	local nearest = intersect.nearest_point_on_line(a_start, a_end, b_pos, vec2:pooled())
	into = intersect.circle_circle_collide(nearest, a_rad, b_pos, b_rad, into)
	nearest:release()
	return into
end

--collide 2 line segments
local _line_line_search_tab = {
	{vec2(), 1},
	{vec2(), 1},
	{vec2(), -1},
	{vec2(), -1},
}
function intersect.line_line_collide(a_start, a_end, a_rad, b_start, b_end, b_rad, into)
	--segment directions from start points
	local a_dir = a_end
		:pooled_copy()
		:vector_sub_inplace(a_start)
	local b_dir = b_end
		:pooled_copy()
		:vector_sub_inplace(b_start)

	--detect degenerate cases
	local a_degen = a_dir:length_squared() <= COLLIDE_EPS
	local b_degen = b_dir:length_squared() <= COLLIDE_EPS
	if a_degen or b_degen then
		vec2.release(a_dir, b_dir)
		if a_degen and b_degen then
			--actually just circles
			return intersect.circle_circle_collide(a_start, a_rad, b_start, b_rad, into)
		elseif a_degen then
			--a is just circle
			return intersect.circle_line_collide(a_start, a_rad, b_start, b_end, b_rad, into)
		elseif b_degen then
			--b is just circle
			return intersect.line_circle_collide(a_start, a_end, a_rad, b_start, b_rad, into)
		else
			error("should be unreachable")
		end
	end
	--otherwise we're _actually_ 2 line segs :)
	if into == nil then into = vec2(0) end

	--first, check intersection

	--(c to lua translation of paul bourke's
	-- line intersection algorithm)
	local dx1 =  (a_end.x   - a_start.x)
	local dx2 =  (b_end.x   - b_start.x)
	local dy1 =  (a_end.y   - a_start.y)
	local dy2 =  (b_end.y   - b_start.y)
	local dxab = (a_start.x - b_start.x)
	local dyab = (a_start.y - b_start.y)

	local denom  = dy2 * dx1  - dx2 * dy1
	local numera = dx2 * dyab - dy2 * dxab
	local numerb = dx1 * dyab - dy1 * dxab

	--check coincident lines
	local intersected
	if
		math.abs(numera) == 0 and
		math.abs(numerb) == 0 and
		math.abs(denom) == 0
	then
		intersected = "both"
	else
		--check parallel, non-coincident lines
		if math.abs(denom) == 0 then
			intersected = "none"
		else
			--get interpolants along segments
			local mua = numera / denom
			local mub = numerb / denom
			--intersection outside segment bounds?
			local outside_a = mua < 0 or mua > 1
			local outside_b = mub < 0 or mub > 1
			if outside_a and outside_b then
				intersected = "none"
			elseif outside_a then
				intersected = "b"
			elseif outside_b then
				intersected = "a"
			else
				intersected = "both"
			end
		end
	end
	assert(intersected)

	if intersected == "both" then
		--simply displace along A normal
		into:set(a_dir)
		vec2.release(a_dir, b_dir)
		return into
			:normalise_inplace()
			:scalar_mul_inplace(a_rad + b_rad)
			:rot90l_inplace()
	end

	vec2.release(a_dir, b_dir)

	--dumb as a rocks check-corners approach
	--todo proper calculus from http://geomalgorithms.com/a07-_distance.html
	local search_tab = _line_line_search_tab
	for i = 1, 4 do
		search_tab[i][1]:sset(math.huge)
	end
	--only insert corners from the non-intersected line
	--since intersected line is potentially the apex
	if intersected ~= "a" then
		--a endpoints
		intersect._line_to_point(b_start, b_end, a_start, search_tab[1][1])
		intersect._line_to_point(b_start, b_end, a_end, search_tab[2][1])
	end
	if intersected ~= "b" then
		--b endpoints
		intersect._line_to_point(a_start, a_end, b_start, search_tab[3][1])
		intersect._line_to_point(a_start, a_end, b_end, search_tab[4][1])
	end

	local best = nil
	local best_len = nil
	for _, v in ipairs(search_tab) do
		local delta = v[1]
		if delta.x ~= math.huge then
			local len = delta:length_squared()
			if len < (best_len or math.huge) then
				best = v
			end
		end
	end

	--fix direction
	into:set(best[1])
		:scalar_mul_inplace(best[2])

	return intersect._line_displacement_to_sep(a_start, a_end, into, a_rad + b_rad)
end

------------------------------------------------------------------------------
-- axis aligned bounding boxes
--
--	pos is the centre position of the box
--	hs is the half-size of the box
--		eg for a 10x8 box, vec2(5, 4)
--
--	we use half-sizes to keep these routines as fast as possible
--	see intersect.rect_to_aabb for conversion from topleft corner and size

--return true on overlap, false otherwise
function intersect.aabb_point_overlap(pos, hs, v)
	local delta = pos
		:pooled_copy()
		:vector_sub_inplace(v)
		:abs_inplace()
	local overlap = delta.x <= hs.x and delta.y <= hs.y
	delta:release()
	return overlap
end

-- discrete displacement
-- return msv to push point to closest edge of aabb
function intersect.aabb_point_collide(pos, hs, v, into)
	--separation between centres
	local delta_c = v
		:pooled_copy()
		:vector_sub_inplace(pos)
	--absolute separation
	local delta_c_abs = delta_c
		:pooled_copy()
		:abs_inplace()
	local res = false
	if delta_c_abs.x < hs.x and delta_c_abs.y < hs.y then
		res = (into or vec2(0))
			--separating offset in both directions
			:set(hs)
			:vector_sub_inplace(delta_c_abs)
			--minimum separating distance
			:minor_inplace()
			--in the right direction
			:vector_mul_inplace(delta_c:sign_inplace())
			--from the aabb's point of view
			:inverse_inplace()
	end
	vec2.release(delta_c, delta_c_abs)
	return res
end

--return true on overlap, false otherwise
function intersect.aabb_aabb_overlap(a_pos, a_hs, b_pos, b_hs)
	local delta = a_pos
		:pooled_copy()
		:vector_sub_inplace(b_pos)
		:abs_inplace()
	local total_size = a_hs
		:pooled_copy()
		:vector_add_inplace(b_hs)
	local overlap = delta.x <= total_size.x and delta.y <= total_size.y
	vec2.release(delta, total_size)
	return overlap
end

--discrete displacement
--return msv on collision, false otherwise
function intersect.aabb_aabb_collide(a_pos, a_hs, b_pos, b_hs, into)
	local delta = a_pos
		:pooled_copy()
		:vector_sub_inplace(b_pos)
	local abs_delta = delta
		:pooled_copy()
		:abs_inplace()
	local size = a_hs
		:pooled_copy()
		:vector_add_inplace(b_hs)
	local abs_amount = size
		:pooled_copy()
		:vector_sub_inplace(abs_delta)
	local res = false
	if abs_amount.x > COLLIDE_EPS and abs_amount.y > COLLIDE_EPS then
		if not into then into = vec2(0) end
		--actually collided
		if abs_amount.x <= abs_amount.y then
			--x min
			res = into:scalar_set(abs_amount.x * mathx.sign(delta.x), 0)
		else
			--y min
			res = into:scalar_set(0, abs_amount.y * mathx.sign(delta.y))
		end
	end
	return res
end

-- helper function to clamp point to aabb
function intersect.aabb_point_clamp(pos, hs, v, into)
	local v_min = pos
		:pooled_copy()
		:vector_sub_inplace(hs)
	local v_max = pos
		:pooled_copy()
		:vector_add_inplace(hs)
	into = into or vec2(0)
	into:set(v)
		:clamp_inplace(v_min, v_max)
	vec2.release(v_min, v_max)
	return into
end

-- return true on overlap, false otherwise
function intersect.aabb_circle_overlap(a_pos, a_hs, b_pos, b_rad)
	local clamped = intersect.aabb_point_clamp(a_pos, a_hs, b_pos, vec2:pooled())
	local edge_distance_squared = clamped:distance_squared(b_pos)
	clamped:release()
	return edge_distance_squared <= (b_rad * b_rad)
end

-- return msv on collision, false otherwise
function intersect.aabb_circle_collide(a_pos, a_hs, b_pos, b_rad, into)
	local abs_delta = a_pos
		:pooled_copy()
		:vector_sub_inplace(b_pos)
		:abs_inplace()
	--circle centre within aabb-like bounds, collide as an aabb
	local like_aabb = abs_delta.x < a_hs.x or abs_delta.y < a_hs.y
	--(clean up)
	abs_delta:release()
	--
	local result
	if like_aabb then
		local pretend_hs = vec2:pooled(0, 0)
		result = intersect.aabb_aabb_collide(a_pos, a_hs, b_pos, pretend_hs, into)
		pretend_hs:release()
	else
		--outside aabb-like bounds so we need to collide with the nearest clamped corner point
		local clamped = intersect.aabb_point_clamp(a_pos, a_hs, b_pos, vec2:pooled())
		result = intersect.circle_circle_collide(clamped, 0, b_pos, b_rad, into)
		clamped:release()
	end
	return result
end

--convert raw x, y, w, h rectangle components to aabb vectors
function intersect.rect_raw_to_aabb(x, y, w, h)
	local hs = vec2(w, h):scalar_mul_inplace(0.5)
	local pos = vec2(x, y):vector_add_inplace(hs)
	return pos, hs
end

--convert (x, y), (w, h) rectangle vectors to aabb vectors
function intersect.rect_to_aabb(pos, size)
	return intersect.rect_raw_to_aabb(pos.x, pos.y, size.x, size.y)
end

--check if a point is in a polygon
--point is the point to test
--poly is a list of points in order
--based on winding number, so re-intersecting areas are counted as solid rather than inverting
function intersect.point_in_poly(point, poly)
	local wn = 0
	for i, a in ipairs(poly) do
		local b = poly[i + 1] or poly[1]
		if a.y <= point.y then
			if
				b.y > point.y
				and vec2.winding_side(a, b, point) > 0
			then
				wn = wn + 1
			end
		else
			if
				b.y <= point.y
				and vec2.winding_side(a, b, point) < 0
			then
				wn = wn - 1
			end
		end
	end
	return wn ~= 0
end

--reversed versions
--it's annoying to need to flip the order of operands depending on what
--shapes you're working with
--so these functions provide the

--todo: ensure this is all of them

--(helper for reversing only if there's actually a vector, preserving false)
function intersect.reverse_msv(result)
	if result then
		result:inverse_inplace()
	end
	return result
end

function intersect.point_circle_overlap(a, b_pos, b_rad)
	return intersect.circle_point_overlap(b_pos, b_rad, a)
end

function intersect.point_circle_collide(a, b_pos, b_rad, into)
	return intersect.reverse_msv(intersect.circle_circle_collide(b_pos, b_rad, a, 0, into))
end

function intersect.point_aabb_overlap(a, b_pos, b_hs)
	return intersect.aabb_point_overlap(b_pos, b_hs, a)
end

function intersect.point_aabb_collide(a, b_pos, b_hs, into)
	return intersect.reverse_msv(intersect.aabb_point_collide(b_pos, b_hs, a, into))
end

function intersect.circle_aabb_overlap(a, a_rad, b_pos, b_hs)
	return intersect.aabb_circle_overlap(b_pos, b_hs, a, a_rad)
end

function intersect.circle_aabb_collide(a, a_rad, b_pos, b_hs, into)
	return intersect.reverse_msv(intersect.aabb_circle_collide(b_pos, b_hs, a, a_rad, into))
end

function intersect.circle_line_collide(a, a_rad, b_start, b_end, b_rad, into)
	return intersect.reverse_msv(intersect.line_circle_collide(b_start, b_end, b_rad, a, a_rad, into))
end

--resolution helpers

--resolve a collision between two bodies, given a (minimum) separating vector
--	from a's frame of reference, like the result of any of the _collide functions
--requires the two positions of the bodies, the msv, and a balance factor
--balance should be between 1 and 0;
--	1 is only a_pos moving to resolve
--	0 is only b_pos moving to resolve
--	0.5 is balanced between both (default)
--note: this wont work as-is for line segments, which have two separate position coordinates
--		you will need to understand what is going on and move the both coordinates yourself
function intersect.resolve_msv(a_pos, b_pos, msv, balance)
	balance = balance or 0.5
	a_pos:fused_multiply_add_inplace(msv, balance)
	b_pos:fused_multiply_add_inplace(msv, -(1 - balance))
end

-- gets a normalised balance factor from two mass inputs, and treats <=0 or infinite or nil masses as static bodies
-- returns false if we're colliding two static bodies, as that's invalid
function intersect.balance_from_mass(a_mass, b_mass)
	--static cases
	local a_static = not a_mass or a_mass <= 0 or a_mass == math.huge
	local b_static = not b_mass or b_mass <= 0 or b_mass == math.huge
	if a_static and b_static then
		return false --colliding two static bodies
	elseif a_static then
		return 0.0
	elseif b_static then
		return 1.0
	end

	--get balance factor
	local total = a_mass + b_mass
	return b_mass / total
end

--bounce a velocity off of a normal (modifying velocity)
--essentially flips the part of the velocity in the direction of the normal
function intersect.bounce_off(velocity, normal, conservation)
	--(default)
	conservation = conservation or 1
	--take a copy, we need it
	local old_vel = velocity:pooled_copy()
	--heading into the normal
	if old_vel:dot(normal) < 0 then
		--reject on the normal (keep velocity tangential to the normal)
		velocity:vector_rejection_inplace(normal)
		--add back the complement of the difference;
		--basically "flip" the velocity in line with the normal.
		velocity:fused_multiply_add_inplace(old_vel:vector_sub_inplace(velocity), -conservation)
	end
	--clean up
	old_vel:release()
	return velocity
end

--mutual bounce; two similar bodies bounce off each other, transferring energy
function intersect.mutual_bounce(velocity_a, velocity_b, normal, conservation)
	--(default)
	conservation = conservation or 1
	--take copies, we need them
	local old_a_vel = velocity_a:pooled_copy()
	local old_b_vel = velocity_b:pooled_copy()
	--reject on the normal
	velocity_a:vector_rejection_inplace(normal)
	velocity_b:vector_rejection_inplace(normal)
	--calculate the amount remaining from the old velocity
	--(transfer pool ownership)
	local a_remaining = old_a_vel:vector_sub_inplace(velocity_a)
	local b_remaining = old_b_vel:vector_sub_inplace(velocity_b)
	--transfer it to the other body
	velocity_a:fused_multiply_add_inplace(b_remaining, conservation)
	velocity_b:fused_multiply_add_inplace(a_remaining, conservation)
	--clean up
	vec2.release(a_remaining, b_remaining)
end

return intersect
