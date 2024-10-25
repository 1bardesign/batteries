--[[
	3d vector type
]]

--import vec2 if not defined globally
local path = (...):gsub("vec3", "")
local class = require(path .. "class")
local vec2 = require(path .. "vec2")
local math = require(path .. "mathx") --shadow global math module
local make_pooled = require(path .. "make_pooled")

local vec3 = class({
	name = "vec3",
})

--stringification
function vec3:__tostring()
	return ("(%.2f, %.2f, %.2f)"):format(self.x, self.y, self.z)
end

--probably-too-flexible ctor
function vec3:new(x, y, z)
	if type(x) == "number" or type(x) == "nil" then
		self:sset(x or 0, y, z)
	elseif type(x) == "table" then
		if type(x.type) == "function" and x:type() == "vec3" then
			self:vset(x)
		elseif x[1] then
			self:sset(x[1], x[2], x[3])
		else
			self:sset(x.x, x.y, x.z)
		end
	end
end

--explicit ctors
function vec3:copy()
	return vec3(self.x, self.y, self.z)
end

function vec3:xyz(x, y, z)
	return vec3(x, y, z)
end

function vec3:filled(x, y, z)
	return vec3(x, y, z)
end

function vec3:zero()
	return vec3(0, 0, 0)
end

--unpack for multi-args
function vec3:unpack()
	return self.x, self.y, self.z
end

--pack when a sequence is needed
function vec3:pack()
	return {self:unpack()}
end

--handle pooling
make_pooled(vec3, 128)

--get a pooled copy of an existing vector
function vec3:pooled_copy()
	return vec3:pooled():vset(self)
end

--modify

function vec3:sset(x, y, z)
	self.x = x
	self.y = y or x
	self.z = z or y or x
	return self
end

function vec3:vset(v)
	self.x = v.x
	self.y = v.y
	self.z = v.z
	return self
end

function vec3:swap(v)
	local sx, sy, sz = self.x, self.y, self.z
	self:vset(v)
	v:sset(sx, sy, sz)
	return self
end

-----------------------------------------------------------
--equality comparison
-----------------------------------------------------------

--threshold for equality in each dimension
local EQUALS_EPSILON = 1e-9

--true if a and b are functionally equivalent
function vec3.equals(a, b)
	return (
		math.abs(a.x - b.x) <= EQUALS_EPSILON and
		math.abs(a.y - b.y) <= EQUALS_EPSILON and
		math.abs(a.z - b.z) <= EQUALS_EPSILON
	)
end

--true if a and b are not functionally equivalent
--(very slightly faster than `not vec3.equals(a, b)`)
function vec3.nequals(a, b)
	return (
		math.abs(a.x - b.x) > EQUALS_EPSILON or
		math.abs(a.y - b.y) > EQUALS_EPSILON or
		math.abs(a.z - b.z) > EQUALS_EPSILON
	)
end

-----------------------------------------------------------
--arithmetic
-----------------------------------------------------------

--immediate mode

--vector
function vec3:vaddi(v)
	self.x = self.x + v.x
	self.y = self.y + v.y
	self.z = self.z + v.z
	return self
end

function vec3:vsubi(v)
	self.x = self.x - v.x
	self.y = self.y - v.y
	self.z = self.z - v.z
	return self
end

function vec3:vmuli(v)
	self.x = self.x * v.x
	self.y = self.y * v.y
	self.z = self.z * v.z
	return self
end

function vec3:vdivi(v)
	self.x = self.x / v.x
	self.y = self.y / v.y
	self.z = self.z / v.z
	return self
end

--scalar
function vec3:saddi(x, y, z)
	if not y then y = x end
	if not z then z = y end
	self.x = self.x + x
	self.y = self.y + y
	self.z = self.z + z
	return self
end

function vec3:ssubi(x, y, z)
	if not y then y = x end
	if not z then z = y end
	self.x = self.x - x
	self.y = self.y - y
	self.z = self.z - z
	return self
end

function vec3:smuli(x, y, z)
	if not y then y = x end
	if not z then z = y end
	self.x = self.x * x
	self.y = self.y * y
	self.z = self.z * z
	return self
end

function vec3:sdivi(x, y, z)
	if not y then y = x end
	if not z then z = y end
	self.x = self.x / x
	self.y = self.y / y
	self.z = self.z / z
	return self
end

--garbage mode

function vec3:vadd(v)
	return self:copy():vaddi(v)
end

function vec3:vsub(v)
	return self:copy():vsubi(v)
end

function vec3:vmul(v)
	return self:copy():vmuli(v)
end

function vec3:vdiv(v)
	return self:copy():vdivi(v)
