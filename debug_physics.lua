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

local seed = 123
local rng = love.math.newRandomGenerator(seed)

---@param fixture love.Fixture
local function draw_fixture(fixture)
    local shape = fixture:getShape()
    local shapeType = shape:getType()

    if (fixture:isSensor()) then
        love.graphics.setColor(0, 0, 255, 96)
    else
        love.graphics.setColor(rng:random(32, 255), rng:random(32, 255), rng:random(32, 255), 96)
    end

    if (shapeType == "circle") then
        local x, y = shape --[[@as love.CircleShape]]:getPoint()
        local radius = shape:getRadius()
        love.graphics.circle("fill", x, y, radius, 15)
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.circle("line", x, y, radius, 15)
        -- local eyeRadius = radius / 4
        love.graphics.setColor(0, 0, 0, 255)
        --		love.graphics.circle("fill",x,y-radius+eyeRadius,eyeRadius,10)
    elseif (shapeType == "polygon") then
        local points = { shape --[[@as love.PolygonShape]]:getPoints() }
        love.graphics.polygon("fill", points)
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.polygon("line", points)
    elseif (shapeType == "edge") then
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.line(shape --[[@as love.EdgeShape]]:getPoints())
    elseif (shapeType == "chain") then
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.line(shape --[[@as love.ChainShape]]:getPoints())
    end
end

---@param body love.Body
local function draw_body(body)
    local bx, by = body:getPosition()
    local bodyAngle = body:getAngle()

    love.graphics.push()
    love.graphics.translate(bx, by)
    love.graphics.rotate(bodyAngle)

    rng:setSeed(seed)

    local fixtures = body:getFixtures()
    for i = 1, #fixtures do
        draw_fixture(fixtures[i])
    end
    love.graphics.pop()
end

local drawnBodies = {}

---@param fixture love.Fixture
---@return boolean
local function debug_world_draw_scissor_callback(fixture)
    drawnBodies[fixture:getBody()] = true
    return true --search continues until false
end

---@param world love.World
---@param x number
---@param y number
---@param width number
---@param height number
local function debug_world_draw(world, x, y, width, height)
    love.graphics.push("all")
    drawnBodies = {}
    world:queryBoundingBox(x, y, x + width, y + height, debug_world_draw_scissor_callback)

    love.graphics.setLineWidth(1)
    for body in pairs(drawnBodies) do
        drawnBodies[body] = nil
        draw_body(body)
    end

    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.setLineWidth(3)
    local joints = world:getJoints()
    for i = 1, #joints do
        local x1, y1, x2, y2 = joints[i]:getAnchors()
        if (x1 and x2) then
            love.graphics.line(x1, y1, x2, y2)
        else
            if (x1) then
                love.graphics.rectangle("fill", x1 - 1, y1 - 1, 3, 3)
            end
            if (x2) then
                love.graphics.rectangle("fill", x1 - 1, y1 - 1, 3, 3)
            end
        end
    end

    love.graphics.setColor(255, 0, 0, 255)
    local contacts = world:getContacts()
    for i = 1, #contacts do
        local x1, y1, x2, y2 = contacts[i]:getPositions()
        if (x1) then
            love.graphics.rectangle("fill", x1 - 1, y1 - 1, 3, 3)
        end
        if (x2) then
            love.graphics.rectangle("fill", x2 - 1, y2 - 1, 3, 3)
        end
    end
    love.graphics.pop()
end

return debug_world_draw
