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

local async = {}
async._mt = {__index = async}

function async:new()
	return setmetatable({
		tasks = {},
		tasks_stalled = {},
	}, self._mt)
end

--add a task to the kernel
function async:call(f, args, cb, error_cb)
	table.insert(self.tasks, {
		coroutine.create(f),
		args,
		cb,
		error_cb,
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
	local co, args, cb, error_cb = td[1], td[2], td[3], td[4]
	--(reuse these 8 temps)
	local a, b, c, d, e, f, g, h
	if args then
		a, b, c, d, e, f, g, h = unpack(args)
	end
	local success, a, b, c, d, e, f, g, h = coroutine.resume(co, a, b, c, d, e, f, g, h)
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