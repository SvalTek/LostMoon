using System;
using System.Collections.Generic;
using System.Linq;
using MoonSharp.Interpreter;
using MoonSharp.Interpreter.Loaders;
using Il2CppSystem.IO;
using BepInEx.Logging;

namespace LostMoon.Interfaces
{
    public interface ILogger
    {
        void Log(string message);
        void LogError(string message);
    }


    public class UnityLogger : ILogger
    {
        private readonly ManualLogSource _log;
        public UnityLogger(ManualLogSource log) => _log = log;
        public void Log(string msg) => _log.LogInfo(msg);
        public void LogError(string msg) => _log.LogError(msg);
    }

    public class LuaState : IDisposable
    {
        private Script _script;
        private readonly object _syncRoot = new();
        private readonly ILogger _logger;
        private bool _disposed;
        private readonly HashSet<Type> _registeredTypes = new();

        public IList<string> ModulePaths { get; }
        public event Action<string> OnScriptReloaded;

        public LuaState(IEnumerable<string> modulePaths = null, ILogger logger = null)
        {
            _logger = logger ?? new UnityLogger(Logger.CreateLogSource("LostMoon::LuaState"));
            ModulePaths = modulePaths?.ToList() ?? ["?/init.lua", "?.lua", "scripts/?/init.lua", "scripts/?.lua"];
            _script = new Script(CoreModules.Preset_SoftSandbox | CoreModules.LoadMethods | CoreModules.IO )
            {
                Options =
                {
                    DebugPrint = s => _logger.Log(s),
                    ScriptLoader = new FileSystemScriptLoader()
                    {
                        ModulePaths = [.. ModulePaths],
                    }
                }
            };

            _script.Globals["error"] = (Action<string>)((s) => throw new LuaScriptErrorException(s));
            _script.Globals["assert"] = (Func<bool, string, bool>)((condition, message) =>
            {
                if (!condition) throw new LuaScriptErrorException(message);
                return true;
            });
            _script.Globals["Log"] = (Action<string>)((s) => _logger.Log(s));
        }


        public void LoadFile(string path)
        {
            EnsureNotDisposed();
            if (!File.Exists(path))
                throw new LuaScriptErrorException($"File '{path}' not found.");

            lock (_syncRoot)
            {
                try
                {
                    _script.DoFile(path);
                    OnScriptReloaded?.Invoke(path);
                }
                catch (SyntaxErrorException ex)
                {
                    throw new LuaScriptSyntaxErrorException($"Syntax error in '{path}': {ex.DecoratedMessage}", ex);
                }
                catch (ScriptRuntimeException ex)
                {
                    throw new LuaScriptRuntimeException($"Runtime error in '{path}': {ex.DecoratedMessage}", ex);
                }
            }
        }

        public DynValue Execute(string luaCode)
        {
            EnsureNotDisposed();
            lock (_syncRoot)
            {
                var sw = System.Diagnostics.Stopwatch.StartNew();
                try
                {
                    return _script.DoString(luaCode);
                }
                catch (SyntaxErrorException ex)
                {
                    throw new LuaScriptSyntaxErrorException($"Syntax error: {ex.DecoratedMessage}", ex);
                }
                catch (ScriptRuntimeException ex)
                {
                    throw new LuaScriptRuntimeException($"Runtime error: {ex.DecoratedMessage}", ex);
                }
                finally
                {
                    sw.Stop();
                    _logger.Log($"Lua execution took {sw.ElapsedMilliseconds}ms");
                }
            }
        }

        public DynValue CallFunction(string name, params object[] args)
        {
            EnsureNotDisposed();
            lock (_syncRoot)
            {
                var function = GetFromNamespace(name);
                if (function.Type != DataType.Function)
                {
                    throw new LuaFunctionNotFoundException($"Function '{name}' not found in Lua globals.");
                }

                try
                {
                    return _script.Call(function, args);
                }
                catch (ScriptRuntimeException ex)
                {
                    _logger.LogError($"Error calling Lua function '{name}': {ex.DecoratedMessage}");
                    throw new LuaScriptExecutionException($"Error calling '{name}': {ex.DecoratedMessage}", ex);
                }
            }
        }

