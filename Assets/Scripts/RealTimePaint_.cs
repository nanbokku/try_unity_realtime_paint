using UnityEngine;

public class RealTimePaint_ : MonoBehaviour
{
    [SerializeField]
    private Material paintMaterial = null;
    private RenderTexture paintTexture = null;
    private int paintWorldPositionId = 0;

    [SerializeField]
    private RenderTexture paintMap = null;

    void Awake()
    {
        Renderer renderer = GetComponent<Renderer>();
        Texture mainTexture = renderer.material.mainTexture;

        // RenderTextureの生成
        paintTexture = new RenderTexture(mainTexture.width, mainTexture.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Default);
        paintTexture.enableRandomWrite = true;

        // 元々のテクスチャを生成したRenderTextureにコピー
        Graphics.Blit(mainTexture, paintTexture);

        // paintMaterialのテクスチャに設定
        int mainTextureId = Shader.PropertyToID("_MainTex");
        paintMaterial.SetTexture(mainTextureId, paintTexture);

        // MainTextureを生成したRenderTextureに変更する
        renderer.material.mainTexture = paintTexture;

        // PaintMap用のテクスチャを生成
        paintMap = new RenderTexture(100, 100, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);   // RenderTextureFormatはARGB32でなければならないらしい...型はシェーダーが自動で変換してくれる
        paintMap.enableRandomWrite = true;

        // paintMapをシェーダーにセット
        int paintMapId = Shader.PropertyToID("_PaintMap");
        paintMaterial.SetTexture(paintMapId, paintMap);

        // 各シェーダープロパティIDを取得
        paintWorldPositionId = Shader.PropertyToID("_PaintWorldPosition");
    }

    void Update()
    {
        Paint();
    }

    void Paint()
    {
        // シェーダーにペイントするワールド座標を設定する
        paintMaterial.SetVector(paintWorldPositionId, new Vector4(0, 0, 0, 0));
    }
}