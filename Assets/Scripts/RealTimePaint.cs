using UnityEngine;
using System.Collections;

public class RealTimePaint : MonoBehaviour
{
    [SerializeField]
    private Renderer myRenderer = null;
    private int paintWorldPositionId = 0;
    private int prevTexId = 0;
    private int currentTexId = 0;
    /// <summary>
    /// 前フレームのテクスチャを参照するためのテクスチャ．
    /// paintBuffer2と書き込み，読み込み役を毎フレーム交代する．
    /// </summary>
    private RenderTexture paintBuffer1 = null;
    /// <summary>
    /// 前フレームのテクスチャを参照するためのテクスチャ．
    /// paintBuffer1と書き込み，読み込み役を毎フレーム交代する．
    /// </summary>
    private RenderTexture paintBuffer2 = null;
    /// <summary>
    /// 偶数フレームで描画されたかどうか
    /// </summary>
    private bool isEvenFrameRendered = false;
    private Vector4 worldPosition = new Vector4(0, 0, 0, -1);
    // [SerializeField]
    // private Renderer buffer1 = null;
    // [SerializeField]
    // private Renderer buffer2 = null;

    void Awake()
    {
        Texture mainTexture = myRenderer.material.mainTexture;

        // 前フレームのテクスチャ参照用
        paintBuffer1 = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
        paintBuffer2 = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
        paintBuffer1.enableRandomWrite = true;
        paintBuffer2.enableRandomWrite = true;

        // メインテクスチャで初期化
        Graphics.Blit(mainTexture, paintBuffer1);
        Graphics.Blit(mainTexture, paintBuffer2);

        // 各シェーダープロパティIDを取得
        paintWorldPositionId = Shader.PropertyToID("_PaintWorldPosition");
        prevTexId = Shader.PropertyToID("_PrevTex");
        currentTexId = Shader.PropertyToID("_CurrentTex");

        StartCoroutine(UpdateTextureAction());

        // // for debug
        // buffer1.material.mainTexture = paintBuffer1;
        // buffer2.material.mainTexture = paintBuffer2;
    }

    void Update()
    {
        // Updateメソッドはレンダリング前に実行されるため，必要なデータはここでセットする．
        UpdatePaint();
    }

    public void Paint(Vector3 worldPosition)
    {
        this.worldPosition = new Vector4(worldPosition.x, worldPosition.y, worldPosition.z, 1);
    }

    /// <summary>
    /// リアルタイムペイントを行う．
    /// </summary>
    void UpdatePaint()
    {
        // シェーダーにペイントするワールド座標を設定する
        myRenderer.material.SetVector(paintWorldPositionId, worldPosition);

        if (Time.frameCount % 2 == 0)
        {
            // 偶数フレームはpaintBuffer1を保存用，paintBuffer2を書き込み用にする
            myRenderer.material.SetTexture(prevTexId, paintBuffer1);
            myRenderer.material.SetTexture(currentTexId, paintBuffer2);
            isEvenFrameRendered = true;

            // RWTexture2Dに書き込みを行うために必要
            Graphics.ClearRandomWriteTargets();
            Graphics.SetRandomWriteTarget(1, paintBuffer2);
        }
        else
        {
            // 奇数フレームはpaintBuffer2を保存用，paintBuffer1を書き込み用にする
            myRenderer.material.SetTexture(prevTexId, paintBuffer2);
            myRenderer.material.SetTexture(currentTexId, paintBuffer1);
            isEvenFrameRendered = false;

            // RWTexture2Dに書き込みを行うために必要
            Graphics.ClearRandomWriteTargets();
            Graphics.SetRandomWriteTarget(1, paintBuffer1);
        }
    }

    /// <summary>
    /// テクスチャを更新する処理
    /// </summary>
    /// <returns></returns>
    IEnumerator UpdateTextureAction()
    {
        while (true)
        {
            // スクリーン上のレンダリングが完了するまで待つ
            yield return new WaitForEndOfFrame();

            if (isEvenFrameRendered)
            {
                // paintBuffer2に入っている新しい値でpaintBuffer1を更新する．
                Graphics.Blit(paintBuffer2, paintBuffer1);
            }
            else
            {
                Graphics.Blit(paintBuffer1, paintBuffer2);
            }

            // 次フレームではペイントしないようにするための処理
            worldPosition.w = -1;
        }
    }
}