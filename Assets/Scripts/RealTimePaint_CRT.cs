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
    [SerializeField]
    private Renderer buffer = null; // デバッグ用

    void Start()
    {
        Texture mainTexture = myRenderer.material.mainTexture;
        Debug.Log(mainTexture);
        int width = mainTexture.width;
        int height = mainTexture.height;

        // NOTE: ある程度テクスチャのサイズが大きくないとその後の描画が変になる
        if (width < 1024 || height < 1024)
        {
            width = height = 1024;
        }

        // ペイント用テクスチャの作成
        paintTexture = new CustomRenderTexture(width, height, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default)
        {
            material = paintMat,    // paintMatに応じて更新される
            initializationSource = CustomRenderTextureInitializationSource.TextureAndColor,
            initializationTexture = mainTexture,
            initializationColor = Color.white,
            initializationMode = CustomRenderTextureUpdateMode.OnDemand,    // スクリプトに応じて初期化
            updateMode = CustomRenderTextureUpdateMode.OnDemand,    // スクリプトに応じて更新
            doubleBuffered = true
        };
        paintTexture.Create();
        paintTexture.Initialize();

        // メインテクスチャへ設定
        int mainTexId = Shader.PropertyToID("_MainTex");
        myRenderer.material.SetTexture(mainTexId, paintTexture);

        // 頂点座標を保持するテクスチャの作成
        // NOTE: 負の値をRenderTextureに記述するためにformatはfloat,あるいはhalfでなければならない．
        vertexMap = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Default)
        {
            // ピクセルを一つ一つブロックのように表示する
            filterMode = FilterMode.Point,
        };

        // 各種シェーダープロパティIDを更新
        paintWorldPositionId = Shader.PropertyToID("_PaintWorldPosition");
        objectToWorldMatrixId = Shader.PropertyToID("_ObjectToWorldMatrix");
        vertexMapId = Shader.PropertyToID("_VertexMap");

        // 頂点座標マップを更新
        UpdateVertexMap();

        // for debug
        buffer.material.mainTexture = vertexMap;
    }

    void Update()
    {
        if (!Input.GetMouseButton(0)) return;

        var screenPos = Input.mousePosition;
        var ray = Camera.main.ScreenPointToRay(screenPos);

        RaycastHit hit;
        bool isHit = Physics.Raycast(ray, out hit);

        if (!isHit) return;

        Paint(hit.point);
    }

    /// <summary>
    /// 任意の座標にペイントする
    /// </summary>
    /// <param name="worldPosition">ペイントする座標</param>
    public void Paint(Vector3 worldPosition)
    {
        this.paintPosition = new Vector4(worldPosition.x, worldPosition.y, worldPosition.z, 1);

        UpdatePaintTexture();
    }

    /// <summary>
    /// 頂点座標マップを更新する
    /// </summary>
    private void UpdateVertexMap()
    {
        // DrawMeshNow()の前に使用するシェーダーパスを指定する
        vertexMapMat.SetPass(0);

        // メッシュを描画
        Graphics.SetRenderTarget(vertexMap);
        Graphics.DrawMeshNow(myMesh, Matrix4x4.identity);
    }

    /// <summary>
    /// ペイント用テクスチャを更新する
    /// </summary>
    private void UpdatePaintTexture()
    {
        paintMat.SetMatrix(objectToWorldMatrixId, myRenderer.localToWorldMatrix);
        paintMat.SetVector(paintWorldPositionId, paintPosition);
        paintMat.SetTexture(vertexMapId, vertexMap);

        paintTexture.Update(1);
    }
}
