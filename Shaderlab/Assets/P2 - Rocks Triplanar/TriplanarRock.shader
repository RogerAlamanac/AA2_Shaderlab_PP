Shader "Custom/TriplanarRock"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _NormalTex ("Normal", 2D) = "bump" {}
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Smoothness ("Smoothness", Range(0,1)) = 0.5

        _TriplanarScale ("Triplanar Scale", Float) = 1.0
        _BlendSharpness ("Blend Sharpness", Range(1,16)) = 4.0

        [Toggle(_TRIPLANAR_LOCAL)] _UseLocalSpace ("Use Local Space Triplanar", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 3.0
        #pragma multi_compile __ _TRIPLANAR_LOCAL

        sampler2D _MainTex;
        sampler2D _NormalTex;

        half _Metallic;
        half _Smoothness;
        float _TriplanarScale;
        float _BlendSharpness;

        struct Input
        {
            float3 localPos;
            float3 localNormal;
            float3 worldPosCustom;
            float3 worldNormalCustom;
        };

        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            o.localPos = v.vertex.xyz;
            o.localNormal = normalize(v.normal);

            o.worldPosCustom = mul(unity_ObjectToWorld, v.vertex).xyz;
            o.worldNormalCustom = normalize(UnityObjectToWorldNormal(v.normal));
        }

        float3 GetTriplanarWeights(float3 n, float sharpness)
        {
            float3 w = abs(n);
            w = pow(w, sharpness);
            return w / max(w.x + w.y + w.z, 0.0001);
        }

        float3 SampleTriplanarAlbedo(float3 pos, float3 weights)
        {
            float2 uvX = pos.yz * _TriplanarScale;
            float2 uvY = pos.xz * _TriplanarScale;
            float2 uvZ = pos.xy * _TriplanarScale;

            float3 colX = tex2D(_MainTex, uvX).rgb;
            float3 colY = tex2D(_MainTex, uvY).rgb;
            float3 colZ = tex2D(_MainTex, uvZ).rgb;

            return colX * weights.x + colY * weights.y + colZ * weights.z;
        }

        float3 SampleTriplanarNormal(float3 pos, float3 weights)
        {
            float2 uvX = pos.yz * _TriplanarScale;
            float2 uvY = pos.xz * _TriplanarScale;
            float2 uvZ = pos.xy * _TriplanarScale;

            float3 nX = UnpackNormal(tex2D(_NormalTex, uvX));
            float3 nY = UnpackNormal(tex2D(_NormalTex, uvY));
            float3 nZ = UnpackNormal(tex2D(_NormalTex, uvZ));

            // Aproximación simple
            float3 mappedX = float3(0.0, nX.x, nX.y);
            float3 mappedY = float3(nY.x, 0.0, nY.y);
            float3 mappedZ = float3(nZ.x, nZ.y, 0.0);

            float3 blended = mappedX * weights.x + mappedY * weights.y + mappedZ * weights.z;
            return normalize(blended);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float3 samplePos;
            float3 sampleNormal;

            #ifdef _TRIPLANAR_LOCAL
                samplePos = IN.localPos;
                sampleNormal = normalize(IN.localNormal);
            #else
                samplePos = IN.worldPosCustom;
                sampleNormal = normalize(IN.worldNormalCustom);
            #endif

            float3 weights = GetTriplanarWeights(sampleNormal, _BlendSharpness);

            float3 albedo = SampleTriplanarAlbedo(samplePos, weights);
            float3 normal = SampleTriplanarNormal(samplePos, weights);

            o.Albedo = albedo;
            o.Normal = normal;
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;
            o.Alpha = 1.0;
        }
        ENDCG
    }

    FallBack "Diffuse"
}