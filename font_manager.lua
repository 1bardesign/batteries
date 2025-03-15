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

---@alias FontStyles
---| '"regular"'
---| '"light"'
---| '"medium"'
---| '"bold"'
---| '"semibold"'

---@class FontManager
---note that your fonts file structure should be like this:
---assets/fonts/{{fontname}}/{{fontname}}_{{fontstyle}}.ttf
---#
---e.g: "assets/fonts/roboto/roboto_regular.ttf"
local FontManager = {
    base_path = "assets/fonts",
    --- example:
    --- FontManager.fonts.roboto = {
    ---     regular = {
    ---         [8] = love.graphics.newFont("assets/fonts/roboto/roboto_regular.ttf", 8)
    ---     }
    --- }
    ---@type table<string, table<string, table<string, love.Font>>>
    fonts = {}
}

---@param font_name string
---@param style FontStyles
local function get_font_path(font_name, style)
    return FontManager.base_path .. "/" .. font_name .. "/" .. font_name .. "_" .. style .. ".ttf"
end

---set the default path to look for fonts in
---@param base_path string
function FontManager.set_base_path(base_path)
    FontManager.base_path = base_path
end

---@param font_name string
---@param style FontStyles
---@param size number
---@return love.Font
local function get_font(font_name, style, size)
    local f = love.graphics.newFont(get_font_path(font_name, style), size)
    f:setFilter('nearest', "nearest")
    return f
end

function FontManager.load_default()
    FontManager.fonts.default = love.graphics.getFont()
end

---you may call load_fonts however many times you wish.
---@param fonts table<string, table<string, table<string, number>>>
function FontManager.load_fonts(fonts)
    if FontManager.fonts.default == nil then
        FontManager.load_default() -- set default font if not set already.
    end

    for font_name, _ in pairs(fonts) do
        FontManager.fonts[font_name] = {}
        for style_name, _ in pairs(fonts[font_name]) do
            FontManager.fonts[font_name][style_name] = {}
            for _, size in pairs(fonts[font_name][style_name]) do
                FontManager.fonts[font_name][style_name][size] = get_font(font_name, style_name, size)
            end
        end
    end
end

---@param font_name string
---@param font_style FontStyles
---@param font_size number
function FontManager.set(font_name, font_style, font_size)
    assert(font_name and font_style and font_size)

    if FontManager.fonts[font_name] and FontManager.fonts[font_name][font_style] and FontManager.fonts[font_name][font_style][font_size] then
        local f = FontManager.fonts[font_name][font_style][font_size]
        love.graphics.setFont(f)
    else
        local f = get_font(font_name, font_style, font_size)
        FontManager.fonts[font_name] = FontManager.fonts[font_name] or {}
        FontManager.fonts[font_name][font_style] = FontManager.fonts[font_name][font_style] or {}
        FontManager.fonts[font_name][font_style][font_size] = f
        love.graphics.setFont(f)
    end
end

function FontManager.unset()
    love.graphics.setFont(FontManager.fonts.default)
end

return FontManager
