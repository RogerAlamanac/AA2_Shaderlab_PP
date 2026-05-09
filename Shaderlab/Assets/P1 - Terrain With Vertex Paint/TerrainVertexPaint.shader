Shader "Custom/TerrainVertexPaint"
{
    Properties
    {
        [Header(Shared)]
        _UVScale ("UV Scale", Float) = 1.0

        [Header(Layer A)]
        _ColorA ("A Color", Color) = (1,1,1,1)
        _MainTexA ("A Albedo", 2D) = "white" {}
        _GlossinessA ("A Smoothness", Range(0,1)) = 0.5
        _MetallicA ("A Metallic", Range(0,1)) = 0.0

        [Header(Layer B)]
        _ColorB ("B Color", Color) = (1,1,1,1)
        _MainTexB ("B Albedo", 2D) = "white" {}
        _GlossinessB ("B Smoothness", Range(0,1)) = 0.5
        _MetallicB ("B Metallic", Range(0,1)) = 0.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTexA;
        sampler2D _MainTexB;

        struct Input
        {
            float2 uv_MainTexA;
        };

        half _UVScale;

        half _GlossinessA;
        half _MetallicA;
        fixed4 _ColorA;

        half _GlossinessB;
        half _MetallicB;
        fixed4 _ColorB;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 uv = IN.uv_MainTexA * _UVScale;

            fixed4 colA = tex2D(_MainTexA, uv) * _ColorA;
            fixed4 colB = tex2D(_MainTexB, uv) * _ColorB;

            // De momento mezclamos al 50% solo para comprobar que funciona
            half blend = 0.5;

            fixed4 finalCol = lerp(colA, colB, blend);

            o.Albedo = finalCol.rgb;
            o.Metallic = lerp(_MetallicA, _MetallicB, blend);
            o.Smoothness = lerp(_GlossinessA, _GlossinessB, blend);
            o.Alpha = finalCol.a;
        }
        ENDCG
    }

    FallBack "Diffuse"
}