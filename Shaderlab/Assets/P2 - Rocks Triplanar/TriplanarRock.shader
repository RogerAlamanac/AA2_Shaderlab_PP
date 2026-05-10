Shader "Custom/TriplanarRock"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Smoothness ("Smoothness", Range(0,1)) = 0.5
        _TriplanarScale ("Triplanar Scale", Float) = 1.0
        _BlendSharpness ("Blend Sharpness", Range(1,16)) = 4.0

        [Toggle(_TRIPLANAR_LOCAL)] _UseLocalSpace ("Use Local Space Triplanar", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 3.0
        #pragma multi_compile __ _TRIPLANAR_LOCAL

        sampler2D _MainTex;
        half _Metallic;
        half _Smoothness;
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

        float3 SampleTriplanar(float3 pos, float3 weights)
        {
            float2 uvX = pos.yz * _TriplanarScale;
            float2 uvY = pos.xz * _TriplanarScale;
            float2 uvZ = pos.xy * _TriplanarScale;

            float3 x = tex2D(_MainTex, uvX).rgb;
            float3 y = tex2D(_MainTex, uvY).rgb;
            float3 z = tex2D(_MainTex, uvZ).rgb;

            return x * weights.x + y * weights.y + z * weights.z;
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
            float3 albedo = SampleTriplanar(samplePos, weights);

            o.Albedo = albedo;
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;
            o.Alpha = 1.0;
        }
        ENDCG
    }

    FallBack "Diffuse"
}