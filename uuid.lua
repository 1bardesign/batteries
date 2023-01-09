--[[
    uuid generation
]]

local path = (...):gsub("uuid", "")

local uuid = {}

--helper for optionally passed random; defaults to love.math.random if present, otherwise math.random
local _global_random = math.random
if love and love.math and love.math.random then
	_global_random = love.math.random
end

local function _random(min, max, r)
	return r and r:random(min, max)
		or _global_random(min, max)
end

local uuid4_template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

--generate a UUID version 4 (random)
function uuid.uuid4()
    return uuid4_template:gsub("[xy]", function (c)
        -- x should be 0x0-0xF, the single y should be 0x8-0xB
        -- 4 should always just be 4 (denoting uuid version)
        return string.format("%x", c == "x" and _random(0x0, 0xF) or _random(0x8, 0xB))
    end)
end

return uuid
