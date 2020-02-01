--[[
	core modules

	if required as the "entire library" (ie by this file), puts everything into
	global namespace as it'll presumably be commonly used

	if not, several of the modules work as "normal" modules and return a table
	for local-friendly use
]]

local path = ...
local function relative_file(p)
	return table.concat({path, p}, ".")
end

require(relative_file("oo"))

require(relative_file("math"))

require(relative_file("table"))
require(relative_file("stable_sort"))

require(relative_file("functional"))
sequence = require(relative_file("sequence"))
unique_mapping = require(relative_file("unique_mapping"))

vec2 = require(relative_file("vec2"))
intersect = require(relative_file("intersect"))

state_machine = require(relative_file("state_machine"))

async = require(relative_file("async"))

manual_gc = require(relative_file("manual_gc"))
