local Events = require('lib.eventmanager')
local configReader = require('lib.configReader')

---@class ScriptPlugin
---@field name string
---@field description string
---@field version string
---@field onLoad function
---@field onUnload function
---@field onUpdate function|nil
---@field configure function
local ScriptPlugin = {}
ScriptPlugin.__index = ScriptPlugin

function ScriptPlugin.new(name, description, version, def)
    assert(type(name) == 'string', 'Plugin name must be a string')
    assert(type(description) == 'string', 'Plugin description must be a string')
    assert(type(version) == 'string', 'Plugin version must be a string')

    assert(type(def) == 'table', 'Plugin definition must be a table')
    assert(type(def.onLoad) == 'function', 'Plugin must define an onLoad function')
    assert(type(def.onUnload) == 'function', 'Plugin must define an onUnload function')

    local self = setmetatable({
        name = name,
        description = description,
        version = version,
        onLoad = def.onLoad,
        onUnload = def.onUnload,
        onUpdate = function(self, ...) end,
    }, ScriptPlugin)

    if def.onUpdate then
        assert(type(def.onUpdate) == 'function', 'onUpdate must be a function if provided')
        self.onUpdate = def.onUpdate
    end

    return self
end

function ScriptPlugin:__tostring()
    return string.format('ScriptPlugin<%s:%s>', self.name, self.version)
end

---@class PluginManager
---@field protected base_dir string
---@field private plugins table<string, ScriptPlugin>
---@field private config table
---@field private _loadConfig function
---@field events EventManager
---@field ScriptPlugin ScriptPlugin
local PluginManager = {}
PluginManager.__index = PluginManager

function PluginManager.new(base_dir)
    local self = setmetatable({
        base_dir = base_dir or 'plugins',
        plugins = {},
        config = {},
        events = Events('PluginManager'),
    }, PluginManager)

    self:_loadConfig()
    return self
end

function PluginManager:_loadConfig()
    local cfgPath = string.format('%s/settings.ini', self.base_dir)
    local cfg = configReader(cfgPath)
    if type(cfg) == 'table' and type(cfg.Autoload) == 'table' then
        self.config.Autoload = cfg.Autoload
    end
end

function PluginManager:Autoload()
    if type(self.config.Autoload) ~= 'table' then return end

    for _, entry in ipairs(self.config.Autoload) do
        assert(type(entry.name) == 'string', 'Autoload entry missing name')
        assert(type(entry.version) == 'string', 'Autoload entry missing version')
        assert(type(entry.subdir) == 'string', 'Autoload entry missing subdir')
        self:loadPlugin(entry.name, entry.version, entry.subdir)
    end
end

function PluginManager:loadPlugin(name, version, subdir)
    assert(type(name) == 'string', 'Plugin name must be a string')
    assert(type(version) == 'string', 'Plugin version must be a string')
    assert(type(subdir) == 'string', 'Plugin subdir must be a string')

    local modulePath = table.concat({ self.base_dir, subdir, name }, '/')
    modulePath = modulePath:gsub('/', '.')
    local pDef = require(modulePath)
    assert(type(pDef) == 'table', 'Plugin module must return a table')
    assert(pDef.name == name, 'Plugin name mismatch: ' .. tostring(pDef.name))
    assert(pDef.version == version, 'Plugin version mismatch: ' .. tostring(pDef.version))
    assert(type(pDef.description) == 'string', 'Plugin missing description')

    local plugin = ScriptPlugin.new(pDef.name, pDef.description, pDef.version, pDef)

    self.plugins[name] = plugin
    plugin.onLoad(plugin)
    return plugin
end

function PluginManager:unloadPlugin(name)
    assert(type(name) == 'string', 'Plugin name must be a string')
    local plugin = self.plugins[name]
    if plugin then
        plugin.onUnload(plugin)
        self.plugins[name] = nil
    else
        error(('Plugin %s is not loaded'):format(name))
    end
end

function PluginManager:unloadAll()
    for name, plugin in pairs(self.plugins) do
        plugin.onUnload(plugin)
    end
    self.plugins = {}
end

function PluginManager:tick(...)
    for _, plugin in pairs(self.plugins) do
        if type(plugin.onUpdate) == 'function' then
            plugin.onUpdate(plugin, ...)
        end
    end
end

function PluginManager:listPlugins()
    local list = {}
    for name, plugin in pairs(self.plugins) do
        list[name] = {
            description = plugin.description,
            hasLoadMethod = type(plugin.onLoad) == 'function',
            hasUnloadMethod = type(plugin.onUnload) == 'function',
            hasUpdateMethod = type(plugin.onUpdate) == 'function',
        }
    end
    return list
end

function PluginManager:use(name)
    return self.plugins[name]
end

return PluginManager
