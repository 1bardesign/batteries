--[[
	dead-simple publish-subscribe message bus
]]

local path = (...):gsub("pubsub", "")
local class = require(path .. "class")
local set = require(path .. "set")
local tablex = require(path .. "tablex")

local pubsub = class({
	name = "pubsub",
})

--create a new pubsub bus
function pubsub:new()
	self.subscriptions = {}
	self._defer = {}
	self._defer_stack = 0
end

--(internal; deferred area check)
function pubsub:_deferred()
	return self._defer_stack > 0
end

--(internal; enter deferred area)
function pubsub:_push_defer(event)
	self._defer_stack = self._defer_stack + 1
	if self._defer_stack > 255 then
		error("pubsub defer stack overflow; event infinite loop with event: "..tostring(event))
	end
end

--(internal; enter deferred area)
function pubsub:_defer_call(defer_f, event, callback)
	if not self:_deferred() then
		error("attempt to defer pubsub call when not required")
	end
	table.insert(self._defer, defer_f)
	table.insert(self._defer, event)
	table.insert(self._defer, callback)
end

--(internal; unwind deferred sub/unsub)
function pubsub:_pop_defer(event)
	self._defer_stack = self._defer_stack - 1
	if self._defer_stack < 0 then
		error("pubsub defer stack underflow; don't call the defer methods directly - event reported: "..tostring(event))
	end
	if self._defer_stack == 0 then
		local defer_len = #self._defer
		if defer_len then
			for i = 1, defer_len, 3 do
				local defer_f = self._defer[i]
				local defer_event = self._defer[i+1]
				local defer_cb = self._defer[i+2]
				self[defer_f](self, defer_event, defer_cb)
			end
			tablex.clear(self._defer)
		end
	end
end

--(internal; notify a callback set of an event)
function pubsub:_notify(event, callbacks, ...)
	if callbacks then
		self:_push_defer(event)
		for _, f in ipairs(callbacks:values()) do
			f(...)
		end
		self:_pop_defer(event)
	end
end

--publish an event, with optional arguments
--notifies both the direct subscribers, and those subscribed to "everything"
function pubsub:publish(event, ...)
	self:_notify(event, self.subscriptions[event], ...)
	self:_notify(event, self.subscriptions.everything, event, ...)
end

--subscribe to an event
--can be a specifically named event, or "everything" to get notified for any event
--for "everything", the callback will receive the event name as the first argument
function pubsub:subscribe(event, callback)
	if self:_deferred() then
		self:_defer_call("subscribe", event, callback)
		return
	end
	local callbacks = self.subscriptions[event]
	if not callbacks then
		callbacks = set()
		self.subscriptions[event] = callbacks
	end
	callbacks:add(callback)
end

--subscribe to an event, automatically unsubscribe once called
--return the function that can be used to unsubscribe early if needed
function pubsub:subscribe_once(event, callback)
	local f
	local called = false
	f = function(...)
		if not called then
			callback(...)
			self:unsubscribe(event, f)
			called = true
		end
	end
	self:subscribe(event, f)
	return f
end

--unsubscribe from an event
function pubsub:unsubscribe(event, callback)
	if self:_deferred() then
		self:_defer_call("unsubscribe", event, callback)
		return
	end
	local callbacks = self.subscriptions[event]
	if callbacks then
		callbacks:remove(callback)
		if callbacks:size() == 0 then
			self.subscriptions[event] = nil
		end
	end
end

--check if there is a subscriber for a given event
function pubsub:has_subscriber(event)
	return self.subscriptions[event] ~= nil
end

return pubsub
