---@diagnostic disable: lowercase-global
if not Log then
    Log = function(...) print(...) end
end

-- Load the required modules
Log("Loading LostMoon...")

if not require then
    Log("LostMoon: require is not available.")
    return
end

require "common";
local meta = require "meta";
local LostMoonConstants = meta.LostMoonConstants;
local LostMoonSettings = meta.LostMoonSettings;
---@module "lib.eventmanager"
local events = require "lib.eventmanager";
---@module "lib.hooker"
local hooker = require "lib.hooker";
---@module "lib.utils"
local utils = require "lib.utils";


--- ─── LostMoonManager ────────────────────────────────────────────────────
--- <br/> *LostMoon is a Lua runtime for Lost Skies, providing a framework for modding and scripting.*
--- <br/>
---@class LostMoon : LostMoonConstants
---@field settings {} | LostMoonSettings
---@field Events EventManager
---@field Hooks HookManager
---@field Plugins PluginManager
local LostMoonManager = Class()

function LostMoonManager:new(cfg)
    cfg = cfg or {}
    self.modName = cfg.NAME or LostMoonConstants.NAME
    self.description = cfg.DESCRIPTION or LostMoonConstants.DESCRIPTION
    self.author = cfg.AUTHOR or LostMoonConstants.AUTHOR
    self.version = cfg.VERSION or LostMoonConstants.VERSION
    self.gameName = cfg.GAME_NAME or LostMoonConstants.GAME_NAME
    self.license = cfg.LICENSE or LostMoonConstants.LICENSE
    self.settings = cfg.SETTINGS or {}

    self.Events = events("Events::Main")
    self.Hooks = hooker("Hooks::Main")
    -- self.Plugins = plugins("Plugins::Main")
end

function LostMoonManager:__tostring()
    return string.format("LostMoonManager(%s)", self.modName)
end

--- Initialize LostMoon
function LostMoonManager:Initialize()
    self.Hooks:Call("LostMoon::PreInit", self)
    -- Initialize the settings
    for key, value in pairs(LostMoonSettings) do
        if self.settings[key] == nil then
            self.settings[key] = value
        end
    end

    self.Hooks:Call("LostMoon::PostInit", self)

    self:Preload()
end

--- Preload LostMoon
--- This function is called when the game is loading into the world.
function LostMoonManager:Preload()
    self.Hooks:Call("LostMoon::PrePreload", self)
    -- Perform any necessary preloading here
    Log("Preloading " .. self.modName)
    self.Hooks:Call("LostMoon::PostPreload", self)
end

--- Start LostMoon
function LostMoonManager:Run()
    self.Hooks:Call("LostMoon::PreRun", self)
    -- Initialize LostMoon
    local msg = string.expand("{modName} (v{version}) for {gameName}", {
        modName = self.modName,
        version = self.version,
        gameName = self.gameName,
    })
    Log("Running " .. msg)
    Log("Author: " .. self.author)
    Log("License: " .. self.license)
    Log("Description: " .. self.description)

    self.Hooks:Call("LostMoon::PostRun", self)
end

--- Shutdown LostMoon
--- This function is called when the game is unloaded.
function LostMoonManager:Shutdown()
    self.Hooks:Call("LostMoon::PreShutdown", self)
    -- Perform any necessary cleanup here
    Log("Shutting down " .. self.modName)
    self.Hooks:Call("LostMoon::PostShutdown", self)
end

-- ─── Runtime ─────────────────────────────────────────────────────────────────
-- Main entry point for the script.

function OnInit()
    ---@class LostMoon
    _G.LostMoon = LostMoonManager()
    LostMoon:Initialize()
end

function OnLoad()
    LostMoon:Run()
    require("main")
end

function OnUnload()
    LostMoon:Shutdown()
    _G["LostMoon"] = nil
end
