--[[
	geometric intersection routines
	from simple point tests to shape vs shape tests

	optimised pretty well in most places.

	options for boolean or minimum separating vector results

	continuous sweeps (where provided) also return the
	time-domain position of first intersection

	TODO: refactor vector storage to be pooled rather than fully local
	      so these functions can be reentrant
]]

local path = (...):gsub("intersect", "")
local vec2 = require(path .. "vec2")

--module storage
local intersect = {}

--epsilon for collisions
local COLLIDE_EPS = 1e-6

------------------------------------------------------------------------------
-- circles

function intersect.circle_point_overlap(pos, rad, v)
	return pos:distance_squared(v) < rad * rad
end

function intersect.circle_circle_overlap(a_pos, a_rad, b_pos, b_rad)
	local rad = a_rad + b_rad
	return a_pos:distance_squared(b_pos) < rad * rad
end

local _ccc_delta = vec2:zero()
function intersect.circle_circle_collide(a_pos, a_rad, b_pos, b_rad, into)
	--get delta
	_ccc_delta:vset(a_pos):vsubi(b_pos)
	--squared threshold
	local rad = a_rad + b_rad
	local dist = _ccc_delta:length_squared()
	if dist < rad * rad then
		if dist == 0 then
			--singular case; just resolve vertically
			dist = 1
			_ccc_delta:sset(0,1)
		else
			--get actual distance
			dist = math.sqrt(dist)
		end
		--allocate if needed
		if into == nil then
			into = vec2:zero()
		end
		--normalise, scale to separating distance
		into:vset(_ccc_delta):sdivi(dist):smuli(rad - dist)
		return into
	end
	return false
end

------------------------------------------------------------------------------
-- line segments
-- todo: separate double-sided, one-sided, and pull-through (along normal) collisions?

--get the nearest point on the line segment a from point b
function intersect.nearest_point_on_line(a_start, a_end, b_pos, into)
	if into == nil then into = vec2:zero() end
	--direction of segment
	local segment = a_end:pooled_copy():vsubi(a_start)
	--detect degenerate case
	local lensq = segment:length_squared()
	if lensq <= COLLIDE_EPS then
		into:vset(a_start)
	else
		--solve for factor along segment
		local point_to_start = b_pos:pooled_copy():vsubi(a_start)
		local factor = math.clamp01(point_to_start:dot(segment) / lensq)
		point_to_start:release()
		into:vset(segment):smuli(factor):vaddi(a_start)
	end
	segment:release()
	return into
end

--vector from line seg to point
function intersect._line_to_point(a_start, a_end, b_pos, into)
	return intersect.nearest_point_on_line(a_start, a_end, b_pos, into):vsubi(b_pos)
end

--line displacement vector from separation vector
function intersect._line_displacement_to_sep(a_start, a_end, separation, total_rad)
	local distance = separation:normalisei_len()
	local sep = distance - total_rad
	if sep <= 0 then
		if distance <= COLLIDE_EPS then
			--point intersecting the line; push out along normal
			separation:vset(a_end):vsubi(a_start):normalisei():rot90li()
		else
			separation:smuli(-sep)
		end
		return separation
	end
	return false
end

--collide a line segment with a circle
function intersect.line_circle_collide(a_start, a_end, a_rad, b_pos, b_rad, into)
	into = intersect._line_to_point(a_start, a_end, b_pos, into)
	return intersect._line_displacement_to_sep(a_start, a_end, into, a_rad + b_rad)
end

