--[[
 HookManager Module
 Lua 5.1 compatible, fully instanceable class
 Features:
   • Class and instance methods via colon syntax
   • Safe unpack shim for Lua 5.1
   • Error trapping in callbacks with custom warning
   • Call returns first non-nil result; CallAll gathers all
--]]

-- Internal helper to pack multiple return values
local function pack_results(...)
    return { n = select('#', ...), ... }
end

-- Safe unpack for Lua 5.1
local function unpack_safe(t)
    return unpack(t, 1, t.n)
end

--- Default warning logger (override per instance if needed)
local function default_warn(self, msg)
    Log(string.format("[%s] Warning: %s", tostring(self._name or "HookManager"), msg))
end

---@class HookManager
---@field private __index HookManager
---@field private _name string optional name for identification in logs
---@field private _table table eventName -> { id -> func }
---@field private _iterator function iterator function for traversing hooks
---@field private warn fun(self, msg: string) warning logger function
local HookManager = {}
HookManager.__index = HookManager

--- Constructor: create a new HookManager instance
-- @param name string: optional name for identification in logs
-- @return HookManager instance
function HookManager.new(name)
    local obj = setmetatable({
        _name     = name or "HookManager",
        _table    = {}, -- eventName -> { id -> func }
        _iterator = pairs,
        warn      = default_warn,
    }, HookManager)
    return obj
end

-- Allow call syntax: HookManager(name) == HookManager.new(name)
setmetatable(HookManager, {
    __call = function(class, name)
        return class.new(name)
    end,
})

--- Add a hook listener for the given event
-- @param eventName string: the event identifier
-- @param id         string|number: unique hook id to allow removal
-- @param func       function: callback to invoke
function HookManager:Add(eventName, id, func)
    assert(type(eventName) == "string", "Add: eventName must be a string")
    assert(type(id) == "string" or type(id) == "number", "Add: id must be string or number")
    assert(type(func) == "function", "Add: func must be a function")

    local evt = self._table[eventName]
    if not evt then
        evt = {}
        self._table[eventName] = evt
    end
    evt[id] = func
end

--- Remove a hook listener
-- @param eventName string: the event identifier
-- @param id         string|number: hook id to remove
-- @return boolean: true on success, false if no such hook
function HookManager:Remove(eventName, id)
    local evt = self._table[eventName]
    if not evt or not evt[id] then
        return false
    end
    evt[id] = nil
    -- clean up empty event tables
    for _ in pairs(evt) do
        return true
    end
    self._table[eventName] = nil
    return true
end

--- Call hooks until one returns non-nil; returns first non-nil set of results
-- @param eventName string: the event identifier
-- @param ...        varargs: passed to hook callbacks
-- @return ... results from the first callback that returned anything
function HookManager:Call(eventName, ...)
    local evt = self._table[eventName]
    -- if no hooks are registered, return nil
    if not evt then return end
    local argv = { ... }

    for id, func in self._iterator(evt) do
        local ok, results = pcall(function() return pack_results(func(unpack_safe(argv))) end)
        if not ok then
            self:warn(string.format("error in hook '%s' for event '%s': %s", tostring(id), eventName, results))
        elseif results.n > 0 then
            return unpack_safe(results)
        end
    end
end

--- Call all hooks and collect their results
-- @param eventName string: the event identifier
-- @param ...        varargs: passed to hook callbacks
-- @return table: list of { id = hook id, result = return values or nil }
function HookManager:CallAll(eventName, ...)
    local evt = self._table[eventName]
    if not evt then return {} end
    local argv = { ... }
    local all = {}

    for id, func in self._iterator(evt) do
        local ok, results = pcall(function() return pack_results(func(unpack_safe(argv))) end)
        if not ok then
            self:warn(string.format("error in hook '%s' for event '%s': %s", tostring(id), eventName, results))
            all[#all + 1] = { id = id, result = nil }
        elseif results.n == 0 then
            all[#all + 1] = { id = id, result = nil }
        elseif results.n == 1 then
            all[#all + 1] = { id = id, result = results[1] }
        else
            -- multiple results: return as a table
            local res = {}
            for i = 1, results.n do res[i] = results[i] end
            all[#all + 1] = { id = id, result = res }
        end
    end
    return all
end

--- Get a read-only view of the internal hook table
-- @return table: eventName mapping to id->func
function HookManager:GetTable()
    return self._table
end

---@overload fun(name): HookManager
local exports = setmetatable({}, {
    __call = function(_, name)
        return HookManager.new(name)
    end,
})


return exports
