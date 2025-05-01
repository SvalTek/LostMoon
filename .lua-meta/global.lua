---@meta

--- Log a message to the console.
---@param msg string
function Log(msg) end

--- Is Client the Host?.
---@type boolean
IsHost = false

--- Set the IsHost flag.
---@param hosting boolean
function SetHost(hosting) end

--- Is Client ingame (connected to a world).
---@type boolean
InGame = false

--- Set the IsIngame flag.
---@param ingame boolean
function SetInGame(ingame) end

FS = {
    --- Get the current working directory.
    ---@param path string
    ---@return string
    Exists = function(path) end,

    --- Read a text file and return its contents.
    ---@param path string
    ---@return string
    ReadAllText = function(path) end,

    --- Write text to a file.
    ---@param path string
    ---@param text string
    WriteAllText = function(path, text) end,

    --- Get files in a directory.
    ---@param path string
    ---@param searchPattern string
    ---@return string[]
    GetFiles = function(path, searchPattern) end,

    --- Create a directory.
    ---@param path string
    CreateDirectory = function(path) end,

    --- Delete a file or directory.
    ---@param path string
    Delete = function(path) end,

    --- Combine two paths.
    ---@param path1 string
    ---@param path2 string
    ---@return string
    Combine = function(path1, path2) end,
}
