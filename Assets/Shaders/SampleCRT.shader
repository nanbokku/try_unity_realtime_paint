Shader "Custom/SampleCRT"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Cull Off ZWrite Off ZTest Always
        Pass
        {
            CGPROGRAM
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

            #include "UnityCustomRenderTexture.cginc"

            fixed4 frag (v2f_customrendertexture i) : SV_Target
            {
                float tw = 1 / _CustomRenderTextureWidth;

                // UVはこのように取得する
                float2 uv = i.globalTexcoord;
                // _SelfTexture2Dで前フレームの結果を取得する
                return tex2D(_SelfTexture2D, uv + half2(tw, 0) * 10);
            }
            ENDCG
        }
    }
}
