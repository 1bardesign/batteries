--[[
	basic timer class

	can check for expiry and register a callback to be called on progress and on finish

	if you find yourself using lots of these for pushing stuff into the future,
	look into async.lua and see if it might be a better fit!
]]

local path = (...):gsub("timer", "")
local class = require(path .. "class")
local timer = class({
	name = "timer",
})

--create a timer, with optional callbacks
--callbacks receive as arguments:
--	the current progress as a number from 0 to 1, so can be used for lerps
--	the timer object, so can be reset if needed
function timer:new(time, on_progress, on_finish)
	self.time = 0
	self.timer = 0
	self.on_progress = on_progress
	self.on_finish = on_finish
	self:reset(time)
end

--update this timer, calling the relevant callback if it exists
function timer:update(dt)
	if not self:expired() then
		self.timer = self.timer + dt

		--set the expired state and get the relevant callback
		self.has_expired = self.timer >= self.time
		local cb = self:expired()
			and self.on_finish
			or self.on_progress

		if cb then
			cb(self:progress(), self)
		end
	end
end

--check if the timer has expired
function timer:expired()
	return self.has_expired
end

--get the timer's progress from 0 to 1
function timer:progress()
	return math.min(self.timer / self.time, 1)
end

--reset the timer; optionally change the time
--will resume calling the same callbacks, so can be used for intervals
function timer:reset(time)
	self.timer = 0
	self.time = math.max(time or self.time, 1e-6) --negative time not allowed
	self.has_expired = false
	return self
end

return timer
