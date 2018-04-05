﻿Shader "Unlit/DepthRender"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
			#include "UnityCG.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 screenPos : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{

				i.screenPos.xy /= i.screenPos.w;

				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy);
				depth = Linear01Depth(depth);
				depth = 1.0 - depth;
				return float4(depth, depth, depth, depth);
			}
			ENDCG
		}
	}
			FallBack "VertexLit"
}