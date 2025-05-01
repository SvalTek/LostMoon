local _M = {
    _namespace = "LostMoon.lua.utils",
    _Version = "0.1.0",
    _Author = "SvalTek",
} -- Copyright (C) 2025 Theros

-- Utility functions
local exports = {

    Path = {
        --- Join an arbitrary number of paths together
        ---@vararg string paths to join
        ---@return string the joined path
        Join = function(...)
            local paths = { ... }
            local result = ""
            for i, path in ipairs(paths) do
                if i > 1 then
                    result = result .. "/"
                end
                result = result .. path
            end
            return result
        end,
    }


}



return setmetatable(exports, {
    __index = function(_, key)
        return _M[key] or exports[key]
    end,
    __newindex = function(_, key, value)
        _M[key] = value
    end,
})