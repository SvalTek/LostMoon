---@diagnostic disable-next-line: deprecated
local unpack = unpack or table['unpack']

function RegisterModule(namespace, mod)
    if package.preload[namespace] then
        return error("module exists")
    end
    package.preload[namespace] = function()
        local this_module = mod
        return this_module
    end
    return true
end

-- Removes a value from a table
function RemoveFromTable(tbl, ent)
    for i, v in ipairs(tbl) do
        if (v == ent) then
            table.remove(tbl, i);
            break;
        end
    end
end

-- EI find entry in spawn/weather tables
function FindInTable(tbl, keyname, keyvalue)
    for i, v in ipairs(tbl) do
        if (v[keyname] == keyvalue) then
            return v
        end
    end
end

-- Inserts a value into a table unless it is already present
function InsertIntoTable(tbl, ent)
    local inside = false;
    for i, v in ipairs(tbl) do
        if (v == ent) then
            inside = true;
            break;
        end
    end
    if (not inside) then
        table.insert(tbl, ent);
    end
end

-- Checks if a value is already inside a table
function IsInsideTable(tbl, ent)
    for i, v in ipairs(tbl) do
        if (v == ent) then
            return true;
        end
    end
    return false;
end

--- safely escape a given string
---@param str string    string to escape
string.escape = function(str) return str:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1') end

