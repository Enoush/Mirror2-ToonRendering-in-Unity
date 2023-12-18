Shader "Unlit/Rita/Skin_eye"
{
    Properties
    {
        [Header(Map)]
        _BaseMap ("BaseMap", 2D) = "white" {}
        _CompMap("CompMap",2D) = "black"{}
        _NormalMap("NormalMap",2D) = "bump"{}
        _DecalMap ("DecalMap", 2D) = "black" {}

        [Header(Diffuse)]
        _DiffuseColor("DiffuseColor",COLOR) = (1,1,1,1)
        _HighlightColor("HighlightColor",COLOR) = (1,1,1,1)

        [Header(Env SPECULAR)]
        _EnvColor("EnvColor",COLOR) = (1,1,1,1)
        _CubeMap("CubeMap",CUBE) = "white"{}
		_Expose("Expose",Float) = 1.0
        _Roughness("Roughness",Float) = 0.5
    }
    SubShader
    {
        Tags {"LightMode"="ForwardBase"}
        LOD 100

        Pass
        {
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
                float3 normal : Normal;
                float4 tangent: TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal_world : TEXCOORD1;
                float3 pos_world : TEXCOORD2;
                float3 tan_world : TEXCOORD3;
                float3 binnor_world : TEXCOORD4;
            };

            sampler2D _BaseMap;
            sampler2D _CompMap;
            sampler2D _NormalMap;
            sampler2D _DecalMap;

            float4 _DiffuseColor;
            float4 _HighlightColor;

            samplerCUBE _CubeMap;
            float4 _CubeMap_HDR;
			float _Expose;
            float _Roughness;
            float4 _EnvColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal_world = normalize(UnityObjectToWorldNormal(v.normal));
                o.pos_world = mul(unity_ObjectToWorld,v.vertex);
                o.tan_world = UnityObjectToWorldDir(v.tangent);
                o.binnor_world = normalize(cross(o.normal_world,o.tan_world)) * v.tangent.w;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                //baseColor
                half4 albedo_col_gamma = tex2D(_BaseMap, i.uv);
                half4 albedo_col = pow(albedo_col_gamma,2.2);
                
                half4 comp_mask = tex2D(_CompMap, i.uv);
                half4 pack_normal = tex2D(_NormalMap, i.uv);
                half3 base_col = albedo_col;
                half4 decal_col = tex2D(_DecalMap, i.uv);

                half hlight = 1 - comp_mask.a;
                //hlight = saturate((hlight - 0.5) * 50);
                #if DirSpec_ON
                float3 hlight_col = lerp(float3(0,0,0),_HighlightColor,hlight);
                #else
                float3 hlight_col = float3(0,0,0);
                #endif

                //向量
                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                float3x3 t2w = float3x3(normalize(i.tan_world),normalize(i.binnor_world),normalize(i.normal_world));
                half3 normal_tan = UnpackNormal(pack_normal);
                half3 normal_world = normalize(mul(normal_tan.xyz,t2w));
                normal_tan.xy = -normal_tan.xy;
                half3 normal_world_iris = normalize(mul(normal_tan,t2w));

                half3 reflect_dir = reflect(-view_dir, normal_world);
                half3 light_dir = normalize(UnityWorldSpaceLightDir(i.pos_world));

                //Direct Diffuse 直接光漫反射
                half3 half_dir = normalize(light_dir+view_dir);
                half NdotL = dot(normal_world_iris,light_dir);
                half half_lambert = (NdotL + 1.0) * 0.5; // [0,1]
                //最终漫反射

                #if DirDiffuse_ON
                half3 final_dif = base_col.rgb * half_lambert * _DiffuseColor.rgb;
                #else
                half3 final_dif = half3(0,0,0);
                #endif


                //Indirect SPECULAR 间接光的镜面反射
                half roughness = lerp(0.0,0.95,saturate(_Roughness));
                roughness = roughness * (1.7 - 0.7 * roughness);
				float mip_level = roughness * 6.0;
				half4 color_cubemap = texCUBElod(_CubeMap,float4(reflect_dir,mip_level));
				half3 env_color = DecodeHDR(color_cubemap, _CubeMap_HDR);//确保在移动端能拿到HDR信息
				half3 env_spe = env_color * _Expose;
                half env_lumin = dot(env_spe,float3(0.299f,0.587f,0.114f));

                #if EnvSpec_ON
                env_spe = env_spe * env_lumin * base_col.r * _EnvColor.rgb;
                #else
                env_spe = half3(0,0,0);
                #endif

                half3 final_col = final_dif + env_spe + hlight_col;
                //+(decal_col.rgb * 0.2)


                final_col = pow(final_col,1.0/2.2);
                return half4(final_col,1.0);
            }
            ENDCG
        }
    }
}
