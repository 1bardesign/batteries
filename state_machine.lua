--[[
	state machine

	a finite state machine implementation

	each state is either:

	- a table with enter, exit, update and draw callbacks (all optional)
		which each take the state table and varargs as arguments
	- a plain function
		which gets passed the current event name, the machine table, and varargs as arguments

	on changing state, the outgoing state's exit callback is called
	then the incoming state's enter callback is called
		enter can trigger another transition by returning a string

	on update, the current state's update callback is called
		the return value can trigger a transition

	on draw, the current state's draw callback is called
		the return value is discarded

	TODO: consider coroutine friendliness
]]

local path = (...):gsub("state_machine", "")
local class = require(path .. "class")

local state_machine = class({
	name = "state_machine",
})

function state_machine:new(states, start_in_state)
	self.states = states or {}
	self.current_state_name = ""
	self.prev_state_name = ""
	self.reset_state_name = start_in_state or ""
	self:reset()
end

--get the current state table (or nil if it doesn't exist)
function state_machine:current_state()
	return self.states[self.current_state_name]
end

-------------------------------------------------------------------------------
--internal helpers

--make an internal call
function state_machine:_call(name, ...)
	local state = self:current_state()
	if state then
		if type(state[name]) == "function" then
			return state[name](state, ...)
		elseif type(state) == "function" then
			return state(name, self, ...)
		end
	end
	return nil
end

--make an internal call
--	transition if the return value is a valid state name - and return nil if so
--	return the call result if it isn't a valid state name
function state_machine:_call_and_transition(name, ...)
	local r = self:_call(name, ...)
	if type(r) == "string" and self:has_state(r) then
		self:set_state(r, true)
		return nil
	end
	return r
end

-------------------------------------------------------------------------------
--various checks

function state_machine:in_state(name)
	return self.current_state_name == name
end

function state_machine:has_state(name)
	return self.states[name] ~= nil
end

-------------------------------------------------------------------------------
--state management

--add a state
function state_machine:add_state(name, state)
	if self:has_state(name) then
		error("error: added duplicate state " .. name)
	else
		self.states[name] = state
		if self:in_state(name) then
			self:_call_and_transition("enter")
		end
	end

	return self
end

--remove a state
function state_machine:remove_state(name)
	if not self:has_state(name) then
		error("error: removed missing state " .. name)
	else
		if self:in_state(name) then
			self:_call("exit")
		end
		self.states[name] = nil
	end

	return self
end

--hard-replace a state table
--	if we're replacing the current state,
--	exit is called on the old state and enter is called on the new state
--	mask_transitions can be used to prevent this if you need to
function state_machine:replace_state(name, state, mask_transitions)
	local do_transitions = not mask_transitions and self:in_state(name)
	if do_transitions then
		self:_call("exit")
	end
	self.states[name] = state
	if do_transitions then
		self:_call_and_transition("enter", self)
	end

	return self
end

--ensure a state doesn't exist; transition out of it if we're currently in it
function state_machine:clear_state(name)
	return self:replace_state(name, nil)
end

-------------------------------------------------------------------------------
--transitions and updates

--reset the machine state to whatever state was specified at creation
function state_machine:reset()
	if self.reset_state_name then
		self:set_state(self.reset_state_name, true)
	end
end

--set the current state
--	if the enter callback of the target state returns a valid state name,
--		then it is transitioned to in turn,
--		and so on until the machine is at rest
function state_machine:set_state(name, reset)
	if self.current_state_name ~= name or reset then
		self:_call("exit")
		self.prev_state_name = self.current_state_name
		self.current_state_name = name
		self:_call_and_transition("enter", self)
	end
	return self
end

--perform an update
--pass in an optional delta time, which is passed as an arg to the state functions
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

--for compatibility when a state machine is nested as a state in another machine
function state_machine:enter(parent)
	self.parent = parent
	self:reset()
end

return state_machine
