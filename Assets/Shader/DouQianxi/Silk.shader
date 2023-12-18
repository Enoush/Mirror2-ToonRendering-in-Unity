Shader "Unlit/DouQianxi/Silk"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _Roughness("Roughness",Range(0.1,10)) = 1

        _Color("Color",Color) = (1,1,1,0.5)
        _CubeMap("_CubeMap",CUBE) = "white"{}
        _Opacity("OpacityMut",float) = 0.5
        
        _FresnelMin("FresnelMin",Range(-1,2)) = 0.5
        _FresnelMax("FresnelMax",Range(-1,2)) = 1
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "LightMode"="ForwardBase"}

        Pass
        {
            ZWrite Off

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #pragma multi_compile __ DirDiffuse_ON
            #pragma multi_compile __ DirSpec_ON
            #pragma multi_compile __ EnvDiffuse_ON
            #pragma multi_compile __ EnvSpec_ON

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent: TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal_world : TEXCOORD1;
                float3 pos_world : TEXCOORD2;
                float3 tan_world : TEXCOORD3;
                float3 binnor_world : TEXCOORD4;

            };

            sampler2D _MainTex;
            sampler2D _NormalMap;

            float4 _Color;

            samplerCUBE _CubeMap;
            float4 _CubeMap_HDR;

            float _Opacity;
            float _Roughness;

            float _FresnelMin;
            float _FresnelMax;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.normal_world = normalize(UnityObjectToWorldNormal(v.normal));
                o.pos_world = mul(unity_ObjectToWorld,v.vertex);
                o.tan_world = UnityObjectToWorldDir(v.tangent);
                o.binnor_world = normalize(cross(o.normal_world,o.tan_world)) * v.tangent.w;

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 albedo_col_gamma = tex2D(_MainTex, i.uv);
                half4 albedo_col = pow(albedo_col_gamma,2.2);
                half4 pack_normal = tex2D(_NormalMap, i.uv);
                half3 base_col = albedo_col.rgb;

                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                float3x3 t2w = float3x3(normalize(i.tan_world),normalize(i.binnor_world),normalize(i.normal_world));
                half3 normal_tan = UnpackNormal(pack_normal);
                half3 normal_world = normalize(mul(normal_tan.xyz,t2w));
                half3 reflect_dir = reflect(-view_dir, normal_world);
                half3 light_dir = normalize(UnityWorldSpaceLightDir(i.pos_world));

                half fresnel = saturate(dot(normal_world,view_dir));
                fresnel = smoothstep(_FresnelMin,_FresnelMax,fresnel);
                float mip_level = _Roughness * 6.0;
				half4 color_cubemap = texCUBElod(_CubeMap,float4(reflect_dir,mip_level));
				half3 env_color = DecodeHDR(color_cubemap, _CubeMap_HDR);//确保在移动端能拿到HDR信息

                half newOpacity = pow(min(1.0,_Color.a/fresnel),_Opacity);

                #if EnvSpec_ON
                half4 final_col = half4(min(env_color,env_color*base_col)+base_col*_Color.rgb,newOpacity);
                #else
                half4 final_col = half4(0,0,0,0);
                #endif

                return final_col;
            }
            ENDCG
        }
    }
}
