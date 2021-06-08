--[[
	2d vector type
]]

local path = (...):gsub("vec2", "")
local class = require(path .. "class")
local math = require(path .. "mathx") --shadow global math module

local vec2 = class()
vec2.type = "vec2"

--stringification
vec2.__mt.__tostring = function(self)
	return ("(%.2f, %.2f)"):format(self.x, self.y)
end

--probably-too-flexible ctor
function vec2:new(x, y)
	if type(x) == "number" and type(y) == "number" then
		return vec2:xy(x,y)
	elseif x then
		if type(x) == "number" then
			return vec2:filled(x)
		elseif type(x) == "table" then
			if x.type == "vec2" then
				return x:copy()
			elseif x[1] and x[2] then
				return vec2:xy(x[1], x[2])
			elseif x.x and x.y then
				return vec2:xy(x.x, x.y)
			end
		end
	end
	return vec2:zero()
end

--explicit ctors
function vec2:copy()
	return self:init({
		x = self.x, y = self.y
	})
end

function vec2:xy(x, y)
	return self:init({
		x = x, y = y
	})
end

function vec2:filled(v)
	return self:init({
		x = v, y = v
	})
end

function vec2:zero()
	return vec2:filled(0)
end

--shared pooled storage
local _vec2_pool = {}
--size limit for tuning memory upper bound
local _vec2_pool_limit = 128

function vec2.pool_size()
	return #_vec2_pool
end

--flush the entire pool
function vec2.flush_pool()
	if vec2.pool_size() > 0 then
		_vec2_pool = {}
	end
end

--drain one element from the pool, if it exists
function vec2.drain_pool()
	if #_vec2_pool > 0 then
		return table.remove(_vec2_pool)
	end
	return nil
end

--get a pooled vector (initialise it yourself)
function vec2:pooled()
	return vec2.drain_pool() or vec2:zero()
end

--get a pooled copy of an existing vector
function vec2:pooled_copy()
	return vec2:pooled():vset(self)
end

--release a vector to the pool
function vec2:release(...)
	if vec2.pool_size() < _vec2_pool_limit then
		table.insert(_vec2_pool, self)
	end
	if ... then
		vec2.release(...)
	end
end

--unpack for multi-args

function vec2:unpack()
	return self.x, self.y
end

--pack when a sequence is needed
--(not particularly useful)

function vec2:pack()
	return {self:unpack()}
end

--modify

function vec2:sset(x, y)
	if not y then y = x end
	self.x = x
	self.y = y
	return self
end

function vec2:vset(v)
	self.x = v.x
	self.y = v.y
	return self
end

function vec2:swap(v)
	local sx, sy = self.x, self.y
	self:vset(v)
	v:sset(sx, sy)
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

--immediate mode

--vector
function vec2:vaddi(v)
	self.x = self.x + v.x
	self.y = self.y + v.y
	return self
end

function vec2:vsubi(v)
	self.x = self.x - v.x
	self.y = self.y - v.y
	return self
end

function vec2:vmuli(v)
	self.x = self.x * v.x
	self.y = self.y * v.y
	return self
end

function vec2:vdivi(v)
	self.x = self.x / v.x
	self.y = self.y / v.y
	return self
end

--scalar
function vec2:saddi(x, y)
	if not y then y = x end
	self.x = self.x + x
	self.y = self.y + y
	return self
end

function vec2:ssubi(x, y)
	if not y then y = x end
	self.x = self.x - x
	self.y = self.y - y
	return self
end

function vec2:smuli(x, y)
	if not y then y = x end
	self.x = self.x * x
	self.y = self.y * y
	return self
end

function vec2:sdivi(x, y)
	if not y then y = x end
	self.x = self.x / x
	self.y = self.y / y
	return self
end

--garbage mode

function vec2:vadd(v)
	return self:copy():vaddi(v)
end

function vec2:vsub(v)
	return self:copy():vsubi(v)
end

function vec2:vmul(v)
	return self:copy():vmuli(v)
end

function vec2:vdiv(v)
	return self:copy():vdivi(v)
end

function vec2:sadd(x, y)
	return self:copy():saddi(x, y)
end

function vec2:ssub(x, y)
	return self:copy():ssubi(x, y)
end

function vec2:smul(x, y)
	return self:copy():smuli(x, y)
end

function vec2:sdiv(x, y)
	return self:copy():sdivi(x, y)
end

--fused multiply-add (a + (b * t))

function vec2:fmai(v, t)
	self.x = self.x + (v.x * t)
	self.y = self.y + (v.y * t)
	return self
end

function vec2:fma(v, t)
	return self:copy():fmai(v, t)
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

--immediate mode

function vec2:normalisei_both()
	local len = self:length()
	if len == 0 then
		return self, 0
	end
	return self:sdivi(len), len
end

function vec2:normalisei()
	local v, len = self:normalisei_both()
	return v
end

function vec2:normalisei_len()
	local v, len = self:normalisei_both()
	return len
end

function vec2:inversei()
	return self:smuli(-1)
end

function vec2:rotatei(angle)
	local s = math.sin(angle)
	local c = math.cos(angle)
	local ox = self.x
	local oy = self.y
	self.x = c * ox - s * oy
	self.y = s * ox + c * oy
	return self
end

function vec2:rot90ri()
	local ox = self.x
	local oy = self.y
	self.x = -oy
	self.y = ox
	return self
end

