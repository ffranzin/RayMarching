// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Effects/RayMarchShader"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			Tags { "RenderType"="Opaque" }
			CGPROGRAM
	
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ DEBUG_PERFORMANCE
			#pragma target 3.0

			#include "UnityCG.cginc"

			uniform float4x4 _FrustumCornerES;
			uniform float4x4 _CameraInvViewMatrix;
			uniform float4 _MainTex_TexelSize;
			sampler2D _MainTex;
			uniform float3 _LightDir;
			uniform float3 _cameraWS;
			fixed4 colorTest = fixed4(1,0,0,0);

			fixed4 _Color;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 ray : TEXCOORD1;
			};

			float sdSphere( float3 p, float s )
			{
			  return length(p) - s;
			}

			float sdTorus(float3 p, float2 t)
			{
				float2 q = float2(length(p.xz) - t.x, p.y);
				return length(q) - t.y;
			}

			
			float map(float3 p) {
				return sdSphere(p, 1);
				return sdTorus(p, float2(1, 0.2));
			}

			float3 CalcNormal(float3 pos)
			{
				const float2 eps = float2(0.001, 0.0);
			
				float3 normal = float3(
								map(pos + eps.xyy).x - map(pos - eps.xyy).x,
								map(pos + eps.yxy).x - map(pos - eps.yxy).x,
								map(pos + eps.yyx).x - map(pos - eps.yyx).x);

				return normalize(normal);
			}


			//Parameters: ro = rayOrigin rd = rayDirection
			fixed4 RayMarching( float3 ro, float3 rd)
			{
				fixed4 ret = fixed4(1,0,0,0);

				const int maxStep = 128;
				float dist = 0;

				for(int i=0; i<maxStep; i = i+1)
				{
					float3 p = ro + rd * dist;

					float d = map(p);

					if(d < 0.001)
					{
						float nor = CalcNormal(p);
						ret = fixed4(dot(- _LightDir.xyz, nor).rrr, 1);
						break;
					}

					dist += d;
				}
				return ret;
			}



			v2f vert (appdata IN)
			{
				v2f OUT;

				half index = IN.vertex.z; // index passed via custom blit function
				IN.vertex.z = 0.1;

				OUT.pos = UnityObjectToClipPos(IN.vertex);
				OUT.uv = IN.uv.xy;

				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0)
						OUT.uv.y = 1 - OUT.uv.y;
				#endif		
				
				OUT.ray = _FrustumCornerES[(int)index].xyz;
				OUT.ray = mul(_CameraInvViewMatrix, OUT.ray);

				return OUT;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{	
				float3 ro = _cameraWS;
				float3 rd = normalize(i.ray.xyz);

				fixed3 col = tex2D(_MainTex, i.uv);
				fixed4 add = RayMarching(ro, rd);
				
				return fixed4(col*(1.0 - add.w) + add.xyz * add.w, 1.0);
			}
		
			ENDCG
		}

	}
}
