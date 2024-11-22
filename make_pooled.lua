--[[
	add pooling functionality to a class

	adds a handful of class and instance methods to do with pooling

	todo: automatically use the pool by replacing __call, so you really just need to :release()
]]

return function(class, limit)
	--shared pooled storage
	local _pool = {}
	--size limit for tuning memory upper bound
	local _pool_limit = limit or 128

	--flush the entire pool
	function class:flush_pool()
		if #_pool > 0 then
			_pool = {}
		end
	end

	--drain one element from the pool, if it exists
	function class:drain_pool()
		if #_pool > 0 then
			return table.remove(_pool)
		end
		return nil
	end

	--get a pooled object
	--(re-initialised with new, or freshly constructed if the pool was empty)
	function class:pooled(...)
		local instance = class:drain_pool()
		if not instance then
			return class(...)
		end
		instance:new(...)
		return instance
	end

	--release an object back to the pool
	function class.release(instance, ...)
		assert(instance:type() == class:type(), "wrong class released to pool")
		if #_pool < _pool_limit then
			table.insert(_pool, instance)
		end
		--recurse
		if ... then
			return class.release(...)
		end
	end
end
