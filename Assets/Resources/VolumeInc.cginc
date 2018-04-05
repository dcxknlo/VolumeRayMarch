	
	#include "Lighting.cginc"

	uniform sampler3D _NoiseTex3D;
	uniform int _NumSamples;
	uniform int _NumLightSamples;
	uniform vector _LightPos;
	uniform vector _CuttingPos;
	uniform vector _CuttingDir;
	uniform float4x4 _ObjectToWorld;
	uniform float _MinVoxelValue;
	uniform float _Absorption;
	uniform float _DensityFactor;
	uniform vector _Color;
	uniform vector _SpecularColor;
	uniform float _SpecPower;
	uniform int _FrameIndex;
	float _MinX, _MaxX, _MinY, _MaxY, _MinZ, _MaxZ;

	uniform sampler2D _CameraDepthTexture;

	float3 hash( float3 p ) 
	{
	p = float3( dot(p,float3(127.1,311.7, 74.7)),
			  dot(p,float3(269.5,183.3,246.1)),
			  dot(p,float3(113.5,271.9,124.6)));

	return -1.0 + 2.0*frac(sin(p)*43758.5453123);
	}

	float noise( in float3 x)
	{
		// grid
		float3 p = floor(x);
		float3 w = frac(x);
    
		// quintic interpolant
		float3 u = w*w*w*(w*(w*6.0-15.0)+10.0);

    
		// gradients
		float3 ga = hash( p+float3(0.0,0.0,0.0) );
		float3 gb = hash( p+float3(1.0,0.0,0.0) );
		float3 gc = hash( p+float3(0.0,1.0,0.0) );
		float3 gd = hash( p+float3(1.0,1.0,0.0) );
		float3 ge = hash( p+float3(0.0,0.0,1.0) );
		float3 gf = hash( p+float3(1.0,0.0,1.0) );
		float3 gg = hash( p+float3(0.0,1.0,1.0) );
		float3 gh = hash( p+float3(1.0,1.0,1.0) );
    
		// projections
		float va = dot( ga, w-float3(0.0,0.0,0.0) );
		float vb = dot( gb, w-float3(1.0,0.0,0.0) );
		float vc = dot( gc, w-float3(0.0,1.0,0.0) );
		float vd = dot( gd, w-float3(1.0,1.0,0.0) );
		float ve = dot( ge, w-float3(0.0,0.0,1.0) );
		float vf = dot( gf, w-float3(1.0,0.0,1.0) );
		float vg = dot( gg, w-float3(0.0,1.0,1.0) );
		float vh = dot( gh, w-float3(1.0,1.0,1.0) );
	
		// interpolation
		return va + 
			   u.x*(vb-va) + 
			   u.y*(vc-va) + 
			   u.z*(ve-va) + 
			   u.x*u.y*(va-vb-vc+vd) + 
			   u.y*u.z*(va-vc-ve+vg) + 
			   u.z*u.x*(va-vb-ve+vf) + 
			   u.x*u.y*u.z*(-va+vb+vc-vd+ve-vf-vg+vh);
	}

	float fbm( in float3 x, int octaves )
	{
		float f = 1.99;
		float s = 0.5;
		float a = 0.1;
		float b = 0.5;


		const float3x3 m3  = float3x3( 0.00,  0.80,  0.60,
						  -0.80,  0.36, -0.48,
						  -0.60, -0.48,  0.64 );

		for( int i=0; i<octaves; i++ )
		{
			float n = noise(x);
			a += b*n;
			b *= s;
			x = mul(f*m3, x);
		}
		return a;
	}

	struct Ray
	{
		float3 from;
		float3 dir;
		float tmax;
	};


	struct appData
	{
		float4 vertex : POSITION;	
	};
	struct v2f
	{
		float4 vertex :SV_POSITION;
		float3 localPos : TEXCOORD0;
		float3 worldPos : TEXCOORD1;
		float4 screenPos : TEXCOORD2;
		float3 rayPers : TEXCOORD3;
		float4 basePos : TEXCOORD4;
	};


	void RayBoxIntersection (inout Ray ray)
	{
     float3 invDir = 1.0 / ray.dir;
     float3 t1 = (- 0.5 - ray.from) * invDir;
     float3 t2 = (+ 0.5 - ray.from) * invDir;

     float3 tmax3 = max (t1, t2);
     float2 tmax2 = min (tmax3.xx, tmax3.yz);
     ray.tmax = min (tmax2.x, tmax2.y);
	}
	
	float SampleDensity(float4 pos)
	{
		fixed x = step(pos.x, _MaxX) * step(_MinX, pos.x);
		fixed y = step(pos.y, _MaxY) * step(_MinY, pos.y);
		fixed z = step(pos.z, _MaxZ) * step(_MinZ, pos.z);		
		return  tex3Dlod(_NoiseTex3D, pos).r * x * y * z;
	}
	float sdq(float4 pos)
	{
		return  tex3Dlod(_NoiseTex3D, pos).r;
	}
	float3 CalcNormal(float4 pos)
	{
	    const float2 off = float2(0.01, 0);
		return normalize(float3(sdq(pos + off.xyyy) - sdq(pos - off.xyyy),
					  sdq(pos + off.yxyy) - sdq(pos - off.yxyy),
					  sdq(pos + off.yyxy) - sdq(pos - off.yyxy)));
	}
	float SampleCut(float3 pos, float3 basePos)
	{	
		//float3 wPos = (pos * 2.0) - 1.0; // convert texture space to -1 to 1; this is the wpos when origin is 0
		float3 worldPos = mul(unity_ObjectToWorld, pos) + basePos;
		float3 ba = normalize(_CuttingPos - worldPos);
		return step(0, dot(ba, _CuttingDir)); // if greater than 0 then data is in front of cutting plane if behind then cull
	}
	float4 CalcColor(float3 viewDir, float3 normal, float3 lightDir)
	{
		return float4(1,1,1,1);
	}
	v2f vert(appData i)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(i.vertex);
		o.screenPos = ComputeScreenPos(o.vertex);
		o.localPos = i.vertex;
		o.basePos = mul(unity_ObjectToWorld, float4(0,0,0,1));
		o.rayPers = mul(unity_CameraInvProjection, o.vertex) * _ProjectionParams.z;
		o.worldPos = mul(unity_ObjectToWorld, i.vertex);
		return o;
	}

	float4 fragTest(v2f i) : SV_Target
	{
	float3 worldDir = normalize(i.worldPos  - _WorldSpaceCameraPos); 
	float3 localDir = normalize(mul(unity_WorldToObject, worldDir));

	Ray ray;
	ray.from = i.localPos;
	ray.dir = localDir;
	RayBoxIntersection(ray);

	float stepSize = ray.tmax / (float)_NumSamples;
	float3 basePos = i.basePos.xyz;
	float3 localPos = i.localPos; 
	float3 localStep = localDir * stepSize;

	float sampleVal = 0;
	fixed4 dst = 0;

	//i.screenPos.xy /= i.screenPos.w;
	//float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy);
	//depth = Linear01Depth(depth);
	//float wDepth = depth * _ProjectionParams.z;

	//float3 reconstructedWPos = depth * i.rayPers;
	float amb = 1.0;
	for (int i = 0; i < _NumSamples; i++, localPos += localStep)
	{
	    sampleVal =  SampleDensity(float4(localPos + 0.5, 0)).r * SampleCut(localPos, basePos);
		if (sampleVal == 0.0 || sampleVal < _MinVoxelValue) 
		{ 
			continue;
		}
		
		float3 objectSpaceLightDir = normalize(mul(unity_WorldToObject, -_WorldSpaceLightPos0.xyz));
		float3 objectSpaceCamPos = normalize(mul(unity_WorldToObject, -_WorldSpaceCameraPos.xyz));

		float3 viewDir = normalize(localPos - objectSpaceCamPos);
		float3 amb = unity_AmbientSky.rgb;
		float3 N = CalcNormal(float4(localPos + 0.5, 0));
		float3 H = normalize(viewDir + objectSpaceLightDir);
		float NdotL = max(dot(N, objectSpaceLightDir.xyz), 0);
		float NdotH = max(dot(N, H), 0);
		float intensity = pow(NdotH, _SpecPower);

		float4 srcCol = float4(amb +  (_Color * _LightColor0.xyz * NdotL.xxx) + (_SpecularColor * intensity) , 1.0);
		dst = (1.0 - dst.a) * srcCol + dst;	

		if (dst.a >= .95)
		{
			break;
		}

	}
		return float4(dst);
	}
	fixed4 fragSurfaceShade(v2f i) : SV_Target
	{
	float3 worldDir = normalize(i.worldPos  - _WorldSpaceCameraPos); 
	float3 localDir = normalize(mul(unity_WorldToObject, worldDir));

	Ray ray;
	ray.from = i.localPos;
	ray.dir = localDir;
	RayBoxIntersection(ray);

	float stepSize = ray.tmax / (float)_NumSamples;
	float3 basePos = i.basePos.xyz;
	float3 localPos = i.localPos; 
	float3 localStep = localDir * stepSize;

	float sampleVal = 0;
	fixed4 dst = 0;

	for (int i = 0; i < _NumSamples; i++, localPos += localStep)
	{
	    sampleVal =  SampleDensity(float4(localPos + 0.5, 0)).r * SampleCut(localPos, basePos);//float4  (tex3Dlod(_NoiseTex3D, float4(localPos + 0.5, 0))).r;
		if (sampleVal == 0.0 || sampleVal < _MinVoxelValue) 
		{ 
			continue;
		}		
		float prevAlpha = sampleVal - (sampleVal * dst.a);
		dst.rgb = prevAlpha * (float3)sampleVal + dst.rgb;
		dst.a += prevAlpha;

		if (dst.a >= .95)
		{
			break;
		}
	}	
		return _Color * float4(dst);
	}	

	fixed4 fragAbsorption(v2f i) : SV_Target
	{
	float3 worldDir = normalize(i.worldPos  - _WorldSpaceCameraPos); 
	float3 localDir = normalize(mul(unity_WorldToObject, worldDir));
	
	Ray ray;
	ray.from = i.localPos;
	ray.dir = localDir;
	RayBoxIntersection(ray);

	//float stepSize = 1.0 / (float)_NumSamples;
	//float lightStepSize = 1.0 / (float)_NumLightSamples;
	float stepSize = ray.tmax / (float)_NumSamples;
	float lightStepSize = ray.tmax / (float)_NumLightSamples;

	float3 basePos = i.basePos.xyz;
	float3 localPos = i.localPos; 
	float3 localStep = localDir * stepSize;
	
	float density;
	
	// Light Variables
	float T = 1.0;
	float3 lightDir;

	float3 Loutput = (float3)0.0;
	float3 lightIntensity = (float3)8.0;

	[loop]
	for (int i = 0; i < _NumSamples; i++)
	{

		localPos += localStep;
		
		float sampleVal = (SampleDensity(float4(localPos.xyz + 0.5, 0))).r * SampleCut(localPos, basePos);

		density = sampleVal *_DensityFactor;
		if (density <= 0.0 ||  sampleVal < _MinVoxelValue) { continue; }
		T *= 1.0 - density * stepSize * _Absorption;

		if (T <= 0.01) break;

		float4 worldLightDir = -_WorldSpaceLightPos0;
		float3 wSpaceLightDir = worldLightDir;
		if(worldLightDir.w > 0)
		{
		 float3 wSpaceVertex = mul(unity_ObjectToWorld, localPos) + basePos;
		 wSpaceLightDir = (wSpaceVertex - worldLightDir.xyz);
		}
		lightDir = normalize(wSpaceLightDir) * lightStepSize;
		float T1 = 1.0;
		float3 lPos = localPos + lightDir;

		for (int i = 0; i < _NumLightSamples; i++)
		{
			float lightDensity = SampleDensity(float4(lPos.xyz + 0.5, 0)).r * SampleCut(lPos, basePos);
			T1 *= 1.0 - _Absorption  * stepSize * lightDensity; // lightStepSize
			if (T1 <= 0.01)
				break;

			lPos += lightDir;	
		}
		float3 Li = lightIntensity * T1;// * _LightColor0.rgb;
		Loutput += Li * T * density * stepSize;		
	}
	return  fixed4(Loutput, 1.0 - T);
	}