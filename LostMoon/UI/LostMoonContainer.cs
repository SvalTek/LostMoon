using Il2CppSystem;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

namespace LostMoon.UI
{
    internal class LostMoonContainer : UnityEngine.MonoBehaviour
    {
        void OnGUI()
        {
            GUILayout.BeginArea(Plugin.LayoutRect);

            GUILayout.Box($"LostMoon v{MyPluginInfo.PLUGIN_VERSION}");

            GUILayout.EndArea();
        }
    }
}
