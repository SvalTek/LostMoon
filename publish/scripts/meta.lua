---@class LostMoonConstants
local LostMoonConstants = {
    NAME = "LostMoon",
    DESCRIPTION = "A Lua runtime for Lost Skies, using Moonsharp as the interpreter.",
    AUTHOR = "SvalTek",
    VERSION = "0.1.0",
    GAME_NAME = "Lost Skies",
    LICENSE = "MIT",
    -- Lua Settings
    LUA_PATH = "scripts/?.lua;scripts/?/init.lua",
    LUA_CPATH = "scripts/?.dll;scripts/?/init.dll",
}

---@class LostMoonSettings
local LostMoonSettings = {
    -- General Settings
    DEBUG = true,
    PlayerHook = true,
}

return {
    LostMoonConstants = LostMoonConstants,
    LostMoonSettings = LostMoonSettings,
}
