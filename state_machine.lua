--[[
	state machine

	a finite state machine implementation;
	each state is a table with optional enter, exit, update and draw callbacks
	which each optionally take the machine, the state table, and varargs as arguments

	on changing state, the outgoing state's exit callback is called, then the incoming state's
	enter callback is called.

	on update, the current state's update callback is called
	on draw, the current state's draw callback is called

	TODO: consider coroutine friendliness

	TODO: consider refactoring the callback signatures to allow using objects with methods
	      like update(dt)/draw() directly
	      current pattern means they need to be wrapped (as in :as_state())
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

--make an internal call
function state_machine:_call(name, ...)
	local state = self:_get_state()
	if state then
		if type(state[name]) == "function" then
			return state[name](self, state, ...)
		elseif type(state) == "function" then
			return state(self, name, ...)
		end
	end
	return nil
end

--make an internal call and transition if the return value is a valid state
--return the value if it isn't a valid state
function state_machine:_call_and_transition(name, ...)
	local r = self:_call(name, ...)
	if self:has_state(r) then
		self:set_state(r, r == self.current_state)
		return nil
	end
	return r
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
	if self:has_state(name) then
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
	if not self:has_state(name) then
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
		self:_call_and_transition("enter")
	end

	return self
end

--ensure a state doesn't exist; transition out of it if we're currently in it
function state_machine:clear_state(name)
	return self:replace_state(name, nil, true)
end

-------------------------------------------------------------------------------
--transitions and updates

--set the current state
--if the enter callback of the target state returns a valid state name, then
--	it is transitioned to in turn, and so on until the machine is at rest
function state_machine:set_state(state, reset)
	if self.current_state ~= state or reset then
		self:_call("exit")
		self.current_state = state
		self:_call_and_transition("enter")
	end
	return self
end

--perform an update
--pass in an optional delta time which is passed as an arg to the state functions
--if the state update returns a string, and we have that state
--	then we change state (reset if it's the current state)
--	and return nil
--otherwise, the result is returned
function state_machine:update(dt)
	return self:_call_and_transition("update", dt)
end

--draw the current state
function state_machine:draw()
	self:_call("draw")
end

--wrap a state machine in a table suitable for use directly as a state in another state_machine
--upon entry, this machine will be forced into enter_state
--the parent will be accessible under m.parent
function state_machine:as_state(enter_state)
	if not self._as_state then
		self._as_state = {
			enter = function(m, s)
				self.parent = m
				self:set_state(enter_state, true)
			end,
			update = function(m, s, dt)
				return self:update(dt)
			end,
			draw = function(m, s)
				return self:draw()
			end,
		}
	end
	return self._as_state
end

return state_machine
