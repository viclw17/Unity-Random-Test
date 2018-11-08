Shader "Stencils/Test2" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
		SubShader{
		//Subsequent draw calls can test against the value, to decide if a pixel should be discarded before running the pixel shader

		//ColorMask 0
		Stencil {
		//The value to be compared against (if Comp is anything else than always) 
		//and/or the value to be written to the buffer (if either Pass, Fail or ZFail is set to replace). 0–255 integer.
		Ref 1
		//The function used to compare the reference value to the current contents of the buffer. Default: always.
		Comp notequal
		//What to do with the contents of the buffer if the stencil test (and the depth test) passes. Default: keep.
		Pass keep
		//What to do with the contents of the buffer if the stencil test fails. Default: keep.
		Fail keep
		//What to do with the contents of the buffer if the stencil test passes, but the depth test fails. Default: keep.
		ZFail keep
		}

		Tags { "RenderType"="Opaque"}
		LOD 200

		// Vert frag shader
		Pass {
			ZWrite off


			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}


		/*
		CGPROGRAM
		#pragma surface surf Lambert

		sampler2D _MainTex;
		fixed4 _Color;

		struct Input {
		float2 uv_MainTex;
		};

		void surf(Input IN, inout SurfaceOutput o) {
		fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
		o.Albedo = c.rgb;
		o.Alpha = c.a;
		}
		ENDCG
		*/
		

		/* // Custom lighting model
		#pragma surface surf SimpleLambert
		half4 LightingSimpleLambert(SurfaceOutput s, half3 lightDir, half atten) {
		half NdotL = dot(s.Normal, lightDir);
		half4 c;
		c.rgb = s.Albedo * _LightColor0.rgb * (NdotL * atten);
		c.a = s.Alpha;
		return c;
		}	*/
	}
	//Fallback "Diffuse"
}
