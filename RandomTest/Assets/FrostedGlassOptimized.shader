Shader "Unlit/FrostedGlass"
{
    Properties
    {
        _Radius("Radius", Range(1, 255)) = 100
        _IterationScale("IterationScale", Range(0.1, 128)) = 0.1

    }
 
    Category
    {
        Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Opaque" }
     
        SubShader
        {
            GrabPass
            {
            }
 
            Pass
            {  
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
 
                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 texcoord: TEXCOORD0;
                };
 
                struct v2f
                {
                    float4 vertex : POSITION;
                    float4 uvgrab : TEXCOORD0;
                };
 
                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);

                    #if UNITY_UV_STARTS_AT_TOP
                    float scale = -1.0;
                    #else
                    float scale = 1.0;
                    #endif

                    o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y*scale) + o.vertex.w) * 0.5;
                    o.uvgrab.zw = o.vertex.zw;
                    return o;
                }
 
                sampler2D _GrabTexture;
                float4 _GrabTexture_TexelSize;
                float _Radius;
                float _IterationScale;
 
                half4 frag(v2f i) : SV_Target
                {
                    half4 sum = half4(0,0,0,0);

                    int measurments = 0;
 
                    for (float range = 0.1; range <= _Radius; range += _IterationScale)
                    {
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * range, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * range, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * range, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * -range, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * -range, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * range, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * -range, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * -range, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));

                        measurments += 4;
                    }

                    /* 
                    // If render in one pass...
                    float radius = 1.41421356237 * _Radius;

                    for (float range = 1.41421356237f*0.1f; range <= radius * 1.41; range += 1.41421356237f*_IterationScale)
                    {
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * range, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * 0, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * -range, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * -0, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * 0, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * range, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * 0, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * -range, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));

                        measurments += 4;
                    }                  
                    */
 
                    return sum / measurments;
                }
                ENDCG
            }
                     
            GrabPass
            {
            }
 
            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma fragmentoption ARB_precision_hint_fastest
                #include "UnityCG.cginc"
 
                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 texcoord: TEXCOORD0;
                };
 
                struct v2f
                {
                    float4 vertex : POSITION;
                    float4 uvgrab : TEXCOORD0;
                };
 
                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                    #if UNITY_UV_STARTS_AT_TOP
                    float scale = -1.0;
                    #else
                    float scale = 1.0;
                    #endif
                    o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y*scale) + o.vertex.w) * 0.5;
                    o.uvgrab.zw = o.vertex.zw;
                    return o;
                }
 
                sampler2D _GrabTexture;
                float4 _GrabTexture_TexelSize;
                float _Radius;
                float _IterationScale;
 
                half4 frag(v2f i) : SV_Target
                {
 
                    half4 sum = half4(0,0,0,0);
                    float radius = 1.41421356237 * _Radius;               

                    int measurments = 0;
 
                    for (float range = 1.41421356237f * 0.1f; range <= radius * 1.41; range += 1.41421356237f * _IterationScale)
                    {
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * range, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * 0, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * -range, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * -0, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * 0, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * range, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));
                        sum += tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(
                        i.uvgrab.x + _GrabTexture_TexelSize.x * 0, 
                        i.uvgrab.y + _GrabTexture_TexelSize.y * -range, 
                        i.uvgrab.z, 
                        i.uvgrab.w)));

                        measurments += 4;
                    }
 
                    return sum / measurments;
                }
                ENDCG
            }
        }
    }
}