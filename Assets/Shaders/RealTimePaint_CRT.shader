Shader "Custom/RealTimePaint_CRT"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BrushTex ("Brush Texture", 2D) = "white" {}    // ペイント用テクスチャ
        _PaintColor ("Paint Color", Color) = (1,1,1,1)  // ペイント色
        _BrushRadius ("Brush Radius", Float) = 5    // ペイント範囲
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

            #include "UnityCustomRenderTexture.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BrushTex;
            float4 _BrushTex_ST;
            float4 _PaintColor;
            float _BrushRadius;
            float4 _PaintWorldPosition; // ペイントする座標

            int isRange(float3 worldPos)
            {
                fixed dist = distance(_PaintWorldPosition.xyz, worldPos);
            }

            fixed4 frag (v2f_customrendertexture i) : SV_Target
            {
                float du = 1.0 / _CustomRenderTextureWidth;
                float dv = 1.0 / _CustomRenderTextureHeight;
                float2 uv = i.globalTexcoord;

                return mul(unity_ObjectToWorld, float4(uv, 0, 1));

                float x = (_CustomRenderTextureWidth / 2.0 + 5) * du;
                float y = (_CustomRenderTextureHeight / 2.0 + 10) * dv;
                float dist = distance(float2(x,y), uv);

                int paint = step(dist, 0.5);
                return lerp(float4(1,1,1,1), _PaintColor, paint);

                fixed4 col = tex2D(_SelfTexture2D, uv);
                return col;
            }
            ENDCG
        }
    }
}