--collide 2 line segments
function intersect.line_line_collide(a_start, a_end, a_rad, b_start, b_end, b_rad, into)
	--segment directions from start points
	local a_dir = a_end:vsub(a_start)
	local b_dir = b_end:vsub(b_start)

	--detect degenerate cases
	local a_degen = a_dir:length_squared() <= COLLIDE_EPS
	local b_degen = a_dir:length_squared() <= COLLIDE_EPS
	if a_degen and b_degen then
		--actually just circles
		return intersect.circle_circle_collide(a_start, a_rad, b_start, b_rad, into)
	elseif a_degen then
		-- a is just circle; annoying, need reversed msv
		local collided = intersect.line_circle_collide(b_start, b_end, b_rad, a_start, a_rad, into)
		if collided then
			collided:smuli(-1)
		end
		return collided
	elseif b_degen then
		--b is just circle
		return intersect.line_circle_collide(a_start, a_end, a_rad, b_start, b_rad, into)
	end
	--otherwise we're _actually_ 2 line segs :)
	if into == nil then into = vec2:zero() end

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
	local intersected = "none"
	if
		math.abs(numera) < COLLIDE_EPS and
		math.abs(numerb) < COLLIDE_EPS and
		math.abs(denom) < COLLIDE_EPS
	then
		intersected = "both"
	else
		--check parallel, non-coincident lines
		if math.abs(denom) < COLLIDE_EPS then
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
				--collision point =
				--[[vec2:xy(
					a_start.x + mua * dx1,
					a_start.y + mua * dy1,
				)]]
			end
		end
	end
	if intersected == "both" then
		--simply displace along A normal
		return into:vset(a_dir):normalisei():smuli(a_rad + b_rad):rot90li()
	else
		--dumb as a rock check-corners approach
		--todo: pool storage
		--todo calculus from http://geomalgorithms.com/a07-_distance.html
		local search_tab = {}
		--only insert corners from the non-intersected line
		--since intersected line is potentially the apex
		if intersected ~= "a" then
			--a endpoints
			table.insert(search_tab, {intersect._line_to_point(b_start, b_end, a_start), 1})
			table.insert(search_tab, {intersect._line_to_point(b_start, b_end, a_end),   1})
		end
		if intersected ~= "b" then
			--b endpoints
			table.insert(search_tab, {intersect._line_to_point(a_start, a_end, b_start), -1})
			table.insert(search_tab, {intersect._line_to_point(a_start, a_end, b_end),   -1})
		end

		local best = table.find_best(search_tab, function(v)
			return -(v[1]:length_squared())
		end)

		--fix direction
		into:vset(best[1]):smuli(best[2])

		return intersect._line_displacement_to_sep(a_start, a_end, into, a_rad + b_rad)
	end

	return false
end

------------------------------------------------------------------------------
-- axis aligned bounding boxes

--return true on overlap, false otherwise
local _apo_delta = vec2:zero()
function intersect.aabb_point_overlap(pos, hs, v)
	_apo_delta:vset(pos):vsubi(v):absi()
	return _apo_delta.x < hs.x and _apo_delta.y < hs.y
end

-- discrete displacement
-- return msv to push point to closest edge of aabb
local _apo_delta_c = vec2:zero()
local _apo_delta_c_abs = vec2:zero()
local _apo_normal = vec2:zero()
function intersect.aabb_point_collide(pos, hs, v, into)
	_apo_delta_c:vset(v):vsubi(pos)
	_apo_delta_c_abs:vset(_apo_delta_c):absi()
	if _apo_delta_c_abs.x < hs.x and _apo_delta_c_abs.y < hs.y then
		into = into or vec2:zero()
		-- ahh get the point outta here
		_apo_normal:vset(hs):vsubi(_apo_delta_c_abs):minori()
		_apo_delta_c:vmuli(_apo_normal):normalisei():smuli(_apo_normal:length())
		-- nudge it a bit
		into:vset(_apo_delta_c):vaddi(_apo_delta_c:normalisei():smuli(COLLIDE_EPS))
		return into
	end
	return false
end

--return true on overlap, false otherwise
local _aao_abs_delta = vec2:zero()
local _aao_total_size = vec2:zero()
function intersect.aabb_aabb_overlap(pos, hs, opos, ohs)
	_aao_abs_delta:vset(pos):vsubi(opos):absi()
	_aao_total_size:vset(hs):vaddi(ohs)
	return _aao_abs_delta.x < _aao_total_size.x and _aao_abs_delta.y < _aao_total_size.y
end

