--[[
	basic timer class

	can check for expiry and register a callback to be called on progress and on finish

	if you find yourself using lots of these for pushing stuff into the future,
	look into async.lua and see if it might be a better fit!
]]

local path = (...):gsub("timer", "")
local class = require(path .. "class")
local timer = class()

--create a timer, with optional callbacks
--callbacks recieve as arguments:
--	the current progress as a number from 0 to 1, so can be used for lerps
--	the timer object, so can be reset if needed
function timer:new(time, on_progress, on_finish)
	return self:init({
		time = 0, --set in the reset below
		timer = 0,
		on_progress = on_progress,
		on_finish = on_finish,
	}):reset(time)
end

--update this timer, calling the relevant callback if it exists
function timer:update(dt)
	if not self:expired() then
		self.timer = self.timer + dt

		--get the relevant callback
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
	return self.timer >= self.time
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
	return self
end

return timer