end

function vec3:sadd(x, y, z)
	return self:copy():saddi(x, y, z)
end

function vec3:ssub(x, y, z)
	return self:copy():ssubi(x, y, z)
end

function vec3:smul(x, y, z)
	return self:copy():smuli(x, y, z)
end

function vec3:sdiv(x, y, z)
	return self:copy():sdivi(x, y, z)
end

--fused multiply-add (a + (b * t))

function vec3:fmai(v, t)
	self.x = self.x + (v.x * t)
	self.y = self.y + (v.y * t)
	self.z = self.z + (v.z * t)
	return self
end

function vec3:fma(v, t)
	return self:copy():fmai(v, t)
end

-----------------------------------------------------------
-- geometric methods
-----------------------------------------------------------

function vec3:length_squared()
	return self.x * self.x + self.y * self.y + self.z * self.z
end

function vec3:length()
	return math.sqrt(self:length_squared())
end

function vec3:distance_squared(other)
	local dx = self.x - other.x
	local dy = self.y - other.y
	local dz = self.z - other.z
	return dx * dx + dy * dy + dz * dz
end

function vec3:distance(other)
	return math.sqrt(self:distance_squared(other))
end

--immediate mode

function vec3:normalisei_both()
	local len = self:length()
	if len == 0 then
		return self, 0
	end
	return self:sdivi(len), len
end

function vec3:normalisei()
	local v, len = self:normalisei_both()
	return v
end

function vec3:normalisei_len()
	local v, len = self:normalisei_both()
	return len
end

function vec3:inversei()
	return self:smuli(-1)
end

--swizzle extraction
--not as nice as property accessors so might be worth doing that later :)

--also dog slow, so there's that
local _swizzle_x_byte = ("x"):byte()
local _swizzle_y_byte = ("y"):byte()
local _swizzle_z_byte = ("z"):byte()
local _allowed_swizzle = {
	[_swizzle_x_byte] = "x",
	[_swizzle_y_byte] = "y",
	[_swizzle_z_byte] = "z",
}

function vec3:encode_swizzle_field(swizzle)
	if type(swizzle) == "string" then
		swizzle = swizzle:byte()
	end
	return _allowed_swizzle[swizzle] or "x"
end

function vec3:extract_single(swizzle)
	return self[self:encode_swizzle_field(swizzle)]
end

function vec3:infuse_single(swizzle, v)
	self[self:encode_swizzle_field(swizzle)] = v
	return self
end

function vec3:extract_vec2(swizzle, into)
	if not into then into = vec2:zero() end
	local x = self:extract_single(swizzle:byte(1))
	local y = self:extract_single(swizzle:byte(2))
	return into:sset(x, y)
end

function vec3:infuse_vec2(swizzle, v)
	self:infuse_single(swizzle:byte(1), v.x)
	self:infuse_single(swizzle:byte(2), v.y)
	return self
end

--rotate around a swizzle
--todo: angle-axis version
function vec3:rotatei(swizzle, angle)
	if angle == 0 then --early out
		return self
	end
	local v = vec2:pooled()
	self:extract_vec2(swizzle, v)
	v:rotatei(angle)
	self:infuse_vec2(swizzle, v)
	v:release()
	return self
end

function vec3:rotate_euleri(angle_x_axis, angle_y_axis, angle_z_axis)
	self:rotatei("yz", angle_x_axis)
	self:rotatei("xz", angle_y_axis)
	self:rotatei("xy", angle_z_axis)
	return self
end

--todo: 90deg rotations

vec3.rot180i = vec3.inversei --alias

function vec3:rotate_aroundi(swizzle, angle, pivot)
	self:vsubi(pivot)
	self:rotatei(swizzle, angle)
	self:vaddi(pivot)
	return self
end

--garbage mode

function vec3:normalised()
	return self:copy():normalisei()
end

function vec3:normalised_len()
	local v = self:copy()
	local len = v:normalisei_len()
	return v, len
end

function vec3:inverse()
	return self:copy():inversei()
end

function vec3:rotate(swizzle, angle)
	return self:copy():rotatei(swizzle, angle)
end

function vec3:rotate_euler(angle_x_axis, angle_y_axis, angle_z_axis)
	return self:copy():rotate_euleri(angle_x_axis, angle_y_axis, angle_z_axis)
end

vec3.rot180 = vec3.inverse --alias

function vec3:rotate_around(swizzle, angle, pivot)
	return self:copy():rotate_aroundi(swizzle, angle, pivot)
end


-----------------------------------------------------------
-- per-component clamping ops
-----------------------------------------------------------

