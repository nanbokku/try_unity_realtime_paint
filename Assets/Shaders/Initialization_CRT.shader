Shader "Custom/Initialization_CRT"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex InitCustomRenderTextureVertexShader
            #pragma fragment frag

            #include "UnityCustomRenderTexture.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            fixed4 frag (v2f_init_customrendertexture i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.texcoord.xy) * _Color;
                return col;
            }
            ENDCG
        }
    }
}
