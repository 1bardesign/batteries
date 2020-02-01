--[[
	simple kernel for async tasks running in the background
	
	todo: 
		multiple types of callbacks
			finish, error, step
		getting a reference to the task for manipulation
			attaching multiple callbacks
			cancelling
]]

local async = class()

function async:new()
	return self:init({
		tasks = {},
	})
end

--add a task to the kernel
function async:run(f, args, cb, error_cb)
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
		return false
	end
	--run a step
	local co, args, cb, error_cb = td[1], td[2], td[3], td[4]
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
	if coroutine.status(task) == "dead" then
		--done? run callback with result
		cb(a, b, c, d, e, f, g, h)
	else
		--if not done, re-add
		table.insert(self.tasks, taskdef)
	end

	return true
end

--update tasks for some amount of time
function async:update_for_time(t)
	local now = love.timer.getTime()
	while love.timer.getTime() - now < t do
		if not self:update() then
			break
		end
	end
end

return async