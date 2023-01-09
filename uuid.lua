--[[
    uuid generation
]]

local path = (...):gsub("uuid", "")

local uuid = {}

--(internal; use a provided random generator object, or not)
local function _random(rng, ...)
	if rng then return rng:random(...) end
	if love then return nlove.math.random(...) end
	return math.random(...)
end

local uuid4_template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

--generate a UUID version 4 (random)
function uuid.uuid4(rng)
    return uuid4_template:gsub("[xy]", function (c)
        -- x should be 0x0-0xF, the single y should be 0x8-0xB
        -- 4 should always just be 4 (denoting uuid version)
        return string.format("%x", c == "x" and _random(rng, 0x0, 0xF) or _random(rng, 0x8, 0xB))
    end)
end

return uuid
