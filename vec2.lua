--[[
	2d vector type
]]

local path = (...):gsub("vec2", "")
local class = require(path .. "class")
local math = require(path .. "mathx") --shadow global math module
local make_pooled = require(path .. "make_pooled")

local vec2 = class({
	name = "vec2",
})

--stringification
function vec2:__tostring()
	return ("(%.2f, %.2f)"):format(self.x, self.y)
end

--ctor
function vec2:new(x, y)
	--0 init by default
	self:scalar_set(0)
	if type(x) == "number" then
		self:scalar_set(x, y)
	elseif type(x) == "table" then
		if type(x.type) == "function" and x:type() == "vec2" then
			self:vector_set(x)
		elseif x[1] then
			self:scalar_set(x[1], x[2])
		else
			self:scalar_set(x.x, x.y)
		end
	end
end

--explicit ctors
function vec2:copy()
	return vec2(self.x, self.y)
end

function vec2:xy(x, y)
	return vec2(x, y)
end

function vec2:polar(length, angle)
	return vec2(length, 0):rotatei(angle)
end

function vec2:filled(v)
	return vec2(v, v)
end

function vec2:zero()
	return vec2(0)
end

--unpack for multi-args
function vec2:unpack()
	return self.x, self.y
end

--pack when a sequence is needed
function vec2:pack()
	return {self:unpack()}
end

--shared pooled storage
make_pooled(vec2, 128)

--get a pooled copy of an existing vector
function vec2:pooled_copy()
	return vec2:pooled():vector_set(self)
end

--modify

function vec2:scalar_set(x, y)
	if not y then y = x end
	self.x = x
	self.y = y
	return self
end

function vec2:vector_set(v)
	self.x = v.x
	self.y = v.y
	return self
end

function vec2:swap(v)
	local sx, sy = self.x, self.y
	self:vector_set(v)
	v:scalar_set(sx, sy)
	return self
end

-----------------------------------------------------------
--equality comparison
-----------------------------------------------------------

--threshold for equality in each dimension
local EQUALS_EPSILON = 1e-9

--true if a and b are functionally equivalent
function vec2.equals(a, b)
	return (
		math.abs(a.x - b.x) <= EQUALS_EPSILON and
		math.abs(a.y - b.y) <= EQUALS_EPSILON
	)
end

--true if a and b are not functionally equivalent
--(very slightly faster than `not vec2.equals(a, b)`)
function vec2.nequals(a, b)
	return (
		math.abs(a.x - b.x) > EQUALS_EPSILON or
		math.abs(a.y - b.y) > EQUALS_EPSILON
	)
end

-----------------------------------------------------------
--arithmetic
-----------------------------------------------------------

--vector
function vec2:vector_add(v)
	self.x = self.x + v.x
	self.y = self.y + v.y
	return self
end

function vec2:vector_sub(v)
	self.x = self.x - v.x
	self.y = self.y - v.y
	return self
end

function vec2:vector_mul(v)
	self.x = self.x * v.x
	self.y = self.y * v.y
	return self
end

function vec2:vector_div(v)
	self.x = self.x / v.x
	self.y = self.y / v.y
	return self
end

--alias; we're a vector library so arithmetic defaults to vector
vec2.add = vec2.vector_add
vec2.sub = vec2.vector_sub
vec2.mul = vec2.vector_mul
vec2.div = vec2.vector_div

--scalar
function vec2:scalar_add(x, y)
	if not y then y = x end
	self.x = self.x + x
	self.y = self.y + y
	return self
end

function vec2:scalar_sub(x, y)
	if not y then y = x end
	self.x = self.x - x
	self.y = self.y - y
	return self
end

function vec2:scalar_mul(x, y)
	if not y then y = x end
	self.x = self.x * x
	self.y = self.y * y
	return self
end

function vec2:scalar_div(x, y)
	if not y then y = x end
	self.x = self.x / x
	self.y = self.y / y
	return self
end

--(a + (b * t))
--useful for integrating physics and adding directional offsets
function vec2:fused_multiply_add(v, t)
	self.x = self.x + (v.x * t)
	self.y = self.y + (v.y * t)
	return self
end

-----------------------------------------------------------
-- geometric methods
-----------------------------------------------------------

function vec2:length_squared()
	return self.x * self.x + self.y * self.y
end

function vec2:length()
	return math.sqrt(self:length_squared())
end

function vec2:distance_squared(other)
	local dx = self.x - other.x
	local dy = self.y - other.y
	return dx * dx + dy * dy
end

function vec2:distance(other)
	return math.sqrt(self:distance_squared(other))
end

function vec2:normalise_both()
	local len = self:length()
	if len == 0 then
		return self, 0
	end
	return self:scalar_div(len), len
end

function vec2:normalise()
	local v, len = self:normalise_both()
	return v
end

function vec2:normalise_len()
	local v, len = self:normalise_both()
	return len
end

function vec2:inverse()
	return self:scalar_mul(-1)
end

-- angle/direction specific

function vec2:rotate(angle)
	local s = math.sin(angle)
	local c = math.cos(angle)
	local ox = self.x
	local oy = self.y
	self.x = c * ox - s * oy
	self.y = s * ox + c * oy
	return self
end

function vec2:rotate_around(angle, pivot)
	self:vector_sub(pivot)
	self:rotate(angle)
	self:vector_add(pivot)
	return self
end

--fast quarter/half rotations
function vec2:rot90r()
	local ox = self.x
	local oy = self.y
	self.x = -oy
	self.y = ox
	return self
