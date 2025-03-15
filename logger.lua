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


---@class Logger
local Logger = {
    -- Log levels
    LEVELS = {
        DEBUG = 1,
        INFO = 2,
        WARN = 3,
        ERROR = 4,
        FATAL = 5
    },

    -- ANSI color codes for console output
    COLORS = {
        DEBUG = "\27[36m", -- Cyan
        INFO = "\27[32m",  -- Green
        WARN = "\27[33m",  -- Yellow
        ERROR = "\27[31m", -- Red
        FATAL = "\27[35m", -- Magenta
        RESET = "\27[0m"
    }
}

-- Private variables
local current_level = Logger.LEVELS.DEBUG
local LOG_CHANNEL = "logger:messages"
local PATH_CHANNEL = "logger:path"
local ERROR_CHANNEL = "logger:errors"
local log_channel = love ~= nil and love.thread.getChannel(LOG_CHANNEL) or nil
local path_channel = love ~= nil and love.thread.getChannel(PATH_CHANNEL) or nil
local error_channel = love ~= nil and love.thread.getChannel(ERROR_CHANNEL) or nil
---@type love.Thread
local log_thread = nil
---@type love.Thread
local error_thread = nil
local is_thread_running = false

-- Module logger cache
local module_loggers = {}

-- Private functions
local function format_timestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

-- Table serialization
local function serialize_table(tbl, indent, visited)
    if not tbl then return "nil" end
    if type(tbl) ~= "table" then return tostring(tbl) end

    visited = visited or {}
    indent = indent or ""

    if visited[tbl] then
        return "[Circular Reference]"
    end
    visited[tbl] = true

    local lines = { "{" }
    local next_indent = indent .. "  "

    -- Sort keys for consistent output
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        if ta == tb then
            if ta == "number" or ta == "string" then
                return a < b
            end
            return tostring(a) < tostring(b)
        end
        return ta < tb
    end)

    for _, k in ipairs(keys) do
        local v = tbl[k]
        local key = type(k) == "number" and "" or tostring(k) .. " = "
        local value
        if type(v) == "table" then
            value = serialize_table(v, next_indent, visited)
        else
            value = type(v) == "string" and string.format("%q", v) or tostring(v)
        end
        table.insert(lines, next_indent .. key .. value .. ",")
    end

    table.insert(lines, indent .. "}")
    return table.concat(lines, "\n")
end

-- Internal logging function
local function log(level, level_name, context, ...)
    if level < current_level then return end

    local timestamp = format_timestamp()

    local stuff = { ... }

    -- Handle different message types
    local final_message = ""

    for i, v in ipairs(stuff) do
        if i > 1 then
            final_message = final_message .. " "
        end

        if type(v) == "table" then
            final_message = final_message .. "\n" .. serialize_table(v)
        elseif type(v) == "string" then
            final_message = final_message .. v
        else
            final_message = final_message .. tostring(v)
        end
    end

    local log_message = string.format("[%s][%s]%s %s", timestamp, level_name, context, final_message)

    -- Print to console with colors
    print(Logger.COLORS[level_name] .. log_message .. Logger.COLORS.RESET)

    -- Send to logging thread
    if is_thread_running and log_channel ~= nil then
        log_channel:push(log_message)
    end
end

---Initialize the logger
---@param filename string?
---@param level integer?
function Logger.init(filename, level)
    current_level = level or Logger.LEVELS.DEBUG

    if path_channel ~= nil then
        -- Get save directory path
        local save_dir = love.filesystem.getSaveDirectory()

        -- Create log directory if it doesn't exist
        local logs_dir = "logs"
        love.filesystem.createDirectory(logs_dir)

        local log_file_path = save_dir .. "/" .. logs_dir .. "/" .. (filename or "game.log")
        print("Log file path:", log_file_path)

        -- Write initial log entry
        local f = io.open(log_file_path, "a+")
        if f then
            f:write("=== Log started at " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===\n")
            f:close()
        end

        Logger.start_logging_thread()

        path_channel:push(log_file_path)
    else
        print("[logger.lua] not in a love2d project. won't persist logs in a file.")
        -- todo: use filesystem api instead for non-love projects
    end
end

-- Start the background logging thread
function Logger.start_logging_thread()
    if is_thread_running then return end
    if love == nil then return end

    -- Create the thread code with proper channel names
    local threadCode = [[
        local log_channel = love.thread.getChannel("logger:messages")
        local path_channel = love.thread.getChannel("logger:path")
        local error_channel = love.thread.getChannel("logger:errors")

        local function thread_print(...)
            error_channel:push(string.format(...))
        end

        local function handle_error(err)
            thread_print("THREAD ERROR: %s", err)
            thread_print("Stack trace: %s", debug.traceback())
        end

        local status, err = xpcall(function()
            local log_path = path_channel:demand()
            thread_print("Log file path: %s", tostring(log_path))

            if not log_path then
                thread_print("ERROR: No path received!")
                return
            end

            local f = io.open(log_path, "a+")

            while true do
                local message = log_channel:demand()

                if message == "STOP" then
                    thread_print("Stopping thread")
                    break
                end

                if f ~= nil and message ~= nil then
                    f:write(message .. "\n")
                    f:flush()
                end
            end

            if f ~= nil then
                f:close()
            end
        end, handle_error)

        if not status then
            thread_print("Thread crashed: %s", err)
        end
        thread_print("Thread exiting")
    ]]

    -- Create error handling thread
    local errorThreadCode = [[
        local error_channel = love.thread.getChannel("logger:errors")

        local function handle_error(err)
            print("[ThreadError]", err)
            print(debug.traceback())
        end

        local status, err = xpcall(function()
            while true do
                local msg = error_channel:demand()
                if msg == "STOP" then break end
            end
        end, handle_error)

        if not status then
            print("[ThreadError] Error thread crashed:", err)
        end
    ]]

    error_thread = love.thread.newThread(errorThreadCode)
    error_thread:start()
    log_thread = love.thread.newThread(threadCode)
    log_thread:start()

    -- Check for thread errors and status
    if log_thread:getError() then
        print("Logger thread error:", log_thread:getError())
        is_thread_running = false
        return
    end
    if error_thread:getError() then
        print("Error thread error:", error_thread:getError())
        is_thread_running = false
        return
    end

    is_thread_running = true
end

---@class ModuleLogger
---@field debug fun(...)
---@field info fun(...)
---@field warn fun(...)
---@field error fun(...)
---@field fatal fun(...)

---@param module_name string
---@return ModuleLogger
function Logger.get_logger(module_name)
    if module_loggers[module_name] then
        return module_loggers[module_name]
    end

    local module_logger = {}
    local context = "[" .. module_name .. "]"

    -- Create module-scoped logging methods
    for level, name in pairs({
        debug = "DEBUG",
        info = "INFO",
        warn = "WARN",
        error = "ERROR",
        fatal = "FATAL"
    }) do
        module_logger[level] = function(...)
            log(Logger.LEVELS[name], name, context, ...)
        end
    end

    module_loggers[module_name] = setmetatable(module_logger, {
        __index = module_logger,
        __call = function(...)
            return module_logger.info(module_logger, ...)
        end
    })

    return module_loggers[module_name]
end

-- Set the logging level
function Logger.set_level(level)
    current_level = level
end

-- Clean up resources
function Logger.close()
    if is_thread_running and log_channel ~= nil and error_channel ~= nil then
        log_channel:push("STOP")
        error_channel:push("STOP")
        if log_thread:getError() then
            print("Logger thread error:", log_thread:getError())
        end
        log_thread:wait()
        is_thread_running = false
    end
end

return Logger
