using System.IO;
using System;
using LostMoon.Interfaces;

namespace LostMoon.LuaBindings
{
    internal class FileSystem
    {
        public static bool Exists(string path) =>
            File.Exists(path) || Directory.Exists(path);

        public static string ReadAllText(string path) =>
            File.ReadAllText(path);

        public static void WriteAllText(string path, string content) =>
            File.WriteAllText(path, content);

        public static string[] GetFiles(string path, string searchPattern = "*") =>
            Directory.Exists(path)
                ? Directory.GetFiles(path, searchPattern)
                : new string[0];

        public static void CreateDirectory(string path) =>
            Directory.CreateDirectory(path);

        public static void Delete(string path)
        {
            if (File.Exists(path))
                File.Delete(path);
            else if (Directory.Exists(path))
                Directory.Delete(path, true);
        }

        public static string Combine(string path1, string path2) =>
            Path.Combine(path1, path2);


        
        internal static void BindLua(LuaState lua)
        {
            lua.RegisterType<FileSystem>();
            lua.RegisterFunction("FS.Exists", new Func<string, bool>(Exists));
            lua.RegisterFunction("FS.ReadAllText", new Func<string, string>(ReadAllText));
            lua.RegisterFunction("FS.WriteAllText", new Action<string, string>(WriteAllText));
            lua.RegisterFunction("FS.GetFiles", new Func<string, string, string[]>(GetFiles));
            lua.RegisterFunction("FS.CreateDirectory", new Action<string>(CreateDirectory));
            lua.RegisterFunction("FS.Delete", new Action<string>(Delete));
            lua.RegisterFunction("FS.Combine", new Func<string, string, string>(Combine));
        }
    }



}


