--[[
    uuid generation
]]

local path = (...):gsub("uuid", "")

local uuid = {}

--(internal; use a provided random generator object, or not)
local function _random(rng, ...)
	if rng then return rng:random(...) end
	if love then return love.math.random(...) end
	return math.random(...)
end

local uuid4_template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

--generate a UUID version 4 (random)
function uuid.uuid4(rng)
	-- x should be 0x0-0xF, the single y should be 0x8-0xB
	-- 4 should always just be 4 (denoting uuid version)
    local out = uuid4_template:gsub("[xy]", function (c)
        return string.format(
			"%x",
			c == "x" and _random(rng, 0x0, 0xF) or _random(rng, 0x8, 0xB)
		)
    end)

	return out
end

-- crockford's base32 https://en.wikipedia.org/wiki/Base32
local _encoding = {
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M",
	"N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"
}

--since ulid needs time since unix epoch with miliseconds, we can just
--use socket. if that's not loaded, they'll have to provide their own
local function _now(time_func, ...)
	if package.loaded.socket then return package.loaded.socket.gettime(...) end
	if require("socket") then return require("socket").gettime(...) end
	if time_func then return time_func(...) end
	error("assertion failed: socket can't be found and no time function provided")
end

--generate the time part of an ulid
local function _encode_time(time)
	time = math.floor((time or _now()) * 1000)

	local out = {}

	for i = 10, 1, -1 do
		local mod = time % #_encoding
		out[i] = _encoding[mod + 1]
		time = (time - mod) / #_encoding
	end

	return table.concat(out)
end

--generate the random part of an ulid
local function _encode_random(rng)
	local out = {}

	for i = 1, 10 do
		out[i] = _encoding[math.floor(_random(rng) * #_encoding) + 1]
	end

	return table.concat(out)
end

--generate an ULID using this rng at this time
--see https://github.com/ulid/spec
--implementation based on https://github.com/Tieske/ulid.lua
function uuid.ulid(rng, time)
	return _encode_time(time) .. _encode_random(rng)
end

return uuid
