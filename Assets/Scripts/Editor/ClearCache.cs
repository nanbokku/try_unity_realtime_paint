using System.IO;
using UnityEditor;
using UnityEngine;

public class ClearCache : MonoBehaviour
{
    [MenuItem("Tools/Clear shader cache")]
    static public void ClearShaderCache()
    {
        var cachePath = Path.Combine(Application.dataPath, "../Library/ShaderCache");
        Directory.Delete(cachePath, true);
    }
}