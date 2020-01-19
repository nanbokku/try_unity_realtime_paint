using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RealTimeMap : MonoBehaviour
{
    [SerializeField]
    private Renderer targetRenderer = null;
    [SerializeField]
    private Material mapMat = null;
    // [SerializeField]
    private RenderTexture mapTexture = null;

    void Awake()
    {
        mapTexture = new RenderTexture(targetRenderer.material.mainTexture.width, targetRenderer.material.mainTexture.height, 0, RenderTextureFormat.ARGB32);
        mapTexture.enableRandomWrite = true;
        mapTexture.Create();

        mapMat.SetTexture("_PaintMap", mapTexture);
        Graphics.ClearRandomWriteTargets();
        Graphics.SetRandomWriteTarget(1, mapTexture);

        var tmp = RenderTexture.GetTemporary(mapMat.mainTexture.width, mapMat.mainTexture.height, 0);
        Graphics.Blit(mapTexture, tmp, mapMat);
        Graphics.Blit(tmp, mapTexture);
        RenderTexture.ReleaseTemporary(tmp);
    }

    void Start()
    {
        targetRenderer.material.mainTexture = mapTexture;
    }
}
