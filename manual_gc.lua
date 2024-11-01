--[[
	"semi-manual" garbage collection

	specify a time budget and a memory ceiling per call.

	called once per frame, this will spread any big collections
	over several frames, and "catch up" when there is too much
	work to do.

	This keeps GC time burden much more predictable.

	The memory ceiling provides a safety backstop.
	if exceeded it will trigger a "full" collection, and this will
	hurt performance - you'll notice the hitch. If you hit your ceiling,
	it indicates you likely need to either find a way to generate less
	garbage, or spend more time each frame collecting.

	the function instructs the garbage collector only as small a step
	as possible each iteration. this prevents the "spiky" collection
	patterns, though with particularly large sets of tiny objects,
	the start of a collection can still take longer than you might like.

	default values:

	time_budget - 1ms (1e-3)
		adjust down or up as needed. games that generate more garbage
		will need to spend longer on gc each frame.

	memory_ceiling - unlimited
		a good place to start might be something like 64mb, though some games
		will need much more. remember, this is lua memory, not the total memory
		consumption of your game.

	disable_otherwise - false
		disabling the gc completely is dangerous - any big allocation
		event (eg - level gen) could push you to an out of memory
		situation and crash your game. test extensively before you
		ship a game with this set true.
]]

return function(time_budget, memory_ceiling, disable_otherwise)
	time_budget = time_budget or 1e-3
	memory_ceiling = memory_ceiling or math.huge
	local max_steps = 1000
	local steps = 0
	local start_time = love.timer.getTime()
	while
		love.timer.getTime() - start_time < time_budget and
		steps < max_steps
	do
		if collectgarbage("step", 1) then
			break
		end
		steps = steps + 1
	end
	--safety net
	if collectgarbage("count") / 1024 > memory_ceiling then
		collectgarbage("collect")
	end
	--don't collect gc outside this margin
	if disable_otherwise then
		collectgarbage("stop")
	end
end
