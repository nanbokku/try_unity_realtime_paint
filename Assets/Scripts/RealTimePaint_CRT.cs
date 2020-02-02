using UnityEngine;

public class RealTimePaint_CRT : MonoBehaviour
{
    [SerializeField]
    private Renderer myRenderer = null;
    [SerializeField]
    private Material uvToWorldPositionMat = null;
    [SerializeField]
    private Renderer buffer = null;

    void Awake()
    {
        Texture mainTexture = myRenderer.material.mainTexture;
        Material originalMat = myRenderer.material;

        myRenderer.material = uvToWorldPositionMat;

        RenderTexture worldPositions = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
        worldPositions.enableRandomWrite = true;

        Graphics.Blit(mainTexture, worldPositions);

        buffer.material.mainTexture = worldPositions;

        myRenderer.material = originalMat;
    }
}
