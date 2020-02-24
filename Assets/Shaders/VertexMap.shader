Shader "Custom/VertexMap"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 pos : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                
                // クリップ空間座標に変換
                float2 uv = v.uv * 2.0 - 1.0;

                #if UNITY_UV_STARTS_AT_TOP
                uv.y *= -1.0;
                #endif

                o.vertex = float4(uv, 1, 1);    // SV_POSITION
                o.pos = v.vertex;    // TEXCOORD0
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return float4(i.pos, 1);
            }
            ENDCG
        }
    }
}
