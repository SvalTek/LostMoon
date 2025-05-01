using System;
using System.IO;
using MoonSharp.Interpreter;
using BepInEx;
using BepInEx.Unity.IL2CPP;
using HarmonyLib;
using UnityEngine;
using LostMoon.Interfaces;
using LostMoon.LuaBindings;

namespace LostMoon
{
    [BepInPlugin(MyPluginInfo.PLUGIN_GUID, MyPluginInfo.PLUGIN_NAME, MyPluginInfo.PLUGIN_VERSION)]
    public class Plugin : BasePlugin
    {
        private readonly Harmony _harmony = new Harmony(MyPluginInfo.PLUGIN_GUID);
        private static BepInEx.Logging.ManualLogSource _log;
        private static LuaState _lua;
        private static bool PANIC = false;

        internal static GlobalGameState GameState { get; } = new GlobalGameState();
        internal static string PlayerName { get; private set; } = "Unknown";
        internal static Vector3 PlayerCoords { get; private set; }
        internal static Rect LayoutRect { get; private set; }

        public override void Load()
        {
            _harmony.PatchAll(typeof(Plugin));
            _log = Log;

            int x = Config.Bind("UI", "x", 0, "X position of main panel").Value;
            int y = Config.Bind("UI", "y", 0, "Y position of main panel").Value;
            int width = Config.Bind("UI", "width", 250, "Width of main panel").Value;
            int height = Config.Bind("UI", "height", 50, "Height of main panel").Value;
            LayoutRect = new Rect(x, y, width, height);
            // TODO: Implement main panel UI


            // Initialize Lua interpreter
            var modulePaths = new[]
            {
                "?/init.lua",
                "?.lua",
                Path.Combine(Paths.PluginPath, "LostMoon", "scripts", "?", "init.lua"),
                Path.Combine(Paths.PluginPath, "LostMoon", "scripts", "?.lua")
            };
            _lua = new LuaState(modulePaths);


            // Register types for Lua to use
            _lua.RegisterType<Vector3>();

            // Setup Bindings.
            GameState.BindLua(_lua);
            FileSystem.BindLua(_lua);


            // Load the init.lua file
            // This is the main entry point for the Lua scripts.
            var initPath = Path.Combine(Paths.PluginPath, "LostMoon", "scripts", "init.lua");
            _lua.LoadFile(initPath);

            if (_lua.IsFunction("OnInit"))
            {
                _log.LogInfo("[LostMoon] Found lua:OnInit(), starting LostMoon...");
                _lua.CallFunction("OnInit");
            }
            else
            {
                PANIC = true;
                _log.LogError("[LostMoon] Failed to find lua:OnInit() function!");
                _log.LogError("[LostMoon] Please report this to the LostMoon devs!");
            }

            _log.LogInfo($"Plugin {MyPluginInfo.PLUGIN_GUID} loaded.");
        }

        [HarmonyPatch(typeof(PlayerNetwork), "Update")]
        [HarmonyPrefix]
        private static void Update(PlayerNetwork __instance)
        {
            if (__instance == null) return;

            if (!__instance.NetworkInstantiated)
            {
                PlayerName = __instance.CharacterName;
                PlayerCoords = __instance.PlayerSync.PlayerWorldPosition;

                if (!GameState.IsHost)
                {
                    GameState.SetHost(true);
                }
            }

            // TODO: Improve lua inititalization routine. we shouldn't do this in every update, need to find better hooks.
            if (!GameState.InGame)
            {
                if (PANIC)
                {
                    _log.LogError("[LostMoon] Lua interpreter failed to initialize, exiting...");
                    return;
                }
                else
                {
                    GameState.SetIngame(true);
                    if (_lua.IsFunction("OnLoad"))
                    {
                        _log.LogInfo("[LostMoon] Found lua:OnLoad(), starting LostMoon...");
                        _lua.CallFunction("OnLoad");
                    }
                    else
                    {
                        PANIC = true;
                        _log.LogError("[LostMoon] Failed to find lua:OnLoad() function!");
                        _log.LogError("[LostMoon] Please report this to the LostMoon devs!");
                        return;
                    }
                }
            }
        }


        /// BUG: i dont even think this is called, need to find the right place to hook into world exit event.
        [HarmonyPatch(typeof(PlayerNetwork), "OnDestroy")]
        [HarmonyPrefix]
        private static void OnDestroy(PlayerNetwork __instance)
        {
            if (__instance == null) return;

            if (GameState.InGame)
            {
                GameState.SetIngame(false);

            }
        }
    }
}
