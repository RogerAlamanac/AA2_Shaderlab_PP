Shader "Custom/TriplanarRock"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _NormalTex ("Normal", 2D) = "bump" {}
        _MaskTex ("Mask (R=Metallic, G=AO, A=Smoothness)", 2D) = "white" {}

        _MetallicMultiplier ("Metallic Multiplier", Range(0,1)) = 1.0
        _SmoothnessMultiplier ("Smoothness Multiplier", Range(0,1)) = 1.0
        _OcclusionMultiplier ("Occlusion Multiplier", Range(0,1)) = 1.0

        _NormalStrength ("Normal Strength", Range(0,2)) = 1.0

        _TriplanarScale ("Triplanar Scale", Float) = 0.15
        _BlendSharpness ("Blend Sharpness", Range(1,16)) = 4.0

        [Toggle(_TRIPLANAR_LOCAL)] _UseLocalSpace ("Use Local Space Triplanar", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 250

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 3.0
        #pragma multi_compile __ _TRIPLANAR_LOCAL

        sampler2D _MainTex;
        sampler2D _NormalTex;
        sampler2D _MaskTex;

        half _MetallicMultiplier;
        half _SmoothnessMultiplier;
        half _OcclusionMultiplier;
        half _NormalStrength;

        float _TriplanarScale;
        float _BlendSharpness;

        struct Input
        {
            float3 localPos;
            float3 worldPos;
            float3 normalDir;
        };

        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            o.localPos = v.vertex.xyz;
            o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            o.normalDir = normalize(v.normal);
        }

        float3 GetTriplanarWeights(float3 n)
        {
            float3 w = abs(n);
            w = pow(w, _BlendSharpness);
            return w / max(w.x + w.y + w.z, 0.0001);
        }

        float4 SampleTriplanarTexture(sampler2D tex, float3 pos, float3 weights)
        {
            float2 uvX = pos.yz * _TriplanarScale;
            float2 uvY = pos.xz * _TriplanarScale;
            float2 uvZ = pos.xy * _TriplanarScale;

            float4 x = tex2D(tex, uvX);
            float4 y = tex2D(tex, uvY);
            float4 z = tex2D(tex, uvZ);

            return x * weights.x + y * weights.y + z * weights.z;
        }

        float3 SampleTriplanarNormal(float3 pos, float3 weights)
        {
            float2 uvX = pos.yz * _TriplanarScale;
            float2 uvY = pos.xz * _TriplanarScale;
            float2 uvZ = pos.xy * _TriplanarScale;

            float3 nX = UnpackNormal(tex2D(_NormalTex, uvX));
            float3 nY = UnpackNormal(tex2D(_NormalTex, uvY));
            float3 nZ = UnpackNormal(tex2D(_NormalTex, uvZ));

            nX.xy *= _NormalStrength;
            nY.xy *= _NormalStrength;
            nZ.xy *= _NormalStrength;

            // Reorientación simple por eje
            float3 worldNX = float3(nX.z, nX.y, nX.x);
            float3 worldNY = float3(nY.x, nY.z, nY.y);
            float3 worldNZ = float3(nZ.x, nZ.y, nZ.z);

            float3 blended = worldNX * weights.x + worldNY * weights.y + worldNZ * weights.z;
            return normalize(blended);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float3 samplePos;

            #ifdef _TRIPLANAR_LOCAL
                samplePos = IN.localPos;
            #else
                samplePos = IN.worldPos;
            #endif

            float3 weights = GetTriplanarWeights(normalize(IN.normalDir));

            float4 albedoSample = SampleTriplanarTexture(_MainTex, samplePos, weights);
            float4 maskSample = SampleTriplanarTexture(_MaskTex, samplePos, weights);
            float3 normalSample = SampleTriplanarNormal(samplePos, weights);

            o.Albedo = albedoSample.rgb;
            o.Normal = normalSample;
            o.Metallic = maskSample.r * _MetallicMultiplier;
            o.Occlusion = maskSample.g * _OcclusionMultiplier;
            o.Smoothness = maskSample.a * _SmoothnessMultiplier;
            o.Alpha = 1.0;
        }
        ENDCG
    }

    FallBack "Diffuse"
}