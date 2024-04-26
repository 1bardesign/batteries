--[[
	barebones oop basics

	construction

		call the class object to construct a new instance

		this will construct a new table, assign it as a class
		instance, and call `new`

		if you are defining a subclass, you will need to call
		`self:super(...)` as part of `new` to complete superclass
		construction - if done correctly this will propagate
		up the chain and you wont have to think about it

	classes are used as metatables directly so that
	metamethods "just work" - except for index, which is
	used to hook up instance methods

		classes do use a prototype chain for inheritance, but
		also copy their interfaces (including superclass)

		we copy interfaces in classes rather than relying on
		a prototype chain, so that pairs on the class gets
		all the methods when implemented as an interface

		class properties are not copied and should likely
		be accessed through the concrete class object so
		that everything refers to the same object

	arguments (all optional):
		name (string):
			the name to use for type()
		extends (class):
			superclass for basic inheritance
		implements (ordered table of classes):
			mixins/interfaces
		default_tostring (boolean):
			whether or not to provide a default tostring function

]]

--generate unique increasing class ids
local class_id_gen = 0
local function next_class_id()
	class_id_gen = class_id_gen + 1
	return class_id_gen
end

--implement an interface into c
local function implement(c, interface)
	c.__is[interface] = true
	for k, v in pairs(interface) do
		if c[k] == nil and type(v) == "function" then
			c[k] = v
		end
	end
end

--build a new class
local function class(config)
	local class_id = next_class_id()

	config = config or {}
	local extends = config.extends
	local implements = config.implements
	local src_location = "call location not available"
	if debug and debug.getinfo then
		local dinfo = debug.getinfo(2)
		local src = dinfo.short_src
		local line = dinfo.currentline
		src_location = ("%s:%d"):format(src, line)
	end
	local name = config.name or ("unnamed class %d (%s)"):format(
		class_id,
		src_location
	)

	local c = {}

	--prototype
	c.__index = c

	--unique generated id per-class
	c.__id = class_id

	--the class name for type calls
	c.__type = name

	--return the name of the class
	function c:type()
		return self.__type
	end

	if config.default_tostring then
		function c:__tostring()
			return name
		end
	end

	--class metatable to set up constructor call
	setmetatable(c, {
		__call = function(self, ...)
			local instance = setmetatable({}, self)
			instance:new(...)
			return instance
		end,
		__index = extends,
	})

	--checking class membership for probably-too-dynamic code
	--returns true for both extended classes and implemented interfaces
	--(implemented with a hashset for fast lookups)
	c.__is = {}
	c.__is[c] = true
	function c:is(t)
		return self.__is[t] == true
	end

	--get the inherited class for super calls if/as needed
	--allows overrides that still refer to superclass behaviour
	c.__super = extends

	--perform a (partial) super construction for an instance
	--for any nested super calls, it'll call the relevant one in the
	--heirarchy, assuming no super calls have been missed
	function c:super(...)
		if not c.__super then return end
		--hold reference so we can restore
		local current_super = c.__super
		--push next super
		c.__super = c.__super.__super
		--call
		current_super.new(self, ...)
		--restore
		c.__super = current_super
	end


	if c.__super then
		--implement superclass interface
		implement(c, c.__super)
	end


	--implement all the passed interfaces/mixins
	--in order provided
	if implements then
		for _, interface in ipairs(implements) do
			implement(c, interface)
		end
	end

	--default constructor, just proxy to the super constructor
	--override it and use to set up the properties of the instance
	--but don't forget to call the super constructor!
	function c:new(...)
		self:super(...)
	end

	--done
	return c
end

return class
