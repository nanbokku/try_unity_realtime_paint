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
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCustomRenderTexture.cginc"
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BrushTex;
            float4 _BrushTex_ST;
            sampler _VertexMap; // 頂点座標マップ
            float4 _VertexMap_ST;
            float4 _PaintColor;
            float _BrushRadius;
            float4 _PaintWorldPosition; // ペイントする座標
            fixed4x4 _ObjectToWorldMatrix;  // unity_ObjectToWorldの代わり

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            /// 描画範囲に含まれているか
            int isRange(float3 worldPos)
            {
                fixed dist = distance(_PaintWorldPosition.xyz, worldPos);
                
                return step(dist, _BrushRadius);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 前フレームのテクスチャを参照する
                float4 lastCol = tex2D(_SelfTexture2D, i.uv);

                // 頂点座標を取得する
                float4 meshCrd = tex2D(_VertexMap, i.uv);

                // 頂点座標からワールド座標を取得する
                float3 worldPos = mul(_ObjectToWorldMatrix, float4(meshCrd.xyz, 1)).xyz;

                // TODO: ここの出力がおかしい．二値化しない
                fixed dist = distance(i.uv, float2(0.5,0.5));
                return lerp(float4(0,0,0,1), float4(1,0,0,1), step(dist, 0.25));
                // return float4(worldPos, 1);

                int canPaint = lerp(0, isRange(worldPos), step(0, _PaintWorldPosition.w));

                if (canPaint != 1) {
                    return lastCol;
                }

                return lerp(lastCol, _PaintColor, isRange(worldPos));
            }
            ENDCG
        }
    }
}
