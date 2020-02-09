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
            float4x4 _ObjectToWorldMatrix;  // unity_ObjectToWorldの代わり

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

            /// どの程度離れているかを2次元座標で示す
            float2 howFar2(float3 worldPos)
            {
                fixed dist = distance(_PaintWorldPosition.xyz, worldPos);
                fixed ratio = dist / _BrushRadius;
                float far = saturate(ratio);    // 0~1にクランプ
                fixed3 diff = worldPos - _PaintWorldPosition.xyz;

                // xy平面の成分
                half2 elem = dot(half2(1,1), diff);
                return far * sign(elem);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // TODO: 前フレーム情報を参照できていない？
                // NOTE: おそらくCustomRenderTexture.materialに参照するシェーダーをセットしなければならない？
                // 前フレームのテクスチャを参照する
                float4 lastCol = tex2D(_SelfTexture2D, i.uv);

                // 頂点座標を取得する
                float4 meshCrd = tex2D(_VertexMap, i.uv);

                // 頂点座標からワールド座標を取得する
                float3 worldPos = mul(_ObjectToWorldMatrix, float4(meshCrd.xyz, 1)).xyz;

                // ペイント点からどれだけ近いかを[-1,1]の範囲で取得
                float2 nearDegree = -1 * howFar2(worldPos);

                // brushTex用のUV座標を計算する
                float2 brushUV = (nearDegree + float2(1,1)) / 2.0;
                brushUV = TRANSFORM_TEX(brushUV, _BrushTex);

                // ペイント色を取得
                fixed4 brushColor = tex2D(_BrushTex, brushUV);
                brushColor = brushColor * _PaintColor;
                half alpha = brushColor.a;
                
                // ブレンドした色
                fixed4 blendedColor = (1 - alpha) * lastCol + alpha * brushColor;

                return lerp(lastCol, blendedColor, isRange(worldPos));
            }
            ENDCG
        }
    }
}
