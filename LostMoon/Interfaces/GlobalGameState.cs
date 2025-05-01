using System;

namespace LostMoon.Interfaces
{
    internal class GlobalGameState
    {
        public bool InGame { get; protected set; }
        public bool IsHost { get; protected set; }

        public GlobalGameState()
        {
            IsHost = false;
            InGame = false;
        }

        public void SetIngame(bool inGame)
        {
            InGame = inGame;
        }

        public void SetHost(bool isHost)
        {
            IsHost = isHost;
        }


        internal void BindLua(LuaState lua)
        {
            lua.RegisterType<GlobalGameState>();
            lua.RegisterFunction("SetInGame", new Action<bool>(SetIngame));
            lua.RegisterFunction("SetHost", new Action<bool>(SetHost));
            lua.RegisterFunction("IsHost", new Func<bool>(() => IsHost));
            lua.RegisterFunction("InGame", new Func<bool>(() => InGame));
        }
    }
}