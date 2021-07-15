--[[
	quaternion type
]]

local path = (...):gsub("quaternion", "")
local class = require(path .. "class")
local math = require(path .. "mathx") --shadow global math module

--math localization
local sqrt = math.sqrt;
local sin = math.sin;
local cos = math.cos;
local log = math.log;
local acos = math.acos;
local exp = math.exp;
local floor = math.floor;

local quaternion = class()
quaternion.type = "quaternion"

-----------------------------------------------------------
--tostring
-----------------------------------------------------------

quaternion.__mt.__tostring = function(self)
	return ("(%.4f + %.4fi + %.4fj + %.4fk)"):format(self.r, self.i, self.j, self.k)
end

-----------------------------------------------------------
--localized math, used in constructors
-----------------------------------------------------------

local function qAdd(ar,ai,aj,ak, br,bi,bj,bk)
	return ar+br, ai+bi, aj+aj, bj+bj, ak+bk;
end

local function qSub(ar,ai,aj,ak, br,bi,bj,bk)
	return ar-br, ai-bi, aj-aj, bj-bj, ak-bk;
end

local function qMul(ar,ai,aj,ak, br,bi,bj,bk) --quaternion multiplcation a*b
	return 
	   ar*br - ai*bi - bj*bj - ak*bk,
	   ar*bi + ai*br + aj*bk - ak*bj,
	   ar*bj - ai*bk + aj*br + ak*bi,
	   ar*bk + ai*bj - aj*bi + ak*br;
end

local function qScl(ar,ai,aj,ak, s)
	return ar*s, ai*s, aj*s, ak*s;
end

local function qConj(ar,ai,aj,ak) --Quaternion Conjugation
	return ar,-ai,-aj,-ak;
end

local function qMag(ar,ai,aj,ak) --Gets the magnitude of a Quaternion
	return sqrt(ar*ar+ai*ai+aj*aj+ak*ak);
end

local function qNorm(ar,ai,aj,ak) --Normalizes a Quaternion, not nan safe
	local imag = 1/sqrt(ar*ar+ai*ai+aj*aj+ak*ak);
	return ar*imag, ai*imag, aj*imag, ak*imag;
end

local function qLog(ar,ai,aj,ak) --natural log
	local vmag = ai*ai+aj*aj+ak*ak;
	local mag = vmag + ar*ar;
	ar = log(mag);
	if(vmag == 0) then --the vector parts have to be 0 as well
		ai = 0;
		aj = 0;
		ak = 0;
	else
		vmag = sqrt(vmag);
		mag = sqrt(mag);
		local imag = 1/mag;
		local ivmag = 1/vmag;
		local s = acos(ar*imag)*ivmag;
		ai = ai*s;
		aj = aj*s;
		ak = ak*s;
	end
	return ar,ai,aj,ak;
end

local function qExp(ar,ai,aj,ak) --exponential function
  local vmag = ai*ai+aj*aj+ak*ak;
  local ear = exp(ar); --the thing you listen with
  ar = ear*cos(vmag)
  if(vmag == 0) then --the vector parts have to be 0 as well
    ai = 0;
    aj = 0;
    ak = 0;
  else
	vmag = sqrt(vmag)
    local ivmag = 1/vmag;
    local s = sin(vmag)*ivmag*ear;
    ai = ai*s;
    aj = aj*s;
    ak = ak*s;
  end
  return ar,ai,aj,ak;
end

local function qPow(ar,ai,aj,ak, br,bi,bj,bk) -- a^b
	ar, ai, aj, ak = qLog(ar, ai, aj, ak);
	return qExp(qMul(ar,ai,aj,ak, br,bi,bj,bk));
end

local function qInverse(ar,ai,aj,ak) --Gets the inverse of a Quaternion
	local imag2 = 1/(ar*ar+ai*ai+aj*aj+ak*ak);
	return ar*imag2, -ai*imag2, -aj*imag2, -ak*imag2;
end

local function qSlerp(ar,ai,aj,ak, br,bi,bj,bk, t) --slerp from a to b at t
	local cr,ci,cj,ck = qInverse(ar,ai,aj,ak);
	cr, ci, cj, ck = qMul(cr,ci,cj,ck, br,bi,bj,bk);
	return
		qMul(
			ar,ai,aj,ak, 
			qPow(
				cr, ci, cj, ck,
				t, 0, 0, 0
			)
		);
