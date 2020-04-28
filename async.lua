--[[
	simple kernel for async tasks running in the background
	
	can "stall" a task by yielding the string "stall"
		this will suspend the coroutine until the rest of
		the queue has been processed or stalled
		and can early-out update_for_time

	todo: 
		multiple types of callbacks
			finish, error, step
		getting a reference to the task for manipulation
			attaching multiple callbacks
			cancelling
]]

local path = (...):gsub("async", "")
local class = require(path .. "class")

local async = class()

function async:new()
	return self:init({
		tasks = {},
		tasks_stalled = {},
	})
end

--add a task to the kernel
function async:call(f, args, callback, error_callback)
	table.insert(self.tasks, {
		coroutine.create(f),
		args or false,
		callback or false,
		error_callback or false,
	})
end

--add an already-existing coroutine to the kernel
function async:add(co, args, callback, error_callback)
	table.insert(self.tasks, {
		co,
		args or false,
		callback or false,
		error_callback or false,
	})
end

--update some task in the kernel
function async:update()
	--grab task definition
	local td = table.remove(self.tasks, 1)
	if not td then
		--have we got stalled tasks to re-try?
		if #self.tasks_stalled > 0 then
			--swap queues rather than churning elements
			self.tasks_stalled, self.tasks = self.tasks, self.tasks_stalled
			td = table.remove(self.tasks, 1)
		else
			return false
		end
	end
	--run a step
	--(using unpack because coroutine is also nyi and it's core to this async model)
	local co, args, cb, error_cb = unpack(td)
	--(8 temps rather than table churn capturing varargs)
	local success, a, b, c, d, e, f, g, h = coroutine.resume(co, unpack(args))
	--error?
	if not success then
		if error_cb then
			error_cb(a)
		else
			error("failure in async task: "..a)
		end
	end
	--check done
	if coroutine.status(co) == "dead" then
		--done? run callback with result
		if cb then
			cb(a, b, c, d, e, f, g, h)
		end
	else
		--if not completed, re-add to the appropriate queue
		if a == "stall" then
			--add to stalled queue as signalled stall
			table.insert(self.tasks_stalled, td)
		else
			table.insert(self.tasks, td)
		end
	end

	return true
end

--update tasks for some amount of time
function async:update_for_time(t, early_out_stalls)
	local now = love.timer.getTime()
	while love.timer.getTime() - now < t do
		if not self:update() then
			break
		end
		--all stalled?
		if early_out_stalls and #self.tasks == 0 then
			break
		end
	end
end

--add a function to run after a certain delay (in seconds)
function async:add_timeout(f, delay)
	local trigger_time = love.timer.getTime() + delay
	self:call(function()
		while love.timer.getTime() < trigger_time do
			coroutine.yield("stall")
		end
		f()
	end)
end

--add a function to run repeatedly every delay (in seconds)
--note: not super useful currently unless you plan to destroy the async object
--		as there's no way to remove tasks :)
function async:add_interval(f, delay)
	local trigger_time = love.timer.getTime() + delay
	self:call(function()
		while true do
			while love.timer.getTime() < trigger_time do
				coroutine.yield("stall")
			end
			f()
			trigger_time = trigger_time + delay
		end
	end)
end

return async