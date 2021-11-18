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
`		proper error traces for coroutines with async:add, additional wrapper?
]]

local path = (...):gsub("async", "")
local class = require(path .. "class")

local async = class({
	name = "async",
})

function async:new()
	self.tasks = {}
	self.tasks_stalled = {}
end

--add a task to the kernel
function async:call(f, args, callback, error_callback)
	self:add(coroutine.create(function(...)
		local results = {xpcall(f, debug.traceback, ...)}
		local success = table.remove(results, 1)
		if not success then
			error(table.remove(results, 1))
		end
		return unpack(results)
	end), args, callback, error_callback)
end

--add an already-existing coroutine to the kernel
function async:add(co, args, callback, error_callback)
	table.insert(self.tasks, {
		co,
		args or {},
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
			return self:update()
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
			local err = ("failure in async task:\n\n\t%s\n")
				:format(tostring(a))
			error(err)
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
	self:call(function()
		async.wait(delay)
		f()
	end)
end

--add a function to run repeatedly every delay (in seconds)
--note: not super useful currently unless you plan to destroy the whole async kernel
--		as there's no way to remove tasks :)
function async:add_interval(f, delay)
	self:call(function()
		while true do
			async.wait(delay)
			f()
		end
	end)
end

--static async operation helpers
--	these are not methods on the async object, but are
--	intended to be called with dot syntax on the class itself

--stall the current coroutine
function async.stall()
	return coroutine.yield("stall")
end

--make the current coroutine wait
function async.wait(time)
	if not coroutine.running() then
		error("attempt to wait in main thread, this will block forever")
	end
	local now = love.timer.getTime()
	while love.timer.getTime() - now < time do
		async.stall()
	end
end

return async