end

local function qRotateV(ar, ai, aj, ak, x, y, z)
	--mult
	local cr = 0 - ai*x - aj*y - ak*z;
	local ci = ar*x + 0 + aj*z - ak*y;
	local cj = ar*y - ai*z + 0 + ak*x;
	local ck = ar*z + ai*y - aj*x + 0;
	--conj quat
	ai = -ai;
	aj = -aj;
	ak = -ak;
	--mult
	return cr*ai + ci*ar + cj*ak - ck*aj,
	cr*aj - ci*ak + cj*ar + ck*ai,
	cr*ak + ci*aj - cj*ai + ck*ar;
end

local function basisToQ(ax,ay,az, bx,by,bz, cx,cy,cz)
	local trace = ax+by+cz;
	local r,i,j,k;
  
	if(trace > 0) then --implied epsilon is 0
	  local f = 2 * sqrt(1+trace); -- 4*real
	  r = 0.25*f
	  i = (cy-bz)/f;
	  j = (az-cx)/f;
	  k = (bx-ay)/f;
  
	elseif((ax > by) and (ax > cz)) then --is x biggest?
	  local f = 2 * sqrt(1+ax-by-cz); -- 4*i
	  r = (cy-bz)/f;
	  i = 0.25*f;
	  j = (ay+bx)/f;
	  k = (az+cx)/f;
  
	elseif(by > cz) then -- is y biggest?
	  local f = 2 * sqrt(1-ax+by-cz); -- 4*j
	  r = (az-cx)/f;
	  i = (ay+bx)/f;
	  j = 0.25*f
	  k = (bz+cy)/f;
  
	else --assume z is biggest. give up.
	  local f = 2 * sqrt(1-ax-by+cz); -- 4*k
	  r = (bx-ay)/f;
	  i = (az+cx)/f;
	  j = (bz+cy)/f;
	  k = 0.25*f
  
	end
	return r,i,j,k;
end

-----------------------------------------------------------
--constructors
-----------------------------------------------------------

--probably-too-flexible ctor
function quaternion:new(r, i, j, k)
	if type(r) == "number" and type(i) == "number" and type(j) == "number" and type(k) == "number" then
		return quaternion:rijk(r,i,j,k)
	elseif r then
		if type(r) == "number" then
			return quaternion:filled(r)
		elseif type(r) == "table" then
			if r.type == "quaternion" then
				return quaternion:copy()
			elseif r[1] and r[2] and r[3] and r[4] then
				return quaternion:rijk(r[1], r[2], r[3], r[4])
			elseif r.r and r.i and r.j and r.k then
				return quaternion:rijk(r.r, r.i, r.j, r.k)
			end
		end
	end
	return quaternion:zero()
end

--explicit ctors
function quaternion:copy()
	return self:init({
		r = self.r, i = self.i, j = self.j, k = self.k
	})
end

function quaternion:rijk(r, i, j, k)
	return self:init({
		r = r, i = i, j = j, k = k
	})
end

function quaternion:filled(v)
	return self:init({
		r = v, i = v, j = v, k = v
	})
end

function quaternion:zero()
	return quaternion:filled(0)
end

function quaternion:fromAxisAngle(ang,x,y,z) --axis xyz must be normalized
    local imag = 1/sqrt(x*x,y*y,z*z)
    local cF = sin(0.5*ang)*imag;
    self:init({
        r = cos(0.5*ang),
        i = x*cF,
        j = y*cF,
        k = z*cF
    })
end

