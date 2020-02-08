using UnityEngine;
using System.Collections.Generic;
using System.Linq;

public class RealTimePaint_CRT : MonoBehaviour
{
    [SerializeField]
    private Renderer myRenderer = null;
    [SerializeField]
    private Mesh myMesh = null;
    /// <summary>
    /// ペイント用のマテリアル
    /// </summary>
    [SerializeField]
    private Material paintMat = null;
    /// <summary>
    /// 頂点座標マップを作成するマテリアル
    /// </summary>
    [SerializeField]
    private Material vertexMapMat = null;
    [SerializeField]
    private Renderer buffer = null;
    /// <summary>
    /// 頂点座標マップ
    /// </summary>
    private RenderTexture vertexMap = null;
    /// <summary>
    /// ペイント用テクスチャ．メインテクスチャにセットする．
    /// </summary>
    private CustomRenderTexture paintTexture = null;
    /// <summary>
    /// ペイントするワールド座標
    /// </summary>
    /// <returns></returns>
    private Vector4 paintPosition = new Vector4(-1, -1, -1, -1);
    private int paintWorldPositionId = 0;
    private int objectToWorldMatrixId = 0;
    private int vertexMapId = 0;

    void Start()
    {
        Texture mainTexture = myRenderer.material.mainTexture;

        // ペイント用テクスチャの作成
        paintTexture = new CustomRenderTexture(mainTexture.width, mainTexture.height, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
        paintTexture.enableRandomWrite = true;
        paintTexture.doubleBuffered = true;

        // ペイントテクスチャの初期化，メインテクスチャへ設定
        Graphics.Blit(mainTexture, paintTexture);
        int mainTexId = Shader.PropertyToID("_MainTex");
        myRenderer.material.SetTexture(mainTexId, paintTexture);

        // 頂点座標を保持するテクスチャの作成
        vertexMap = new RenderTexture(mainTexture.width, mainTexture.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default)
        {
            // ピクセルを一つ一つブロックのように表示する
            filterMode = FilterMode.Point,
        };
        vertexMap.enableRandomWrite = true;

        // 各種シェーダープロパティIDを更新
        paintWorldPositionId = Shader.PropertyToID("_PaintWorldPosition");
        objectToWorldMatrixId = Shader.PropertyToID("_ObjectToWorldMatrix");
        vertexMapId = Shader.PropertyToID("_VertexMap");

        // 頂点座標マップを更新
        UpdateVertexMap();

        // for debug
        buffer.material.mainTexture = vertexMap;
        paintPosition = new Vector4(0, 0, 0, 1);
    }

    void Update()
    {
        // if (Input.GetMouseButton(0))
        UpdateRenderTexture();
    }

    /// <summary>
    /// 頂点座標マップを更新する
    /// </summary>
    private void UpdateVertexMap()
    {
        // DrawMeshNow()の前に使用するシェーダーパスを指定する
        vertexMapMat.SetPass(0);

        // Define translation, rotation and scaling matrix 
        Matrix4x4 trs = Matrix4x4.TRS(Vector3.zero, this.transform.rotation, this.transform.localScale);

        // メッシュを描画
        Graphics.SetRenderTarget(vertexMap);
        Graphics.DrawMeshNow(myMesh, trs);
    }

    private void UpdateRenderTexture()
    {
        paintMat.SetMatrix(objectToWorldMatrixId, this.transform.localToWorldMatrix);
        paintMat.SetVector(paintWorldPositionId, paintPosition);
        paintMat.SetTexture(vertexMapId, vertexMap);

        RenderTexture tmp = RenderTexture.GetTemporary(paintTexture.descriptor);
        Graphics.Blit(paintTexture, tmp);
        Graphics.Blit(tmp, paintTexture, paintMat);
        RenderTexture.ReleaseTemporary(tmp);
    }
}
