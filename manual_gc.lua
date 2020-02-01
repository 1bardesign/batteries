--[[
	"semi-manual" garbage collection

	specify a time budget and a memory ceiling per call.

	called once per frame, this will spread any big collections
	over a couple of frames, and "catch up" when there is. This
	keeps GC burden much more predictable.

	The memory ceiling provides some level of "relief valve" - if
	exceeded it will trigger a "full" collection, but this is
	likely to hurt performance. If you hit the ceiling, it
	indicates you likely need to either generate less garbage
	or spent more time each frame collecting.

	1ms (1e-3) is a good place to start for the budget, adjust
	down or up as needed. games that generate more garbage will
	need to spend longer on gc each frame.

	64mb is a good place to start for the memory ceiling, though
	some games will need much more.

	the function steps the garbage collector only do a small step
	each time. this prevents the start of collection from "spiking",
	though it still causes some with particularly large sets
]]

return function(time_budget, safetynet_megabytes, disable_otherwise)
	local max_steps = 1000
	local steps = 0
	local start_time = love.timer.getTime()
	while
		love.timer.getTime() - start_time < time_budget and
		steps < max_steps
	do
		collectgarbage("step", 1)
		steps = steps + 1
	end
	--safety net
	if collectgarbage("count") / 1024 > safetynet_megabytes then
		collectgarbage("collect")
	end
	--don't collect gc outside this margin
	if disable_otherwise then
		collectgarbage("stop")
	end
end