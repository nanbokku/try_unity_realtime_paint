Shader "Custom/RealTimeMap_"
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
            RWTexture2D<float4> _PaintMap;  // register(u1); // ペイントする場所を示したマップ
            sampler2D _MapTex;
            float4 _MapTex_ST;
            float4 _PaintMap_TexelSize; // _PaintMapのサイズ

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

            fixed4 frag (v2f i) : SV_Target
            {   
                // 参照するindexを取得
                uint2 index = i.uv * _PaintMap_TexelSize.zw;

                // ペイント点からどれだけ近いかを[-1,1]の範囲で取得
                float2 nearDegree = howFar2(i.worldPos);
                float2 brushUV = (nearDegree + float2(1,1)) / 2.0;
                brushUV = TRANSFORM_TEX(brushUV, _BrushTex);

                // if (canPaint) then _PaintColor, else _PaintMap[index] color
                // if文を避けるため，lerpとstep関数を組み合わせる
                int canPaint = isRange(i.worldPos);
                fixed4 mainColor = tex2D(_MainTex, i.uv);
                fixed4 brushColor = tex2D(_BrushTex, brushUV);
                brushColor = brushColor * _PaintColor;

                half alpha = brushColor.w;
                fixed4 col = (1 - alpha) * mainColor + alpha * brushColor;

                // TODO: RWTextureはread機能はない
                // マップの保存と描画をわけれない
                if (canPaint == 1) {
                    _PaintMap[index] = col;
                    return col;
                }else {
                    _PaintMap[index] = fixed4(1,1,1,1);
                    return fixed4(1,1,1,1);
                }
                
                return _PaintColor;
                // return _PaintMap[index];
            }
            ENDCG
        }
    }
}
