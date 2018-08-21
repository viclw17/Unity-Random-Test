// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Victor/Awesome Water" {
	Properties{
		_SpeedX("Wave Speed X", Range(-0.1, 0.1)) = 0.01
	    _SpeedZ("Wave Speed Z", Range(-0.1, 0.1)) = 0.01
		_Cube("Reflection Map", Cube) = "" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
	    _NormalStrength("Normal Strength", Range(-5, 5)) = 0.5
		_Color("Diffuse Material Color", Color) = (1,1,1,1)
		_SpecColor("Specular Material Color", Color) = (1,1,1,1)
		_Shininess("Shininess", Range(0, 5000)) = 10

		_Refraction ("Refraction", Range (0.00, 100.0)) = 1.0
		_DistortTex ("Base (RGB)", 2D) = "white" {}
	}




		CGINCLUDE // common code for all passes of all subshaders

		#include "UnityCG.cginc"
		uniform float4 _LightColor0;
		// color of light source (from "Lighting.cginc")

		// User-specified properties
		uniform samplerCUBE _Cube;

		uniform sampler2D _BumpMap;
		uniform float4 _BumpMap_ST;

		uniform float4 _Color;
		uniform float4 _SpecColor;
		uniform float _Shininess;

		uniform float _NormalStrength;

		uniform float _SpeedX;
		uniform float _SpeedZ;

		sampler2D _GrabTexture;
		sampler2D _DistortTex;
		float _Refraction;
		float4 _GrabTexture_TexelSize;

		struct vertexInput {
			float4 vertex : POSITION;
			float4 texcoord : TEXCOORD0;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
//			float2 uv_DistortTex : TEXCOORD1;
//			float3 worldRefl; 
//			float4 screenPos;

		};

		struct vertexOutput {
			float4 pos : SV_POSITION;
			float4 posWorld : TEXCOORD0;
			// position of the vertex (and fragment) in world space
			float4 tex 		     : TEXCOORD1;
			float3 tangentWorld  : TEXCOORD2;
			float3 normalWorld   : TEXCOORD3;
			float3 binormalWorld : TEXCOORD4;
			float4 screenPos : TEXCOORD5;
		};

		vertexOutput vert(vertexInput input)
		{
			vertexOutput output;

			float4x4 modelMatrix = unity_ObjectToWorld;
			float4x4 modelMatrixInverse = unity_WorldToObject;

			output.tangentWorld = normalize(mul(modelMatrix, float4(input.tangent.xyz, 0.0)).xyz);
			output.normalWorld = normalize(mul(float4(input.normal, 0.0), modelMatrixInverse).xyz);
			output.binormalWorld = normalize(cross(output.normalWorld, output.tangentWorld)* input.tangent.w);// tangent.w is specific to Unity

			output.tex = input.texcoord;
			output.tex += float4(_Time.y * _SpeedX, _Time.y* _SpeedZ,0,0);
			output.posWorld = mul(modelMatrix, input.vertex);
			output.pos = UnityObjectToClipPos(input.vertex);
			output.screenPos = ComputeScreenPos(output.pos);
			return output;
		}



















		// fragment shader with ambient lighting
		float4 fragWithAmbient(vertexOutput input) : COLOR
		{
			// in principle we have to normalize tangentWorld,
			// binormalWorld, and normalWorld again; however, the
			// potential problems are small since we use this
			// matrix only to compute "normalDirection",
			// which we normalize anyways

		float4 encodedNormal = tex2D(_BumpMap, _BumpMap_ST.xy * input.tex.xy + _BumpMap_ST.zw);
		// sample the normal map
		float3 localCoords = float3(2.0 * encodedNormal.a - 1.0, 2.0 * encodedNormal.g - 1.0, 0.0)*_NormalStrength;
		localCoords.z = sqrt(1.0 - dot(localCoords, localCoords));
		// approximation without sqrt:  localCoords.z =
		// 1.0 - 0.5 * dot(localCoords, localCoords);

		float3x3 local2WorldTranspose = float3x3(
			input.tangentWorld,
			input.binormalWorld,
			input.normalWorld);

		float3 normalDirection =normalize(mul(localCoords, local2WorldTranspose));
		float3 viewDirection = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
		float3 lightDirection;
		float attenuation;

		/*
		if (0.0 == _WorldSpaceLightPos0.w) // directional light?
		{
			attenuation = 1.0; // no attenuation
			lightDirection = normalize(_WorldSpaceLightPos0.xyz);
		}
		else // point or spot light
		{
			float3 vertexToLightSource =_WorldSpaceLightPos0.xyz - input.posWorld.xyz;
			float distance = length(vertexToLightSource);
			attenuation = 1.0 / distance; // linear attenuation
			lightDirection = normalize(vertexToLightSource);
		}
		*/


		// optimization
		float3 vertexToLightSource =_WorldSpaceLightPos0.xyz - input.posWorld.xyz * _WorldSpaceLightPos0.w;
		float one_over_distance =1.0 / length(vertexToLightSource);
		attenuation =lerp(1.0, one_over_distance, _WorldSpaceLightPos0.w);
		lightDirection =vertexToLightSource * one_over_distance;


		float3 ambientLighting =UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;

		float3 diffuseReflection =attenuation * _LightColor0.rgb * _Color.rgb* max(0.0, dot(normalDirection, lightDirection));



		float3 specularReflection;
//		if (dot(normalDirection, lightDirection) < 0.0)
//			// light source on the wrong side?
//		{
//			specularReflection = float3(0.0, 0.0, 0.0);
//			// no specular reflection
//		}
//		else // light source on the right side
//		{
			specularReflection = 
			attenuation * 
			_LightColor0.rgb* 
			_SpecColor.rgb * pow(max(0.0, dot(reflect(-lightDirection, normalDirection),viewDirection)), _Shininess);
//		}

		// reflection
		float3 reflectedDir = reflect(viewDirection, normalDirection);
        float4 reflection = texCUBE(_Cube, reflectedDir);

        // refraction
		// Fresnel 1
        float fresnelTerm = dot(viewDirection, normalDirection);
        fresnelTerm = 1 - fresnelTerm*1.3;
        // Fresnel 2
//	            float fangle = 1 + dot(viewDirection, normalDirection);
//	            fangle = pow (fangle,5);
//	            fresnelTerm = 1/fangle;
        // Fresnel 3
//	            fresnelTerm = 0.02 + 0.97 * pow ((1-dot(viewDirection, normalDirection)),5);

		float4 final = float4(
			ambientLighting +
			diffuseReflection	+
			specularReflection,
			1);

		final = final * (1-fresnelTerm) + reflection * clamp(fresnelTerm, 0, 1); // clamp!


		float3 distort = tex2D(_DistortTex, input.tex.xy);// * input.color.rgb;
	    float2 _offset = distort * _Refraction * _GrabTexture_TexelSize.xy;
//		input.screenPos.xy = _offset * input.screenPos.z + input.screenPos.xy;	
		input.screenPos.xy = _offset + input.screenPos.xy;	
		float4 refrColor = tex2Dproj(_GrabTexture, input.screenPos);



		return refrColor * final;//float4(final.xyz * refrColor.rgb,_Color.a);
		}











		// fragment shader for pass 2 without ambient lighting
		float4 fragWithoutAmbient(vertexOutput input) : COLOR
		{
			// in principle we have to normalize tangentWorld,
			// binormalWorld, and normalWorld again; however, the
			// potential problems are small since we use this
			// matrix only to compute "normalDirection",
			// which we normalize anyways

		float4 encodedNormal = tex2D(_BumpMap,_BumpMap_ST.xy * input.tex.xy + _BumpMap_ST.zw);
		float3 localCoords = float3(2.0 * encodedNormal.a - 1.0,2.0 * encodedNormal.g - 1.0, 0.0)*_NormalStrength;
		localCoords.z = sqrt(1.0 - dot(localCoords, localCoords));
		// approximation without sqrt:  localCoords.z =
		// 1.0 - 0.5 * dot(localCoords, localCoords);

		float3x3 local2WorldTranspose = float3x3(
			input.tangentWorld,
			input.binormalWorld,
			input.normalWorld);

		float3 normalDirection =normalize(mul(localCoords, local2WorldTranspose));
		float3 viewDirection = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
		float3 lightDirection;
		float attenuation;

		/*
		if (0.0 == _WorldSpaceLightPos0.w) // directional light?
		{
			attenuation = 1.0; // no attenuation
			lightDirection = normalize(_WorldSpaceLightPos0.xyz);
		}
		else // point or spot light
		{
			float3 vertexToLightSource =_WorldSpaceLightPos0.xyz - input.posWorld.xyz;
			float distance = length(vertexToLightSource);
			attenuation = 1.0 / distance; // linear attenuation
			lightDirection = normalize(vertexToLightSource);
		}
		*/

		// optimization
		float3 vertexToLightSource =_WorldSpaceLightPos0.xyz - input.posWorld.xyz * _WorldSpaceLightPos0.w;
		float one_over_distance =1.0 / length(vertexToLightSource);
		attenuation =lerp(1.0, one_over_distance, _WorldSpaceLightPos0.w);
		lightDirection =vertexToLightSource * one_over_distance;

		float3 diffuseReflection =attenuation * _LightColor0.rgb * _Color.rgb* max(0.0, dot(normalDirection, lightDirection));

		float3 specularReflection;
//		if (dot(normalDirection, lightDirection) < 0.0)
//			// light source on the wrong side?
//		{
//			specularReflection = float3(0.0, 0.0, 0.0);
//			// no specular reflection
//		}
//		else // light source on the right side
//		{
			specularReflection = 
			attenuation * 
			_LightColor0.rgb* 
			_SpecColor.rgb * 
			pow(max(0.0, dot(reflect(-lightDirection, normalDirection),viewDirection)), _Shininess);
//		}

		// reflection
		float3 reflectedDir = reflect(viewDirection, normalDirection);
        float4 reflection = texCUBE(_Cube, reflectedDir);

        // refraction
		// Fresnel 1
        float fresnelTerm = dot(viewDirection, normalDirection);
        fresnelTerm = 1 - fresnelTerm*1.3;
        // Fresnel 2
//	            float fangle = 1 + dot(viewDirection, normalDirection);
//	            fangle = pow (fangle,5);
//	            fresnelTerm = 1/fangle;
        // Fresnel 3
//	            fresnelTerm = 0.02 + 0.97 * pow ((1-dot(viewDirection, normalDirection)),5);

		float4 final = float4(
			diffuseReflection	+
			specularReflection,
			1);

		final = final * (1-fresnelTerm) + reflection * clamp(fresnelTerm, 0, 1); // clamp!

		float3 distort = tex2D(_DistortTex, input.tex.xy);// * input.color.rgb;
	    float2 _offset = distort * _Refraction * _GrabTexture_TexelSize.xy;
//		input.screenPos.xy = _offset * input.screenPos.z + input.screenPos.xy;	
		input.screenPos.xy = _offset + input.screenPos.xy;	
		float4 refrColor = tex2Dproj(_GrabTexture, input.screenPos);

		return refrColor * final;//float4(final.xyz,_Color.a) * refrColor; 

		}
	    ENDCG	






		SubShader {

		Tags{ "Queue"="Transparent"}

		Blend SrcAlpha OneMinusSrcAlpha
//		Blend One One
//		Blend DstColor Zero // Multiplicative
//		Blend OneMinusDstColor One // Soft Additive

			GrabPass 
				{ 
					
				}

			Pass{
				Tags{ "LightMode" = "ForwardBase" }
				// pass for ambient light and first light source

				CGPROGRAM
				//#pragma exclude_renderers gles
				#pragma vertex vert
				#pragma fragment fragWithAmbient
				// the functions are defined in the CGINCLUDE part
				ENDCG
				}

			Pass{
				Tags{ "LightMode" = "ForwardAdd" }
				// pass for additional light sources
				Blend One One // additive blending

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment fragWithoutAmbient
				// the functions are defined in the CGINCLUDE part
				ENDCG
				}
			}
}
