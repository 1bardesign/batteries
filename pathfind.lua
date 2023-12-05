--[[
	general pathfinding with a general goal
]]

local path = (...):gsub("pathfind", "")
local sort = require(path .. "sort")

--helper to generate a constant value for default weight, heuristic
local generate_constant = function() return 1 end

--find a path in a weighted graph
--	uses A* algorithm internally
--returns a table of all the nodes from the start to the goal,
--	or false if no path was found
--arguments table requires the following fields
--	start - the value of the node to start from
--		alias: start_node
--	is_goal - a function which takes a node, and returns true is a goal
--		alias: goal
--	neighbours - a function which takes a node, and returns a table of neighbour nodes
--		alias: generate_neighbours
--	distance - a function which given two nodes, returns the distance between them
--		defaults to a constant distance, which means all steps between nodes have the same cost
--		alias: weight, g
--	heuristic - a function which given a node, returns a heuristic indicative of the distance to the goal;
--		can be used to speed up searches at the cost of accuracy by returning some proportion higher than the actual distance
--		defaults to a constant value, which means the A* algorithm degrades to breadth-first search
--		alias: h
local function pathfind(args)
	local start = args.start or args.start_node
	local is_goal = args.is_goal or args.goal
	local neighbours = args.neighbours or args.generate_neighbours
	local distance = args.distance or args.weight or args.g or generate_constant
	local heuristic = args.heuristic or args.h or generate_constant

	local predecessor = {}
	local seen = {}
	local f_score = {[start] = 0}
	local g_score = {[start] = 0}

	local function search_compare(a, b)
		return
			(f_score[a] or math.huge) >
			(f_score[b] or math.huge)
	end
	local to_search = {}

	local current = start
	while current and not is_goal(current) do
		seen[current] = true
		for i, node in ipairs(neighbours(current)) do
			if not seen[node] then
				local tentative_g_score = (g_score[current] or math.huge) + distance(current, node)
				if g_score[node] == nil then
					if tentative_g_score < (g_score[node] or math.huge) then
						predecessor[node] = current
						g_score[node] = tentative_g_score
						f_score[node] = tentative_g_score + heuristic(node)
					end
					table.insert(to_search, node)
					sort.insertion_sort(to_search, search_compare)
				end
			end
		end
		current = table.remove(to_search)
	end

	--didn't make it to the goal
	if not current or not is_goal(current) then
		return false
	end

	--build up result path
	local result = {}
	while current do
		table.insert(result, 1, current)
		current = predecessor[current]
	end
	return result
end

-- Based on https://github.com/lewtds/pathfinder.lua/blob/master/pathfinder.lua
-- with modification to allow for generalised goals/heuristics
-- Modified 2022 Max Cahill

-- Original License:
-- Copyright © 2016 Trung Ngo

-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the \"Software\"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

return pathfind
