Shader "Custom/RealTimePaint"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}   // ペイント用テクスチャ
        _PaintColor ("PaintColor", Color) = (0,0,0,0)   // ペイントする色
        _BrushRadius ("BrushRadius", Float) = 5 // ペイントする範囲（半径）
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD2;
                float3 worldDirection : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _PaintColor;
            float _BrushRadius;
            float4 _PaintWorldPosition; // ペイント中心位置
            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_ST;
            float4x4 _ViewProjectionInverse; // (projction * view).inverse

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                // o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // TODO: ワールド座標を求める

                // float4 clip = float4((o.uv.x) * 2 - 1, (o.uv.y) * 2 - 1, 0, 1);

                // MEMO: RenderTextureだとテクスチャ座標になる
                float4 clip = float4(o.vertex.xy, 0, 1);
                o.worldDirection = mul(_ViewProjectionInverse, clip).xyz - _WorldSpaceCameraPos;

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                depth = LinearEyeDepth(depth);

                // float4 H = float4((i.uv.x) * 2 - 1, (i.uv.y) * 2 - 1, depth, 1);
                float4 H = float4((i.uv.x) * 2 - 1, (i.uv.y) * 2 - 1, 0, 1);

                float4 D = mul(_ViewProjectionInverse, H);
                D = D / D.w;
                
                float3 worldPos = D.xyz + _WorldSpaceCameraPos;
                return float4(i.worldDirection, 1);
                return fixed4(i.worldDirection * depth + _WorldSpaceCameraPos, 1);

                float2 uv = TRANSFORM_TEX(i.uv, _MainTex);
                fixed4 col = tex2D(_MainTex, uv);

                if (distance(worldPos.xyz, _PaintWorldPosition.xyz) < _BrushRadius) {
                    col = _PaintColor * tex2D(_MainTex, uv);
                }

                // // sample the texture
                // fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
