return {
    name = "test",
    version = "1.0.0",
    description = "Test plugin",
    author = "Theros",
    dependencies = {
        "lostmoon"
    },
    OnLoad = function()
        -- Initialize the test plugin
        print("Test plugin initialized")
    end,
    OnUnload = function()
        -- Run the test plugin
        print("Test plugin unloaded")
    end,
    OnUpdate = function()
        -- Update the test plugin
        print("Test plugin updated")
    end,
}
