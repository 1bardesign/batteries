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
	else
		self:scalar_set(0)
	end
end

--explicit ctors; mostly vestigial at this point
function vec2:copy()
	return vec2(self.x, self.y)
end

function vec2:xy(x, y)
	return vec2(x, y)
end

function vec2:polar(length, angle)
	return vec2(length, 0):rotate_inplace(angle)
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
	return vec2:pooled(self)
end

--modify

function vec2:vector_set(v)
	self.x = v.x
	self.y = v.y
	return self
end

function vec2:scalar_set(x, y)
	if not y then y = x end
	self.x = x
	self.y = y
	return self
end

function vec2:swap(v)
	local sx, sy = self.x, self.y
	self.x, self.y = v.x, v.y
	v.x, v.y = sx, sy
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

--alias
vec2.not_equals = vec2.nequals

-----------------------------------------------------------
--arithmetic
-----------------------------------------------------------

--vector
function vec2:vector_add_inplace(v)
	self.x = self.x + v.x
	self.y = self.y + v.y
	return self
end

function vec2:vector_sub_inplace(v)
	self.x = self.x - v.x
	self.y = self.y - v.y
	return self
end

function vec2:vector_mul_inplace(v)
	self.x = self.x * v.x
	self.y = self.y * v.y
	return self
end

function vec2:vector_div_inplace(v)
	self.x = self.x / v.x
	self.y = self.y / v.y
	return self
end

--(a + (b * t))
--useful for integrating physics and adding directional offsets
function vec2:fused_multiply_add_inplace(v, t)
	self.x = self.x + (v.x * t)
	self.y = self.y + (v.y * t)
	return self
end

--scalar
function vec2:scalar_add_inplace(x, y)
	if not y then y = x end
	self.x = self.x + x
	self.y = self.y + y
	return self
end

function vec2:scalar_sub_inplace(x, y)
	if not y then y = x end
	self.x = self.x - x
	self.y = self.y - y
	return self
end

function vec2:scalar_mul_inplace(x, y)
	if not y then y = x end
	self.x = self.x * x
	self.y = self.y * y
	return self
end

function vec2:scalar_div_inplace(x, y)
	if not y then y = x end
	self.x = self.x / x
	self.y = self.y / y
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

function vec2:normalise_both_inplace()
	local len = self:length()
	if len == 0 then
		return self, 0
	end
	return self:scalar_div_inplace(len), len
end

function vec2:normalise_inplace()
	local v, len = self:normalise_both_inplace()
	return v
end

function vec2:normalise_len_inplace()
	local v, len = self:normalise_both_inplace()
	return len
end

function vec2:inverse_inplace()
	return self:scalar_mul_inplace(-1)
end

-- angle/direction specific

function vec2:rotate_inplace(angle)
	local s = math.sin(angle)
	local c = math.cos(angle)
	local ox = self.x
	local oy = self.y
	self.x = c * ox - s * oy
	self.y = s * ox + c * oy
	return self
end

function vec2:rotate_around_inplace(angle, pivot)
	self:vector_sub_inplace(pivot)
	self:rotate_inplace(angle)
	self:vector_add_inplace(pivot)
	return self
end

--fast quarter/half rotations
function vec2:rot90r_inplace()
	local ox = self.x
	local oy = self.y
	self.x = -oy
	self.y = ox
	return self
end

function vec2:rot90l_inplace()
	local ox = self.x
	local oy = self.y
	self.x = oy
	self.y = -ox
	return self
end

vec2.rot180_inplace = vec2.inverse_inplace --alias

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
function vec2:lerp_direction_inplace(v, t)
	return self:rotate_inplace(self:angle_difference(v) * t)
end

-----------------------------------------------------------
-- per-component clamping ops
-----------------------------------------------------------

function vec2:min_inplace(v)
	self.x = math.min(self.x, v.x)
	self.y = math.min(self.y, v.y)
	return self
end

function vec2:max_inplace(v)
	self.x = math.max(self.x, v.x)
	self.y = math.max(self.y, v.y)
	return self
end

function vec2:clamp_inplace(min, max)
	self.x = math.clamp(self.x, min.x, max.x)
	self.y = math.clamp(self.y, min.y, max.y)
	return self
end

-----------------------------------------------------------
-- absolute value
-----------------------------------------------------------

function vec2:abs_inplace()
	self.x = math.abs(self.x)
	self.y = math.abs(self.y)
	return self
end

-----------------------------------------------------------
-- sign
-----------------------------------------------------------

function vec2:sign_inplace()
	self.x = math.sign(self.x)
	self.y = math.sign(self.y)
	return self
end

-----------------------------------------------------------
-- truncation/rounding
-----------------------------------------------------------

function vec2:floor_inplace()
	self.x = math.floor(self.x)
	self.y = math.floor(self.y)
	return self
end

function vec2:ceil_inplace()
	self.x = math.ceil(self.x)
	self.y = math.ceil(self.y)
	return self
end

function vec2:round_inplace()
	self.x = math.round(self.x)
	self.y = math.round(self.y)
	return self
end

-----------------------------------------------------------
-- interpolation
-----------------------------------------------------------

function vec2:lerp_inplace(other, amount)
	self.x = math.lerp(self.x, other.x, amount)
	self.y = math.lerp(self.y, other.y, amount)
	return self
end

function vec2:lerp_eps_inplace(other, amount, eps)
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

function vec2:vector_projection_inplace(other)
	local div = other:dot(other)
	if div == 0 then
		return self:scalar_set(0)
	end
	local fac = self:dot(other) / div
	return self:vector_set(other):scalar_mul_inplace(fac)