function vec2:rot90li()
	local ox = self.x
	local oy = self.y
	self.x = oy
	self.y = -ox
	return self
end

vec2.rot180i = vec2.inversei --alias

function vec2:rotate_aroundi(angle, pivot)
	self:vsubi(pivot)
	self:rotatei(angle)
	self:vaddi(pivot)
	return self
end

--garbage mode

function vec2:normalised()
	return self:copy():normalisei()
end

function vec2:normalised_len()
	local v = self:copy()
	local len = v:normalisei_len()
	return v, len
end

function vec2:inverse()
	return self:copy():inversei()
end

function vec2:rotate(angle)
	return self:copy():rotatei(angle)
end

function vec2:rot90r()
	return self:copy():rot90ri()
end

function vec2:rot90l()
	return self:copy():rot90li()
end

vec2.rot180 = vec2.inverse --alias

function vec2:rotate_around(angle, pivot)
	return self:copy():rotate_aroundi(angle, pivot)
end

function vec2:angle()
	return math.atan2(self.y, self.x)
end

-----------------------------------------------------------
-- per-component clamping ops
-----------------------------------------------------------

function vec2:mini(v)
	self.x = math.min(self.x, v.x)
	self.y = math.min(self.y, v.y)
	return self
end

function vec2:maxi(v)
	self.x = math.max(self.x, v.x)
	self.y = math.max(self.y, v.y)
	return self
end

function vec2:clampi(min, max)
	self.x = math.clamp(self.x, min.x, max.x)
	self.y = math.clamp(self.y, min.y, max.y)
	return self
end

function vec2:min(v)
	return self:copy():mini(v)
end

function vec2:max(v)
	return self:copy():maxi(v)
end

function vec2:clamp(min, max)
	return self:copy():clampi(min, max)
end

-----------------------------------------------------------
-- absolute value
-----------------------------------------------------------

function vec2:absi()
	self.x = math.abs(self.x)
	self.y = math.abs(self.y)
	return self
end

function vec2:abs()
	return self:copy():absi()
end

-----------------------------------------------------------
-- sign
-----------------------------------------------------------

function vec2:signi()
	self.x = math.sign(self.x)
	self.y = math.sign(self.y)
	return self
end

function vec2:sign()
	return self:copy():signi()
end

-----------------------------------------------------------
-- truncation/rounding
-----------------------------------------------------------

function vec2:floori()
	self.x = math.floor(self.x)
	self.y = math.floor(self.y)
	return self
end

function vec2:ceili()
	self.x = math.ceil(self.x)
	self.y = math.ceil(self.y)
	return self
end

function vec2:roundi()
	self.x = math.round(self.x)
	self.y = math.round(self.y)
	return self
end

function vec2:floor()
	return self:copy():floori()
end

function vec2:ceil()
	return self:copy():ceili()
end

function vec2:round()
	return self:copy():roundi()
end

-----------------------------------------------------------
-- interpolation
-----------------------------------------------------------

function vec2:lerpi(other, amount)
	self.x = math.lerp(self.x, other.x, amount)
	self.y = math.lerp(self.y, other.y, amount)
	return self
end

function vec2:lerp(other, amount)
	return self:copy():lerpi(other, amount)
end

function vec2:lerp_epsi(other, amount, eps)
	self.x = math.lerp_eps(self.x, other.x, amount, eps)
	self.y = math.lerp_eps(self.y, other.y, amount, eps)
	return self
end

function vec2:lerp_eps(other, amount, eps)
	return self:copy():lerp_epsi(other, amount, eps)
end

-----------------------------------------------------------
-- vector products and projections
-----------------------------------------------------------

function vec2.dot(a, b)
	return a.x * b.x + a.y * b.y
end

--"fake", but useful - also called the wedge product apparently
function vec2.cross(a, b)
	return a.x * b.y - a.y * b.x
end

--scalar projection a onto b
function vec2.sproj(a, b)
	local len = b:length()
	if len == 0 then
		return 0
	end
	return a:dot(b) / len
end

--vector projection a onto b (writes into a)
function vec2.vproji(a, b)
	local div = b:dot(b)
	if div == 0 then
		return a:sset(0,0)
	end
	local fac = a:dot(b) / div
	return a:vset(b):smuli(fac)
end

function vec2.vproj(a, b)
	return a:copy():vproji(b)
end

--vector rejection a onto b (writes into a)
function vec2.vreji(a, b)
	local tx, ty = a.x, a.y
	a:vproji(b)
	a:sset(tx - a.x, ty - a.y)
	return a
end

function vec2.vrej(a, b)
	return a:copy():vreji(b)
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
local _v_friction = vec2:zero() --avoid alloc
function vec2:apply_friction(mu, dt)
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
function vec2:apply_friction_xy(mu_x, mu_y, dt)
	self.x = apply_friction_1d(self.x, mu_x, dt)
	self.y = apply_friction_1d(self.y, mu_y, dt)
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
function vec2:majori()
	if self.x > self.y then
		self.y = 0
	else
		self.x = 0
	end
	return self
end
-- mask out max component, with preference to keep x
function vec2:minori()
	if self.x < self.y then
		self.y = 0
	else
		self.x = 0
	end
	return self
end


--garbage generating versions
function vec2:major(axis)
	return self:copy():majori(axis)
end

function vec2:minor(axis)
	return self:copy():minori(axis)
end

return vec2
