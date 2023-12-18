Shader "Unlit/DouQianxi/Face"
{
    Properties
    {
        [Header(Map)]
        _BaseMap ("BaseMap", 2D) = "white" {}
        _CompMap ("CompMap", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _DiffRampMap ("RampMap", 2D) = "white" {}
        _ToonMap("ToonMap",2D) = "white"{}

        [Header(Diffuse)]
        _DiffuseColor("DiffuseColor",COLOR) = (1,1,1,1)
        _AddDiffuseColor("AddDiffuseColor",COLOR) = (0,0,0,0)

        [Header(SPECULAR)]
        _SpecularColor("SpecularColor",COLOR) = (0,0,0,0)
        _SpecularSmoothness("SpecularSmoothness",Range(0.01,100)) = 1
        _SpecularIntensity("SpecularIntensity",Range(0.01,20)) = 1

        [Header(Toon)]
        _ToonColor("ToonColor",COLOR) = (1,1,1,1)
        _ToonColorOffset("ToonColor1Offset",Range(-1,1)) = 0
        _ToonTransit("_ToonTransit",Range(0,1)) = 0.5

        [Header(OutLine)]
        _OutLineWidth("OutLine Width",float) = 2.0
        _OutLineColor("OutLine Color",color) = (1,1,1,1)
        _OutLineZbias("OutLine Z bias",float) = -10
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
            };

            sampler2D _BaseMap;
            sampler2D _CompMap;
            sampler2D _NormalMap;
            sampler2D _DiffRampMap;
            sampler2D _ToonMap;

            float4 _DiffuseColor;
            float4 _AddDiffuseColor;

            float4 _SpecularColor;
            float _SpecularSmoothness;
            float _SpecularIntensity;

            samplerCUBE _CubeMap;
            float4 _CubeMap_HDR;
			float _Expose;

            float4 _ToonColor;
            float _ToonColorOffset;
            float _ToonTransit;


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal_world = normalize(UnityObjectToWorldNormal(v.normal));
                o.pos_world = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                //baseColor
                half4 albedo_col_gamma = tex2D(_BaseMap, i.uv);
                half4 albedo_col = pow(albedo_col_gamma,2.2);
                half4 comp_mask = tex2D(_CompMap, i.uv);
                half4 pack_normal = tex2D(_NormalMap, i.uv);
                half3 toon_map_col = tex2D(_ToonMap,i.uv);

                half3 base_col = albedo_col;

                half ao = saturate(comp_mask.b);
                half add_term = saturate(1 - comp_mask.g);

                //向量
                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                half3 normal_world = normalize(i.normal_world);
                half3 reflect_dir = reflect(-view_dir, normal_world);
                half3 light_dir = normalize(UnityWorldSpaceLightDir(i.pos_world));


                //Direct Diffuse 直接光漫反射
                half3 half_dir = normalize(light_dir+view_dir);
                half NdotL = dot(normal_world,light_dir);
                half half_lambert = (NdotL + 1.0) * 0.5; // [0,1]
                half lambert_term = half_lambert * ao;

                half2 uv_ramp = half2(lambert_term + _ToonColorOffset,_ToonTransit);
                half toon_dif = tex2D(_DiffRampMap,uv_ramp).g;//受光区域为0
                half3 toon_col = lerp(half3(1,1,1),_ToonColor.rgb * toon_map_col.rgb,toon_dif * _ToonColor.a);

                //最终漫反射
                #if DirDiffuse_ON
                half3 final_dif = toon_col.rgb * base_col.rgb * _LightColor0.rgb 
                * _DiffuseColor.rgb;
                #else
                half3 final_dif = half3(0,0,0);
                #endif


                //Direct Specular直接光的镜面反射
                half NdotH = dot(normal_world,half_dir);
                half spe_term = max(0.0001,pow(NdotH,_SpecularSmoothness)) * ao;

                #if DirSpec_ON
                half3 direct_spe = spe_term * _LightColor0.rgb * 
                base_col * _SpecularIntensity * _SpecularColor.rgb;
                #else
                half3 direct_spe = half3(0,0,0);
                #endif

                half3 final_col = final_dif + direct_spe;
                final_col = pow(final_col,1.0/2.2);

                return half4(final_col,1.0);
            }
            ENDCG
        }

        Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ OutLine_ON

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;

                float2 texcoord0 : TEXCOORD0;
                float3 normal : Normal;
                float4 vertex_col : COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 vertex_col : TEXCOORD3;
            };

            sampler2D _BaseMap;

            float _OutLineWidth;
            float _OutLineZbias;
            float4 _OutLineColor;


            v2f vert (appdata v)
            {
                v2f o;

                float3 pos_view = UnityObjectToViewPos(v.vertex.xyz);

                float3 normal_world = UnityObjectToWorldNormal(v.normal);
                float3 OutLine_dir = normalize(mul((float3x3)UNITY_MATRIX_V,normal_world));

                OutLine_dir.z = _OutLineZbias * (1.0 - v.vertex_col.b);//顶点色的b通道用来控制描边的偏移

                o.uv = v.texcoord0;
                o.vertex_col = v.vertex_col;

                pos_view += OutLine_dir * _OutLineWidth * 0.001 * v.vertex_col.a;//顶点色的a通道用来控制描边的宽度

                #if OutLine_ON
                o.vertex = mul(UNITY_MATRIX_P, float4(pos_view, 1.0));
                #else
                o.vertex = UnityObjectToClipPos(v.vertex);
                #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 basecolor = tex2D(_BaseMap,i.uv).xyz;
                half maxComponent = max(max(basecolor.r, basecolor.g), basecolor.b) - 0.004;
                half3 saturatedColor = step(maxComponent.rrr,basecolor) * basecolor;
                saturatedColor = lerp(basecolor.rgb, saturatedColor, 0.6);
                half3 outlineColor = 0.8 * saturatedColor * basecolor * _OutLineColor.xyz;
                
                #if OutLine_ON
                return float4(outlineColor, 1.0);
                #else
                return float4(1,1,1,0);
                #endif
            }
            ENDCG
        }
    }
}
