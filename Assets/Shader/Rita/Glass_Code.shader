Shader "Unlit/Rita/Glass_Code"
{
    Properties
    {
        _DiffRampMap ("RampMap", 2D) = "white" {}
        _CutOut("CutOut",Range(0,1)) = 0.1
        _Alpha("Alpha",Range(0,1)) = 0.1
    }
    SubShader
    {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

        LOD 100
        ZWrite Off
        Blend DstColor SrcColor

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

            sampler2D _DiffRampMap;
            float4 _DiffRampMap_ST;

            float _CutOut;
            float _Alpha;

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.vertex.xy * _DiffRampMap_ST.xy + _DiffRampMap_ST.zw;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 rampMap = tex2D(_DiffRampMap,i.uv);

                clip(rampMap.g - _CutOut);

                return fixed4(rampMap,_Alpha);
            }
            ENDCG
        }
    }
}
