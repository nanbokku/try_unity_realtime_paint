Shader "Custom/RealTimeMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            // // make fog work
            // #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : TEXCOORD0;
                // UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            RWTexture2D<float4> _PaintMap : register(u1);  // マップ
            float4 _PaintWorldPosition;
            // worldPosition -> shader
            // shader : clipPosition -> worldPosition == worldPosition?

            v2f vert (appdata v)
            {
                v2f o;
                // o.vertex = UnityObjectToClipPos(v.vertex);
                // o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // テクスチャ座標を頂点座標に変換
                float2 uv = v.uv * 2.0 - 1.0;

                // 座標系の違いを吸収
                #if UNITY_UV_STARTS_AT_TOP
                uv.y *= -1;
                #endif
                
                o.vertex = float4(uv, 1, 1);

                // 頂点座標を出力
                o.pos = o.vertex;

                // UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // // sample the texture
                // fixed4 col = tex2D(_MainTex, i.uv);
                // // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);

                // 頂点座標を色として出力
                float4 col = float4(i.pos.xyz, 1);
                _PaintMap[int2(i.vertex.xy)] = col;

                return col;
            }
            ENDCG
        }
    }
}
