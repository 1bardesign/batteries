--[[
	basic timer class

	can check for expiry and register a callback to be called on progress and on finish

	if you find yourself using lots of these for pushing stuff into the future,
	look into async.lua and see if it might be a better fit!
]]

local path = (...):gsub("timer", "")
---@class Class
local Class = require(path .. "class")

---@class Timer
---@field private time number The total duration of the timer
---@field private timer number The current elapsed time
---@field private has_expired boolean Whether the timer has expired
---@field private on_progress function? Callback for progress updates
---@field private on_finish function? Callback for timer completion
---@field private paused boolean Whether the timer is paused
---@field private time_scale number The scale at which time passes for this timer
---@field private loop boolean Whether the timer should loop
local Timer = Class({
	name = "timer",
})

---create a timer, with optional callbacks
---callbacks receive as arguments:
---the current progress as a number from 0 to 1, so can be used for lerps
---the timer object, so can be reset if needed
---@param time number
---@param on_progress fun(...): any
---@param on_finish fun(...): any
function Timer:new(time, on_progress, on_finish)
	assert(type(time) == "number", "Time must be a number")
	assert(time > 0, "Time must be positive")
	assert(on_progress == nil or type(on_progress) == "function", "on_progress must be a function or nil")
	assert(on_finish == nil or type(on_finish) == "function", "on_finish must be a function or nil")

	self.time = 0
	self.timer = 0
	self.on_progress = on_progress
	self.on_finish = on_finish
	self.paused = false
	self.time_scale = 1
	self.loop = false
	self:reset(time)
end

---update this timer, calling the relevant callback if it exists
---@param dt number
function Timer:update(dt)
	if self.paused or self:expired() then return end

	self.timer = self.timer + (dt * self.time_scale)

	if self.timer >= self.time then
		if self.loop then
			self:reset()
		else
			self.has_expired = true
		end
	end

	--get the relevant callback
	local cb = self:expired() and self.on_finish or self.on_progress

	if cb then
		local success, err = pcall(cb, self:progress(), self)
		if not success then
			error("Timer callback error: " .. tostring(err))
		end
	end
end

---check if the timer has expired
---@return boolean
function Timer:expired()
	return self.has_expired
end

---get the timer's progress from 0 to 1
---@return number
function Timer:progress()
	return math.min(self.timer / self.time, 1)
end

---get remaining time
---@return number
function Timer:remaining()
	return math.max(self.time - self.timer, 0)
end

---reset the timer; optionally change the time
---will resume calling the same callbacks, so can be used for intervals
---@param time number?
---@return Timer
function Timer:reset(time)
	self.timer = 0
	self.time = math.max(time or self.time, 1e-6) --negative time not allowed
	self.has_expired = false
	return self
end

---set the callbacks for the timer
---@param on_progress function?
---@param on_finish function?
---@return Timer
function Timer:set_callbacks(on_progress, on_finish)
	self.on_progress = on_progress
	self.on_finish = on_finish
	return self
end

---set whether the timer should loop
---@param should_loop boolean
---@return Timer
function Timer:setLoop(should_loop)
	self.loop = should_loop
	return self
end

---set the time scale for the timer
---@param scale number
---@return Timer
function Timer:set_time_scale(scale)
	assert(type(scale) == "number", "Time scale must be a number")
	self.time_scale = scale
	return self
end

---pause the timer
---@return Timer
function Timer:pause()
	self.paused = true
	return self
end

---resume the timer
---@return Timer
function Timer:resume()
	self.paused = false
	return self
end

---check if the timer is paused
---@return boolean
function Timer:is_paused()
	return self.paused
end

---cancel the timer
---@return Timer
function Timer:cancel()
	self.timer = self.time
	self.has_expired = true
	return self
end

---clean up the timer
function Timer:destroy()
	self.on_progress = nil
	self.on_finish = nil
end

return Timer
