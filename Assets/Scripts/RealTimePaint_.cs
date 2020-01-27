using UnityEngine;

public class RealTimePaint_ : MonoBehaviour
{
    [SerializeField]
    private Renderer myRenderer = null;
    private int paintWorldPositionId = 0;
    /// <summary>
    /// ペイント点を保持するためのテクスチャ
    /// </summary>
    [SerializeField]
    private RenderTexture paintMap = null;
    [SerializeField]
    private Material mapMat = null;

    void Awake()
    {
        Texture mainTexture = myRenderer.material.mainTexture;

        // PaintMap用のテクスチャを生成
        paintMap = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);   // RenderTextureFormatはARGB32でなければならないらしい(?:未確認)...型はシェーダーが自動で変換してくれる
        paintMap.enableRandomWrite = true;
        // paintMap.doubleBuffered = true; // ダブルバッファをONにして，全フレームのテクスチャを参照できるようにする
        // paintMap.initializationMode = CustomRenderTextureUpdateMode.OnLoad;
        // paintMap.initializationTexture = myRenderer.material.mainTexture;

        // paintMapをシェーダーにセット
        int paintMapId = Shader.PropertyToID("_MapTex");
        myRenderer.material.SetTexture(paintMapId, paintMap);

        // RWTexture2Dに書き込みを行うために必要
        Graphics.ClearRandomWriteTargets();
        Graphics.SetRandomWriteTarget(1, paintMap);
        Graphics.ClearRandomWriteTargets();

        // 各シェーダープロパティIDを取得
        paintWorldPositionId = Shader.PropertyToID("_PaintWorldPosition");
    }

    void Update()
    {
        Paint();
    }

    void Paint()
    {
        // // シェーダーにペイントするワールド座標を設定する
        // myRenderer.material.SetVector(paintWorldPositionId, new Vector4(Random.Range(-5, 5), 0, 0, 1));

        mapMat.SetVector(paintWorldPositionId, new Vector4(0, 0, 0, 1));

        RenderTexture tmp = RenderTexture.GetTemporary(paintMap.width, paintMap.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
        Graphics.Blit(paintMap, tmp, mapMat);
        Graphics.Blit(tmp, paintMap);
        RenderTexture.ReleaseTemporary(tmp);
    }
}