end

function vec2:vector_rejection_inplace(other)
	local tx, ty = self.x, self.y
	self:vector_projection_inplace(other)
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

--return whether a is nearer to v than b
function vec2.nearer(v, a, b)
	return v:distance_squared(a) < v:distance_squared(b)
end

-----------------------------------------------------------
-- vector extension methods for special purposes
--   (any common vector ops worth naming)
-----------------------------------------------------------

--"physical" friction
function vec2:apply_friction_inplace(mu, dt)
	local friction = self:pooled_copy():scalar_mul_inplace(mu * dt)
	if friction:length_squared() > self:length_squared() then
		self:scalar_set(0, 0)
	else
		self:vector_sub_inplace(friction)
	end
	friction:release()
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
function vec2:apply_friction_xy_inplace(mu_x, mu_y, dt)
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

-- meta functions for mathmatical operations
function vec2.__add(a, b)
	return a:vector_add(b)
end

function vec2.__sub(a, b)
	return a:vector_sub(b)
end

function vec2.__mul(a, b)
	if type(a) == "number" then
		return b:scalar_mul(a)
	elseif type(b) == "number" then
		return a:scalar_mul(b)
	else
		return a:vector_mul(b)
	end
end

function vec2.__div(a, b)
	if type(b) == "number" then
		return a:scalar_div(b)
	else
		return a:vector_div(b)
	end
end

-- mask out min component, with preference to keep x
function vec2:major_inplace()
	if self.x > self.y then
		self.y = 0
	else
		self.x = 0
	end
	return self
end
-- mask out max component, with preference to keep x
function vec2:minor_inplace()
	if self.x < self.y then
		self.y = 0
	else
		self.x = 0
	end
	return self
end

--vector_ free alias; we're a vector library, so semantics should default to vector
vec2.add_inplace = vec2.vector_add_inplace
vec2.sub_inplace = vec2.vector_sub_inplace
vec2.mul_inplace = vec2.vector_mul_inplace
vec2.div_inplace = vec2.vector_div_inplace
vec2.set = vec2.vector_set

--american spelling alias
vec2.normalize_both_inplace = vec2.normalise_both_inplace
vec2.normalize_inplace = vec2.normalise_inplace
vec2.normalize_len_inplace = vec2.normalise_len_inplace

--garbage generating functions that return a new vector rather than modifying self
for _, inplace_name in ipairs({
	"vector_add_inplace",
	"vector_sub_inplace",
	"vector_mul_inplace",
	"vector_div_inplace",
	"fused_multiply_add_inplace",
	"add_inplace",
	"sub_inplace",
	"mul_inplace",
	"div_inplace",
	"scalar_add_inplace",
	"scalar_sub_inplace",
	"scalar_mul_inplace",
	"scalar_div_inplace",
	"normalise_both_inplace",
	"normalise_inplace",
	"normalise_len_inplace",
	"normalize_both_inplace",
	"normalize_inplace",
	"normalize_len_inplace",
	"inverse_inplace",
	"rotate_inplace",
	"rotate_around_inplace",
	"rot90r_inplace",
	"rot90l_inplace",
	"lerp_direction_inplace",
	"min_inplace",
	"max_inplace",
	"clamp_inplace",
	"abs_inplace",
	"sign_inplace",
	"floor_inplace",
	"ceil_inplace",
	"round_inplace",
	"lerp_inplace",
	"lerp_eps_inplace",
	"vector_projection_inplace",
	"vector_rejection_inplace",
	"apply_friction_inplace",
	"apply_friction_xy_inplace",
	"major_inplace",
	"minor_inplace",
}) do
	local garbage_name = inplace_name:gsub("_inplace", "")
	vec2[garbage_name] = function(self, ...)
		self = self:copy()
		return self[inplace_name](self, ...)
	end
end

--"hungarian" shorthand aliases for compatibility and short names
--
--i do encourage using the longer versions above as it makes code easier
--to understand when you come back, but i also appreciate wanting short code
for _, v in ipairs({
	{"sset", "scalar_set"},
	{"sadd", "scalar_add"},
	{"ssub", "scalar_sub"},
	{"smul", "scalar_mul"},
	{"sdiv", "scalar_div"},
	{"vset", "vector_set"},
	{"vadd", "vector_add"},
	{"vsub", "vector_sub"},
	{"vmul", "vector_mul"},
	{"vdiv", "vector_div"},
	--(no plain addi etc, imo it's worth differentiating vaddi vs saddi)
	{"fma", "fused_multiply_add"},
	{"vproj", "vector_projection"},
	{"vrej", "vector_rejection"},
	--just for the _inplace -> i shorthand, mostly for backwards compatibility
	{"min", "min"},
	{"max", "max"},
	{"clamp", "clamp"},
	{"abs", "abs"},
	{"sign", "sign"},
	{"floor", "floor"},
	{"ceil", "ceil"},
	{"round", "round"},
	{"lerp", "lerp"},
	{"rotate", "rotate"},
	{"normalise", "normalise"},
	{"normalize", "normalize"},
}) do
	local shorthand, original = v[1], v[2]
	if vec2[shorthand] == nil then
		vec2[shorthand] = vec2[original]
	end
	--and inplace version
	shorthand = shorthand .. "i"
	original = original .. "_inplace"
	if vec2[shorthand] == nil then
		vec2[shorthand] = vec2[original]
	end
end

return vec2