end

function vec2:rot90l()
	local ox = self.x
	local oy = self.y
	self.x = oy
	self.y = -ox
	return self
end

vec2.rot180 = vec2.inverse --alias

--get the angle of this vector relative to (1, 0) 
function vec2:angle()
	return math.atan2(self.y, self.x)
end

--get the normalised difference in angle between two vectors
function vec2:angle_difference(v)
	return math.angle_difference(self:angle(), v:angle())
end

--lerp towards the direction of a provided vector
--(length unchanged)
function vec2:lerp_direction(v, t)
	return self:rotate(self:angle_difference(v) * t)
end

-----------------------------------------------------------
-- per-component clamping ops
-----------------------------------------------------------

function vec2:min(v)
	self.x = math.min(self.x, v.x)
	self.y = math.min(self.y, v.y)
	return self
end

function vec2:max(v)
	self.x = math.max(self.x, v.x)
	self.y = math.max(self.y, v.y)
	return self
end

function vec2:clamp(min, max)
	self.x = math.clamp(self.x, min.x, max.x)
	self.y = math.clamp(self.y, min.y, max.y)
	return self
end

-----------------------------------------------------------
-- absolute value
-----------------------------------------------------------

function vec2:abs()
	self.x = math.abs(self.x)
	self.y = math.abs(self.y)
	return self
end

-----------------------------------------------------------
-- sign
-----------------------------------------------------------

function vec2:sign()
	self.x = math.sign(self.x)
	self.y = math.sign(self.y)
	return self
end

-----------------------------------------------------------
-- truncation/rounding
-----------------------------------------------------------

function vec2:floor()
	self.x = math.floor(self.x)
	self.y = math.floor(self.y)
	return self
end

function vec2:ceil()
	self.x = math.ceil(self.x)
	self.y = math.ceil(self.y)
	return self
end

function vec2:round()
	self.x = math.round(self.x)
	self.y = math.round(self.y)
	return self
end

-----------------------------------------------------------
-- interpolation
-----------------------------------------------------------

function vec2:lerp(other, amount)
	self.x = math.lerp(self.x, other.x, amount)
	self.y = math.lerp(self.y, other.y, amount)
	return self
end

function vec2:lerp_eps(other, amount, eps)
	self.x = math.lerp_eps(self.x, other.x, amount, eps)
	self.y = math.lerp_eps(self.y, other.y, amount, eps)
	return self
end

-----------------------------------------------------------
-- vector products and projections
-----------------------------------------------------------

function vec2:dot(other)
	return self.x * other.x + self.y * other.y
end

--"fake", but useful - also called the wedge product apparently
function vec2:cross(other)
	return self.x * other.y - self.y * other.x
end

function vec2:scalar_projection(other)
	local len = other:length()
	if len == 0 then
		return 0
	end
	return self:dot(other) / len
end

function vec2:vector_projection(other)
	local div = other:dot(other)
	if div == 0 then
		return self:scalar_set(0)
	end
	local fac = self:dot(other) / div
	return self:vector_set(other):scalar_muli(fac)
end

function vec2:vector_rejection(o)
	local tx, ty = self.x, self.y
	self:vector_proji(other)
	self:scalar_set(tx - self.x, ty - self.y)
	return self
end

--get the winding side of p, relative to the line a-b
-- (this is based on the signed area of the triangle a-b-p)
-- return value:
--	>0 when p left of line
--	=0 when p on line
--	<0 when p right of line
function vec2.winding_side(a, b, p)
	return (b.x - a.x) * (p.y - a.y)
		 - (p.x - a.x) * (b.y - a.y)
end

-----------------------------------------------------------
-- vector extension methods for special purposes
--   (any common vector ops worth naming)
-----------------------------------------------------------

--"physical" friction
local _v_friction = vec2() --avoid alloc
function vec2:apply_friction(mu, dt)
	_v_friction:vector_set(self):scalar_muli(mu * dt)
	if _v_friction:length_squared() > self:length_squared() then
		self:scalar_set(0, 0)
	else
		self:vector_subi(_v_friction)
	end
	return self
end

--"gamey" friction in one dimension
local function _friction_1d(v, mu, dt)
	local friction = mu * v * dt
	if math.abs(friction) > math.abs(v) then
		return 0
	else
		return v - friction
	end
end

--"gamey" friction in both dimensions
function vec2:apply_friction_xy(mu_x, mu_y, dt)
	self.x = _friction_1d(self.x, mu_x, dt)
	self.y = _friction_1d(self.y, mu_y, dt)
	return self
end

--minimum/maximum components
function vec2:mincomp()
	return math.min(self.x, self.y)
end

function vec2:maxcomp()
	return math.max(self.x, self.y)
end

-- mask out min component, with preference to keep x
function vec2:major()
	if self.x > self.y then
		self.y = 0
	else
		self.x = 0
	end
	return self
end
-- mask out max component, with preference to keep x
function vec2:minor()
	if self.x < self.y then
		self.y = 0
	else
		self.x = 0
	end
	return self
end

--garbage generating functions that return a new vector rather than modifying self
for _, v in ipairs({

}) do
	vec2[name] = function(self, ...)
		self = self:copy()
		self[v](self, ...)
	end
end

--"hungarian" shorthand aliases
for _, v in ipairs({
	{"saddi", "scalar_add"},
	{"sadd", "scalar_add_copy"},

}) do
	local shorthand, original = v[1], v[2]
	vec2[shorthand] = vec2[original]
end

return vec2
