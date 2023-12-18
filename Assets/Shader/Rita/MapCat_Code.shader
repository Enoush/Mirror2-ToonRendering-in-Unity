Shader "Unlit/Rita/MapCat_Code"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _DiffuseColor("DiffuseColor",COLOR) = (0,0,0,0)

        _MapCatTex ("MapCatTex", 2D) = "white" {}
        _MapCatAddTex ("MapCatAddTex", 2D) = "white" {}
        _MapCatIntensity("MapCatIntensity",float) = 1.0
        _MapCatAddIntensity("MapCatAddIntensity",float) = 1.0

        _SpecularScale("SpecularScale",Range(0.01,5)) = 1
        _SpecularIntensity("SpecularIntensity",Range(0.01,5)) = 1
        _SpecularColor("SpecularColor",COLOR) = (0,0,0,0)
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

            #pragma multi_compile __ DirDiffuse_ON
            #pragma multi_compile __ DirSpec_ON
            #pragma multi_compile __ EnvDiffuse_ON
            #pragma multi_compile __ EnvSpec_ON

            #pragma multi_compile __ MapCatSpec_ON
            #pragma multi_compile __ OutLine_ON

            #include "UnityCG.cginc"
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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 pos_world : TEXCOORD3;
                float3 tan_world : TEXCOORD4;
                float3 binnor_world : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            float4 _DiffuseColor;

            sampler2D _MapCatTex;
            sampler2D _MapCatAddTex;
            float _MapCatIntensity;
            float _MapCatAddIntensity;
            float _SpecularScale;
            float _SpecularIntensity;
            float4 _SpecularColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.pos_world = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                o.worldViewDir = normalize(UnityWorldSpaceViewDir(o.pos_world));

                o.tan_world = UnityObjectToWorldDir(v.tangent);
                o.binnor_world = normalize(cross(o.worldNormal,o.tan_world)) * v.tangent.w;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 albedo_col_gamma = tex2D(_MainTex, i.uv);
                half4 col = pow(albedo_col_gamma,2.2);


                half3 worldNormal = normalize(i.worldNormal);
                half3 worldViewDir = normalize(i.worldViewDir);
                half4 pack_normal = tex2D(_NormalMap, i.uv);
                float3x3 t2w = float3x3(normalize(i.tan_world),normalize(i.binnor_world),worldNormal);
                half3 normal_tan = UnpackNormal(pack_normal);
                worldNormal = normalize(mul(normal_tan.xyz,t2w));

                half3 viewNormal = normalize(mul(UNITY_MATRIX_V,float4(worldNormal,0.0)));
                half3 light_dir = normalize(UnityWorldSpaceLightDir(i.pos_world));

                //Direct Specular直接光的镜面反射
                half3 half_dir = normalize(light_dir+worldViewDir);
                half spe_fac = pow(saturate(dot(half_dir,worldNormal)),_SpecularScale);

                #if DirSpec_ON
                half3 direct_spe = spe_fac * _LightColor0.rgb * col.rgb  * _SpecularIntensity * _SpecularColor.rgb;
                #else
                half3 direct_spe = half3(0,0,0);
                #endif

                //MapCat
                half NdotL = dot(worldNormal,light_dir);
                half lambert_term = saturate(NdotL);
                half half_lambert = NdotL * 0.5 + 0.5;

                half2 uv_mapcat = (viewNormal.xy + 0.5) * 0.5;
                fixed3 mapcat_c = tex2D(_MapCatTex,uv_mapcat) * _MapCatIntensity;
                fixed3 mapcatadd_c = tex2D(_MapCatAddTex,uv_mapcat) * _MapCatAddIntensity;

                //Dir DIFFUSE
                #if DirDiffuse_ON
                fixed3 final_diffuse = col.rgb *_DiffuseColor.rgb * half_lambert * _LightColor0.rgb;
                //fixed3 final_diffuse = col.rgb * half_lambert * _LightColor0.rgb;
                #else
                fixed3 final_diffuse = fixed3(0,0,0);
                #endif

                #if MapCatSpec_ON
                fixed3 final_mapcat = (mapcat_c + mapcatadd_c) * lambert_term;
                #else
                fixed3 final_mapcat = fixed3(0,0,0);
                #endif

                fixed3 finalC = final_mapcat + final_diffuse + direct_spe;

                finalC = pow(finalC,1.0/2.2);

                return fixed4(finalC,1.0);
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
                
                return float4(outlineColor, 1.0);
            }
            ENDCG
        }
    }
}