--discrete displacement
--return msv on collision, false otherwise
local _aac_delta = vec2:zero()
local _aac_abs_delta = vec2:zero()
local _aac_size = vec2:zero()
local _aac_abs_amount = vec2:zero()
function intersect.aabb_aabb_collide(apos, ahs, bpos, bhs, into)
	if not into then into = vec2:zero() end
	_aac_delta:vset(apos):vsubi(bpos)
	_aac_abs_delta:vset(_aac_delta):absi()
	_aac_size:vset(ahs):vaddi(bhs)
	_aac_abs_amount:vset(_aac_size):vsubi(_aac_abs_delta)
	if _aac_abs_amount.x > COLLIDE_EPS and _aac_abs_amount.y > COLLIDE_EPS then
		--actually collided
		if _aac_abs_amount.x <= _aac_abs_amount.y then
			--x min
			if _aac_delta.x < 0 then
				return into:sset(-_aac_abs_amount.x, 0)
			else
				return into:sset(_aac_abs_amount.x, 0)
			end
		else
			--y min
			if _aac_delta.y < 0 then
				return into:sset(0, -_aac_abs_amount.y)
			else
				return into:sset(0, _aac_abs_amount.y)
			end
		end
	end
	return false
end

--return normal and fraction of dt encountered on collision, false otherwise
--TODO: re-pool storage here
function intersect.aabb_aabb_collide_continuous(
	a_startpos, a_endpos, ahs,
	b_startpos, b_endpos, bhs,
	into
)
	if not into then into = vec2:zero() end

	--compute delta motion
	local _self_delta_motion = a_endpos:vsub(a_startpos)
	local _other_delta_motion = b_endpos:vsub(b_startpos)

	--cheap "is this even possible" early-out
	do
		local _self_half_delta = _self_delta_motion:smul(0.5)
		local _self_bounds_pos = _self_half_delta:vadd(a_endpos)
		local _self_bounds_hs = _self_half_delta:vadd(ahs)

		local _other_half_delta = _other_delta_motion:smul(0.5)
		local _other_bounds_pos = _other_half_delta:vadd(b_endpos)
		local _other_bounds_hs = _other_half_delta:vadd(bhs)

		if not body._overlap_raw(
			_self_bounds_pos, _self_bounds_hs,
			_other_bounds_pos, _other_bounds_hs
		) then
			return false
		end
	end

	--get ccd minkowski box
	--this is a relative-space box
	local _relative_delta_motion = _self_delta_motion:vsub(_other_delta_motion)
	local _minkowski_halfsize = ahs:vadd(bhs)
	local _minkowski_pos = b_startpos:vsub(a_startpos)

	--if a line seg from our relative motion hits the minkowski box, we're in luck
	--slab raycast is speedy

	--alias
	local _rmx = _relative_delta_motion.x
	local _rmy = _relative_delta_motion.y

	local _inv_x = math.huge
	if _rmx ~= 0 then _inv_x = 1 / _rmx end
	local _inv_y = math.huge
	if _rmy ~= 0 then _inv_y = 1 / _rmy end

	local _minkowski_tl = _minkowski_pos:vsub(_minkowski_halfsize)
	local _minkowski_br = _minkowski_pos:vadd(_minkowski_halfsize)

	--clip x
	--get edge t along line
	local tx1 = (_minkowski_tl.x) * _inv_x
	local tx2 = (_minkowski_br.x) * _inv_x
	--clip to existing clip space
	local txmin = math.min(tx1, tx2)
	local txmax = math.max(tx1, tx2)
	--clip y
	--get edge t along line
	local ty1 = (_minkowski_tl.y) * _inv_y
	local ty2 = (_minkowski_br.y) * _inv_y
	--clip to existing clip space
	local tymin = math.min(ty1, ty2)
	local tymax = math.max(ty1, ty2)

	--clip space
	local tmin = math.max(0, txmin, tymin)
	local tmax = math.min(1, txmax, tymax)

	--still some unclipped? collision!
	if tmin <= tmax then
		--"was colliding at start"
		if tmin == 0 then
			--todo: maybe collide at old pos, not new pos
			local msv = self:collide(other, into)
			if msv then
				return msv, tmin
			else
				return false
			end
		end

		--delta before colliding
		local _self_collide_pre = _self_delta_motion:smul(tmin)
		--delta after colliding (to be discarded or projected or whatever)
		local _self_collide_post = _self_delta_motion:smul(1.0 - tmin)
		--get the collision normal
		--(whichever boundary crossed _last_ -> normal)
		local _self_collide_normal = vec2:zero()
		if txmin > tymin then
			_self_collide_normal.x = -math.sign(_self_delta_motion.x)
		else
			_self_collide_normal.y = -math.sign(_self_delta_motion.y)
		end

		--travelling away from normal?
		if _self_collide_normal:dot(_self_delta_motion) >= 0 then
			return false
		end

		--just "slide" projection for now
		_self_collide_post:vreji(_self_collide_normal)

		--combine
		local _final_delta = _self_collide_pre:vadd(_self_collide_post)

		--construct the target position
		local _target_pos = a_startpos:vadd(_final_delta)

		--return delta to target pos
		local msv = _target_pos:vsub(a_endpos)

		if math.abs(msv.x) > COLLIDE_EPS or math.abs(msv.y) > COLLIDE_EPS then
			into:vset(msv)
			return into, tmin
		end
	end

	return false
