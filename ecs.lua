--[[
MIT LICENSE

Copyright (c) 2025 WiredSoft SAS

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local _ECS = {
    E = {},
    C = {},
    S = {},
    ---Keep track of which queries need updating when components change
    ---@type table<number, {dirty: boolean, include_components: table<number, boolean>, exclude_components: table<number, boolean>}>
    dirty_queries = {}
}

---Private API
_ECS.E = {
    next_e_id = 1,
    ---@type table<number, boolean|nil>
    entities = {},
    ---@return integer
    create_entity = function()
        local e_id = _ECS.E.next_e_id
        _ECS.E.next_e_id = _ECS.E.next_e_id + 1

        _ECS.E.entities[e_id] = true -- O(1) insertion
        _ECS.E.components_map[e_id] = {}
        return e_id
    end,
    ---@param e_id number
    remove_entity = function(e_id)
        _ECS.E.entities[e_id] = nil -- O(1) removal

        -- Mark queries as dirty if they might have included this entity
        for query_id, _ in pairs(_ECS.dirty_queries) do
            _ECS.dirty_queries[query_id].dirty = true
        end

        -- Remove from components data
        for _, component_data in pairs(_ECS.C.data) do
            component_data[e_id] = nil
        end

        _ECS.E.components_map[e_id] = nil
    end,
    ---@type table<number, table<number, boolean|nil>>
    components_map = {},
    ---set/unset component in entity
    ---@param e_id number
    ---@param c_id number
    toggle_has_component = function(e_id, c_id)
        local prev = _ECS.E.components_map[e_id][c_id]
        _ECS.E.components_map[e_id][c_id] = prev == true and nil or true -- O(1) insertion/removal

        -- Mark queries that include or exclude this component as dirty
        for query_id, query in pairs(_ECS.dirty_queries) do
            if query.include_components[c_id] or query.exclude_components[c_id] then
                _ECS.dirty_queries[query_id].dirty = true
            end
        end
    end
}

_ECS.C = {
    next_c_id = 1,
    ---@type table<number, table>
    components = {},
    data = {},
    ---register a new component
    ---@param component table
    ---@return integer component_id
    register_component = function(component)
        local c_id = _ECS.C.next_c_id
        _ECS.C.next_c_id = _ECS.C.next_c_id + 1
        _ECS.C.components[c_id] = component
        _ECS.C.data[c_id] = {}
        return c_id
    end,
    ---add component to entity
    ---@param e_id number
    ---@param c_id number
    set = function(e_id, c_id, data)
        assert(_ECS.E.components_map[e_id] ~= nil)
        assert(_ECS.C.data[c_id] ~= nil, "Component is not registered")
        _ECS.C.data[c_id][e_id] = data
    end,
    ---remove component from entity
    ---@param e_id number
    ---@param c_id number
    unset = function(e_id, c_id)
        assert(_ECS.C.data[c_id] ~= nil, "Component is not registered")
        _ECS.C.data[c_id][e_id] = nil
    end
}

---@class EntityBuilder
---@field id number
---@field with fun(c_id: number, data?: table|nil): EntityBuilder
---@field without fun(c_id: number): EntityBuilder

---@param e_id number?
---@return EntityBuilder
local function get_entity_builder(e_id)
    assert(type(e_id) == 'nil' or type(e_id) == 'number')

    e_id = e_id or _ECS.E.create_entity()

    local entity_builder = { id = e_id }

    entity_builder.with = function(c_id, data)
        local component_schema = _ECS.C.components[c_id]
        assert(component_schema ~= nil, "Component is not registered")

        data = data or {} -- if data is not provided then default
        local final_data = {}

        for k, default in pairs(component_schema) do
            final_data[k] = data[k] or default
        end

        _ECS.C.set(entity_builder.id, c_id, final_data)
        _ECS.E.toggle_has_component(entity_builder.id, c_id)

        return entity_builder
    end

    entity_builder.without = function(c_id)
        _ECS.C.unset(entity_builder.id, c_id)
        _ECS.E.toggle_has_component(entity_builder.id, c_id)

        return entity_builder
    end

    return entity_builder
end

-- Generate a unique ID for each query
local next_query_id = 1

---Public APIs
---@class ECS
return {
    E = {
        create_entity = function()
            return get_entity_builder()
        end,
        modify_entity = get_entity_builder,
        remove_entity = _ECS.E.remove_entity,
        ---@param e_id number
        get_components = function(e_id)
            return _ECS.E.components_map[e_id] or {}
        end
    },
    C = {
        register_component = _ECS.C.register_component,
        ---@param c_id number
        ---@return table
        get_entities = function(c_id)
            return _ECS.C.data[c_id] or {}
        end,
        ---@param c_id table|number?
        ---@param e_id number?
        ---@return table
        get = function(c_id, e_id)
            if c_id == nil then return _ECS.C.data end
            if not e_id then return _ECS.C.data[c_id] end
            return _ECS.C.data[c_id][e_id]
        end
    },
    ---@return Query
    query = function()
        local query_id = next_query_id
        next_query_id = next_query_id + 1

        ---@class Query
        ---@field protected include_components table
        ---@field protected exclude_components table
        ---@field protected dirty boolean
        ---@field protected id number
        ---@field protected results nil|table<number>
        ---@field build fun(): table<number>
        local q = {
            id = query_id,
            results = nil,
            include_components = {},
            exclude_components = {},
            dirty = true -- Initially dirty to build on first use
        }

        -- Register this query for dirty tracking
        _ECS.dirty_queries[query_id] = q

        local function build()
            -- Only rebuild results if dirty
            if not q.dirty and q.results ~= nil then
                return q
            end

            -- Reuse existing results table if possible, or create a new one
            q.results = q.results or {}
            local results_count = 0

            -- Faster to clear and reuse the table than create a new one
            for i = 1, #q.results do
                q.results[i] = nil
            end

            for e_id, _ in pairs(_ECS.E.entities) do
                local valid = true
                -- Check if entity has all required components
                for c_id, _ in pairs(q.include_components) do
                    if not _ECS.E.components_map[e_id] or not _ECS.E.components_map[e_id][c_id] then
                        valid = false
                        break
                    end
                end

                -- Only check excluded components if still valid
                if valid then
                    for c_id, _ in pairs(q.exclude_components) do
                        if _ECS.E.components_map[e_id] and _ECS.E.components_map[e_id][c_id] then
                            valid = false
                            break
                        end
                    end

                    if valid then
                        -- Faster to increment counter and set directly than use table.insert
                        results_count = results_count + 1
                        q.results[results_count] = e_id
                    end
                end
            end

            q.dirty = false
            return q
        end

        ---component id to include
        ---@param c_id number
        ---@return Query
        q.with = function(c_id)
            q.include_components[c_id] = true
            q.dirty = true
            return q
        end

        ---component id to exclude
        ---@param c_id number
        ---@return Query
        q.without = function(c_id)
            q.exclude_components[c_id] = true
            q.dirty = true
            return q
        end

        ---Explicitly build the results
        q.build = build

        ---will trigger build() automatically if needed
        ---@param callback fun(e_id: number)
        ---@return nil
        q.each = function(callback)
            build()
            for i = 1, #q.results do
                callback(q.results[i])
            end
            return q --explicitly return q as nil for public api, so you can't chain .each with other fns.
        end

        ---@return number
        q.count = function()
            build()
            return #q.results
        end

        ---Allow destroying queries when no longer needed
        q.destroy = function()
            _ECS.dirty_queries[query_id] = nil
        end

        return q --[[@as Query]]
    end
}

--example:

-- local Position = ECS.C.register_component({
--     x = 0,
--     y = 0
-- })

-- local Speed = ECS.C.register_component({
--     x = 10,
--     y = 5
-- })

-- local MovableQuery = ECS.query().with(Position).with(Speed)

-- local MovableSystem = function()
--     MovableQuery.each(function(e_id)
--         local pos = ECS.C.get(Position, e_id)
--         local spd = ECS.C.get(Speed, e_id)

--         pos.x = pos.x + spd.x
--         pos.y = pos.y + spd.y
--     end)
-- end

-- local CharacterFactory = {
--     ---@param n number
--     ---@return number|table
--     create = function(n)
--         n = n or 1


--         local _create = function()
--             return ECS.E.create_entity().with(Position).with(Speed)
--         end

--         if n == 1 then return _create() end

--         local entities = {}

--         for i = 1, n do
--             local e_id = _create()
--             table.insert(entities, e_id)
--         end

--         return entities
--     end
-- }

-- function love.load()
--     CharacterFactory.create(10000)
-- end

-- ---@param dt number
-- function love.update(dt)
--     logger.info("here")
--     MovableSystem()
-- end
