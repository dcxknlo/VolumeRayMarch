// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
Shader "Custom/VMarch"
{
	Properties
	{
		_NoiseTex3D("3d texture", 3D) = "" {}
		_NumSamples("Number of Samples", int) = 128
		_NumLightSamples("Number of Light Samples", int) = 32
		_CuttingPos("Cutting Plane Position", vector) = (0,0,0,0)
		_CuttingDir("Cutting Plane Forward Direction", vector) = (0,0,0,0)
		_MinVoxelValue("Minimum Value for Contribution", float) = 0.1
		_Absorption("Absorption", float) = 5.6
		_DensityFactor("Density", float) = 3.0
		_Color("Color", Color) = (1,1,1,1)
		_SpecularColor ("Specular Material Color", Color) = (1,1,1,1) 
		_SpecPower ("Specular Power", Float) = 10

		_MinX("minX", Range(0,1)) = 0.0
		_MaxX("maxX", Range(0,1)) = 1.0
		_MinY("minY", Range(0,1)) = 0.0
		_MaxY("maxY", Range(0,1)) = 1.0
		_MinZ("minZ", Range(0,1)) = 0.0
		_MaxZ("maxZ", Range(0,1)) = 1.0

	}

		SubShader
		{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		
		LOD 100
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha  // remove this and set queue to opaque to write to depth buffer
			Lighting Off
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragSurfaceShade
			#include "UnityCG.cginc"
			#include "VolumeInc.cginc"
			ENDCG
		}
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha 
			Lighting Off
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragAbsorption
			#include "UnityCG.cginc"
			#include "VolumeInc.cginc"
			ENDCG
		}
		Pass
		{
		Tags{"LightMode" = "ForwardBase"}
			Blend SrcAlpha OneMinusSrcAlpha  
			Lighting Off
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragTest
			#include "UnityCG.cginc"
			#include "VolumeInc.cginc"
			ENDCG
		}
	

	}
	FallBack "VertexLit"
}