end

-- helper function to clamp point to aabb
local _v_min = vec2:zero()
local _v_max = vec2:zero()
local _v_clamp = vec2:zero()
local function aabb_clamp(pos, hs, v)
	_v_min:sset(pos.x-hs.x, pos.y-hs.y)
	_v_max:sset(pos.x+hs.x, pos.y+hs.y)
	_v_clamp:vset(v):clampi(_v_min,_v_max)
	return _v_clamp.x, _v_clamp.y
end

--  return true on overlap, false otherwise
local _a_b_closest = vec2:zero()
local _a_b_delta = vec2:zero() -- Delta vec for minimum distance between aabb and circle
function intersect.aabb_circle_overlap(apos, ahs, bpos, brad)
	_a_b_closest:sset(aabb_clamp(apos, ahs, bpos))
	_a_b_delta:vset(bpos):vsubi(_a_b_closest)
	return _a_b_delta:dot(_a_b_delta) < (brad*brad) + COLLIDE_EPS -- Pythag theorem
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
			if b.y > point.y and vec2.winding_side(a, b, point) > 0 then
				wn = wn + 1
			end
		else
			if b.y <= point.y and vec2.winding_side(a, b, point) < 0 then
				wn = wn - 1
			end
		end
	end
	return wn ~= 0
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
--		you will need to understand what is going on and move the second coordinate yourself
function intersect.resolve_msv(a_pos, b_pos, msv, balance)
	balance = balance or 0.5
	a_pos:fmai(msv, balance)
	b_pos:fmai(msv, -(1 - balance))
end

--bounce a velocity off of a normal (modifying velocity)
--essentially flips the part of the velocity in the direction of the normal
function intersect.bounce_off(velocity, normal, conservation)
	--(default)
	conservation = conservation or 1
	--take a copy, we need it
	local old_vel = vec2.pooled_copy(velocity)
	--reject on the normal (keep velocity tangential to the normal)
	velocity:vreji(normal)
	--add back the complement of the difference;
	--basically "flip" the velocity in line with the normal.
	velocity:fmai(old_vel:vsubi(velocity), -conservation)
	--clean up
	old_vel:release()
	return velocity
end

--mutual bounce; two similar bodies bounce off each other, transferring energy
function intersect.mutual_bounce(velocity_a, velocity_b, normal, conservation)
	--(default)
	conservation = conservation or 1
	--take copies, we need them
	local old_a_vel = vec2.pooled_copy(velocity_a)
	local old_b_vel = vec2.pooled_copy(velocity_b)
	--reject on the normal
	velocity_a:vreji(normal)
	velocity_b:vreji(normal)
	--calculate the amount remaining from the old velocity
	--(transfer ownership)
	local a_remaining = old_a_vel:vsubi(velocity_a)
	local b_remaining = old_b_vel:vsubi(velocity_b)
	--transfer it to the other body
	velocity_a:fmai(b_remaining, conservation)
	velocity_b:fmai(a_remaining, conservation)
	--clean up
	a_remaining:release()
	b_remaining:release()
end

return intersect
