--[[
	identifier generation

	uuid is version 4, ulid is an alternative to uuid (see
	https://github.com/ulid/spec).

	todo:
		this ulid isn't guaranteed to be sortable for ulids generated
		within the same second yet
]]

local path = (...):gsub("identifier", "")

local identifier = {}

--(internal; use a provided random generator object, or not)
local function _random(rng, ...)
	if rng then return rng:random(...) end
	if love then return love.math.random(...) end
	return math.random(...)
end

local uuid4_template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

--generate a UUID version 4
function identifier.uuid4(rng)
	--x should be 0x0-0xf, the single y should be 0x8-0xb
	--4 should always just be 4 (denoting uuid version)
    local out = uuid4_template:gsub("[xy]", function (c)
        return string.format(
			"%x",
			c == "x" and _random(rng, 0x0, 0xf) or _random(rng, 0x8, 0xb)
		)
    end)

	return out
end

--crockford's base32 https://en.wikipedia.org/wiki/Base32
local _encoding = {
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M",
	"N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"
}

--since ulid needs time since unix epoch with miliseconds, we can just
--use socket. if that's not loaded, they'll have to provide their own
local function _now(time_func, ...)
	if package.loaded.socket then return package.loaded.socket.gettime(...) end
	if pcall(require, "socket") then return require("socket").gettime(...) end
	if time_func then return time_func(...) end
	error("assertion failed: socket can't be found and no time function provided")
end

--generate an ULID using this rng at this time (now by default)
--implementation based on https://github.com/Tieske/ulid.lua
function identifier.ulid(rng, time)
	time = math.floor((time or _now()) * 1000)

	local time_part = {}
	local random_part = {}

	for i = 10, 1, -1 do
		local mod = time % #_encoding
		time_part[i] = _encoding[mod + 1]
		time = (time - mod) / #_encoding
	end

	for i = 1, 16 do
		random_part[i] = _encoding[math.floor(_random(rng) * #_encoding) + 1]
	end

	return table.concat(time_part) .. table.concat(random_part)
end

return identifier