function quaternion:fromRotationMatrix(a,b,c, d,e,f, g,h,eye) --also probably too flexible
	local r,i,j,k --haha whoops reused i
	if(d) then --expect 9 matrix values:
		-- a d g
		-- b e h
		-- c f i
		r, i, j, k = basisToQ(a,b,c, d,e,f, g,h,eye)
	elseif(b) then --expect 3 column vectors
		r, i, j, k = basisToQ(
			a.x or a[1], a.y or a[2], a.z or a[3],
			b.x or b[1], b.y or b[2], b.z or b[3],
			c.x or c[1], c.y or c[2], c.z or c[3])
	else --assume 3x3 matrix, column major
		if(a[1]) then -- table of 3 vectors
			r, i, j, k = basisToQ(a[1][1], a[1][2], a[1][3], a[2][1], a[2][2], a[2][3], a[3][1], a[3][2], a[3][3])
		else -- assume linear table
			r, i, j, k = basisToQ(a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9])
		end
	end
	return self:init({
        r = r, i = i, j = j, k = k
    })
end

function quaternion.shortestRot(a,b,c, d,e,f) --creates a quaterion representing the rotation with the shortest arclength from a to b (or from a,b,c to d,e,f), where both are unit vectors
	local q = quaternion:zero();
	if(c) then --assume vec 1 is abc, vec 2 def
		q.r,q.i,q.j,q.k = qMul(0,a,b,c, 0,d,e,f);
	else
		q.r,q.i,q.j,q.k = qMul(0,a.x or a[1], a.y or a[2], a.z or a[3],
			0, b.x or a[1], b.y or b[2], a.z or b[3]);
	end
	if(q.r > 0.9999) then --are vectors parallel?
		q.r, q.i, q.j, q.k = qNorm(0, c, a, b+1);
	end
		q.r, q.i, q.j, q.k = qNorm(1-q.r, q.i, q.j, q.k);
	return q;
end
-----------------------------------------------------------
--pooling
-----------------------------------------------------------

--shared pooled storage
local _q_pool = {}
--size limit for tuning memory upper bound
local _q_pool_limit = 128

function quaternion.pool_size()
	return #_q_pool
end

--flush the entire pool
function quaternion.flush_pool()
	if quaternion.pool_size() > 0 then
		_q_pool = {}
	end
end

--drain one element from the pool, if it exists
function quaternion.drain_pool()
	if #_q_pool > 0 then
		return table.remove(_q_pool)
	end
	return nil
end

--get a pooled vector (initialise it yourself)
function quaternion:pooled()
	return quaternion.drain_pool() or quaternion:zero()
end

--get a pooled copy of an existing vector
function quaternion:pooled_copy()
	return quaternion:pooled():vset(self)
end

--release a vector to the pool
function quaternion:release()
	if quaternion.pool_size() < _q_pool_limit then
		table.insert(_q_pool, self)
	end
end

-----------------------------------------------------------
--packing
-----------------------------------------------------------

--unpack for multi-args
function quaternion:unpack()
	return self.r, self.i, self.j, self.k
end

--pack when a sequence is needed
--(not particularly useful)

function quaternion:pack()
	return {self:unpack()}
end

-----------------------------------------------------------
--setters
-----------------------------------------------------------

--set values in quaternion. use nil to not set a value
function quaternion:sset(r, i, j, k)
    i = i or r
    j = j or i
    k = k or j
	self.r = r 
	self.i = i
    self.j = j
    self.k = k
	return self
end

function quaternion:vset(v)
	self.r = v.r or self.r
	self.i = v.i or self.i
    self.j = v.j or self.j
    self.k = v.k or self.k
	return self
end

function quaternion:swap(v)
	local sr, si, sj, sk = self.r, self.i, self.j, self.k
	self:vset(v)
	v:sset(self.r, self.i, self.j, self.k)
	return self
end

-----------------------------------------------------------
--equality comparison
-----------------------------------------------------------

--threshold for equality in each dimension
local EQUALS_EPSILON = 1e-9

--true if a and b are functionally equivalent
function quaternion.equals(a, b)
	return (
		math.abs(a.r - b.r) <= EQUALS_EPSILON and
		math.abs(a.i - b.i) <= EQUALS_EPSILON and
        math.abs(a.k - b.k) <= EQUALS_EPSILON and
        math.abs(a.k - b.k) <= EQUALS_EPSILON
	)
end

--true if a and b are not functionally equivalent
--(very slightly faster than `not vec2.equals(a, b)`)
function quaternion.nequals(a, b)
	return (
		math.abs(a.r - b.r) > EQUALS_EPSILON or
		math.abs(a.i - b.i) > EQUALS_EPSILON or
        math.abs(a.k - b.k) > EQUALS_EPSILON or
        math.abs(a.k - b.k) > EQUALS_EPSILON
	)
