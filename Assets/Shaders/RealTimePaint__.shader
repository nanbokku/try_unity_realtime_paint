Shader "Custom/RealTimePaint__"
{
    Properties
    {
        _MainTex ("MainTexture", 2D) = "white" {}   // メインのテクスチャ
        _BrushTex ("BrushTexture", 2D) = "white" {}   // ペイント用テクスチャ
        _PaintColor ("PaintColor", Color) = (1,1,1,1)  // ペイントする色
        _BrushRadius ("BrushRadius", Float) = 5 // ペイントする範囲（半径）
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BrushTex;
            float4 _BrushTex_ST;
            float4 _PaintColor;
            float _BrushRadius;
            float4 _PaintWorldPosition;
            RWTexture2D<float4> _CurrentTex;    // register(u1); 更新後のテクスチャ保存用
            Texture2D<float4> _PrevTex; // 前フレームのテクスチャ
            float4 _PrevTex_TexelSize;  // _PrevTexのサイズ

            /// 描画範囲に含まれているか
            int isRange(float3 worldPos)
            {
                fixed dist = distance(_PaintWorldPosition.xyz, worldPos);

                // if (_BrushRadius >= dist) then 1.0, else 0.0
                return step(dist, _BrushRadius);
            }

            /// どの程度離れているか
            float howFar(float3 worldPos)
            {
                fixed dist = distance(_PaintWorldPosition.xyz, worldPos);
                fixed ratio = dist / _BrushRadius;

                return saturate(ratio); // 0~1にクランプ
            }

            /// どの程度離れているかを2次元座標で示す(xy平面が基準)
            float howFar2(float3 worldPos)
            {
                float far = howFar(worldPos);
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

                // ワールド座標を求める
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            // TODO: 微妙に色塗りの境界線が見えてしまう
            fixed4 frag (v2f i) : SV_Target
            {   
                // 参照するindexを取得
                uint2 index = i.uv * _PrevTex_TexelSize.zw;

                // ペイント点からどれだけ近いかを[-1,1]の範囲で取得
                float2 nearDegree = howFar2(i.worldPos);

                // brushTex用のUV座標を計算する
                float2 brushUV = (nearDegree + float2(1,1)) / 2.0;
                brushUV = TRANSFORM_TEX(brushUV, _BrushTex);

                // ペイント色を取得
                fixed4 brushColor = tex2D(_BrushTex, brushUV);
                brushColor = brushColor * _PaintColor;

                // 新しい色でテクスチャを塗り替えるか判定
                // _PaintWorldPosition.wが0以上の場合にペイント
                int canPaint = lerp(0, isRange(i.worldPos), step(0, _PaintWorldPosition.w));

                // 塗り替える場合は新しい色を返す
                if (canPaint == 1) {
                    half alpha = brushColor.w;
                    fixed4 col = (1 - alpha) * _PrevTex[index] + alpha * brushColor;

                    // 新しい値を保存
                    _CurrentTex[index] = col;

                    return col;
                }

                // 塗り替えない場合は前フレームの色をそのまま返す
                return _PrevTex[index];
            }
            ENDCG
        }
    }
}