        public bool IsFunction(string name)
        {
            EnsureNotDisposed();
            lock (_syncRoot)
            {
                var function = GetFromNamespace(name);
                return function.Type == DataType.Function;
            }
        }

        public void RegisterFunction(string name, Delegate del)
        {
            EnsureNotDisposed();
            lock (_syncRoot)
            {
                if (string.IsNullOrWhiteSpace(name))
                {
                    throw new ArgumentException("Function name cannot be null or whitespace.", nameof(name));
                }

                if (del == null)
                {
                    throw new ArgumentNullException(nameof(del), "Delegate cannot be null.");
                }

                SetInNamespace(name, DynValue.NewCallback((ctx, args) =>
                {
                    try
                    {
                        var csArgs = new object[args.Count];
                        for (int i = 0; i < args.Count; i++)
                        {
                            csArgs[i] = args[i].ToObject();
                        }
                        var result = del.DynamicInvoke(csArgs);

                        return result switch
                        {
                            DynValue dynValue => dynValue,
                            null => DynValue.Nil,
                            _ => DynValue.FromObject(_script, result)
                        };
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError($"Lua callback '{name}' failed: {ex.Message}");
                        return DynValue.Nil;
                    }
                }));
            }
        }

        private DynValue GetFromNamespace(string name)
        {
            var parts = name.Split('.');
            var table = _script.Globals;
            for (int i = 0; i < parts.Length - 1; i++)
            {
                table = table.Get(parts[i]).Table;
                if (table == null)
                {
                    throw new LuaFunctionNotFoundException($"Namespace '{string.Join(".", parts.Take(i + 1))}' not found.");
                }
            }
            return table.Get(parts[^1]);
        }

        private void SetInNamespace(string name, DynValue value)
        {
            var parts = name.Split('.');
            var table = _script.Globals;
            for (int i = 0; i < parts.Length - 1; i++)
            {
                var nextTable = table.Get(parts[i]).Table;
                if (nextTable == null)
                {
                    nextTable = new Table(_script);
                    table.Set(parts[i], DynValue.NewTable(nextTable));
                }
                table = nextTable;
            }
            table.Set(parts[^1], value);
        }

        public void SetGlobal(string name, object value)
        {
            EnsureNotDisposed();
            lock (_syncRoot)
            {
                _script.Globals[name] = DynValue.FromObject(_script, value);
            }
        }

        public DynValue GetGlobalDyn(string name)
        {
            EnsureNotDisposed();
            lock (_syncRoot)
            {
                return _script.Globals.Get(name);
            }
        }

        public T GetGlobal<T>(string name)
        {
            var dv = GetGlobalDyn(name);
            return dv.IsNil() ? default : dv.ToObject<T>();
        }

        public void RegisterType<T>()
        {
            EnsureNotDisposed();
            lock (_syncRoot)
            {
                if (_registeredTypes.Add(typeof(T)))
                    UserData.RegisterType<T>();
            }
        }

        private void EnsureNotDisposed()
        {
            if (_disposed) throw new ObjectDisposedException(nameof(LuaState));
        }

        public void Dispose()
        {
            if (_disposed) return;
            lock (_syncRoot)
            {
                _script = null;
                _disposed = true;
                GC.SuppressFinalize(this);
            }
        }
    }

    #region Lua Exceptions
    public class LuaException : Exception
    {
        public LuaException(string message, Exception inner = null) : base(message, inner) { }
    }
    public class LuaFunctionNotFoundException : LuaException
    {
        public LuaFunctionNotFoundException(string func) : base($"Lua function '{func}' not found.") { }
    }
    public class LuaScriptSyntaxErrorException : LuaException
    {
        public LuaScriptSyntaxErrorException(string message, Exception inner = null) : base(message, inner) { }
    }
    public class LuaScriptRuntimeException : LuaException
    {
        public LuaScriptRuntimeException(string message, Exception inner = null) : base(message, inner) { }
    }
    public class LuaScriptExecutionException : LuaException
    {
        public LuaScriptExecutionException(string message, Exception inner = null) : base(message, inner) { }
    }
    public class LuaScriptErrorException : LuaException
    {
        public LuaScriptErrorException(string message, Exception inner = null) : base(message, inner) { }
    }
    #endregion
}
