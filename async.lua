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
		proper error traces for coroutines with async:add, additional wrapper?
]]

local path = (...):gsub("async", "")
local assert = require(path .. "assert")
local class = require(path .. "class")
local tablex = require(path .. "tablex")

local async = class({
	name = "async",
})

function async:new()
	self.tasks = {}
	self.tasks_stalled = {}
end

local capture_callstacks
if love and love.system and love.system.getOS() == 'Web' then
	--do no extra wrapping under lovejs because using xpcall
	--	causes a yield across a c call boundary
	capture_callstacks = function(f)
		return f
	end
else
	capture_callstacks = function(f)
		--report errors with the coroutine's callstack instead of one coming
		--	from async:update
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
	return self:add(coroutine.create(f), args, callback, error_callback)
end

--add an already-existing coroutine to the kernel
function async:add(co, args, callback, error_callback)
	local task = {
		co,
		args or {},
		callback or false,
		error_callback or false,
	}
	table.insert(self.tasks, task)
	return task
end

--remove a running task based on the reference we got earlier
function async:remove(task)
	task.remove = true
	if coroutine.status(task[1]) == "running" then
		--removed the current running task
		return true
	else
		--remove from the queues
		return tablex.remove_value(self.tasks, task)
			or tablex.remove_value(self.tasks_stalled, task)
	end
end

--separate local for processing a resume;
--	because the results come as varargs this way
local function process_resume(self, task, success, msg, ...)
	local co, args, cb, error_cb = unpack(task)
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
	if coroutine.status(co) == "dead" or task.remove then
		--done? run callback with result
		if cb then
			cb(msg, ...)
		end
	else
		--if not completed, re-add to the appropriate queue
		if msg == "stall" then
			--add to stalled queue as signalled stall
			table.insert(self.tasks_stalled, task)
		else
			table.insert(self.tasks, task)
		end
	end
end

--update some task in the kernel
function async:update()
	--grab task definition
	local task = table.remove(self.tasks, 1)
	if not task then
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
	local co, args = unpack(task)
	process_resume(self, task, coroutine.resume(co, unpack(args)))

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

--await the result of a function or set of functions
--return the results
function async:await(to_call, args)
	local single_call = false
	if type(to_call) == "function" then
		to_call = {to_call}
		single_call = true
	end

	local awaiting = #to_call
	local results = {}
	for i, v in ipairs(to_call) do
		self:call(function(...)
			table.insert(results, {v(...)})
			awaiting = awaiting - 1
		end, args)
	end

	while awaiting > 0 do
		async.stall()
	end

	--unwrap
	if single_call then
		results = results[1]
	end

	return results
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

--eventually get a result, inline
--	repeatedly calls the provided function until it returns something,
--	stalling each time it doesn't, returning the result in the end
function async.value(f)
	local r = f()
	while not r do
		async.stall()
		r = f()
	end
	return r
end

--make an iterator or search function asynchronous, stalling every n (or 1) iterations
--can be useful with functional queries as well, if they are done in a coroutine.
function async.wrap_iterator(f, stall, n)
	stall = stall or false
	n = n or 1
	local count = 0
	return function(...)
		count = count + 1
		if count >= n then
			count = 0
			if stall then
				async.stall()
			else
				coroutine.yield()
			end
		end
		return f(...)
	end
end
return async
