Shader "Hidden/GuassBlur"
{
    CGINCLUDE
    #include "UnityCG.cginc"
    sampler2D _MainTex;
    float4 _MainTex_TexelSize;
    float _BlurOffset;

    half4 frag_guassVertical(v2f_img i) : SV_Target
    {
        half4 s = 0;
        half2 uv1 = i.uv + _MainTex_TexelSize.xy * half2(0,1) * -2.0* _BlurOffset;
        half2 uv2 = i.uv + _MainTex_TexelSize.xy * half2(0,1) * -1.0* _BlurOffset;
        half2 uv3 = i.uv;
        half2 uv4 = i.uv + _MainTex_TexelSize.xy * half2(0,1) * 1.0* _BlurOffset;
        half2 uv5 = i.uv + _MainTex_TexelSize.xy * half2(0,1) * 2.0* _BlurOffset;

        s += tex2D(_MainTex,uv1) * 0.05;
        s += tex2D(_MainTex,uv2) * 0.25;
        s += tex2D(_MainTex,uv3) * 0.40;
        s += tex2D(_MainTex,uv4) * 0.25;
        s += tex2D(_MainTex,uv5) * 0.05;

        return s;
    }

    half4 frag_guassHorizontal(v2f_img i) : SV_Target
    {
        half4 s = 0;
        half2 uv1 = i.uv + _MainTex_TexelSize.xy * half2(1,0) * -2.0* _BlurOffset;
        half2 uv2 = i.uv + _MainTex_TexelSize.xy * half2(1,0) * -1.0* _BlurOffset;
        half2 uv3 = i.uv;
        half2 uv4 = i.uv + _MainTex_TexelSize.xy * half2(1,0) * 1.0* _BlurOffset;
        half2 uv5 = i.uv + _MainTex_TexelSize.xy * half2(1,0) * 2.0* _BlurOffset;

        s += tex2D(_MainTex,uv1) * 0.05;
        s += tex2D(_MainTex,uv2) * 0.25;
        s += tex2D(_MainTex,uv3) * 0.40;
        s += tex2D(_MainTex,uv4) * 0.25;
        s += tex2D(_MainTex,uv5) * 0.05;

        return s;
    }
    ENDCG


    Properties
    {
        _MainTex ("_MainTex", 2D) = "white" {}

        _BlurOffset("_BlurOffset",float) = 1
    }

    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_guassVertical
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_guassHorizontal
            ENDCG
        }
    }
}
