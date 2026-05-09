Shader "Custom/TerrainVertexPaint"
{
    Properties
    {
        [Header(Surface Options)]
        _UVScale ("UV Scale", Float) = 0.2

        [Header(Set A)]
        _AlbedoA ("A - Albedo", 2D) = "white" {}
        _NormalA ("A - Normal", 2D) = "bump" {}
        _MAOHSA ("A - MAOHS", 2D) = "white" {}

        [Header(Set B)]
        _AlbedoB ("B - Albedo", 2D) = "white" {}
        _NormalB ("B - Normal", 2D) = "bump" {}
        _MAOHSB ("B - MAOHS", 2D) = "white" {}

        [Header(Snow)]
        _SnowAlbedo ("Snow Albedo", 2D) = "white" {}
        _SnowNormal ("Snow Normal", 2D) = "bump" {}
        _SnowMAOHS ("Snow MAOHS", 2D) = "white" {}

        [Header(Blend)]
        _NoiseTex ("Noise Texture", 2D) = "gray" {}
        _NoiseScale ("Noise Scale", Float) = 1.0
        _BlendDistance ("Blend Distance", Range(0.01, 1.0)) = 0.2

        [Header(Snow Settings)]
        _SnowMetallic ("Snow Metallic", Range(0,1)) = 0.0
        _SnowSmoothness ("Snow Smoothness", Range(0,1)) = 0.2
        _SnowAO ("Snow AO", Range(0,1)) = 1.0

        [Header(Displacement)]
        _VerticalDisplacement ("Vertical Displacement", Float) = 0.2
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 3.0

        sampler2D _AlbedoA;
        sampler2D _NormalA;
        sampler2D _MAOHSA;

        sampler2D _AlbedoB;
        sampler2D _NormalB;
        sampler2D _MAOHSB;

        sampler2D _SnowAlbedo;
        sampler2D _SnowNormal;
        sampler2D _SnowMAOHS;

        sampler2D _NoiseTex;

        half _UVScale;
        half _NoiseScale;
        half _BlendDistance;

        half _SnowMetallic;
        half _SnowSmoothness;
        half _SnowAO;

        half _VerticalDisplacement;

        struct Input
        {
            float2 uv_AlbedoA;
            float4 color : COLOR;
        };

        void vert (inout appdata_full v)
        {
            // Canal azul del vertex color = displacement vertical
            float displacementMask = saturate(v.color.b);
            v.vertex.y += displacementMask * _VerticalDisplacement;
        }

        half GetBlendValue(half vertexMask, half noiseValue, half blendDistance)
        {
            half centeredNoise = noiseValue - 0.5h;
            half blend = vertexMask + centeredNoise * blendDistance;
            return saturate(blend);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 uv = IN.uv_AlbedoA * _UVScale;

            // Noise para romper la transición
            half noise = tex2D(_NoiseTex, uv * _NoiseScale).r;

            // Canal rojo: mezcla entre A y B
            half abBlend = GetBlendValue(IN.color.r, noise, _BlendDistance);

            fixed4 albedoA = tex2D(_AlbedoA, uv);
            fixed4 albedoB = tex2D(_AlbedoB, uv);

            half3 normalA = UnpackNormal(tex2D(_NormalA, uv));
            half3 normalB = UnpackNormal(tex2D(_NormalB, uv));

            fixed4 maohsA = tex2D(_MAOHSA, uv);
            fixed4 maohsB = tex2D(_MAOHSB, uv);

            fixed3 baseAlbedo = lerp(albedoA.rgb, albedoB.rgb, abBlend);
            half3 baseNormal = normalize(lerp(normalA, normalB, abBlend));
            fixed4 baseMAOHS = lerp(maohsA, maohsB, abBlend);

            // Canal verde: mezcla con nieve
            half snowBlend = saturate(IN.color.g);

            fixed4 snowAlbedo = tex2D(_SnowAlbedo, uv);
            half3 snowNormal = UnpackNormal(tex2D(_SnowNormal, uv));
            fixed4 snowMAOHS = tex2D(_SnowMAOHS, uv);

            fixed3 finalAlbedo = lerp(baseAlbedo, snowAlbedo.rgb, snowBlend);
            half3 finalNormal = normalize(lerp(baseNormal, snowNormal, snowBlend));
            fixed4 finalMAOHS = lerp(baseMAOHS, snowMAOHS, snowBlend);

            // MAOHS:
            // R = Metallic
            // G = Ambient Occlusion
            // B = Height
            // A = Smoothness
            o.Albedo = finalAlbedo;
            o.Normal = finalNormal;
            o.Metallic = lerp(finalMAOHS.r, _SnowMetallic, snowBlend);
            o.Occlusion = lerp(finalMAOHS.g, _SnowAO, snowBlend);
            o.Smoothness = lerp(finalMAOHS.a, _SnowSmoothness, snowBlend);
            o.Alpha = 1;
        }
        ENDCG
    }

    FallBack "Standard"
}