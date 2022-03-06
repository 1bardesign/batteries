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
local assert = require(path .. "assert")
local class = require(path .. "class")

local async = class({
	name = "async",
})

function async:new()
	self.tasks = {}
	self.tasks_stalled = {}
end

local capture_callstacks
if love.system.getOS() == 'Web' then
	-- Do no extra wrapping under lovejs because using xpcall causes "attempt
	-- to yield across metamethod/C-call boundary"
	capture_callstacks = function(f)
		return f
	end
else
	capture_callstacks = function(f)
		-- Report errors with the coroutine's callstack instead of one coming
		-- from async:update.
		return function(...)
			local results = {xpcall(f, debug.traceback, ...)}
			local success = table.remove(results, 1)
			if not success then
				error(table.remove(results, 1))
			end
			return unpack(results)
		end
	end
end

--add a task to the kernel
function async:call(f, args, callback, error_callback)
	assert:type_or_nil(args, "table", "async:call - args", 1)
	f = capture_callstacks(f)
	self:add(coroutine.create(f), args, callback, error_callback)
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

local function process_resume(self, td, success, msg, ...)
	local co, args, cb, error_cb = unpack(td)
	--error?
	if not success then
		if error_cb then
			error_cb(msg)
		else
			local err = ("failure in async task:\n\n\t%s\n")
				:format(tostring(msg))
			error(err)
		end
	end
	--check done
	if coroutine.status(co) == "dead" then
		--done? run callback with result
		if cb then
			cb(msg, ...)
		end
	else
		--if not completed, re-add to the appropriate queue
		if msg == "stall" then
			--add to stalled queue as signalled stall
			table.insert(self.tasks_stalled, td)
		else
			table.insert(self.tasks, td)
		end
	end
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
	local co, args = unpack(td)
	process_resume(self, td, coroutine.resume(co, unpack(args)))

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