--- Split a string at a given string as delimeter (defaults to a single space)
-- | local str = string.split('string | to | split', ' | ') -- split at ` | `
-- >> str = {"string", "to", "split"}
---@param str string        string to split
---@param delimiter string  optional delimiter, defaults to " "
string.split = function(str, delimiter)
    local result = {}
    local from = 1
    local delim = delimiter or " "
    local delim_from, delim_to = string.find(str, delim, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delim, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

--- extracts key=value styled arguments from a given string
---@param str string string to extract args from
---@return table args table containing any found key=value patterns
string.kvargs = function(str)
    local t = {}
    for k, v in string.gmatch(str, '(%w+)=(%w+)') do t[k] = v end
    return t
end

--- Expand a string with placeholders using a table.
--- This function replaces placeholders in the format {key} or #{index} with corresponding values from the provided table.
--- The placeholders can be either string keys or numeric indices.
---@param str string The string to expand.
---@param tbl table The table with key-value pairs for placeholders.
---@return string|nil The expanded string, or nil if an error occurs.
---@example
---```lua
---local utils = require("lib.utils")
---local str = "Hello, {name}! secret: #{1}"
---local tbl = { [1] = "baz", name = "World" }
---local expanded = utils.expand_string(str, tbl)
---print(expanded) -- Output: "Hello, World! secret: baz"
---```
string.expand = function(str, tbl)
    if type(str) ~= "string" or str == "" then
        error("Invalid input: Expected a non-empty string, got " .. tostring(str))
    end
    if type(tbl) ~= "table" or next(tbl) == nil then
        error("Invalid input: Expected a non-empty table, got " .. tostring(tbl))
    end

    -- Combine placeholder replacements into a single gsub call
    local success, expanded = pcall(function()
        return str:gsub("{(.-)}", function(key)
            local value = tbl[key]
            if value == nil then
                error("Missing value for placeholder: " .. key)
            end
            return tostring(value)
        end):gsub("#%{(%d+)%}", function(index)
            index = tonumber(index)
            local value = tbl[index]
            if value == nil then
                error("Missing value for placeholder index: " .. index)
            end
            return tostring(value)
        end)
    end)

    if not success then
        error("Error expanding string: " .. expanded)
    end

    return expanded
end

local charset = {}
do -- [0-9a-zA-Z]
    for c = 48, 57 do table.insert(charset, string.char(c)) end
    for c = 65, 90 do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

---* Cleans Eccess quotes from input string
function string.clean_quotes(inputString)
    local result
    result = inputString:gsub('^"', ''):gsub('"$', '')
    result = result:gsub('^\'', ''):gsub('\'$', '')
    return result
end

--- generate a random string with a given length
---@param	length number num chars to generate
---@return	string
function RandomString(length)
    if not length or length <= 0 then return '' end
    math.randomseed(os.clock() ^ 5)
    return RandomString(length - 1) .. charset[math.random(1, #charset)]
end

function Dec2Hex(nValue)
    if type(nValue) == 'string' then nValue = tonumber(nValue) end
    local nHexVal = string.format('%X', nValue) -- %X returns uppercase hex, %x gives lowercase letters
    local sHexVal = nHexVal .. ''
    return sHexVal
end

function Hex2Dec(someHexString) return tonumber(someHexString, 16) end

---* Evaluate a Lua String
--- evaluates `Eval` in Protected mode, Does nothing if the provided string
--- contains errors or is not a valid lua chunk, else returns boolean,result
---@param luaStr string
---@return boolean success
---@return any result
function Eval(luaStr)
    if not type(luaStr) == 'string' then
        return false, 'Invalid Argument: Expected String'
    else
        local eString = luaStr:gsub('%^%*', ','):gsub('%*%^', ',')
        local eval_func = function(s) return loadstring(s)() end
        return pcall(eval_func, eString)
    end
end

--
-- ────────────────────────────────────────────────────── GetterS AND SetterS ─────
--

-- @function Compose
---* Create a function composition from given functions.
-- any further functions as arguments get added to composition in order
--- @param f1 function
-- the outermost function of the composition
--- @param f2 function
-- second outermost function of the composition
--- @return function the composite function
function Compose(f1, f2, ...)
    if select('#', ...) > 0 then
        local part = Compose(f2, ...)
        return Compose(f1, part)
    else
        return function(...) return f1(f2(...)) end
    end
end

-- @function Bind
---* Create a function with bound arguments ,
-- The bound function returned will call func() ,
-- with the arguments passed on to its creation .
-- If more arguments are given during its call, they are ,
-- appended to the original ones .
-- `...` the arguments to Bind to the function.
--- @param func function
-- the function to create a Binding of
--- @return function
-- the bound function
function Bind(func, ...)
    local saved_args = { ... }
    return function(...)
        local args = { unpack(saved_args) }
        for _, arg in ipairs({ ... }) do table.insert(args, arg) end
        return func(unpack(args))
    end
end

-- @function Bind_self
---* Create f bound function whose first argument is t ,
--  Particularly useful to pass a method as a function ,
-- Equivalent to Bind(t[k], t, ...) ,
-- `...` further arguments to Bind to the function.
--- @param t table Binding
-- The table to be accessed
--- @param k any Key
-- The key to be accessed
--- @return function BoundFunc
-- The Binding for t[k]
function Bind_self(t, k, ...) return Bind(t[k], t, ...) end

---* Create a function that returns the value of t[k] ,
-- | The returned function is Bound to the Provided Table,Key.
--- @param t table      table to access
--- @param k any        key to return
--- @return function    Getter function
--- @return string?   error message
function Bind_Getter(t, k)
    return function()
        if (not type(t) == 'table') then
            return nil, 'Bound object is not a table'
        elseif (t == {}) then
            return nil, 'Bound table is Empty'
        elseif (t[k] == nil) then
            return nil, 'Bound Key does not Exist'
        else
            return t[k], 'Fetched Bound Key'
        end
    end
end

---* Create a function that sets the value of t[k] ,
---| The returned function is Bound to the Provided Table,Key ,
---| The argument passed to the returned function is used as the value to set.
--- @param t table       table to access
--- @param k table       key to set
--- @return function?     Setter function
--- @return string?      error message
function Bind_Setter(t, k)
    return function(v)
        if (not type(t) == 'table') then
            return nil, 'Bound object is not a table'
        elseif (t == {}) then
            return nil, 'Bound table is Empty'
        elseif (t[k] == nil) then
            return nil, 'Bound Key does not Exist'
        else
            t[k] = v
            return true, 'Set Bound Key'
        end
    end
end

---* Create a function that returns the value of t[k] ,
---| The argument passed to the returned function is used as the Key.
--- @param t table       table to access
--- @return function?     Getter function
--- @return string?      error message
function Getter(t)
    if (not type(t) == 'table') then
        return nil, 'Bound object is not a table'
    elseif (t == {}) then
        return nil, 'Bound table is Empty'
    else
        return function(k) return t[k] end
    end
end

---* Create a function that sets the value of t[k] ,
---| The argument passed to the returned function is used as the Key.
--- @param t table       table to access
--- @return function?     returned Setter function
--- @return string?      error message
function Setter(t)
    if (not type(t) == 'table') then
        return nil, 'Bound object is not a table'
    elseif (t == {}) then
        return nil, 'Bound table is Empty'
    else
        return function(k, v)
            t[k] = v
            return true
        end
    end
end

--
-- ──────────────────────────────────────────────────────────────────── EXTRA ─────
--

--- load and execute a lua script from a given path
function RequireFile(filename)
    local oldPackagePath = package.path
    package.path = './' .. filename .. ';' .. package.path
    local obj = require(filename)
    package.path = oldPackagePath
    if obj then
        return obj, 'success loading file from ' .. filename
    else
        return nil, 'Failed to Require file from path ' .. filename
    end
end

local function import_symbol(T, k, v, libname)
    local key = rawget(T, k)
    -- warn about collisions!
    if key and k ~= '_M' and k ~= '_NAME' and k ~= '_PACKAGE' and k ~= '_VERSION' then
        Log(string.format('warning: \'%s.%s\' will not override existing symbol\n', libname, k))
        return
    end
    rawset(T, k, v)
end

local function lookup_lib(T, t)
    for k, v in pairs(T) do if v == t then return k end end
    return '?'
end

local already_imported = {}

---* take a table and 'inject' it into the local namespace.
--- @param t table
-- The Table
--- @param T  table
-- An optional destination table (defaults to callers environment)
function Import(t, T)
    T = T or _G
    if type(t) == 'string' then t = require(t) end
    local libname = lookup_lib(T, t)
    if already_imported[t] then return end
    already_imported[t] = libname
    for k, v in pairs(t) do import_symbol(T, k, v, libname) end
end

local function Invoker(links, index)
    return function(...)
        local link = links[index]
        if not link then return end
        local continue = Invoker(links, index + 1)
        local returned = link(continue, ...)
        if returned then returned(function(_, ...) continue(...) end) end
    end
end

---* used to chain multiple functions/callbacks
-- Example
-- local function TimedText (seconds, text)
--     return function (go)
--         print(text)
--         millseconds = (seconds or 1) * 1000
--         Script.SetTimerForFunction(millseconds, go)
--     end
-- end
--
-- Chain(
--     TimedText(1, 'fading in'),
--     TimedText(1, 'showing splash screen'),
--     TimedText(1, 'showing title screen'),
--     TimedText(1, 'showing demo')
-- )()
---@return function chain
-- the cretedfunction chain
function Chain(...)
    local links = { ... }

    local function chain(...)
        if not (...) then return Invoker(links, 1)(select(2, ...)) end
        local offset = #links
        for index = 1, select('#', ...) do links[offset + index] = select(index, ...) end
        return chain
    end

    return chain
end

---@alias UUID string UniqueID
--- Generate a new UUID
--- using an improved randomseed function accouning for lua 5.1 vm limitations
--- Lua 5.1 has a limitation on the bitsize meaning that when using randomseed
--- numbers over the limit get truncated or set to 1 , destroying all randomness for the run
--- uses an assumed Lua 5.1 maximim bitsize of 32.
---@return UUID uuid
---@return number uuidSeed
function UUID()
    local bitsize = 32
    local initTime = os.time()
    local function better_randomseed(seed)
        seed = math.floor(math.abs(seed))
        if seed >= (2 ^ bitsize) then
            -- integer overflow, reduce  it to prevent a bad seed.
            seed = seed - math.floor(seed / 2 ^ bitsize) * (2 ^ bitsize)
        end
        math.randomseed(seed - 2 ^ (bitsize - 1))
        return seed
    end
    local uuidSeed = better_randomseed(initTime)
    local function UUID(prefix)
        local template = 'xyxxxxxx-xxyx-xxxy-yxxx-xyxxxxxxxxxx'
        local mutator = function(c)
            local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
            return string.format('%x', v)
        end
        return string.gsub(template, '[xy]', mutator)
    end
    return UUID(), uuidSeed
end

---* Bind an argument to a type and throw an error if the provided param doesnt match at runtime.
-- Note this works in reverse of the normal assert in that it returns nil if the argumens provided are valid
-- if not the it either returns true plus and error message , or if it fails to grab debug info just true.
--- @param idx number
-- positonal index of the param to Bind
--- @param val any the param to Bind
--- @param tp string the params bound type
--- @usage
-- local test = function(somearg,str,somearg)
-- if assert_arg(2,str,'string') then
--    return
-- end
--
-- test(nil,1,nil) -> Invalid Param in [test()]> Argument:2 Type: number Expected: string
function _G.assert_arg(idx, val, tp)
    if type(val) ~= tp then
        local fn = debug.getinfo(2, 'n')
        local msg = 'Invalid Param in [' .. fn.name .. '()]> ' ..
            string.format('Argument:%s Type: %q Expected: %q', tostring(idx), type(val), tp)
        local test = function() error(msg, 4) end
        local rStat, cResult = pcall(test)
        if rStat then
            return true
        else
            return true, cResult
        end
    end
end

--- Create a new Class
---| uses the classic.lua Object library
---@param base? table optional class schema
function Class(base)
    local Object = base or {}
    Object.__index = Object
    function Object:__tostring() return 'Object' end

    function Object:__call(...)
        local obj = setmetatable({}, self)
        if obj.new then
            ---@diagnostic disable-next-line: redundant-parameter
            local ret = obj:new(...)
            if ret then return ret end
        end
        return obj
    end

    --- Create a new Instance of this Object.
    function Object:new() end

    --- Extend this Object.
    function Object:extend()
        local cls = {}
        for k, v in pairs(self) do
            if k:find("__") == 1 then
                cls[k] = v
            end
        end
        cls.__index = cls
        cls.super = self
        setmetatable(cls, self)
        return cls
    end

    --- Implement Methods from anouther Object.
    function Object:implement(...)
        for _, cls in pairs({ ... }) do
            for k, v in pairs(cls) do if self[k] == nil and type(v) == 'function' then self[k] = v end end
        end
    end

    --- Check an Objects type.
    function Object:is(T)
        local mt = getmetatable(self)
        while mt do
            if mt == T then return true end
            mt = getmetatable(mt)
        end
        return false
    end

    return Object:extend()
end