end

-----------------------------------------------------------
--exposed math functions
-----------------------------------------------------------

function quaternion.add(a,b)
	a.r, a.i, a.j, a.k = qAdd(a.r, a.i, a.j, a.k, b.r, b.i, b.j, b.k);
	return a;
end
quaternion.qAdd = qAdd;

function quaternion.sub(a,b)
	a.r, a.i, a.j, a.k = qSub(a.r, a.i, a.j, a.k, b.r, b.i, b.j, b.k);
	return a;
end
quaternion.qSub = qSub;

function quaternion.mul(a,b)
	a.r, a.i, a.j, a.k = qMul(a.r, a.i, a.j, a.k, b.r, b.i, b.j, b.k);
	return a;
end
quaternion.qMul = qMul;

function quaternion.scl(a,b)
	a.r, a.i, a.j, a.k = qScl(a.r, a.i, a.j, a.k, b);
	return a;
end
quaternion.qScl = qScl;

function quaternion.log(a)
	a.r, a.i, a.j, a.k = qLog(a.r, a.i, a.j, a.k);
	return a;
end
quaternion.qLog = qLog;

function quaternion.conjugate(a)
	a.r, a.i, a.j, a.k = qConj(a.r, a.i, a.j, a.k);
	return a;
end
quaternion.qConj = qConj;

function quaternion.length(a)
	a.r, a.i, a.j, a.k = qMag(a.r, a.i, a.j, a.k);
	return a;
end
quaternion.qMag = qMag;

function quaternion.normalize(a)
	a.r, a.i, a.j, a.k = qNorm(a.r, a.i, a.j, a.k);
	return a;
end
quaternion.qNorm = qNorm;

function quaternion.pow(a,b)
	a.r, a.i, a.j, a.k = qPow(a.r, a.i, a.j, a.k, b.r, b.i, b.j, b.k);
	return a;
end
quaternion.qPow = qPow;

function quaternion.inverse(a)
	a.r, a.i, a.j, a.k = qInverse(a.r, a.i, a.j, a.k);
	return a;
end
quaternion.qInverse = qInverse;

function quaternion.rotateVector(a,v)
	return qRotateV(a.r, a.i, a.j, a.k, v.x, v.y, v.z);
end  
quaternion.qRotateV = qRotateV;

function quaternion.slerp(a, b, t)
	a.r, a.i, a.j, a.k = qSlerp(a.r, a.i, a.j, a.k, b.r, b.i, b.j, b.k, t);
	return a;
end
quaternion.qSlerp = qSlerp;

--TODO: reimplement in matricies, maybe.
function quaternion.quaternionToMatrix(a,scale,translation)--sub-table represents a row
  local ar = a.r;
  local ai = a.i;
  local aj = a.j;
  local ak = a.k;
  if translation then
    return 
      scale*(1 - 2*aj*aj - 2*ak*ak ), scale*(2*ai*aj - 2*ak*ar ), scale*(2*ai*ak + 2*aj*ar),translation[1],
      scale*(2*ai*aj + 2*ak*ar) , scale*(1 - 2*ai*ai - 2*ak*ak), scale*(2*aj*ak - 2*ai*ar),translation[2],
      scale*(2*ai*ak - 2*aj*ar) , scale*(2*aj*ak + 2*ai*ar) , scale*(1- 2*ai*ai - 2*aj*aj),translation[3],
      0,0,0,1;
  else
    return 
		scale*(1 - 2*aj*aj - 2*ak*ak ), scale*(2*ai*aj - 2*ak*ar ), scale*(2*ai*ak + 2*aj*ar),
		scale*(2*ai*aj + 2*ak*ar) , scale*(1 - 2*ai*ai - 2*ak*ak), scale*(2*aj*ak - 2*ai*ar),
		scale*(2*ai*ak - 2*aj*ar) , scale*(2*aj*ak + 2*ai*ar) , scale*(1- 2*ai*ai - 2*aj*aj);
  end
end

return quaternion
