--[[
	state machine

	a finite state machine implementation;
	each state is a table with optional enter, exit, update and draw callbacks
	which each optionally take the machine, and the state table as arguments

	on changing state, the outgoing state's exit callback is called, then the incoming state's
	enter callback is called.

	on update, the current state's update callback is called
	on draw, the current state's draw callback is called

	TODO: consider coroutine friendliness
]]

local path = (...):gsub("state_machine", "")
local class = require(path .. "class")

local state_machine = class()
function state_machine:new(states, start)
	self = self:init({
		states = states or {},
		current_state = ""
	})

	if start then
		self:set_state(start)
	end

	return self
end

-------------------------------------------------------------------------------
--internal helpers

function state_machine:_get_state()
	return self.states[self.current_state]
end

--make an internal call, with up to 4 arguments
function state_machine:_call(name, a, b, c, d)
	local state = self:_get_state()
	if state and type(state[name]) == "function" then
		return state[name](self, state, a, b, c, d)
	end
	return nil
end

-------------------------------------------------------------------------------
--various checks

function state_machine:in_state(name)
	return self.current_state == name
end

function state_machine:has_state(name)
	return self.states[name] ~= nil
end

-------------------------------------------------------------------------------
--state adding/removing

--add a state
function state_machine:add_state(name, data)
	if self.has_state(name) then
		error("error: added duplicate state "..name)
	else
		self.states[name] = data
		if self:in_state(name) then
			self:_call("enter")
		end
	end

	return self
end

--remove a state
function state_machine:remove_state(name)
	if not self.has_state(name) then
		error("error: removed missed state "..name)
	else
		if self:in_state(name) then
			self:_call("exit")
		end
		self.states[name] = nil
	end

	return self
end

--hard-replace a state table
--if do_transitions is truthy and we're replacing the current state,
--exit is called on the old state and enter is called on the new state
function state_machine:replace_state(name, data, do_transitions)
	local current = self:in_state(name)
	if do_transitions and current then
		self:_call("exit")
	end
	self.states[name] = data
	if do_transitions and current then
		self:_call("enter")
	end

	return self
end

--ensure a state doesn't exist
function state_machine:clear_state(name)
	return self:replace_state(name, nil, true)
end

-------------------------------------------------------------------------------
--transitions and updates

function state_machine:set_state(state, reset)
	if self.current_state ~= state or reset then
		self:_call("exit")
		self.current_state = state
		self:_call("enter")
	end
	return self
end

--perform an update
--pass in an optional delta time which is passed as an arg to the state functions
function state_machine:update(dt)
	return self:_call("update", dt)
end

function state_machine:draw()
	self:_call("draw")
end

return state_machine