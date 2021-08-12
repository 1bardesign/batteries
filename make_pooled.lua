--[[
	add pooling functionality to a class

	adds a handful of class and instance methods to do with pooling
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
		if #_pool == 0 then
			return class(...)
		end
		local instance = class:drain_pool()
		instance:new(...)
		return instance
	end

	--release a object to the pool
	function class:release()
		if #_pool < _pool_limit then
			table.insert(_pool, self)
		end
	end
end