function vec3:mini(v)
	self.x = math.min(self.x, v.x)
	self.y = math.min(self.y, v.y)
	self.z = math.min(self.z, v.z)
	return self
end

function vec3:maxi(v)
	self.x = math.max(self.x, v.x)
	self.y = math.max(self.y, v.y)
	self.z = math.max(self.z, v.z)
	return self
end

function vec3:clampi(min, max)
	self.x = math.clamp(self.x, min.x, max.x)
	self.y = math.clamp(self.y, min.y, max.y)
	self.z = math.clamp(self.z, min.z, max.z)
	return self
end

function vec3:min(v)
	return self:copy():mini(v)
end

function vec3:max(v)
	return self:copy():maxi(v)
end

function vec3:clamp(min, max)
	return self:copy():clampi(min, max)
end

-----------------------------------------------------------
-- absolute value
-----------------------------------------------------------

function vec3:absi()
	self.x = math.abs(self.x)
	self.y = math.abs(self.y)
	self.z = math.abs(self.z)
	return self
end

function vec3:abs()
	return self:copy():absi()
end

-----------------------------------------------------------
-- truncation/rounding
-----------------------------------------------------------

function vec3:floori()
	self.x = math.floor(self.x)
	self.y = math.floor(self.y)
	self.z = math.floor(self.z)
	return self
end

function vec3:ceili()
	self.x = math.ceil(self.x)
	self.y = math.ceil(self.y)
	self.z = math.ceil(self.z)
	return self
end

function vec3:roundi()
	self.x = math.round(self.x)
	self.y = math.round(self.y)
	self.z = math.round(self.z)
	return self
end

function vec3:floor()
	return self:copy():floori()
end

function vec3:ceil()
	return self:copy():ceili()
end

function vec3:round()
	return self:copy():roundi()
end

-----------------------------------------------------------
-- interpolation
-----------------------------------------------------------

function vec3:lerpi(other, amount)
	self.x = math.lerp(self.x, other.x, amount)
	self.y = math.lerp(self.y, other.y, amount)
	self.z = math.lerp(self.z, other.z, amount)
	return self
end

function vec3:lerp(other, amount)
	return self:copy():lerpi(other, amount)
end

function vec3:lerp_epsi(other, amount, eps)
	self.x = math.lerp_eps(self.x, other.x, amount, eps)
	self.y = math.lerp_eps(self.y, other.y, amount, eps)
	self.z = math.lerp_eps(self.z, other.z, amount, eps)
	return self
end

function vec3:lerp_eps(other, amount, eps)
	return self:copy():lerp_epsi(other, amount, eps)
end

-----------------------------------------------------------
-- vector products and projections
-----------------------------------------------------------

function vec3.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end

function vec3.cross(a, b, into)
	if not into then into = vec3:zero() end
	return into:sset(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	)
end

--scalar projection a onto b
function vec3.sproj(a, b)
	local len = b:length()
	if len == 0 then
		return 0
	end
	return a:dot(b) / len
end

--vector projection a onto b (writes into a)
function vec3.vproji(a, b)
	local div = b:dot(b)
	if div == 0 then
		return a:sset(0, 0, 0)
	end
	local fac = a:dot(b) / div
	return a:vset(b):smuli(fac)
end

function vec3.vproj(a, b)
	return a:copy():vproji(b)
end

--vector rejection a onto b (writes into a)
function vec3.vreji(a, b)
	local tx, ty, tz = a.x, a.y, a.z
	a:vproji(b)
	a:sset(tx - a.x, ty - a.y, tz - a.z)
	return a
end

function vec3.vrej(a, b)
	return a:copy():vreji(b)
end

-----------------------------------------------------------
-- vector extension methods for special purposes
--   (any common vector ops worth naming)
-----------------------------------------------------------

--"physical" friction
local _v_friction = vec3:zero() --avoid alloc
function vec3:apply_friction(mu, dt)
	_v_friction:vset(self):smuli(mu * dt)
	if _v_friction:length_squared() > self:length_squared() then
		self:sset(0, 0)
	else
		self:vsubi(_v_friction)
	end
	return self
end

--"gamey" friction in one dimension
local function apply_friction_1d(v, mu, dt)
	local friction = mu * v * dt
	if math.abs(friction) > math.abs(v) then
		return 0
	else
		return v - friction
	end
end

--"gamey" friction in both dimensions
function vec3:apply_friction_xy(mu_x, mu_y, dt)
	self.x = apply_friction_1d(self.x, mu_x, dt)
	self.y = apply_friction_1d(self.y, mu_y, dt)
	self.z = apply_friction_1d(self.z, mu_y, dt)
	return self
end

return vec3
