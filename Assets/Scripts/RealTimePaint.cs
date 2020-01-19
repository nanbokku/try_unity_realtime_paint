using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RealTimePaint : MonoBehaviour
{
    [SerializeField]
    private Material paintMaterial = null;
    private RenderTexture paintTexture = null;
    private int paintWorldPositionId = 0;
    private int viewProjectionInverseId = 0;

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

        // 各シェーダープロパティIDを取得
        paintWorldPositionId = Shader.PropertyToID("_PaintWorldPosition");
        viewProjectionInverseId = Shader.PropertyToID("_ViewProjectionInverse");

        // シェーダーでdepthを取り出すための設定
        Camera.main.depthTextureMode = DepthTextureMode.Depth;
    }

    void Update()
    {
        Paint();
    }

    // void OnRenderImage(RenderTexture src, RenderTexture dest)
    // {
    //     paintMaterial.SetVector(paintWorldPositionId, new Vector4(0, 0, 0, 0));

    //     // from https://gamedev.stackexchange.com/questions/131978/shader-reconstructing-position-from-depth-in-vr-through-projection-matrix/140924#140924
    //     Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(Camera.main.projectionMatrix, false);
    //     projectionMatrix[2, 3] = projectionMatrix[3, 2] = 0.0f;
    //     projectionMatrix[3, 3] = 1.0f;

    //     Matrix4x4 clipToWorld = Matrix4x4.Inverse(projectionMatrix * Camera.main.worldToCameraMatrix) * Matrix4x4.TRS(new Vector3(0, 0, -projectionMatrix[2, 2]), Quaternion.identity, Vector3.one);
    //     paintMaterial.SetMatrix(viewProjectionInverseId, clipToWorld);

    //     // ペイント処理
    //     Graphics.Blit(src, dest, paintMaterial);
    // }

    void Paint()
    {
        paintMaterial.SetVector(paintWorldPositionId, new Vector4(0, 0, 0, 0));

        // from https://gamedev.stackexchange.com/questions/131978/shader-reconstructing-position-from-depth-in-vr-through-projection-matrix/140924#140924
        Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(Camera.main.projectionMatrix, false);
        projectionMatrix[2, 3] = projectionMatrix[3, 2] = 0.0f;
        projectionMatrix[3, 3] = 1.0f;

        Matrix4x4 clipToWorld = Matrix4x4.Inverse(projectionMatrix * Camera.main.worldToCameraMatrix) * Matrix4x4.TRS(new Vector3(0, 0, -projectionMatrix[2, 2]), Quaternion.identity, Vector3.one);
        paintMaterial.SetMatrix(viewProjectionInverseId, clipToWorld);

        // ペイント処理
        RenderTexture tmp = RenderTexture.GetTemporary(paintTexture.width, paintTexture.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Default);  // 一時的なテクスチャを作成する
        Graphics.Blit(paintTexture, tmp, paintMaterial);  // paintMaterialを基にtmpに描画する
        Graphics.Blit(tmp, paintTexture); // その後，tmpに描画された結果をpaintTextureにコピー
        RenderTexture.ReleaseTemporary(tmp);  // tmpを解放
    }
}
