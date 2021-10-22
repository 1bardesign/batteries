--[[
	very simple benchmarking tools for finding out
	how long something takes to run
]]

local path = (...):gsub("measure", "")
local functional = require(path .. "functional")

local measure = {}

--replace this with whatever your highest accuracy timer is
--os.time will almost certainly be too coarse
measure.get_time = os.time
if love and love.timer then
	--love.timer is _much_ better
	measure.get_time = love.timer.getTime
end

--measure the mean, minimum, and maximum time taken in seconds to run test_function
--over several runs (default 1000).
--warmup_runs can be provided to give the JIT or cache some time to warm up, but
--are off by default
function measure.time_taken(test_function, runs, warmup_runs)
	--defaults
	runs = runs or 1000
	warmup_runs = warmup_runs or 0
	--collect data
	local times = {}
	for i = 1, warmup_runs + runs do
		local start_time = measure.get_time()
		test_function()
		local end_time = measure.get_time()
		if i > warmup_runs then
			table.insert(times, end_time - start_time)
		end
	end

	local mean = functional.mean(times)
	local min, max = functional.minmax(times)
	return mean, min, max
end

--measure the mean, minimum, and maximum memory increase in kilobytes for a run of test_function
--doesn't modify the gc state each run, to emulate normal running conditions
function measure.memory_taken(test_function, runs, warmup_runs)
	--defaults
	runs = runs or 1000
	warmup_runs = warmup_runs or 0
	--collect data
	local mems = {}
	for i = 1, warmup_runs + runs do
		local start_mem = collectgarbage("count")
		test_function()
		local end_mem = collectgarbage("count")
		if i > warmup_runs then
			table.insert(mems, math.max(0, end_mem - start_mem))
		end
	end

	local mean = functional.mean(mems)
	local min, max = functional.minmax(mems)
	return mean, min, max
end

--measure the mean, minimum, and maximum memory increase in kilobytes for a run of test_function
--performs a full collection each run and then stops the gc, so the amount reported is as close as possible to the total amount allocated each run
function measure.memory_taken_strict(test_function, runs, warmup_runs)
	--defaults
	runs = runs or 1000
	warmup_runs = warmup_runs or 0
	--collect data
	local mems = {}
	for i = 1, warmup_runs + runs do
		collectgarbage("collect")
		collectgarbage("stop")
		local start_mem = collectgarbage("count")
		test_function()
		local end_mem = collectgarbage("count")
		if i > warmup_runs then
			table.insert(mems, math.max(0, end_mem - start_mem))
		end
	end
	collectgarbage("restart")

	local mean = functional.mean(mems)
	local min, max = functional.minmax(mems)
	return mean, min, max
end

return measure
