Shader "Unlit/RealTimePaint_"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}   // ペイント用テクスチャ
        _PaintColor ("PaintColor", Color) = (0,0,0,0)  // ペイントする色
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                UNITY_FOG_COORDS(2)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _PaintColor;
            float _BrushRadius;
            float4 _PaintWorldPosition; // ペイント中心位置
            RWTexture2D<float4> _PaintMap;  // ペイントする場所を示したマップ

            bool isRange(float3 worldPos)
            {
                float3 paintPos = _PaintWorldPosition.xyz;
                fixed dist = distance(paintPos, worldPos);

                if (dist <= _BrushRadius) return true;
                else return false;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv2 = v.uv2;
                UNITY_TRANSFER_FOG(o,o.vertex);

                // ワールド座標を求める
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                bool canPaint = isRange(i.worldPos);

                if (canPaint) {
                    // mapTextureに描画する
                    _PaintMap[i.uv2] = _PaintColor;
                }

                // 描画されたmapTextureに基づき色付けを行う
                fixed4 col = tex2D(_MainTex, i.uv) * _PaintMap[i.uv2];
                col = _PaintMap[i.uv2];

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }
            ENDCG
        }
    }
}
